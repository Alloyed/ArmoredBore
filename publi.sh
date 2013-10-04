#!/bin/bash
NAME="bloomy-circles"
#NAME="${PWD##*/}" #nice default
LOVEDIR="${HOME}/src/love-0.8.0-win-x86"
FINALDIR="${HOME}/Dropbox/Public/games/${NAME}"
TMPDIR="/tmp/"

# Source
DOTLOVE="${FINALDIR}/${NAME}.love"
echo creating $DOTLOVE
mkdir -p $FINALDIR
zip -r $DOTLOVE *

# Win32
DOTEXE="${FINALDIR}/${NAME}-win32.zip"
echo creating $DOTEXE
cd $TMPDIR
rm -Ir ${NAME}
mkdir -p ${NAME}
cp -r "$LOVEDIR/." "$NAME" 
cat "$LOVEDIR/love.exe" $DOTLOVE > "${NAME}/${NAME}.exe"
rm ${NAME}/love.exe
zip -r $DOTEXE ${NAME}

echo Win32  : `dropbox puburl $DOTEXE`
echo Source : `dropbox puburl $DOTLOVE`
