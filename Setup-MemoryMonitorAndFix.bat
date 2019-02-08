@ECHO off
TITLE Memory fix and monitor for CopTrax and NetMotion
CLS
ECHO   Welcome to memory fix and monitor setup for CopTrax and NetMotion    
ECHO -------------------------------------------------------------------------

:: Check IF we are running as Admin
FSUTIL dirty query %SystemDrive% >nul
IF ERRORLEVEL 1 (ECHO This batch file need to be run as Admin. && PAUSE && EXIT /B)

SET log=C:\CopTrax Support\CPUMemoryMonitor.log
CALL :log %date% New Setup

TaskKill /IM CPUMemoryMonitor.exe /F  && (CALL :log Cleared the running process of CPUMemoryMonitor.exe.) || (CALL :log No running CPUMemoryMonitor.exe is found.)
ECHO Copying files to target folder...
CD /d %~dp0
COPY /Y CPUMemoryMonitor.exe "C:\CopTrax Support\"  && (CALL :log Copied CPUMemoryMonitor.exe to C:\CopTrax Support\.) || (CALL :log Cannot update CPUMemoryMonitor.exe in C:\CopTrax Support\.)
COPY /Y Setup*.bat "C:\CopTrax Support\"  && (CALL :log Copied Setup-MemoryMonitorAndFix.bat to C:\CopTrax Support\.) || (CALL :log Cannot update SetupCPUMemoryMonitor.bat in C:\CopTrax Support\.)
ECHO Files copied.
SCHTASKS /Delete /TN "PatchFixMem" /F && (CALL :log Deleted the old PatchFixMem.) || (CALL :log Find no old PatchFixMem.)

IF NOT EXIST "C:\Program Files (x86)\InstallShield Installation Information\{9C049509-055C-4CFF-A116-1D12312225EB}\Install.exe" (CALL :log The Driver has already been removed. && GOTO Mon)
ECHO Please Click Yes on the pop-up window to confirm the delete of the driver.
"C:\Program Files (x86)\InstallShield Installation Information\{9C049509-055C-4CFF-A116-1D12312225EB}\Install.exe" -uninst 
CALL :log Running the initial RealTek Driver installer.
ECHO The removing may take 1-2 minutes.

:Mon
ECHO.
ECHO Select setup option now:
ECHO Type 1 to setup the auto luanching of the monitor every time the DVR reboot.
ECHO Type 2 to stop the monitor next time the DVR reboot.
CHOICE /N /C:12 /M "MAKE YOUR CHOICE (1 or 2)"%1
IF ERRORLEVEL 2 GOTO CancelMonitor

SCHTASKS /CREATE /SC ONLOGON /TN CPUMemoryMonitor /TR "C:\CopTrax Support\CPUMemoryMonitor.exe" /F 
C:
CD "C:\CopTrax Support\"
Start CPUMemoryMonitor.exe && CALL :log Started CPUMemoryMonitor.exe
CALL :log The Monitor has been setup.
PAUSE
EXIT /B

:CancelMonitor
SCHTASKS /DELETE /TN CPUMemoryMonitor /F
CALL :log The Monitor has been stopped to luance at next reboot.
PAUSE
EXIT /B

:: A function to write to a log file and write to stdout
:log
ECHO %time% : %* >> "%log%"
ECHO %*
EXIT /B 0
