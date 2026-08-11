#!/bin/bash
#
# gitup.sh – Änderungen sichern
#
cd /Users/massaguana/RCloning || exit 1

if [ -z "$(git status --porcelain)" ]; then
    echo "Nichts geändert."
    exit 0
fi

git status --short
echo ""
read -r -p "Commit-Nachricht (leer = Datum): " MSG
[ -z "$MSG" ] && MSG="Update $(date '+%Y-%m-%d %H:%M')"

git add -A
git commit -m "$MSG"
git pull --rebase
git push
