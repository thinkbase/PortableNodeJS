@echo off

SETLOCAL

pushd %~dp0
set BASE_DIR=%cd%
popd

SET PATH=.\node_modules\.bin;%BASE_DIR%\scripts;%BASE_DIR%\scripts\inst\bin\npm-global\bin;%PATH%
call %ComSpec% /K "PROMPT=[NodeJS]$g$s"

ENDLOCAL