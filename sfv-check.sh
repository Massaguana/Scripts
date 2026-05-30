#!/bin/bash
BASE="/volume1/Plex/TV-Serien"
for SHOW_DIR in "$BASE"/*; do
    [ -d "$SHOW_DIR" ] || continue
    [[ "$(basename "$SHOW_DIR")" == @* ]] && continue  # Synology @-Ordner überspringen
    SHOW_NAME=$(basename "$SHOW_DIR")
    SFV_TARGET="$SHOW_DIR/$SHOW_NAME.sfv"

    REGENERATE=0

    # Stufe 1: SFV fehlt
    if [ ! -f "$SFV_TARGET" ]; then
        echo "SFV fehlt: $SHOW_NAME"
        REGENERATE=1
    fi

    # Stufe 2: Neuere Videodatei als SFV
    if [ "$REGENERATE" -eq 0 ]; then
        NEWER=$(find "$SHOW_DIR" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" \) -newer "$SFV_TARGET" | head -n 1)
        if [ -n "$NEWER" ]; then
            echo "Neue Videodatei gefunden: $SHOW_NAME"
            REGENERATE=1
        fi
    fi

    # Stufe 3: Anzahl stimmt nicht
    if [ "$REGENERATE" -eq 0 ]; then
        VIDEO_COUNT=$(find "$SHOW_DIR" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" \) | wc -l)
        SFV_COUNT=$(grep -c "^[^;]" "$SFV_TARGET" 2>/dev/null || echo 0)
        if [ "$VIDEO_COUNT" -ne "$SFV_COUNT" ]; then
            echo "Anzahl geändert: $SHOW_NAME"
            REGENERATE=1
        fi
    fi

    # Stufe 4: CRC32 Prüfung
    if [ "$REGENERATE" -eq 0 ]; then
        if (cd "$SHOW_DIR" && filebot -check "$SFV_TARGET" 2>/dev/null); then
            echo "SFV OK: $SFV_TARGET"
            continue
        else
            echo "CRC32 Fehler: $SHOW_NAME"
            REGENERATE=1
        fi
    fi

    echo "Erzeuge SFV für: $SHOW_NAME"

    # Alte SFVs überall löschen
    find "$SHOW_DIR" -name "*.sfv" -delete

    # Neu erzeugen
    (cd "$SHOW_DIR" && filebot -check -r .)

    # Alle erzeugten SFVs zusammenführen und nach oben verschieben
    find "$SHOW_DIR" -mindepth 2 -name "*.sfv" | while read sfv; do
        cat "$sfv" >> "$SFV_TARGET"
        rm "$sfv"
    done

    # Falls filebot die SFV anders benannt hat
    GENERATED_SFV=$(find "$SHOW_DIR" -maxdepth 1 -name "*.sfv" ! -name "$SHOW_NAME.sfv" | head -n 1)
    if [ -f "$GENERATED_SFV" ]; then
        cat "$GENERATED_SFV" >> "$SFV_TARGET"
        rm "$GENERATED_SFV"
    fi

done