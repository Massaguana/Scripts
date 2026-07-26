#!/bin/bash -i
#
# FTP LOGIN                     #  #  #   DAS SCRIPT IST NUR FÜR EINZELNE Filme/ Episoden GEEIGNET #  #  #
#
HOST='109.201.135.12'
USER='Ir0nDuk3'
PORT='43231'
PASSWORD='fhhgf73jkkf6645'
#read -p "Password: " PASSWORD
#
# FTP Download
#
lftp -u $USER,$PASSWORD -p $PORT $HOST << EOF
set ssl:verify-certificate no#
#cd /RECENT/X264-1080P/
#cd /ARCHIVE/X264-1080P/
#cd /RECENT/AVC/
cd /RECENT/TV-1080P/
#cd /ARCHIVE2/REMOTE1/SERIEN/X264-1080P-DE/n/NCIS/S20/
#cd /ARCHIVE2/REMOTE1/MOVIES/X264-1080P-DE/d/
mirror --directory=Das.Boot.S04E*
EOF
#
# Unrar, rename, copy, delete, chmod
#
find . -iname '*.rar' | while read file; do
 (
   DIRNAME=$(dirname "${file}")
   BASENAME=$(basename "${file}")
   cd "${DIRNAME}"
   unrar x -o- "${BASENAME}"
   chmod -v 644 *.mkv
   NEW=$DIRNAME
   mv *.mkv "${NEW}".mkv
   mv *.mkv "/Users/massaguana/-={ Temp }=-/RCloning/Temp/" 
#   rm -rf "/Users/massaguana/-={ Temp }=-/RCloning/"${DIRNAME}"
)
done
#
# Rename File "Filebot"
#
filebot --log all --lang German -non-strict -script fn:amc /Users/massaguana/-\=\{\ Temp\ \}\=-/RCloning/Temp/*.mkv --output "/Users/massaguana/-={ Temp }=-/RCloning/Temp/"  --def @"/Users/massaguana/-={ Temp }=-/RCloning/filebot.txt"
#
#
#
exit
