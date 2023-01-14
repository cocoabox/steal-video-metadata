#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ITEM_ID="$1"
SYNOP="$2"
if [[ -z "$ITEM_ID" || -z "$SYNOP" ]]; then
    echo "usage : $0 <SEASON_ID>  <SYNOPSIS>" >&2
    exit 1
fi

USER_ID=$( "$SCRIPT_DIR"/jellyfin-api.sh GET Users | jq -r '.[0].Id' )
CURRENT_JSON=$( "$SCRIPT_DIR"/jellyfin-api.sh GET Users/$USER_ID/Items/$ITEM_ID )
JQ_SYN='. | {
    Overview: '$(echo "$SYNOP" | tr -d '\r\n' | jq --raw-input --slurp .)',

    DateCreated: .DateCreated, Genres:.Genres, Id:.Id, IndexNumber:.IndexNumber, LockData:.LockData, 
    LockedFields:.LockedFields, Name:.Name, People:.People, PremiereDate:.PremiereDate,
    ProductionYear:.ProductionYear, ProviderIds:.ProviderIds, Studios:.Studios, Taglines:.Taglines, Tags:.Tags,

    "AirDays": [],
    "AirTime": "",
    "AirsAfterSeasonNumber": "",
    "AirsBeforeEpisodeNumber": "",
    "AirsBeforeSeasonNumber": "",
    "Album": "",
    "AlbumArtists": [],
    "ArtistItems": [],
    "AspectRatio": "",
    "CommunityRating": "",
    "CriticRating": "",
    "CustomRating": "",
    "DisplayOrder": "",
    "EndDate": null,
    "ForcedSortName": "",
    "OfficialRating": "",
    "OriginalTitle": "",
    "ParentIndexNumber": null,
    "PreferredMetadataCountryCode": "",
    "PreferredMetadataLanguage": "",
    "Status": "",
    "Video3DFormat": ""
} '

NEW_JSON=$(echo "$CURRENT_JSON" |  jq "$JQ_SYN")


TEMP_DIR=$(mktemp -d)
echo "$NEW_JSON" > "$TEMP_DIR/body.json"

STATUS_CODE=$("$SCRIPT_DIR"/jellyfin-api.sh POST "Items/$ITEM_ID"  "$TEMP_DIR/body.json"    "application/json")

if [[ "$STATUS_CODE" == 204 ]]; then
    RES=0
else 
    echo "Failed : $STATUS_CODE" >&2
    RES=1
fi

rm -Rf "$TEMP_DIR"
exit "$RES"

