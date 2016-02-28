#!/bin/bash

# Global variables
DATA_DIR="$HOME/.lapser"

PROFILE_DIR=''
LABEL_FILE=''
CONFIG_FILE=''
SHOTS_CURRENT_DIR=''
SHOTS_NOT_CONVERTED_DIR=''
SHOTS_CONVERTED_DIR=''
MOVIES_NOT_UPLOADED_DIR=''
MOVIES_UPLOADED_DIR=''

set_profile_dirs(){
  profile=$1
  PROFILE_DIR="$DATA_DIR"/profiles/"$profile"
  LABEL_FILE="$PROFILE_DIR"/working_on.txt
  CONFIG_FILE="$PROFILE_DIR"/config.cfg
  LOG_FILE="$PROFILE_DIR"/log.txt
  SHOTS_CURRENT_DIR="$PROFILE_DIR"/current_shots
  SHOTS_NOT_CONVERTED_DIR="$PROFILE_DIR"/shots_archived_not_converted
  SHOTS_CONVERTED_DIR="$PROFILE_DIR"/shots_archived_converted
  MOVIES_NOT_UPLOADED_DIR="$PROFILE_DIR"/movies_not_uploaded
  MOVIES_UPLOADED_DIR="$PROFILE_DIR"/movies_uploaded

  for d in "$DATA_DIR" "$DATA_DIR"/profiles "$DATA_DIR"/profiles/default "$PROFILE_DIR" "$SHOTS_CURRENT_DIR" "$SHOTS_NOT_CONVERTED_DIR" "$SHOTS_CONVERTED_DIR" "$MOVIES_NOT_UPLOADED_DIR" "$MOVIES_UPLOADED_DIR" ;do
    if [ ! -d "$d" ]; then
      mkdir "$d"
    fi
  done

  for f in "$LABEL_FILE" "$LOG_FILE" "$CONFIG_FILE";do
    if [ ! -f "$f" ]; then
      echo -n > "$f"
    fi
  done
}

set_basic_dirs(){
  
  for d in "$DATA_DIR" "$DATA_DIR"/profiles "$DATA_DIR"/profiles/default;do
    if [ ! -d "$d" ]; then mkdir "$d"; fi
  done

}


yad_message(){
  yad \
  --width=600 \
  --title="Config" \
  --text="$1" \
  --button="OK:0" \
  --center
}

first_current_shot(){
  file=`ls -d "$SHOTS_CURRENT_DIR"/* | head -1`
  file=`basename $file`
  file="${file%.*}"
  echo "$file"
}

last_current_shot(){
  file=`ls -d "$SHOTS_CURRENT_DIR"/* | tail -1`
  file=`basename $file`
  file="${file%.*}"
  echo "$file"
}


how_many_current_shots(){
  ret=`find "$SHOTS_CURRENT_DIR" -maxdepth 1 -type f | wc -l`
  echo "$ret"
}


monitor(){
  # DEBUG, PUT BACK TO 15 AFTER DEBUGGING
  threshold='15';
  #threshold='1';
  timestamp=$SECONDS
  while sleep 1; do 
 
    echo 100

    new_timestamp=$SECONDS
    delta=`expr $new_timestamp - $timestamp`;

    if [ $delta -ge $threshold ];then

      # Prepare timestamp for next cycle
      timestamp=$new_timestamp

      # Get label variables ready
      now=$(date +"%Y-%m-%d_%H.%M.%S")
      label=`cat "$LABEL_FILE"`

      # Make screenshot
      import -resize 800 -window root /tmp/shot.${PID}.jpg
      convert /tmp/shot.${PID}.jpg  -gravity Southwest -background black  -fill white -splice 0x22 -pointsize 18 -annotate +0+0 "$now: $label" "$SHOTS_CURRENT_DIR"/"$now".jpg

    fi
  done
}



