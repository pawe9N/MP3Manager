#!/bin/bash

MainMenu(){
dialog --backtitle "MP3Manager" \
	--title "Main menu" \
	--menu "Make your choice" 13 60 6 \
	1 "Play song" \
	2 "Exit" 2> .tempfile
output=`cat .tempfile`
echo $output
rm -f .tempfile

if [ "$output" = "1" ]; then
	menuitems=()
	while ((i++)); read song ;
	do
		menuitems+=( "$song" $i )
	done < <(ls -A1 ../../Downloads/*.mp3)

	dialog --menu  "Make your own choice" 13 70 6 "${menuitems[@]}" 2>.tempfile
	output=`cat .tempfile`
	rm -f .tempfile
	echo $output
	clear
	mpg123 "$output"
	pid=$!
	wait pid
	MainMenu
elif [ "$output" = "2" ]; then
	clear
fi
}
MainMenu
exit 0
