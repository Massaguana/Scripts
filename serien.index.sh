#!/bin/bash
#
# serien_index.sh – Bestandsliste der NAS lokal ablegen
#

BASE="/Users/massaguana/RCloning"
NAS="/Volumes/Plex/TV-Serien"
INDEX="$BASE/serien_index.txt"

if [ ! -d "$NAS" ]; then
    echo "❌ NAS nicht gemountet unter: $NAS"
    echo "   Bitte zuerst verbinden: smb://DS1522plus._smb._tcp.local/Plex"
    exit 1
fi

echo "======================================"
echo "Lese Bestand ein …"
echo "Quelle: $NAS"
echo "======================================"

TMP="$INDEX.tmp"

find "$NAS" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) \
     -not -path "*/@eaDir/*" | \
while read -r FILE; do
    SERIE=$(echo "$FILE" | sed "s|^$NAS/||" | cut -d/ -f1)

    if [ "$SERIE" != "$LAST" ]; then
        printf "\r\033[K  → %s\n" "$SERIE" >&2
        LAST="$SERIE"
    fi

    N=$((N + 1))
    printf "\r     %d Dateien gelesen …" "$N" >&2

    TAG=$(basename "$FILE" | grep -oiE 's[0-9]{1,2}e[0-9]{1,3}' | head -n 1)
    if [ -n "$TAG" ]; then
        S=$(echo "$TAG" | grep -oiE '^s[0-9]{1,2}' | tr -d 'sS')
        E=$(echo "$TAG" | grep -oiE 'e[0-9]{1,3}$' | tr -d 'eE')
        printf "%s|%s\n" "$SERIE" "$(printf 'S%02dE%02d' "$((10#$S))" "$((10#$E))")"
    fi
done | sort -u > "$TMP"

printf "\r\033[K" >&2

COUNT=$(wc -l < "$TMP" | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
    echo "⚠️  Keine Episoden gefunden – alter Index bleibt unverändert."
    rm -f "$TMP"
    exit 1
fi

mv "$TMP" "$INDEX"
date '+%Y-%m-%d %H:%M' > "$INDEX.date"

SERIEN=$(cut -d'|' -f1 "$INDEX" | sort -u | wc -l | tr -d ' ')

echo "======================================"
echo "✅ Index geschrieben: $INDEX"
echo "   $SERIEN Serien, $COUNT Episoden"
echo "   Stand: $(cat "$INDEX.date")"
echo "======================================"
