@ECHO off
TITLE CPU and Memory monitor for CopTrax and NetMotion
CLS
ECHO   Welcome to setup the CPU and Memory monitor for CopTrax and NetMotion    
ECHO -------------------------------------------------------------------------

:: Check IF we are running as Admin
FSUTIL dirty query %SystemDrive% >nul
IF ERRORLEVEL 1 (ECHO This batch file need to be run as Admin. && PAUSE && EXIT /B)

SET log=C:\CopTrax Support\CPUMemoryMonitor.log
CALL :log %date% New Setup

TaskKill /IM CPUMemoryMonitor.exe /F  && (CALL :log Cleared the running process of CPUMemoryMonitor.exe.) || (CALL :log No running CPUMemoryMonitor.exe is found.)
ECHO   Coping files to target folder
CD /d %~dp0
COPY /Y CPUMemoryMonitor.exe "C:\CopTrax Support\"  && (CALL :log Copied CPUMemoryMonitor.exe to C:\CopTrax Support\.) || (CALL :log Cannot update CPUMemoryMonitor.exe in C:\CopTrax Support\.)
COPY /Y SetupCPUMemoryMonitor.bat "C:\CopTrax Support\"  && (CALL :log Copied SetupCPUMemoryMonitor.bat to C:\CopTrax Support\.) || (CALL :log Cannot update SetupCPUMemoryMonitor.bat in C:\CopTrax Support\.)
ECHO Files copied.
ECHO.
ECHO Select setup option now:
ECHO Type 1 in case you want to setup the auto luanching of the monitor every time the DVR reboot.
ECHO Type 2 in case you want to stop the monitor next time the DVR reboot.
CHOICE /N /C:12 /M "MAKE YOUR CHOICE (1 or 2)"%1
IF ERRORLEVEL == 2 GOTO CancelMonitor
SCHTASKS /CREATE /SC ONLOGON /TN CPUMemoryMonitor /TR "C:\CopTrax Support\CPUMemoryMonitor.exe" /F 
C:
CD "C:\CopTrax Support\"
Start CPUMemoryMonitor.exe && CALL :log Started CPUMemoryMonitor.exe
CALL :log The Monitor has been setup.
PAUSE
EXIT /B

:CancelMonitor
SCHTASKS /DELETE /TN CPUMemoryMonitor /F
ECHO The Monitor has been stopped to luance at next reboot.
PAUSE
EXIT /B

:: A function to write to a log file and write to stdout
:log
ECHO %time% : %* >> "%log%"
ECHO %*
EXIT /B 0
