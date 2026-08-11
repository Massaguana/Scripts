#!/bin/bash -i
#
# rename.sh – Nur umbenennen, kein Download
#
BASE="/Users/massaguana/RCloning"
TEMP="$BASE/Temp"

# Typ aus dem Dateinamen ableiten: S##E## => Serie, sonst Film
if ls "$TEMP"/*.mkv 2>/dev/null | grep -qiE '(^|[._-])S[0-9]{1,2}E[0-9]{1,3}'; then
    LABEL="tv"
else
    LABEL="movie"
fi
echo "Typ: $LABEL"

# Alte Metadaten entfernen – sonst gewinnen sie gegen den Dateinamen
find "$TEMP" -name "*.mkv" -exec xattr -c {} \;

filebot --log all --lang German -non-strict -script fn:amc "$TEMP"/*.mkv \
    --output "$TEMP" --def ut_label=$LABEL @"$BASE/filebot.txt"

chmod -R 755 "$TEMP"
find "$TEMP" -name "*.mkv" -exec chmod 644 {} \;
