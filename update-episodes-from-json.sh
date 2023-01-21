#!/bin/bash
SHOW_ID="$1"
SEASON="$2"
JSON_PATH="$3"

if [[ -z "$SHOW_ID" || -z "$SEASON" ]]; then
    echo "usage : $0 <SHOW_ID> <SEASON> [METADATA_JSON_PATH]" >&2
    exit 1
fi

if [[ -z "$JSON_PATH" ]]; then
    TEMP_DIR=$(mktemp -d )
    echo "reading JSON from stdin" >&2
    cp /dev/stdin  "$TEMP_DIR/info.json"
    JSON_PATH="$TEMP_DIR/info.json"
else 
    if [[ ! -f "$JSON_PATH" ]]; then
        echo "not found : $JSON_PATH"
        exit 1
    fi
fi

set -e 

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SEASON_ID=$("$SCRIPT_DIR"/get-seasons.sh $SHOW_ID $SEASON)

if [[ -z "$SEASON_ID" ]]; then
    echo "ERROR : Failed to get season $SEASON of show($SHOW_ID) ; check if your ShowId is correct" >&2
    [[ ! -z "$TEMP_DIR" ]] && rm -Rf "$TEMP_DIR"
    exit 1
fi

# シーズンのあらすじ

"$SCRIPT_DIR"/update-season-synop.sh "$SEASON_ID" "$(cat "$JSON_PATH" | jq -r '.series_synop')"

# 各話のあらすじ

find_ep() {
    local WANT_EP="$1"
    "$SCRIPT_DIR"/get-episodes.sh  $SHOW_ID  $SEASON_ID | while read LINE; do
        EP_ID=$( echo "$LINE" | awk 'BEGIN { FS="\t" } { print $3 }' )
        DB_EP=$( echo "$LINE" | awk 'BEGIN { FS="\t" } { print $1 }' )
        if [[ "$DB_EP" == "null" ]]; then
            FN=$( echo "$LINE" | awk 'BEGIN { FS="\t" } { print $4 }' )
            GUESS_EP=$( node "$SCRIPT_DIR/guess-episode" "$FN" | jq .ep)
            if [[ "$GUESS_EP" != "null" && "$GUESS_EP" == "$WANT_EP" ]]; then
                echo "--> found : $FN ($EP_ID)" >&2
                echo "$EP_ID"
                break
            fi 
        fi
    done
}

cat "$JSON_PATH"  | jq -r '.episodes | .[] | (.ep|tostring) ' | while read EP; do

    EP_ID="$("$SCRIPT_DIR"/get-episodes.sh  $SHOW_ID  $SEASON_ID $EP)"
    if [[ "$GUESS" == 1 || -z "$EP_ID" ]]; then
        echo "`tput setaf 6`trying to guess which file is: episode ${EP} of season ${SEASON} of show ${SHOW_ID}`tput sgr0`" >&2
        EP_ID=$(find_ep $EP)
        if [[ -z "$EP_ID" ]]; then
            echo "`tput setaf 1`failed to get: episode ${EP} of season ${SEASON} of show ${SHOW_ID}`tput sgr0`" >&2
            exit 1
        fi
    fi
    TITLE="$( cat "$JSON_PATH" | jq -r '.episodes | .[] | select(.ep=='$EP') | .title')"
    echo "`tput setaf 10`### $EP : $TITLE`tput sgr0`"  >&2
    OVERVIEW="$(  cat "$JSON_PATH" | jq -r '.episodes | .[] | select(.ep=='$EP') | .synop' )"

    "$SCRIPT_DIR"/update-item.sh "$EP_ID" "$EP" "$TITLE" "$OVERVIEW"

    bash "$SCRIPT_DIR"/set-episode-img.sh   $EP_ID   "$(  cat "$JSON_PATH" | jq -r '.episodes | .[] | select(.ep=='$EP') | .img_href' )"

done

[[ ! -z "$TEMP_DIR" ]] && rm -Rf "$TEMP_DIR"

