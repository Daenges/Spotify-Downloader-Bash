![TitleImage](https://user-images.githubusercontent.com/57369924/221327749-5c84244d-92f9-4014-97c2-7a6af55e05b1.jpg)

An automation script to download **Spotify exported** songs using `yt-dlp` / `youtube-dl` and `FFMPEG`.

---

## :pencil2: Key Features
:heavy_check_mark: **Customizable**<br>
:heavy_check_mark: **Parallel downloads**<br>
:heavy_check_mark: **Full metadata handling**<br>
:heavy_check_mark: **No additional overhead**<br>
:heavy_check_mark: **No need to deal with the Spotify API**<br>

&nbsp;

## :clipboard: Script Setup

1. Visit &nbsp;<a href="https://watsonbox.github.io/exportify/"><img style="height: 1em;" src="https://watsonbox.github.io/exportify/favicon.png"> <b>Exportify</b></a>, **sign in with your Spotify credentials** and **export** your desired playlists as a `.csv` file.
2. Install a **downloader** (`yt-dlp` or `youtube-dl` &rarr; **Check for a recent version!** ) and `FFMPEG` with your prefered package manager.
3. **Get the script** and **make it executable**:
```sh
wget https://raw.githubusercontent.com/Daenges/Spotify-Downloader-Bash/main/Downloader.sh &&\
chmod +x Downloader.sh
```
4. Check the script one last time with your favourite editor before execution.

&nbsp;

## :arrow_forward: Script Execution
:arrow_right_hook: `./Downloader.sh "Path/To/YourPlaylist.csv"` starts the script with default parameters.

<br>

*These parameters are:*
```sh
csvFile=""
downloader=""
processNumber=5
musicPath="./"
additionalKeywords=""
```
<br>

:bulb: **Execution with Parameters:** `./Downloader.sh "Path/To/YourPlaylist.csv" --additionalKeywords clean --processNumber 10`

|Parameter|Usage|
|:-:|-|
|`csvFile`|Must be entered as first parameter on execution and sets the path of your playlist file.|
|`downloader`|Sets the download command<br>There is an automatic detection *(prefering `yt-dlp`)*, that **can be overwritten with:** `--downloader youtube-dl`.|
|`processNumber`|Number of parallel started Downloadprocesses.<br>**Can be altered with:** `--processNumber 10`|
|`musicPath`|Sets the path where the music is saved, default is the execution path of the script.<br>**Can be changed with:** `--musicPath /Your/New/Path`|
|`additionalKeywords`|Since we are performing Youtube searches with `Title` and `Author`, certain keywords<br>(e.g. `clean`, `lyrics`, ...) might improve the results.<br>**Can be set with:** `--additionalKeywords clean`|
<br>

## :x: Errors
If you got any error, **check the version of your downloader against their latest release** (**[yt-dlp](https://github.com/yt-dlp/yt-dlp/releases)** or **[youtube-dl](https://github.com/ytdl-org/youtube-dl/releases)**).
Most errors arise through Youtube updating their page which needs to be implemented into the downloaders.
If you have a recent downloader version and still get errors, feel free to create an issue here.

<br>

## :mag_right: What is the script doing in the background?
1. Reading all parameters
2. Getting the column number for the according data fields (`Artist Name`, `Track Name`, ...)
3. Creating an array containing all lines of data
4. Starting parallel jobs that handle the download process
    - download picture and `.mp3` into `/temp/`
    - merge them with `FFMPEG` while also applying metadata