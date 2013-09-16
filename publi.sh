#!/bin/bash
NAME="bloomy-circles"
#NAME="${PWD##*/}" #nice default
LOVEDIR="${HOME}/src/love-0.8.0-win-x86"
FINALDIR="${HOME}/Dropbox/Public/games/${NAME}"
DOTLOVE="${FINALDIR}/${NAME}.love"
DOTEXE="${FINALDIR}/${NAME}-win32.zip"
TMPDIR="/tmp/"

mkdir -p $FINALDIR
zip -r $DOTLOVE *

cd $TMPDIR
mkdir -p ${NAME}
cp -r "$LOVEDIR/." "$NAME" 
cat "$LOVEDIR/love.exe" $DOTLOVE > "${NAME}/${NAME}.exe"
rm ${NAME}/love.exe
zip -r $DOTEXE ${NAME}

echo Win32  : `dropbox puburl $DOTEXE`
echo Source : `dropbox puburl $DOTLOVE`
