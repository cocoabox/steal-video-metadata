#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "$(readlink "${BASH_SOURCE[0]}")" )" &> /dev/null && pwd )

EP_ID="$1"
IMG_PATH="$2"

if [[ "$IMG_PATH" =~ ^https?:// ]] ; then
    FILE_TYPE=$( curl -s -I "$IMG_PATH" | awk 'tolower($1)=="content-type:" { print $2 }' | awk 'BEGIN { FS="/" } { print $2 }' )
    TEMP_DIR=$(mktemp -d)
    echo "==> download : $IMG_PATH"
    DOWNLOAD_TO="${TEMP_DIR}/primary.${FILE_TYPE}"
    curl -s "$IMG_PATH" > "$DOWNLOAD_TO"
    IMG_PATH="$DOWNLOAD_TO"
fi

if [[ -z "$EP_ID" || -z "$IMG_PATH" || ! -f "$IMG_PATH" ]]; then
    [[ -z "$TEMP_DIR" ]] && rm -Rf "$TEMP_DIR"
    echo "usage : $0 <EP_ID> <IMAGE_FILE_PATH>" >&2
    exit 1
fi

# detect mime type
BASENAME=$(basename "$IMG_PATH")
IMG_MIME_TYPE=$(echo "image/${BASENAME##*.}" | tr -d "\n\r")

STATUS_CODE=$( "$SCRIPT_DIR"/jellyfin-api.sh POST "Items/$EP_ID/Images/Primary" "$IMG_PATH" "$IMG_MIME_TYPE" )
if [[ "$STATUS_CODE" == 204 ]]; then
    RES=0
else 
    echo "Failed : $STATUS_CODE" >&2
    RES=1
fi

[[ -z "$TEMP_DIR" ]] && rm -Rf "$TEMP_DIR"

exit "$RES"
