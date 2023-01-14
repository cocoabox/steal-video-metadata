#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "$(readlink "${BASH_SOURCE[0]}")" )" &> /dev/null && pwd )
SHOW_ID="$1"
SEASON_NUM="$2"
if [[ -z "$SHOW_ID" ]]; then
    echo "usage : $0 <SHOW_ID> [SEASON_NUMBER]" >&2
    exit 1
fi

OUT=$( "$SCRIPT_DIR"/jellyfin-api.sh GET "Shows/$SHOW_ID/Seasons"  | jq -r '.Items | .[] | ((.IndexNumber | tostring) + "\t" + .Name + "\t" + .Id)' )

if [[ -z "$SEASON_NUM" ]] ; then
    echo "$OUT"
else
    echo "$OUT" | awk 'BEGIN {FS="\t"} $1=="'$SEASON_NUM'" { print $3 } '
fi



