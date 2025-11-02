@echo off
REM Multi-Task Starter for Schnell Verkauf (Windows)
REM Nutzung: run.bat [task]
REM Tasks:
REM   dev        -> flutter run
REM   build-apk  -> flutter build apk --release
REM   analyze    -> flutter analyze
REM   pub-get    -> flutter pub get
REM   clean      -> flutter clean

SET TASK=%1
IF "%TASK%"=="" SET TASK=help

IF "%TASK%"=="help" (
  echo Verfuegbare Tasks:
  echo   run.bat dev
  echo   run.bat build-apk
  echo   run.bat analyze
  echo   run.bat pub-get
  echo   run.bat clean
  goto :eof
)

IF "%TASK%"=="dev" (
  flutter run
  goto :eof
)
IF "%TASK%"=="build-apk" (
  flutter build apk --release
  goto :eof
)
IF "%TASK%"=="analyze" (
  flutter analyze
  goto :eof
)
IF "%TASK%"=="pub-get" (
  flutter pub get
  goto :eof
)
IF "%TASK%"=="clean" (
  flutter clean
  goto :eof
)

echo Unbekannter Task '%TASK%'. Bitte run.bat ohne Parameter aufrufen.