the_program(){

  profile=$1

  if [ -z "$profile" ];then
    profile='default';
  fi

  set_profile_dirs $profile
  PID=$$

  # Read the config file
  source "$CONFIG_FILE"
  
  working_on=`cat $LABEL_FILE`
  
  while true;do
  
    ##############
    # MAIN MENU
    ##############
  
    # Show main dialog, getting $ret and $res
    res=$(yad \
    --width=600 \
    --title="Lapser automatic screenshots - $profile" \
    --text="Press the button to start logging..." \
    --form \
    --field="Working on..." \
    --button="Start capturing:2" \
    --button="Archive:6" \
    --button="Convert to movie:8" \
    --button="Upload:10" \
    --button="Config:4" \
    --button="Cancel:17" \
    --center \
    "$working_on" )
  
    ret=$?
  
    # This gets saved regardless (unless ESCAPing or CANCELing)
    if [ $ret -ne 17 -a $ret -ne 252 ];then
      working_on=`echo $res | cut -d '|' -f 1`
      echo "$working_on" > $LABEL_FILE
    fi
  
    # #1: Start capturing
    if [ $ret -eq 2 -o $ret -eq 0 ];then
      first_shot=$(first_current_shot)
      how_many=$(how_many_current_shots)
      if [ $how_many -eq 0 ];then
        extra_text="This is a first capture after archiving"
      else
        first_shot=$(first_current_shot)
        extra_text="This capture started on $first_shot"
      fi

      d=$(date +"%Y-%m-%d_%H.%M.%S")
      label=`cat "$LABEL_FILE"`
      echo $d - START $label >> $LOG_FILE
      monitor | yad --progress --title="Capturing for $profile" --progress-text="Capturing in progress. $extra_text" --text="Press Cancel to stop capturing" --center
      d=$(date +"%Y-%m-%d_%H.%M.%S")
      echo $d - STOP $label >> $LOG_FILE
  
    # #4: Config
    elif [ $ret -eq 4 ];then
  
      res=$(yad \
      --width=600 \
      --title="Config" \
      --text="COnfiguration options" \
      --form \
      --field="User" \
      --field="Password:H" \
      --field="SSH Server" \
      --button="Save:2" \
      --button="Cancel:1" \
      --center \
      "$cfg_user" "$cfg_password" "$cfg_server" )
  
      ret=$?
  
      if [ $ret -eq 2 -o $ret -eq 0 ];then
        cfg_user=`echo $res | cut -d '|' -f 1`
        cfg_password=`echo $res | cut -d '|' -f 2`
        cfg_server=`echo $res | cut -d '|' -f 3`
        echo -e "cfg_user='${cfg_user}'\ncfg_password='${cfg_password}'\ncfg_server='${cfg_server}'\n" > $CONFIG_FILE
        source "$CONFIG_FILE"
  
        yad_message "Configuration saved!"
      fi
  
    # #6: Archive
    elif [ $ret -eq 6 ];then
  
      how_many=$(how_many_current_shots)
  
      if [ $how_many -le 4 ];then
        yad_message "Less than 4 screenshots taken, too early to archive"
      else 
  
        first_file=$(first_current_shot)
        last_file=$(last_current_shot)
  
        if [ -z "$last_file" -o  -z "$first_file" ];then
          yad_message "Error working out the name of the destination folder!"
        else 
      
         log=$(cat $LOG_FILE)

          yad \
          --width=600 \
          --height=400 \
          --title="Are you sure?" \
          --text="This will archive the current time lapse.\n\n(From $first_file to $last_file)\n\n" \
          --form \
          --field="Log entries that will be attached to the archive:TXT" \
          --center \
          "$log"

          ret=$?
  
          if [ $ret -eq 0 ];then
     
          to="$first_file"_TO_"$last_file" 
          mkdir "$SHOTS_NOT_CONVERTED_DIR"/"$to"
          mv "$SHOTS_CURRENT_DIR"/* "$SHOTS_NOT_CONVERTED_DIR"/"$to"
          cp "$LOG_FILE" "$SHOTS_NOT_CONVERTED_DIR"/"$to"
          > "$LOG_FILE"
          yad_message "Archive created, timestamp: $to"
        fi
      fi
    fi
  
    # #8: Convert to movie
    elif [ $ret -eq 8 ];then
     
      list='';
      for f in "$SHOTS_NOT_CONVERTED_DIR"/*;do
        f=`basename $f`
        exc='!'
        list="${list}${exc}${f}"
      done
     
      pick=$(yad \
      --width=600 \
      --title="Which archive do you want to convert?" \
      --form \
      --field="Pick an archive:CB" \
      --center \
      "$list")
      ret=$?
  
      if [ $ret -ne 1 -a $ret -ne 252 ];then
        pick=`echo $pick | cut -d '|' -f 1`
  
        ffmpeg -y -framerate 4  -pattern_type glob -i "$SHOTS_NOT_CONVERTED_DIR"/"$pick"/'*.jpg' -b:v 800k /tmp/video.${PID}.mp4
  
        ret=$?
  
        if [ "$ret" -ne 0 ];then
          yad_message "Video creation failed"
        else
          # Move the screenshots to the "CONVERTED" directory
          mv "$SHOTS_NOT_CONVERTED_DIR"/"$pick" "$SHOTS_CONVERTED_DIR"
          # Move the freshly generated video over
          mv /tmp/video.${PID}.mp4  "$MOVIES_NOT_UPLOADED_DIR"/"$pick".mp4
          # Copy the log file over, named as the video
          cp "$SHOTS_CONVERTED_DIR"/"$pick"/log.txt "$MOVIES_NOT_UPLOADED_DIR"/"$pick".log
          yad_message "Conversion successful!"
        fi
      fi
  
  
    # #8: Upload
    elif [ $ret -eq 10 ];then
      
       yad \
      --width=600 \
      --title="Are you sure?" \
      --text="This will upload the existing movies to the remote server\nAre you sure?" \
      --center
      ret=$?
  
    # #4: The end
    elif [ $ret -eq 4 -o $ret -eq 252 ];then
     return
    fi
  
  done;
  
  
  # TODO:
  # ----
  
  # * Fix cycle, so that first yad calls second one and back to first
  # * Write rsync call to upload/move videos
  
  # * Check if this command makes better videos smaller
  # convert 0.png -background black -flatten +matte 0_opaque.png
  # http://stackoverflow.com/questions/3561715/using-ffmpeg-to-encode-a-high-quality-video|
} 
 




set_basic_dirs

while true;do

  list='';
  for f in "$DATA_DIR"/profiles/*;do
    f=`basename $f`
    exc='!'
    list="${list}${exc}${f}"
  done
  list="${list}${exc}Make new profile"

  pick=$(yad \
  --width=600 \
  --title="Which profile do you want to enter?" \
  --form \
  --field="Pick a profile:CB" \
  --center \
  "$list")
  ret=$?

  if [ $ret -ne 1 -a $ret -ne 252 ];then

    pick=`echo $pick | cut -d '|' -f 1`
    if [ "$pick" == 'Make new profile' ];then

       res=$(yad \
      --width=600 \
      --title="Create new profile" \
      --form \
      --field="New profile" \
      --button="Create:2" \
      --button="Cancel:1" \
      --center )

      ret=$?
  
      # Pressed enter on the field, or the "Create" button
      if [ $ret -eq 2 -o $ret -eq 0 ];then
       res=`echo $res | cut -d '|' -f 1`
       set_profile_dirs $res 
      fi

    else
      the_program $pick
    fi
  else
    exit 0
  fi

done

