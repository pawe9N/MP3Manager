#!/bin/bash

while getopts "vh" OPTION
do
    case $OPTION in
		v ) echo "MP3Manager, version 1.0.0";;
		h ) echo "To play song select 'Play song' option"
		    echo "To play song with specific filename select 'Play song (search by filename)'"
		    echo "To see and edit MP3 tags select 'Show and edit file tags' option"
		    echo "To download new MP3 file select 'Download MP3 file from youtube' option"
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
		done < <(find $HOME -iname "*.mp3" -print | grep -i $1)
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
		--menu "Make your choice" 20 60 10 \
		1 "Play song" \
		2 "Play song (search by filename)" \
		3 "Play song (search by artist tag)" \
		4 "Show and edit file tags" \
		5 "Download MP3 file from youtube (by video id)" \
		6 "Move MP3 files to Music directory" \
		7 "Exit" 2>.tempfile
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
		dialog --backtitle "MP3Manager" \
		       	--title "Search by artist" \
			--inputbox "Enter artist name" 8 60 2>.tempfile
		artist=$?
		if [ "$artist" -eq "0" ]; then
			artist=`cat .tempfile`
			f=0
			files=()
			while ((f++)); read file ;
			do
				if [[ $(id3info "$file" | grep "TPE1" | awk '{$1="";$2="";$3="";$4="";print}' | sed -e 's/^[ \t]*//' | grep $artist) ]]; then
					files+=( "$file" $f )
				fi
			done < <(find $HOME -iname "*.mp3" -print)
			dialog --menu  "Make your own choice" 13 70 6 "${files[@]}" 2>.tempfile
			output=`cat .tempfile`
			rm -f .tempfile
			clear
			mpg123 "$output"
			pid=$!
			wait pid
		fi
		MainMenu	
	elif [ "$output" = "4" ]; then
		ShowFiles
		t=0
		tagitems=""
		while ((t++)); read filetag ;
		do
			tagitems+="$filetag \n"
		done < <(id3info "$output" | grep "===" | awk '{$1="";$2="";print}' | sed -e 's/^[ \t]*//')
		
		if [ -z "$tagitems" ]; then
			tagitems="There are no tags"
		fi

		dialog --backtitle "MP3Manager" \
		       --title "Do you want to edit this file's tags?" \
	       	       --yesno "$tagitems" 7 60
		toedit=$?

		if [ "$toedit" -eq 0 ]; then
			dialog --backtitle "MP3Manager" \
				--title "Select tag to change" \
				--menu "Make your choice" 13 60 6 \
				1 "Title" \
				2 "Artist" \
				3 "Album" \
				4 "Year" \
				5 "Genre" 2>.tempfile
			tag=`cat .tempfile`
			case $tag in
				1 ) tagname="title"
				    prefix="s";;
				2 ) tagname="artist"
				    prefix="a";;
				3 ) tagname="album"
				    prefix="A";;
				4 ) tagname="year"
				    prefix="y";;
				5 ) tagname="genre"
				    prefix="g";;
			esac
			dialog --backtitle "MP3Manager" \
				--title "Edit $tagname" \
				--inputbox "Enter new $tagname" 8 60 2>.tempfile
			value=`cat .tempfile`
			echo $output
			echo $tag
			echo $value
			id3tag -"$prefix""$value" "$output"
		fi
		MainMenu
	elif [ "$output" = "5" ]; then
		video_id=$(dialog --backtitle "MP3Manager" \
			--title "Download MP3 file from youtube" \
			--inputbox "Enter video id" 8 60 3>&1 1>&2 2>&3 3>&-)
		clear
		url="https://www.youtube.com/watch?v=$video_id"
		echo $url
		youtube-dl -x --audio-format mp3 "$url"
		pid=$!
		wait pid
		MainMenu
	elif [ "$output" = "6" ]; then
		find $HOME -iname "*.mp3" -type f -exec /bin/mv -n {} $HOME/Music \;
		MainMenu
	elif [ "$output" = "7" ]; then
		clear
	else 
		clear
	fi
}
MainMenu
exit 0
