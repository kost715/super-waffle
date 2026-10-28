@echo off
rem Converts every *_ca.png in this folder to .paa with ImageToPAA from Arma 3 Tools.
rem Arma 3 Tools is free on Steam (Library > Tools). Adjust the path if it is installed elsewhere.
setlocal
set "TOOL=C:\Program Files (x86)\Steam\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe"
if not exist "%TOOL%" (
    echo ImageToPAA not found: %TOOL%
    echo Edit the TOOL line in this file to point to ImageToPAA.exe.
    pause
    exit /b 1
)
cd /d "%~dp0"
for %%f in (*_ca.png) do (
    echo %%f
    "%TOOL%" "%%f" "%%~nf.paa"
)
echo Done.
pause
