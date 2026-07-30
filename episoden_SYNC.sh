#!/bin/bash
#
# episoden_SYNC.sh – Fehlende Episoden anhand des lokalen Index nachladen
#
# Ohne Argumente: arbeitet serien_watch.txt reihum ab (MAX_SEARCHES pro Lauf)
# Mit Argumenten: ./episoden_SYNC.sh "Silo" "House of the Dragon"
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.ftp_credentials"

BASE="/Users/massaguana/RCloning"
TEMP="$BASE/Temp"
INDEX="$BASE/serien_index.txt"
PENDING="$BASE/serien_pending.txt"
WATCH="$BASE/serien_watch.txt"
STATE="$BASE/.sync_state"

SECTION="TV-1080P"
SEARCH_TAGS="GERMAN"

# Suchkontingent des Servers – mehr geht pro Lauf nicht durch
MAX_SEARCHES=5
SEARCH_DELAY=3

# ── Hilfsfunktionen ───────────────────────────────────────────────
norm() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr '._-' '   ' | tr -s ' '
}

sxxeyy() {
    local TAG S E
    TAG=$(echo "$1" | grep -oiE 's[0-9]{1,2}e[0-9]{1,3}' | head -n 1)
    [ -z "$TAG" ] && return 1
    S=$(echo "$TAG" | grep -oiE '^s[0-9]{1,2}' | tr -d 'sS')
    E=$(echo "$TAG" | grep -oiE 'e[0-9]{1,3}$' | tr -d 'eE')
    printf 'S%02dE%02d' "$((10#$S))" "$((10#$E))"
}

do_search() {
    lftp -u "$USER,$PASSWORD" -p "$PORT" "$HOST" -e "
        set ssl:verify-certificate no
        quote SITE SEARCH $1 $SEARCH_TAGS
        bye" 2>/dev/null
}

# ── Index prüfen ──────────────────────────────────────────────────
if [ ! -f "$INDEX" ]; then
    echo "❌ Kein Index gefunden: $INDEX"
    echo "   Bitte serien.index.sh ausführen, solange die NAS läuft."
    exit 1
fi

[ -f "$INDEX.date" ] && echo "Index-Stand: $(cat "$INDEX.date")"
echo "Sektion    : $SECTION   Filter: $SEARCH_TAGS"

mkdir -p "$TEMP"
touch "$PENDING"

# ── Episoden in Temp (noch nicht einsortiert) ─────────────────────
TEMP_INDEX=$(find "$TEMP" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) 2>/dev/null | \
while read -r F; do
    T=$(sxxeyy "$(basename "$F")") || continue
    printf "%s|%s\n" "$(norm "${F#$TEMP/}")" "$T"
done)

# ── Bereits geladen, aber noch nicht im Index ─────────────────────
PENDING_INDEX=$(while IFS='|' read -r P T; do
    [ -z "$T" ] && continue
    printf "%s|%s\n" "$(norm "$P")" "$T"
done < "$PENDING")

[ -n "$TEMP_INDEX" ] && \
    echo "Temp       : $(echo "$TEMP_INDEX" | wc -l | tr -d ' ') Episode(n) warten aufs Einsortieren"
[ -n "$PENDING_INDEX" ] && \
    echo "Pending    : $(echo "$PENDING_INDEX" | wc -l | tr -d ' ') Episode(n) noch nicht im Index"

# ── Serienliste bestimmen ─────────────────────────────────────────
ROTATE=0

