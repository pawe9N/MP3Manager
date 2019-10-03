# MP3Manager
A simple bash script that manages mp3 files

## Description of script
This script allows to turn on mp3 files, change tags, download music from youtube and move all your mp3 files to default Music directory

## Requirements
For the application to work properly you must have the latest versions of the following libraries / packages:
- dialog
- mpg123
- id3lib
- youtube-dl

## Manual
If you want to see manual you have to run: 
```
man MP3Manager.man 
```
command in your terminal.

## Getting Started
If you want to use this program, you have to set execute permission on your script: 
```
chmod +x MP3Manager.sh
```
and then run it by:
```
./MP3Manager.sh
```
## Preview

- menu list
<img src="https://i.imgur.com/bnqQilC.png">

- example page with song titles
<img src="https://i.imgur.com/AOfOPoj.png">

- search by filename
<img src="https://i.imgur.com/mWEbxBo.png">
<img src="https://i.imgur.com/n1oTZkK.png">

- search by artist
<img src="https://i.imgur.com/dUfIh0S.png">
<img src="https://i.imgur.com/oh8u8AN.png">

- play song
<img src="https://i.imgur.com/botVicc.png">

-edit tags
<img src="https://i.imgur.com/nU7OiwT.png">
<img src="https://i.imgur.com/wJnoYoF.png">
<img src="https://i.imgur.com/hIKwzo9.png">
<img src="https://i.imgur.com/3WOZQcq.png">
<img src="https://i.imgur.com/pWLPjE6.png">

- download mp3 from youtube by video id
<img src="https://i.imgur.com/yrbG46z.png">
<img src="https://i.imgur.com/rWZgDUh.png">

- download mp3 from youtube using the video id saved in file
<img src="https://i.imgur.com/j2pDtwl.png">
<img src="https://i.imgur.com/UTygP2a.png">

- move all mp3 files to Music directory
```
find $HOME -iname "*.mp3" -type f -exec /bin/mv -n --force {} $HOME/Music 2>/dev/null \; 
```
