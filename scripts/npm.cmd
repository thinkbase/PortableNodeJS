:: Portable Node.js
:: 2016/03/24 by thinkbase.net@gmail.com

@SETLOCAL
@PROMPT $g$s
cscript "%~dp0.\inst\node-install.vbs" //NoLogo
@echo off
IF EXIST "%~dp0.\inst\bin\start-npm.bat" (
	call "%~dp0.\inst\bin\start-npm.bat" %*
) ELSE (
	echo [PortableNodeJS] node.js not installed properly.
	exit /B -1
)
@ENDLOCAL