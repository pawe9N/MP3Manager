#!/bin/bash

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
		m ) man ./MP3Manager;;
    esac
    exit 0
done

# function for showing menu with list of mp3 filenames with path
ShowFiles(){
	menuitems=()

	# if there is no filename parameter then show all files
	if [ -z "$1" ]; then
		while ((i++)); read song ;
		do
			menuitems+=( "$song" $i )
		done < <(find $HOME -iname "*.mp3" -print | sort)

	# if there is a filename parameter then show all files with this filename
	else
		while ((i++)); read song ;
		do
			menuitems+=( "$song" $i )
		done < <(find $HOME -iname "*.mp3" -print | grep -i $1 | sort)
	fi
	dialog --menu  "Make your own choice" 20 90 10 "${menuitems[@]}" 2>.tempfile
	
	# if user select sth then get output from temporary file
	if [ "$?" -eq "0" ]; then
		output=`cat .tempfile`
		rm -f .tempfile
		clear
	
	# if user selects cancel option then go to main menu
	else 
		MainMenu
	fi
}

# function for showing menu with list of script's functionality
MainMenu(){
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
	output=`cat .tempfile`
	echo $output
	rm -f .tempfile
	i=0

	# seleced option for playing song from menu
	if [ "$output" = "1" ]; then
		ShowFiles
		# play selected mp3 file
		mpg123 "$output"
		pid=$!
		# wait for playing to the end and after that go to main menu
		wait pid
		MainMenu

	# selected option for playing song from menu filtered by filename
	elif [ "$output" = "2" ]; then
		dialog --backtitle "MP3Manager" \
		       	--title "Search by filename" \
			--inputbox "Enter filename" 8 80 2>.tempfile
		# check whether the user hasn't chosen cancel option
		if [ "$?" -eq "0" ]; then
			# if not then play mp3 file and wait for end
			fname=`cat .tempfile`
			echo $fname
			ShowFiles "$fname"
			mpg123 "$output"
			pid=$!
			wait pid
		fi 
		MainMenu

	# selected option for playing song from menu filtered by artist tag
	elif [ "$output" = "3" ]; then
		#input artist name
		dialog --backtitle "MP3Manager" \
		       	--title "Search by artist" \
			--inputbox "Enter artist name" 8 80 2>.tempfile
		artist=$?
		if [ "$artist" -eq "0" ]; then
			artist=`cat .tempfile`
			f=0
			files=()
			# find files with specified artist tag
			while ((f++)); read file ;
			do
				if [[ $(id3info "$file" | grep "TPE1" | awk '{$1="";$2="";$3="";$4="";print}' | sed -e 's/^[ \t]*//' | grep $artist | sort) ]]; then
					files+=( "$file" $f )
				fi
			done < <(find $HOME -iname "*.mp3" -print)
			dialog --menu  "Make your own choice" 20 90 10 "${files[@]}" 2>.tempfile
			# if user selected file then play it
			if [ "$?" -eq "0" ]; then
				output=`cat .tempfile`
				rm -f .tempfile
				clear
				mpg123 "$output"
				pid=$!
				wait pid
			fi
		fi
		MainMenu	
	
	# selected option for showing and editing mp3 tags
	elif [ "$output" = "4" ]; then
		ShowFiles
		# check wheter user selected the file
		if [ "$?" -eq "0" ]; then
			t=0
			tagitems=""

			# take tags from file
			while ((t++)); read filetag ;
			do
				tagitems+="$filetag \n"
			done < <(id3info "$output" | grep "===" | awk '{$1="";$2="";print}' | sed -e 's/^[ \t]*//')
			
			# if file hasn't tags then show this message
			if [ -z "$tagitems" ]; then
				tagitems="There are no tags"
			fi

			# show tags and ask user if he wants to edit file's tags
			dialog --backtitle "MP3Manager" \
			       --title "Do you want to edit this file's tags?" \
	       		       --yesno "$tagitems" 7 80
			toedit=$?
			
			# if user wants to edit tags
			if [ "$toedit" -eq 0 ]; then
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
						id3tag -"$prefix""$value" "$output"
					fi
				fi
			fi
		fi
		MainMenu

	# selected option for downloading mp3 file from youtube by video id
	elif [ "$output" = "5" ]; then
		# get video id from user
		video_id=$(dialog --backtitle "MP3Manager" \
			--title "Download MP3 file from youtube" \
			--inputbox "Enter video id" 8 80 3>&1 1>&2 2>&3 3>&-)

		# if user entered video id
		if [ "$!" -eq "0" ]; then
			clear
			# setting url for specified video to download as mp3 file
			url="https://www.youtube.com/watch?v=$video_id"
			# download video as mp3 file and wait for end
			youtube-dl -x --audio-format mp3 "$url"
			pid=$!
			wait pid
		fi
		MainMenu
	
	# selected option for downloading mp3 file from youtube by video id from file
	elif [ "$output" = "6" ]; then
		# get video ids with song titles from file
		menuitems=()
		valueitems=()
		v=0
		while ((v++)); read songname video_id ;
		do
			menuitems+=( $v "$songname" )
			valueitems+=( "$video_id" )
		done < <(cat videosToDownload.txt | sort)
		# select title from menu
		dialog --menu  "Choose file to download" 20 80 10 "${menuitems[@]}" 2>.tempfile
		# if user selected title then download it and wait for end
		if [ "$!" -eq "0" ]; then
			selected_id=`cat .tempfile`
			m -f .tempfile
			selected_id=`expr $selected_id - 1`
			selected_video_id="${valueitems[$selected_id]}"
			clear
			url="https://www.youtube.com/watch?v=$selected_video_id"
			youtube-dl -x --audio-format mp3 "$url"
			pid=$	
			wait pid
		fi
		MainMenu
	
	# selected option for moving all mp3 files to Music folder in user home directory
	elif [ "$output" = "7" ]; then
		find $HOME -iname "*.mp3" -type f -exec /bin/mv -n {} $HOME/Music \;
		MainMenu

	# selected exit option
	elif [ "$output" = "8" ]; then
		clear

	# clicked cancel button
	else 
		clear
	fi
}
MainMenu
exit 0
