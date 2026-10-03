@echo off
setlocal
rem Run after MelonLoader.Installer-0.7.exe.
rem If Il2Cpp assemblies are missing, launch the game once, close it, then run this again.
rem Save.json and QuadStashs are left alone.
rem Pass the game folder as the first argument when it is not the default path.

set "GAME=E:\SteamLibrary\steamapps\common\Last Epoch"
if not "%~1"=="" set "GAME=%~1"
if not exist "%GAME%\Last Epoch.exe" (
  echo Last Epoch.exe was not found:
  echo %GAME%
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0MelonLoader.Installer-0.7-patch\fix-il2cpp-angle-o.ps1" -GamePath "%GAME%"
set "EC=%ERRORLEVEL%"
if "%EC%"=="2" (
  pause
  exit /b 2
)
if not "%EC%"=="0" (
  echo Patch failed. Exit code %EC%
  pause
  exit /b %EC%
)
pause
exit /b 0