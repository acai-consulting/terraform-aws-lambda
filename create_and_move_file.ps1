param (
  [string]$FILE_NAME,
  [string]$DEST_PATH,
  [string]$FILE_CONTENT
)

try {
  if ([string]::IsNullOrEmpty($FILE_NAME)) {
    throw "FILE_NAME is empty or null"
  }
  if ([string]::IsNullOrEmpty($DEST_PATH)) {
    throw "DEST_PATH is empty or null"
  }
  if ([string]::IsNullOrEmpty($FILE_CONTENT)) {
    throw "FILE_CONTENT is empty or null"
  }

  Write-Host "FILE_CONTENT $FILE_CONTENT"

  $DecodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($FILE_CONTENT))


  # Ensure the destination directory exists
  $FullPath = Join-Path -Path $DEST_PATH -ChildPath (Split-Path -Path $FILE_NAME -Parent)
  if (-not (Test-Path -Path $FullPath)) {
      New-Item -ItemType Directory -Force -Path $FullPath | Out-Null
  }
  
  
  $FilePath = Join-Path -Path $DEST_PATH -ChildPath $FILE_NAME
  Set-Content -Path $FilePath -Value $DecodedContent -NoNewline
  Write-Host "File $FILE_NAME created successfully at $FilePath"

} catch {
  Write-Error "Failed to create file $FILE_NAME. Error: $_"
  exit 1
}