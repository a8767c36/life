@echo off

CALL I:\User\Downloads\node-v12.19.0-win-x64\wat2wasm life.wat
if errorlevel 1 pause
if errorlevel 1 exit
CALL I:\User\Downloads\node.exe --experimental-modules --experimental-wasm-modules index.mjs
pause
