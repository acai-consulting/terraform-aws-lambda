#!/bin/bash

if [ -z "$FILE_NAME" ]; then
  echo "Error: FILE_NAME is empty or not set"
  exit 1
fi

if [ -z "$FILE_CONTENT" ]; then
  echo "Error: FILE_CONTENT is empty or not set"
  exit 1
fi

if [ -z "$DEST_PATH" ]; then
  echo "Error: DEST_PATH is empty or not set"
  exit 1
fi

# Ensure the destination directory exists
mkdir -p "$DEST_PATH"

# Decode the base64 content and write to file
echo "$FILE_CONTENT" | base64 -d > "$DEST_PATH/$FILE_NAME"

echo "File $FILE_NAME created successfully at $DEST_PATH/$FILE_NAME"