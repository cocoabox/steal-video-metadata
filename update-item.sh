#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "$(readlink "${BASH_SOURCE[0]}")" )" &> /dev/null && pwd )

ITEM_ID="$1"
EP="$2"
TITLE="$3"
SYNOP="$4"

if [[ -z "$ITEM_ID" || -z "$EP" || -z "$TITLE" || -z "$SYNOP" ]]; then
    echo "usage : $0 <ITEM_ID>  <EP>  <TITLE>  <OVERVIEW>" >&2
    exit 1
fi
JSON=$(
echo "{\
  \"IndexNumber\": $(echo "$EP" | tr -d '\r\n' | jq --raw-input --slurp .) , 
  \"Name\":        $(echo "$TITLE" | tr -d '\r\n' | jq --raw-input --slurp .) , 
  \"Overview\":    $(echo "$SYNOP" | tr -d '\r\n' | jq --raw-input --slurp .) , 
  \"Id\":          \"${ITEM_ID}\" , 

  \"OriginalTitle\": \"\",
  \"ForcedSortName\": \"\",
  \"CommunityRating\": \"\",
  \"CriticRating\": \"\",
  \"AirsBeforeSeasonNumber\": \"\",
  \"AirsAfterSeasonNumber\": \"\",
  \"AirsBeforeEpisodeNumber\": \"\",
  \"ParentIndexNumber\": null,
  \"DisplayOrder\": \"\",
  \"Album\": \"\",
  \"AlbumArtists\": [],
  \"ArtistItems\": [],
  \"Status\": \"\",
  \"AirDays\": [],
  \"AirTime\": \"\",
  \"Genres\": [],
  \"Tags\": [],
  \"Studios\": [],
  \"PremiereDate\": null,
  \"EndDate\": null,
  \"ProductionYear\": \"\",
  \"AspectRatio\": \"\",
  \"Video3DFormat\": \"\",
  \"OfficialRating\": \"\",
  \"CustomRating\": \"\",
  \"People\": [],
  \"LockData\": false,
  \"LockedFields\": [],
  \"ProviderIds\": { },
  \"PreferredMetadataLanguage\": \"\",
  \"PreferredMetadataCountryCode\": \"\",
  \"Taglines\": []
}" | jq --ascii-output -c )


TEMP_DIR=$(mktemp -d)
echo "$JSON" > "$TEMP_DIR/body.json"

STATUS_CODE=$("$SCRIPT_DIR"/jellyfin-api.sh POST "Items/$ITEM_ID"  "$TEMP_DIR/body.json"    "application/json")

if [[ "$STATUS_CODE" == 204 ]]; then
    echo "OK"
    RES=0
else 
    echo "Failed : $STATUS_CODE" >&2
    RES=1
fi

rm -Rf "$TEMP_DIR"
exit "$RES"

