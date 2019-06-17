#!/bin/bash

FILES_MENU_OUTPUT="-1"

while getopts "vhm" OPTION
do
    case $OPTION in
	    	# version
		v ) echo "MP3Manager, version 1.0.0";;
		# help
		h ) echo "To play song select 'Play song' option"
		    echo "To play song with specific filename select 'Play song (search by filename)' option"
		    echo "To play song with specific artist select 'Play song (search by artist tag)' option"
		    echo "To see and edit MP3 tags select 'Show and edit file tags' option"
		    echo "To download new MP3 file with specific video id on youtube select 'Download MP3 file from youtube (by video id)' option"
		    echo "To download new MP3 file which is on the list in file videosToDownload.txt select 'Download MP3 file from youtube (by video id from file) option'"
		    echo "To move all your MP3 files to Music folder in user home directory select 'Move MP3 files to Music directory' option"
		    echo "To quit the program select 'Exit' option";;
		# manual
		m ) man ./MP3Manager.man;;
    esac
    exit 0
done

# function for showing menu with list of mp3 filenames with path
ShowFiles(){
	menu_items=()
	value_items=()

	# if there is no filename parameter then show all files
	if [ -z "$1" ]; then
		while ((i++)); read song ;
		do
			value_items+=( "$song" )
			menu_song="$(echo $song | sed 's:.*/::' | cut -f 1 -d '.')"
			menu_items+=( $i "$menu_song" )
		done < <(find $HOME -iname "*.mp3" -print | sort)

	# if there is a filename parameter then show all files with this filename
	else
		while ((i++)); read song ;
		do
			value_items+=(  "$song" )
			menu_song="$(echo $song | sed 's:.*/::' | cut -f 1 -d '.')"
			menu_items+=( $i "$menu_song" )
		done < <(find $HOME -iname "*.mp3" -print | grep -i $1 | sort)
	fi
	dialog --menu  "Make your own choice" 20 90 10 "${menu_items[@]}" 2>.tempfile
	
	# if user select sth then get output from temporary file
	if [ "$?" -eq "0" ]; then
		selected_index=`cat .tempfile`
		selected_index=`expr $selected_index - 1`
		FILES_MENU_OUTPUT="${value_items[$selected_index]}"
		rm -f .tempfile
		clear
	
	# if user selects cancel option then go to main menu
	else 
		MainMenu
	fi
}

# function for showing mp3 file tags with possibility to edit them
ShowAndEditTags(){
	t=0
	tag_items=""

	# take tags from file
	while ((t++)); read filetag ;
	do
		tag_items+="$filetag \n"
	done < <(id3info "$FILES_MENU_OUTPUT" | grep "===" | awk '{$1="";$2="";print}' | sed -e 's/^[ \t]*//')
	
	# if file hasn't tags then show this message
	if [ -z "$tag_items" ]; then
		tag_items="There are no tags"
	fi

	filename="$(echo $FILES_MENU_OUTPUT | sed 's:.*/::' | cut -f 1 -d '.')"

	# show tags and ask user if he wants to edit file's tags
	dialog --backtitle "MP3Manager" \
		--title "Do you want to edit ($filename) tags?" \
       	       --yesno "$tag_items" 7 80
	to_edit=$?
		
	# if user wants to edit tags
	if [ "$to_edit" -eq 0 ]; then
		dialog --backtitle "MP3Manager" \
			--title "Select tag to change" \
			--menu "Make your choice" 13 80 6 \
			1 "Title" \
			2 "Artist" \
			3 "Album" \
			4 "Year" \
			5 "Genre" 2>.tempfile

		# if user selected tag to change
		if [ "$?" -eq "0" ]; then
			tag=`cat .tempfile`
			rm -f .tempfile
			case $tag in
				# set variables for changing title
				1 ) tagname="title"
				    prefix="s";;
				# set variables for changing artist
				2 ) tagname="artist"
				    prefix="a";;
				# set variables for changing album
				3 ) tagname="album"
				    prefix="A";;
				# set variables for changing year
				4 ) tagname="year"
				    prefix="y";;
			        # set variables for chaning genre (SHORT type)
				5 ) tagname="genre"
				    prefix="g";;
			esac
			dialog --backtitle "MP3Manager" \
				--title "Edit $tagname" \
				--inputbox "Enter new $tagname" 8 80 2>.tempfile
			if [ "$?" -eq "0" ]; then
				value=`cat .tempfile`
				# change tag
				id3tag -"$prefix""$value" "$FILES_MENU_OUTPUT"
				ShowAndEditTags
			fi
		fi
	fi
	
}

