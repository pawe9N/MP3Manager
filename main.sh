#!/bin/bash

while getopts "vh" OPTION
do
    case $OPTION in
		v ) echo "MP3Manager, version 1.0.0";;
		h ) echo "To play song select 'Play song' option"
		    echo "To play song with specific filename select 'Play song (search by filename)'"
		    echo "To see and edit MP3 tags select 'Show and edit file tags' option"
		    echo "To download new MP3 files select 'Download MP3 files' option"
		    echo "To quit the program select 'Exit' option";;
    esac
    exit 0
done

ShowFiles(){
	menuitems=()
	if [ -z "$1" ]; then
		while ((i++)); read song ;
		do
			menuitems+=( "$song" $i )
		done < <(find $HOME -iname "*.mp3" -print)
	else
		while ((i++)); read song ;
		do
			menuitems+=( "$song" $i )
		done < <(find $HOME -iname "*.mp3" -print | grep $1)
	fi
	dialog --menu  "Make your own choice" 13 70 6 "${menuitems[@]}" 2>.tempfile
	output=`cat .tempfile`
	rm -f .tempfile
	echo $output
	clear
}

MainMenu(){
	dialog --backtitle "MP3Manager" \
		--title "Main menu" \
		--menu "Make your choice" 13 60 6 \
		1 "Play song" \
		2 "Play song (search by filename)" \
		3 "Show and edit file tags" \
		4 "Download MP3 files" \
		5 "Exit" 2>.tempfile
	output=`cat .tempfile`
	echo $output
	rm -f .tempfile
	i=0
	if [ "$output" = "1" ]; then
		ShowFiles
		mpg123 "$output"
		pid=$!
		wait pid
		MainMenu
	elif [ "$output" = "2" ]; then
		dialog --backtitle "MP3Manager" \
		       	--title "Search by filename" \
			--inputbox "Enter filename" 8 60 2>.tempfile
		fname=`cat .tempfile`
		echo $fname
		ShowFiles "$fname"
		mpg123 "$output"
		pid=$!
		wait pid
		MainMenu
	elif [ "$output" = "3" ]; then
		ShowFiles
		MainMenu
	elif [ "$output" = "4" ]; then
		clear
	elif [ "$output" = "5" ]; then
		clear
	fi
}
MainMenu
exit 0
