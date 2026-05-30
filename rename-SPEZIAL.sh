#!/bin/bash -i
#
# Rename Only - Manuell
#

# TheTVDB ID hier eintragen:
TVDB_ID="77847"

filebot --log all --lang German -non-strict --q "$TVDB_ID" -script fn:amc "/Users/massaguana/-={ Temp }=-/RCloning/Temp/"*.mkv --output "/Users/massaguana/-={ Temp }=-/RClonin>
chmod -Rv 755 "/Users/massaguana/-={ Temp }=-/RCloning/Temp/"
find "/Users/massaguana/-={ Temp }=-/RCloning/Temp/" -name "*.mkv" -exec chmod 644 {} \;
exit