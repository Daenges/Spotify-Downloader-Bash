#!/bin/bash

csvFile=""
downloader=""
processNumber=5
musicPath="./"
additionalKeywords=""

###
# Set operation variables
if [ -z $1 ]; then
    echo "ERROR: No .csv file provided. Obtain one here: https://watsonbox.github.io/exportify/"
    exit 1
else
    csvFile=$1
fi

while [ $# -gt 0 ]; do
   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
   fi
   shift
done

if [[ ! -z $musicPath ]] && [[ ! -d "$musicPath" ]]
then
    echo "ERROR: Selected path does not exist: $musicPath"
    exit 1
fi
###

###
# Detect downloader and FFMPEG
if [[ -z "$downloader" ]]
then
    if command -v yt-dlp &> /dev/null
    then
        downloader="yt-dlp"
    elif command -v youtube-dl &> /dev/null
    then
        downloader="youtube-dl"
    else
        echo "No downloader provided or detected. Install 'yt-dlp' or 'youtube-dl'."
        exit 1
    fi
fi
echo "Using '$downloader' as downloader."

if ! command -v "ffmpeg" &> /dev/null
then
    echo "ERROR: FFMPEG could not be found. Install 'FFMPEG'."
    exit 1
fi
###

###
# Name of the different columns containing the metadata
colNameTitle="Track Name"
colNameArtist="Artist Name"
colNameImageURL="Album Image URL"
colNameAlbumName="Album Name"
colNameAlbumArtistName="Album Artist Name(s)"
colNameDiscNum="Disc Number"
colNameTrackNumber="Track Number"
###

csvHeader=$(head -1 $csvFile | tr ',' '\n' | nl)

###
# Evaluate the coresponding column number for each name
colNumTitle=$(echo "$csvHeader" | grep -w "$colNameTitle" | tr -d " " | awk -F " " '{print $1}')
colNumArtist=$(echo "$csvHeader" | grep -w "$colNameArtist" | tr -d " " | awk -F " " '{print $1}' | head -1)
colNumImageURL=$(echo "$csvHeader" | grep -w "$colNameImageURL" | tr -d " " | awk -F " " '{print $1}')
colNumAlbumName=$(echo "$csvHeader"  | grep -w "$colNameAlbumName" | tr -d " " | awk -F " " '{print $1}')
colNumAlbumArtistName=$(echo "$csvHeader" | grep -w "$colNameAlbumArtistName" | tr -d " " | awk -F " " '{print $1}')
colNumDiscNumber=$(echo "$csvHeader" | grep -w "$colNameDiscNum" | tr -d " " | awk -F " " '{print $1}')
colNumTrack=$(echo "$csvHeader" | grep -w "$colNameTrackNumber" | tr -d " " | awk -F " " '{print $1}')
###

###
# Save all lines in array
songArray=()
###

###
# Populate array from file
while read songLine
do
    songArray+=("$songLine")
done < <(tail -n +2 $csvFile)
echo "Found: ${#songArray[@]} entries"
###

###
# Get a line from .csv file as input - download and merge everything
crawlerTask() {
    ###
    # Split column names to array
    colArray=($(echo "$1" | grep -Eo '"([^"]*)"' | sed 's/\"//g' | tr ' ' '_'))
    ###

    ###
    # Assert values for this entry to variables
    # Special replacement for songTitle as it is used for paths
    songTitle="$(echo ${colArray[$colNumTitle - 1]} | tr '_/\\' ' ')"
    artist="$(echo ${colArray[$colNumArtist - 1]} | tr '_' ' ' | cut -f1 -d',')"
    image="$(echo ${colArray[$colNumImageURL - 1]} | tr '_' ' ')"
    albumName="$(echo ${colArray[$colNumAlbumName - 1]} | tr '_' ' ')"
    albumArtistsName="$(echo ${colArray[$colNumAlbumArtistName - 1]} | tr '_' ' ')"
    discNumber="$(echo ${colArray[$colNumDiscNumber - 1]} | tr '_' ' ')"
    trackNumber="$(echo ${colArray[$colNumTrack - 1]}| tr '_' ' ')"
    ###

    ###
    # Get rid of possible old cache
    clearCache() {
        if [[ -f "/tmp/${songTitle}.mp3" ]]; then
            rm "/tmp/${songTitle}.mp3"
        fi

        if [[ -f "/tmp/${songTitle}.jpg" ]]; then
            rm "/tmp/${songTitle}.jpg"
        fi
    }

    clearCache
    ###

    ###
    # Prevent download if file already exists
    if [[ ! -f "${musicPath}${songTitle}.mp3" ]]; then
        ###
        # Get cover and .mp3 file
        curl -s $image > "/tmp/${songTitle}.jpg" &
        $downloader -o "/tmp/${songTitle}.%(ext)s" $(echo "https://music.youtube.com/search?q=${songTitle}+${artist}+${additionalKeywords}#Songs" | tr " " "+") -I 1 -x --audio-format mp3 --audio-quality 0 --quiet &
        wait
        ###

        ###
        # Merge cover, metadata and .mp3 file
        ffmpeg -i "/tmp/${songTitle}.mp3" -i "/tmp/$songTitle.jpg" \
        -map 0:0 -map 1:0 -codec copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
        -metadata artist="$artist" \
        -metadata album="$albumName" \
        -metadata album_artist="$albumArtistsName" \
        -metadata disc="$discNumber" \
        -metadata title="$songTitle" \
        -metadata track="$trackNumber" \
        -hide_banner \
        -loglevel error \
        "${musicPath}${songTitle}.mp3" -y
        ###

        ###
        # Clear cached files
        clearCache
        ###

        echo "Finished: ${songTitle}"
    else
        echo "Skipping: ${songTitle}.mp3 - (File already exists in: ${musicPath})"
    fi
    ###
}

###
startedSongs=0
numJobs="\j" # Number of background jobs.
###

###
# Start parallel crawling instances
for song in "${songArray[@]}"
do
    while (( ${numJobs@P} >= ${processNumber} )); do
        wait -n
    done

    crawlerTask "$song" &

    ((startedSongs++))
    echo "Status: #${startedSongs} downloads started - $(awk "BEGIN {print ((${startedSongs}/${#songArray[@]})*100)}")%"
done

echo "All downloads have been started. Waiting for completion."
wait $(jobs -p)
###

exit 0
