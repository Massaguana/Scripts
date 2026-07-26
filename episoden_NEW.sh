#!/bin/bash -i
#
# FTP LOGIN - NEW VERSION       #  #  #   DAS SCRIPT IST NUR FÜR EINZELNE Filme/ Episoden GEEIGNET #  #  #
#
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.ftp_credentials"
#
# FTP Download
#
lftp -u $USER,$PASSWORD -p $PORT $HOST << EOF
set ssl:verify-certificate no
#cd /RECENT/X264-1080P/
#cd /ARCHIVE/X264-1080P/
#cd /RECENT/AVC/
cd /RECENT/TV-1080P/
#cd /ARCHIVE2/REMOTE1/SERIEN/X264-1080P-DE/n/NCIS/S20/
#cd /ARCHIVE2/REMOTE1/MOVIES/X264-1080P-DE/d/

mirror --directory=Silo.S03E04*

EOF
#
# Rechte vor dem Entpacken
#
chmod -Rv 755 /Users/massaguana/RCloning/
#
# Unrar, rename, copy, chmod
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
   mv *.mkv "/Users/massaguana/RCloning/Temp/"
)
done
#
# Rechte nach dem Entpacken
#
chmod -Rv 755 "/Users/massaguana/RCloning/Temp/"
find "/Users/massaguana/RCloning/Temp/" -name "*.mkv" -exec chmod 644 {} \;
#
# Rename File "Filebot"
#
filebot --log all --lang German -non-strict -script fn:amc /Users/massaguana/RCloning/Temp/*.mkv --output "/Users/massaguana/RCloning/Temp/" --def seriesDB=TheTVDB ut_label=tv @"/Users/massaguana/RCloning/filebot.txt"
#
# Rechte nach Filebot
#
chmod -Rv 755 "/Users/massaguana/RCloning/Temp/"
find "/Users/massaguana/RCloning/Temp/" -name "*.mkv" -exec chmod 644 {} \;
exit