if [ $# -eq 0 ]; then
    if [ ! -f "$WATCH" ]; then
        echo "❌ Keine Serie angegeben und keine Watchlist: $WATCH"
        exit 1
    fi

    OLDIFS="$IFS"; IFS=$'\n'
    ALL=($(grep -v '^[[:space:]]*#' "$WATCH" | grep -v '^[[:space:]]*$' | sort -u))
    IFS="$OLDIFS"

    TOTAL=${#ALL[@]}
    ROTATE=1

    START=0
    [ -f "$STATE" ] && START=$(cat "$STATE" 2>/dev/null | tr -dc '0-9')
    [ -z "$START" ] && START=0
    [ "$START" -ge "$TOTAL" ] && START=0

    SERIES=()
    N=$MAX_SEARCHES
    [ "$N" -gt "$TOTAL" ] && N=$TOTAL
    for ((k = 0; k < N; k++)); do
        SERIES+=("${ALL[$(( (START + k) % TOTAL ))]}")
    done

    NEXT=$(( (START + N) % TOTAL ))
    echo "$NEXT" > "$STATE"

    echo "Watchlist  : $TOTAL Serien – dieser Lauf: $((START + 1)) bis $((START + N))"
else
    SERIES=("$@")
fi

cd "$BASE" || exit 1

DOWNLOADS=()
FIRST=1
BLOCKED=0

# ── Pro Serie vergleichen ─────────────────────────────────────────
for SERIE in "${SERIES[@]}"; do
    echo ""
    echo "──────────────────────────────────────"
    echo "Serie: $SERIE"

    SNORM=$(norm "$SERIE")

    HAVE=$(awk -F'|' -v s="$SERIE" '
        BEGIN { ls = tolower(s) }
        { if (index(tolower($1), ls) == 1) print $2 }
    ' "$INDEX" | sort -u)

    if [ -z "$HAVE" ]; then
        echo "  ⚠️  Nicht im Index – alle Treffer gelten als fehlend"
    else
        echo "  Bestand: $(echo "$HAVE" | wc -l | tr -d ' ') Episoden," \
             "zuletzt $(echo "$HAVE" | tail -n 1)"
    fi

    [ "$FIRST" -eq 0 ] && sleep "$SEARCH_DELAY"
    FIRST=0

    PATTERN=$(echo "$SERIE" | tr ' ' '.' | sed "s/'//g")
    RAW=$(do_search "$PATTERN")

    if ! echo "$RAW" | grep -q "rels listed"; then
        echo "  ❌ Suchkontingent aufgebraucht – übersprungen"
        BLOCKED=1
        continue
    fi

    HITS=$(echo "$RAW" \
        | awk -F'\t' '/^200-[[:space:]]*[0-9]+\t/ {
              p = $NF; sub(/[[:space:]]+$/, "", p); print p
          }' \
        | grep "^/RECENT/${SECTION}/")

    if [ -z "$HITS" ]; then
        echo "  Keine Releases in $SECTION"
        continue
    fi

    SEEN=""
    while read -r FULLPATH; do
        [ -z "$FULLPATH" ] && continue

        DIR=$(dirname "$FULLPATH")
        REL=$(basename "$FULLPATH")

        SXXEYY=$(sxxeyy "$REL") || continue

        case " $SEEN " in *" $SXXEYY "*) continue ;; esac
        SEEN="$SEEN $SXXEYY"

        if echo "$HAVE" | grep -qx "$SXXEYY"; then
            echo "  ✓ $SXXEYY"
        elif echo "$PENDING_INDEX" | grep -F "|$SXXEYY" | grep -qF "$SNORM"; then
            echo "  ✓ $SXXEYY (geladen, noch nicht im Index)"
        elif echo "$TEMP_INDEX" | grep -F "|$SXXEYY" | grep -qF "$SNORM"; then
            echo "  ⏸ $SXXEYY liegt in Temp"
        else
            echo "  ↓ $SXXEYY  →  $REL"
            DOWNLOADS+=("$DIR|$REL")
        fi
    done <<< "$HITS"
done

# ── Hinweis auf den nächsten Lauf ─────────────────────────────────
if [ "$ROTATE" -eq 1 ]; then
    echo ""
    echo "Nächster Lauf beginnt bei: ${ALL[$NEXT]}"
fi

[ "$BLOCKED" -eq 1 ] && echo "⚠️  Mindestens eine Suche wurde abgewiesen – später erneut versuchen."

# ── Bestätigung ───────────────────────────────────────────────────
echo ""
echo "======================================"
if [ ${#DOWNLOADS[@]} -eq 0 ]; then
    echo "Nichts zu tun – alles aktuell."
    exit 0
fi

echo "${#DOWNLOADS[@]} Release(s) zum Download:"
for ITEM in "${DOWNLOADS[@]}"; do
    echo "  ${ITEM#*|}"
done
echo "======================================"

read -r -p "Starten? (j/n): " OK
OK=$(echo "$OK" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
case "$OK" in
    j|ja|y|yes) echo "Starte Download …" ;;
    *) echo "Abgebrochen (Eingabe: '$OK')"; exit 0 ;;
esac

# ── Download ──────────────────────────────────────────────────────
for ITEM in "${DOWNLOADS[@]}"; do
    DIR="${ITEM%%|*}"
    REL="${ITEM#*|}"
    echo ""
    echo "↓ $REL"
    lftp -u "$USER,$PASSWORD" -p "$PORT" "$HOST" -e "
        set ssl:verify-certificate no
        cd $DIR
        mirror --directory=$REL
        bye"
done

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
filebot --log all --lang German -non-strict -script fn:amc "$TEMP"/*.mkv \
    --output "$TEMP" --def seriesDB=TheTVDB ut_label=tv @"$BASE/filebot.txt"

chmod -R 755 "$TEMP"
find "$TEMP" -name "*.mkv" -exec chmod 644 {} \;

# ── Zuwachs vormerken ─────────────────────────────────────────────
echo ""
echo "Aktualisiere Pending-Liste …"

find "$TEMP" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" \) 2>/dev/null | \
while read -r F; do
    REST="${F#$TEMP/}"
    FOLDER="${REST%%/*}"
    T=$(sxxeyy "$(basename "$F")") || continue
    printf "%s|%s\n" "$FOLDER" "$T"
done >> "$PENDING"

sort -u -o "$PENDING" "$PENDING"
echo "  $(wc -l < "$PENDING" | tr -d ' ') Episode(n) vorgemerkt"

echo ""
echo "Fertig. Nach dem Einsortieren auf die NAS bitte serien.index.sh ausführen."