# function for showing menu with list of script's functionality
MainMenu(){
	MAIN_MENU_OUTPUT="-1"

	dialog --backtitle "MP3Manager" \
		--title "Main menu" \
		--menu "Make your choice" 20 80 10 \
		1 "Play song" \
		2 "Play song (search by filename)" \
		3 "Play song (search by artist tag)" \
		4 "Show and edit file tags" \
		5 "Download MP3 file from youtube (by video id)" \
		6 "Download MP3 file from youtube (by video id from file)" \
		7 "Move MP3 files to Music directory" \
		8 "Exit" 2>.tempfile
	MAIN_MENU_OUTPUT=`cat .tempfile`
	rm -f .tempfile
	i=0

	# seleced option for playing song from menu
	if [ "$MAIN_MENU_OUTPUT" = "1" ]; then
		ShowFiles
		# play selected mp3 file
		mpg123 "$FILES_MENU_OUTPUT"
		pid=$!
		# wait for playing to the end and after that go to main menu
		wait pid
		MainMenu

	# selected option for playing song from menu filtered by filename
	elif [ "$MAIN_MENU_OUTPUT" = "2" ]; then
		dialog --backtitle "MP3Manager" \
		       	--title "Search by filename" \
			--inputbox "Enter filename" 8 80 2>.tempfile
		# check whether the user hasn't chosen cancel option
		if [ "$?" -eq "0" ]; then
			# if not then play mp3 file and wait for end
			fname=`cat .tempfile`
			rm -f .tempfile
			ShowFiles "$fname"
			mpg123 "$FILES_MENU_OUTPUT"
			pid=$!
			wait pid
		fi 
		MainMenu

	# selected option for playing song from menu filtered by artist tag
	elif [ "$MAIN_MENU_OUTPUT" = "3" ]; then
		#input artist name
		dialog --backtitle "MP3Manager" \
		       	--title "Search by artist" \
			--inputbox "Enter artist name" 8 80 2>.tempfile
		artist=$?
		if [ "$artist" -eq "0" ]; then
			artist=`cat .tempfile`
			rm -f .tempfile
			i=0
			menu_items=()
			value_items=()
			# find files with specified artist tag
			while read song ;
			do
				if [[ $(id3info "$song" | grep "TPE1" | awk '{$1="";$2="";$3="";$4="";print}' | sed -e 's/^[ \t]*//' | grep $artist | sort) ]]; then
					value_items+=(  "$song" )
					menu_song="$(echo $song | sed 's:.*/::' | cut -f 1 -d '.')"
					menu_items+=( $i "$menu_song" )
					i=`expr $i + 1`
				fi
			done < <(find $HOME -iname "*.mp3" -print)
			dialog --menu  "Make your own choice" 20 90 10 "${menu_items[@]}" 2>.tempfile
			# if user selected file then play it
			if [ "$?" -eq "0" ]; then
				selected_index=`cat .tempfile`
				selected_index=`expr $selected_index - 1`
				FILES_MENU_OUTPUT="${value_items[$selected_index]}"
				rm -f .tempfile
				clear
				mpg123 "$FILES_MENU_OUTPUT"
				pid=$!
				wait pid
			fi
		fi
		MainMenu	
	
	# selected option for showing and editing mp3 tags
	elif [ "$MAIN_MENU_OUTPUT" = "4" ]; then
		ShowFiles
		ShowAndEditTags		
		MainMenu

	# selected option for downloading mp3 file from youtube by video id
	elif [ "$MAIN_MENU_OUTPUT" = "5" ]; then
		# get video id from user
		video_id=$(dialog --backtitle "MP3Manager" \
			--title "Download MP3 file from youtube" \
			--inputbox "Enter video id" 8 80 3>&1 1>&2 2>&3 3>&-)

		# if user entered video id
		if [ "$?" -eq "0" ]; then
			clear
			# setting url for specified video to download as mp3 file
			url="https://www.youtube.com/watch?v=$video_id"
			# download video as mp3 file and wait for end
			youtube-dl -x --audio-format mp3 -o '%(title)s.%(ext)s' "$url"
			pid=$!
			wait pid
		fi
		MainMenu
	
	# selected option for downloading mp3 file from youtube by video id from file
	elif [ "$MAIN_MENU_OUTPUT" = "6" ]; then
		# get video ids with song titles from file
		menu_items=()
		value_items=()
		v=0
		while ((v++)); read songname video_id ;
		do
			menu_items+=( $v "$songname" )
			value_items+=( "$video_id" )
		done < <(cat videosToDownload.txt | sort)
		# select title from menu
		dialog --menu  "Choose file to download" 20 80 10 "${menu_items[@]}" 2>.tempfile
		# if user selected title then download it and wait for end
		if [ "$?" -eq "0" ]; then
			selected_id=`cat .tempfile`
			rm -f .tempfile
			selected_id=`expr $selected_id - 1`
			selected_video_id="${valueitems[$selected_id]}"
			clear
			url="https://www.youtube.com/watch?v=$selected_video_id"
			youtube-dl -x --audio-format mp3 -o '%(title)s.%(ext)s' "$url"
			pid=$	
			wait pid
		fi
		MainMenu
	
	# selected option for moving all mp3 files to Music folder in user home directory
	elif [ "$MAIN_MENU_OUTPUT" = "7" ]; then
		find $HOME -iname "*.mp3" -type f -exec /bin/mv -n --force {} $HOME/Music 2>/dev/null \; 
		MainMenu

	# selected exit option
	elif [ "$MAIN_MENU_OUTPUT" = "8" ]; then
		clear
		exit 0

	# clicked cancel button
	else 
		clear
		exit 0
	fi
}
MainMenu
exit 0
