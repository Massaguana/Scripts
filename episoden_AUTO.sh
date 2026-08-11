#!/bin/bash -i
#
# episoden_AUTO.sh – Release direkt herunterladen
#
# Eingabe: Releasename, Wildcards erlaubt
#   Silo.S03E04.GERMAN.DL.1080p.WEB.h264-SAUERKRAUT
#   Silo.S03E*
#   House.of.the.Dragon.S03*GERMAN*
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.ftp_credentials"

BASE="/Users/massaguana/RCloning"
TEMP="$BASE/Temp"

# Sektionen in der Reihenfolge, in der probiert wird
SECTIONS="TV-1080P X264-1080P TV-2160P X265-2160P TV-720P X264-720P TV-SD X264-SD"

read -r -p "Release: " REL
[ -z "$REL" ] && { echo "Keine Eingabe – Abbruch."; exit 1; }
REL=$(echo "$REL" | sed 's|/*$||')

mkdir -p "$TEMP"
cd "$BASE" || exit 1

BEFORE=$(ls -1 | wc -l | tr -d ' ')

# ── Sektionen durchprobieren ──────────────────────────────────────
for SEC in $SECTIONS; do
    echo ""
    echo "── /RECENT/$SEC/"

    lftp -u "$USER,$PASSWORD" -p "$PORT" "$HOST" -e "
        set ssl:verify-certificate no
        cd /RECENT/$SEC/
        mirror --directory=$REL
        bye"

    AFTER=$(ls -1 | wc -l | tr -d ' ')
    if [ "$AFTER" -gt "$BEFORE" ]; then
        echo "  ✓ $((AFTER - BEFORE)) Ordner geladen aus $SEC"
        break
    fi
    echo "  nichts gefunden"
done

if [ "$AFTER" -le "$BEFORE" ]; then
    echo ""
    echo "❌ In keiner Sektion gefunden. Name exakt? Groß-/Kleinschreibung zählt."
    exit 1
fi

# ── Entpacken ─────────────────────────────────────────────────────
echo ""
echo "Entpacke …"
find . -iname '*.rar' | while read -r FILE; do
 (
   DIRNAME=$(dirname "$FILE")
   BASENAME=$(basename "$FILE")
   cd "$DIRNAME" || exit
   unrar x -o- "$BASENAME"
   mv *.mkv "${DIRNAME}".mkv 2>/dev/null
   mv *.mkv "$TEMP/" 2>/dev/null
 )
done

chmod -R 755 "$TEMP"
find "$TEMP" -name "*.mkv" -exec chmod 644 {} \;

# ── Umbenennen ────────────────────────────────────────────────────
echo ""
echo "Benenne um …"
if echo "$REL" | grep -qiE '(^|[._-])S[0-9]{1,2}(E[0-9]{1,3})?'; then
    filebot --log all --lang German -non-strict -script fn:amc "$TEMP"/*.mkv \
        --output "$TEMP" --def seriesDB=TheTVDB ut_label=tv @"$BASE/filebot.txt"
else
    filebot --log all --lang German -non-strict -script fn:amc "$TEMP"/*.mkv \
        --output "$TEMP" --def ut_label=movie @"$BASE/filebot.txt"
fi

chmod -R 755 "$TEMP"
find "$TEMP" -name "*.mkv" -exec chmod 644 {} \;

echo ""
echo "Fertig."
