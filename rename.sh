#!/bin/bash -i
#
# Rename Only
#

filebot --log all --lang German -non-strict -script fn:amc /Users/massaguana/-\=\{\ Temp\ \}\=-/RCloning/Temp/*.mkv --output "/Users/massaguana/-={ Temp }=-/RCloning/Temp/"  ->
chmod -Rv 755 "/Users/massaguana/-={ Temp }=-/RCloning/Temp/"
chmod -Rv 644 "/Users/massaguana/-={ Temp }=-/RCloning/Temp/"*.mkv
exit