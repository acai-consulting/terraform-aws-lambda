#!/bin/bash

FILE_NAME=$1
DEST_PATH=$2
FILE_CONTENT=$3

if [ -z "$FILE_NAME" ]; then
  echo "Error: FILE_NAME is empty or not set"
  exit 1
fi

if [ -z "$DEST_PATH" ]; then
  echo "Error: DEST_PATH is empty or not set"
  exit 1
fi

if [ -z "$FILE_CONTENT" ]; then
  echo "Error: FILE_CONTENT is empty or not set"
  exit 1
fi

# Ensure the destination directory exists
DEST_DIR=$(dirname "$DEST_PATH/$FILE_NAME")
mkdir -p "$DEST_DIR"

# Function to check if a string is base64 encoded
is_base64() {
  echo "$1" | base64 --decode &> /dev/null
  if [ $? -eq 0 ]; then
    return 0
  else
    return 1
  fi
}

# Check if FILE_CONTENT is base64 encoded and decode if necessary
if is_base64 "$FILE_CONTENT"; then
  echo "$FILE_CONTENT" | base64 --decode > "$DEST_PATH/$FILE_NAME"
else
  echo "$FILE_CONTENT" > "$DEST_PATH/$FILE_NAME"
fi

echo "File $FILE_NAME created successfully at $DEST_PATH/$FILE_NAME"
