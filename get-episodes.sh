#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SHOW_ID="$1"
SEASON_ID="$2"
if [[ -z "$SEASON_ID" || -z "$SHOW_ID" ]]; then
    echo "usage : $0 <SHOW_ID> <SEASON_ID> [EPISODE_NUMBER]" >&2
    exit 1
fi
EPISODE_NUM="$3"

OUT=$( "$SCRIPT_DIR"/jellyfin-api.sh GET "Shows/$SHOW_ID/Episodes?seasonId=$SEASON_ID&fields=MediaSources" | 
  jq -r '.Items | .[] | ( (.IndexNumber|tostring) + "\t" + .Name + "\t" + .Id + "\t" + (.MediaSources | .[] | select(.Protocol=="File") | .Path)  )'
)

if [[ -z "$EPISODE_NUM" ]]; then
    echo "$OUT" 
else 
    echo "$OUT" | awk 'BEGIN {FS="\t"} $1=="'$EPISODE_NUM'" { print $3 } '
fi

