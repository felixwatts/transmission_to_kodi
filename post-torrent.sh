#! /bin/bash
# post-torrent.sh by felixwatts

# A script to move completed torrents from Transmission to Kodi library
#
# Use as Transmission post-download script
#
# 1. Tries to categorize torrent as Audio, Film or TV based on the name
# 2. Moves the torrent data to the appropriate Kodi library folder
# 3. Removes the torrent from Transmission
# 4. Updates the Kodi library

{
  #
  # PARAMETERS - set these to your own values
  #

  # Log file, file where we tell what events have been processed.
  LOG_FILE=/home/felix/post-torrent.log

  # Username for transmission remote.
  TR_USERNAME="TR_USERNAME"

  # Password for transmission remote.
  TR_PASSWORD="TR_PASSWORD"

  # Username for Kodi web interface
  KODI_USERNAME="KODI_USERNAME"

  # Password for Kodi web interface
  KODI_PASSWORD="KODI_PASSWORD"

  # Directory to store movies in
  MOVIE_DIR="/home/felix/media/Video/Films/"

  # Directory to store TV shows in
  TV_DIR="/home/felix/media/Video/Series/"

  # Directory to store music in
  AUDIO_DIR="/home/felix/media/Audio/"

  # Directory to put stuff when we can't work out what type it is
  LOST_DIR="/home/felix/media/Lost/"

  #
  # SCRIPT - you shouldn't need to edit below here
  #

  # Get current time.
  NOW=$(date +%Y-%m-%d\ %H:%M:%S)

  # Completed torrent file
  SRC_FILE="${TR_TORRENT_DIR}/${TR_TORRENT_NAME}"

  # 1. Try to categorize torrent as Audio, Film or TV based on the name

  echo $NOW "Processing completed torrent: $SRC_FILE" >> $LOG_FILE

  DEST_DIR='';
  if [[ "${TR_TORRENT_NAME^^}" =~ .*(DISCOGRAPHY|ALBUM).* ]]
  then
    DEST_DIR=$AUDIO_DIR
  elif [[ "${TR_TORRENT_NAME^^}" =~ .*(SEASON|(S[0-9]{2})).* ]]
  then
    DEST_DIR=$TV_DIR  
  elif [[ $TR_TORRENT_NAME =~ .*(19|20)[0-9]{2}.* ]]
  then
    DEST_DIR=$MOVIE_DIR  
  else
    DEST_DIR=$LOST_DIR
  fi

  # 2. Move the torrent data to the appropriate Kodi library folder

  echo $NOW "Moving $SRC_FILE to $DEST_DIR" >> $LOG_FILE

  mv "$SRC_FILE" "$DEST_DIR"

  if [ $? -eq 0 ]; then
     echo $NOW "Succeeded" >> $LOG_FILE
  else
    echo $NOW "Failed" >> $LOG_FILE
    exit 0
  fi

  # 3. Remove the torrent from Transmission

  echo $NOW "Deleting torrent from Transmission" >> $LOG_FILE
  transmission-remote -n $TR_USERNAME:$TR_PASSWORD -t $TR_TORRENT_HASH --remove-and-delete

  if [ $? -eq 0 ]; then
     echo $NOW "Succeeded" >> $LOG_FILE
  else
    echo $NOW "Failed" >> $LOG_FILE
    exit 0
  fi

  # 4. Update the Kodi library

  echo $NOW "Updating Kodi libraries" >> $LOG_FILE
  curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' http://$KODI_USERNAME:$KODI_PASSWORD@localhost:8080/jsonrpc
  curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' http://$KODI_USERNAME:$KODI_PASSWORD@localhost:8080/jsonrpc

  if [ $? -eq 0 ]; then
     echo $NOW "Succeeded" >> $LOG_FILE
  else
    echo $NOW "Failed" >> $LOG_FILE
    exit 0
  fi

} &
