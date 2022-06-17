#!/bin/bash

csvFile=""
downloader="youtube-dl"
processNumber=5
musicPath=""

###
# Set operation variables
if [ -z $1 ]; then
    echo "ERROR: No .csv file provided."
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

if [[ ! -d "$musicPath" ]]
then
    echo "ERROR: Selected path does not exist: $musicPath"
    exit 1
fi
###

###
# Check if downloader and ffmpeg are present
if ! command -v $downloader &> /dev/null
then
    echo "ERROR: Downloader could not be found: ${downloader}"
    exit 1
fi

if ! command -v "ffmpeg" &> /dev/null
then
    echo "ERROR: FFMPEG not found"
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

csvHeadder=$(head -1 $csvFile | tr ',' '\n' | nl)

###
# Evaluate the coresponding column number for each name
colNumTitle=$(echo "$csvHeadder" | grep -w "$colNameTitle" | tr -d " " | awk -F " " '{print $1}')
colNumArtist=$(echo "$csvHeadder" | grep -w "$colNameArtist" | tr -d " " | awk -F " " '{print $1}' | head -1)
colNumImageURL=$(echo "$csvHeadder" | grep -w "$colNameImageURL" | tr -d " " | awk -F " " '{print $1}')
colNumAlbumName=$(echo "$csvHeadder"  | grep -w "$colNameAlbumName" | tr -d " " | awk -F " " '{print $1}')
colNumAlbumArtistName=$(echo "$csvHeadder" | grep -w "$colNameAlbumArtistName" | tr -d " " | awk -F " " '{print $1}')
colNumDiscNumber=$(echo "$csvHeadder" | grep -w "$colNameDiscNum" | tr -d " " | awk -F " " '{print $1}')
colNumTrack=$(echo "$csvHeadder" | grep -w "$colNameTrackNumber" | tr -d " " | awk -F " " '{print $1}')
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
    songTitle="$(echo ${colArray[$colNumTitle - 1]} | tr '_' ' ')"
    artist="$(echo ${colArray[$colNumArtist - 1]} | tr '_' ' ')"
    image="$(echo ${colArray[$colNumImageURL - 1]} | tr '_' ' ')"
    albumName="$(echo ${colArray[$colNumAlbumName - 1]} | tr '_' ' ')"
    albumArtistsName="$(echo ${colArray[$colNumAlbumArtistName - 1]} | tr '_' ' ')"
    discNumber="$(echo ${colArray[$colNumDiscNumber - 1]} | tr '_' ' ')"
    trackNumber="$(echo ${colArray[$colNumTrack - 1]}| tr '_' ' ')"
    ###

    ###
    # Get rid of possible old cache
    if [[ -f "/tmp/${songTitle}.mp3" ]]; then
        echo "Clearing cached file: /tmp/${songTitle}.mp3"
        rm "/tmp/${songTitle}.mp3"
    fi

    if [[ -f "/tmp/${songTitle}.jpg" ]]; then
        echo "Clearing cached file: /tmp/${songTitle}.jpg"
        rm "/tmp/${songTitle}.jpg"
    fi
    ###

    ###
    # Get cover and .mp3 file
    echo "Downloading: ${songTitle}"
    curl -s $image > "/tmp/${songTitle}.jpg" &
    $downloader -o "/tmp/${songTitle}.%(ext)s" "ytsearch1:${songTitle} ${artist}" -x --audio-format mp3 --audio-quality 0 --quiet &
    wait
    ###

    ###
    # Merge cover, metadata and .mp3 file
    ffmpeg -i "/tmp/${songTitle}.mp3" -i "/tmp/$songTitle.jpg" \
    -map 0:0 -map 1:0 -codec copy -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
    -metadata artist="$artist" \
    -metadata title="$songTitle" \
    -metadata album="$albumName" \
    -metadata album_artist="$albumArtistsName" \
    -metadata disc="$discNumber" \
    -metadata track="$trackNumber" \
    -hide_banner \
    -loglevel error \
    "${musicPath}/${songTitle}.mp3" -y
    ###

    ###
    # Clear cached files
    rm "/tmp/${songTitle}.jpg"
    rm "/tmp/${songTitle}.mp3"
    ###

    echo "Finished: ${songTitle}"
}
###

###
# Start parallel crawling instances -
for song in "${songArray[@]}"
do
    ((i=i%processNumber)); ((i++==0)) && wait
    crawlerTask "$song" &
done
###

exit 0
