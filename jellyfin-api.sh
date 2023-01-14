#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ -z "$JELLYFIN_API_KEY" ]]; then
    if [[ -f "$SCRIPT_DIR/conf/api-key.txt" ]]; then
        JELLYFIN_API_KEY=$(cat "$SCRIPT_DIR/conf/api-key.txt")
    else
        echo "need \$JELLYFIN_API_KEY or conf/api-key.txt" >&2
        exit 1
    fi
fi
if [[ -z "$JELLYFIN_HOST" ]]; then
    if [[ -f "$SCRIPT_DIR/conf/host.txt" ]]; then
        JELLYFIN_HOST=$(cat "$SCRIPT_DIR/conf/host.txt")
    else
        echo "need \$JELLYFIN_HOST or conf/host.txt" >&2
        exit 1
    fi
fi

METHOD="GET"
if [[ "$1" == "PUT" || "$1" == "GET" || "$1" == "POST" || "$1" == "DELETE" ]]; then
    METHOD="$1"
    shift
fi
API="$1"
shift

echo "==> $METHOD $API" >&2
if [[ -z "$1" ]]; then
    curl -s -X $METHOD  "$JELLYFIN_HOST/$API" -H "X-MediaBrowser-Token: $JELLYFIN_API_KEY" 
else 
    # 
    # upload file : jellyfin-api.sh "PUT|POST" [FILENAME] [MIME_TYPE]
    #
    FILE_NAME="$1"
    shift
    MIME_TYPE="$1"
    shift
    CONTENT_TYPE=$(echo "$MIME_TYPE" | tr -d "\n\r")
    if [[ "$CONTENT_TYPE" =~ "image/" ]]; then
        if [[ `uname` == "Linux" ]]; then
            BODY=$(cat "$FILE_NAME" | base64 -w0 | tr -d "\n\r") 
        else 
            BODY=$(cat "$FILE_NAME" | base64 | tr -d "\n\r") 
        fi
    else 
        BODY=$(cat "$FILE_NAME")
    fi
    LEN=$(echo "$BODY" | wc -c | tr -d "\n\r ")
    curl "$JELLYFIN_HOST/$API" \
        -s -w "%{http_code}" \
        -X "$METHOD" \
        -H "Content-Type: $CONTENT_TYPE" \
        -H "X-MediaBrowser-Token: $JELLYFIN_API_KEY" \
        --data-binary "`echo -n "$BODY"`"
fi

