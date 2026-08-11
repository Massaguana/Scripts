#!/bin/bash -i
#
# rename-SPEZIAL.sh – Umbenennen mit vorgegebenem Treffer
#
# Eingabe: TheTVDB-ID (Serien), TMDB-ID oder Titel (Filme)
#
BASE="/Users/massaguana/RCloning"
TEMP="$BASE/Temp"

read -r -p "Suchbegriff oder ID: " QUERY
[ -z "$QUERY" ] && { echo "Keine Eingabe – Abbruch."; exit 1; }

# Typ aus dem Dateinamen ableiten: S##E## => Serie, sonst Film
if ls "$TEMP"/*.mkv 2>/dev/null | grep -qiE '(^|[._-])S[0-9]{1,2}E[0-9]{1,3}'; then
    LABEL="tv"
    DB="seriesDB=TheTVDB"
else
    LABEL="movie"
    DB=""
fi
echo "Typ: $LABEL   Query: $QUERY"

# Alte Metadaten entfernen – sonst gewinnen sie gegen die Vorgabe
find "$TEMP" -maxdepth 1 -name "*.mkv" -exec xattr -c {} \;

filebot --log all --lang German -non-strict --q "$QUERY" \
    -script fn:amc "$TEMP"/*.mkv \
    --output "$TEMP" --def ut_label=$LABEL $DB @"$BASE/filebot.txt"

chmod -R 755 "$TEMP"
find "$TEMP" -name "*.mkv" -exec chmod 644 {} \;
