@ECHO OFF
set installfolder=%cd%
ECHO The Monkey will now plant a Jungle in your computer.
ECHO Good Luck!
ECHO It's CTRL+C to quit this btw.
ECHO If you wanna quit, now is the right time, because stopping copying files can be annyoing to clean.
ECHO IMPORTANT: DELETE THE CONTENTS OF YOUR MODS FOLDER BEFORE DOING THIS AS I DONT WANT TO FIND OUT
PAUSE
cd %appdata%\.minecraft
MD mods
CD mods

SET /P installfabric=Install Fabric (Y/[N])?
IF /I "%installfabric%" NEQ "Y" GOTO SKIPINSTALLFABRIC
SET fabriclocation=%installfolder%\fabric-installer-1.0.1.exe
START %fabriclocation%
ECHO Give this a second to load before moving onto the next step!
PAUSE

:SKIPINSTALLFABRIC

SET /P installcore=Install Core (Y/[N])?
IF /I "%installcore%" NEQ "Y" GOTO SKIPINSTALLCORE
COPY %installfolder%\core\*

:SKIPINSTALLCORE

SET /P installextra=Install Extras (Y/[N])?
IF /I "%installextra%" NEQ "Y" GOTO SKIPINSTALLEXTRA
COPY %installfolder%\extra\*

:SKIPINSTALLEXTRA

SET /P installshaders=Install Shaders (Y/[N])?
IF /I "%installshaders%" NEQ "Y" GOTO SKIPINSTALLSHADERS
COPY %installfolder%\shaders\*
CD ..
MD shaderpacks
CD shaderpacks
XCOPY %installfolder%\shaderpacks %cd% /s /e

:SKIPINSTALLSHADERS

ECHO Everything has installed successfully! 
ECHO Have fun!

PAUSE