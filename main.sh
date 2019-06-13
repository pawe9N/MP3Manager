#!/bin/bash

while getopts "vh" OPTION
do
    case $OPTION in
		v ) echo "MP3Manager, version 1.0.0";;
		h ) echo "To play song select 'Play song' option"
		    echo "To see and edit MP3 tags select 'Show and edit file tags' option"
		    echo "To download new MP3 files select 'Download MP3 files' option"
		    echo "To quit the program select 'Exit' option";;
    esac
    exit 0
done

ShowFiles(){
	menuitems=()
	while ((i++)); read song ;
	do
		menuitems+=( "$song" $i )
	done < <(find $HOME -iname "*.mp3" -print)

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
		2 "Show and edit file tags" \
		3 "Download MP3 files" \
		4 "Exit" 2> .tempfile
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
		ShowFiles
		MainMenu
	elif [ "$output" = "3" ]; then
		clear
	elif [ "$output" = "4" ]; then
		clear
	fi
}
MainMenu
exit 0
