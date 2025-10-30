@ECHO OFF 
REM The names of these colours can be found at
REM https://hexdocs.pm/color_palette/ansi_color_codes.html
SETLOCAL enabledelayedexpansion

ECHO ======== 256 colour table ========
FOR /L %%i IN (1,1,255) DO call ECHO "[38;5;%%imColor %%i[0m"
ECHO.

ECHO ========  system colours  ========
FOR /L %%i IN (30,1,37) DO call ECHO "[28;5;%%imColor %%i[0m"
FOR /L %%i IN (40,1,47) DO call ECHO "[28;5;%%imColor %%i[0m"
FOR /L %%i IN (90,1,97) DO call ECHO "[28;5;%%imColor %%i[0m"
FOR /L %%i IN (101,1,107) DO call ECHO "[28;5;%%imColor %%i[0m"
ECHO.

ENDLOCAL
EXIT /B 0
