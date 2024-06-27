param (
  [string]$FILE_NAME,
  [string]$FILE_CONTENT,
  [string]$DEST_PATH
)

try {
  if ([string]::IsNullOrEmpty($FILE_NAME)) {
    throw "FILE_NAME is empty or null"
  }
  if ([string]::IsNullOrEmpty($FILE_CONTENT)) {
    throw "FILE_CONTENT is empty or null"
  }
  if ([string]::IsNullOrEmpty($DEST_PATH)) {
    throw "DEST_PATH is empty or null"
  }

  $DecodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($FILE_CONTENT))
  
  # Ensure the destination directory exists
  New-Item -ItemType Directory -Force -Path $DEST_PATH | Out-Null
  
  $FilePath = Join-Path -Path $DEST_PATH -ChildPath $FILE_NAME
  Set-Content -Path $FilePath -Value $DecodedContent -NoNewline
  Write-Host "File $FILE_NAME created successfully at $FilePath"
} catch {
  Write-Error "Failed to create file $FILE_NAME. Error: $_"
  exit 1
}