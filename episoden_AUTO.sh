#!/bin/bash -i
#
# FTP Download mit automatischer Serien-/Film-Erkennung
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.ftp_credentials"

BASE="/Users/massaguana/RCloning"
TEMP="$BASE/Temp"

# Eingabe
read -p "Release-Name (Wildcards mit * erlaubt): " SEARCH

if [ -z "$SEARCH" ]; then
    echo "Keine Eingabe – Abbruch."
    exit 1
fi

# Serie oder Film? S01E01, S01, s3e12 usw. => Serie
if echo "$SEARCH" | grep -qiE '(^|[._ -])S[0-9]{1,2}(E[0-9]{1,3})?([._ -]|\*|$)'; then
    TYPE="serie"
    FTP_PATH="/RECENT/TV-1080P/"
else
    TYPE="movie"
    FTP_PATH="/RECENT/X264-1080P/"
    FTP_PATH="/RECENT/X265-2160P/"
fi

echo "Erkannt als: $TYPE"
echo "FTP-Pfad   : $FTP_PATH"
read -p "Fortfahren? (j/n): " OK
[ "$OK" != "j" ] && exit 1

mkdir -p "$TEMP"
cd "$BASE" || exit 1

#
# FTP Download
#
lftp -u $USER,$PASSWORD -p $PORT $HOST << EOF
set ssl:verify-certificate no
cd $FTP_PATH
mirror --directory=$SEARCH
EOF

#
# Entpacken
#
find . -iname '*.rar' | while read file; do
 (
   DIRNAME=$(dirname "${file}")
   BASENAME=$(basename "${file}")
   cd "${DIRNAME}" || exit
   unrar x -o- "${BASENAME}"
   NEW=$DIRNAME
   mv *.mkv "${NEW}".mkv 2>/dev/null
   mv *.mkv "$TEMP/" 2>/dev/null
 )
done

chmod -R 755 "$TEMP"
find "$TEMP" -name "*.mkv" -exec chmod 644 {} \;

#
# Umbenennen
#
if [ "$TYPE" = "serie" ]; then
    filebot --log all --lang German -non-strict -script fn:amc "$TEMP"/*.mkv \
        --output "$TEMP" --def seriesDB=TheTVDB ut_label=tv @"$BASE/filebot.txt"
else
    filebot --log all --lang German -non-strict -script fn:amc "$TEMP"/*.mkv \
        --output "$TEMP" --def ut_label=movie @"$BASE/filebot.txt"
fi

chmod -R 755 "$TEMP"
find "$TEMP" -name "*.mkv" -exec chmod 644 {} \;
