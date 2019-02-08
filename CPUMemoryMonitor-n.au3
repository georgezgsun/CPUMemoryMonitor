; This script tries to monitor the CPU and memory usage of CopTrax togather with NetMotion
; George Sun, 2019-01


#include <File.au3>
#include <AutoItConstants.au3>
#include <WinAPISys.au3>
#include <WinAPIProc.au3>

Global $logFile = FileOpen("C:\CopTrax Support\CPUMemoryMonitor.log", 1+8)
FileWriteLine($logFile, "")
FileWriteLine($logFile, @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC)
FileWriteLine($logFile, "PID" & @TAB & "Process Name" & @TAB & "Working set size" & @TAB & "Peak working set size")
Local $hTimer = TimerInit()	; Begin the timer and store the handler

Global $pl = ProcessList()

Local $i
Local $mem
For $i = 0 To UBound($pl, $UBOUND_ROWS)-1
	$mem = ProcessGetStats($pl[$i][1])
	If IsArray($mem) Then
		FileWriteLine($logFile, $pl[$i][1] & @TAB & $pl[$i][0] & @TAB & Round($mem[0] / 1024 / 1024) & "MB" & @TAB & Round($mem[1] / 1024 /1024) & "MB")
	Else
		FileWriteLine($logFile, $pl[$i][1] & @TAB & $pl[$i][0] & @TAB & "#" & @TAB & "#")
	EndIf
Next
Local $currentTime = TimerDiff($hTimer)
FileWriteLine($logFile, Round($currentTime / 1000, 2) & "s ---------------------------------")
FileWriteLine($logFile, "")

Global $configFile = "C:\CopTrax Support\config.txt"
Global $pName[5]
$pName[0] = "IncaXPCApp.exe"
$pName[1] = "nomtray.exe"
$pName[2] = "wa_3rd_party_host_32.exe"
$pName[3] = "mesproc.exe"
$pName[4] = "mobilecam.exe"
ReadConfig()
Local $txt = "CPU and Memory Monitor for: " & @CRLF
For $i = 0 To 4
	$txt &= $pName[$i] & @CRLF
Next
$txt &= @CRLF & "Press Alt-Shift-Q to quit monitor at any time." & @CRLF & "The results are saved in C:\CopTrax Support\CPUMemoryMonitor.log"
MsgBox($MB_OK, "CPU and Memory Monitor", $txt, 5)

HotKeySet("+!q", "HotKeyPressed") ; Esc to stop testing

Local $timeout = 1000
Global $testEnd = False

While Not $testEnd
	$currentTime = TimerDiff($hTimer)
	If  $currentTime > $timeout Then
		ReportCPUMemory()
		$timeout += 60*1000
	EndIf
   Sleep(100)
WEnd

FileClose($logFile)

MsgBox($MB_OK, "CPU Monitor", "Bye. The results are saved in C:\CopTrax Support\CPUMemoryMonitor.log", 5)
Exit

Func ReadConfig()
	If $CmdLine[0] >= 1 Then $configFile = $CmdLine[1]
;	MsgBox($MB_OK, "CPU and Memory Monitor", "Reading the client configuration from " & $configFile, 2)

	Local $file = FileOpen($configFile,0)	; for configures reading, readonly
	If $file < 0 Then Return

	Local $n = 0
	Local $aLine
	Local $aTxt
	Local $eof = False
	Do
		$aLine = FileReadLine($file)
		If @error < 0 Then ExitLoop

		$aLine = StringRegExpReplace($aLine, "([;].*)", "")
		$aLine = StringRegExpReplace($aLine, "([//].*)", "")
		If $aLine = "" Then ContinueLoop

		If Not StringInStr($aLine, ".exe") Then ContinueLoop
		$pName[$n] = $aLine ;read the process name
		$n += 1
		If $n > 5 Then ExitLoop
	Until $eof

	FileClose($file)
EndFunc

Func HotKeyPressed()
   If @HotKeyPressed = "+!q" Then $testEnd = True	;	Stop testing marker
 EndFunc   ;==>HotKeyPressed

Func ReportCPUMemory()
	Local $PID[5]
	Local $TimeP[5]
	Local $sp[5] = {"HandleCount", "PageFileUsage", "ProcessId", "ThreadCount", "WorkingSetSize"}
	Local $i
	Local $TimeS = _WinAPI_GetSystemTimes()
	Local $TimeT
	Local $TimeP
	Local $sBuf = @ComSpec & " /c WMIC PROCESS GET description"
	For $i = 0 To 4
		$sBuf &= "," & $sp[i]
	Next
	Local $sStatus = Run($sBuf, @SystemDir, @SW_HIDE, 8)

	$sBuf = ""
    While 1
        $sBuf &= StdoutRead($sStatus)
        If @Error then ExitLoop ; We have lift off, let's go!
    WEnd
    $sProc = StringSplit($sBuf, @CRLF)
	For $i = 0 To 4
		$sp[i] = StringInStr($sProc[0], $sp[i])
	Next

	For $i = 0 To 4
		$PID[$i] = ProcessExists($pName[$i])
		$TimeP[$i] = 0
		If $PID[$i]	<= 0 Then ContinueLoop
		$TimeT = _WinAPI_GetProcessTimes($PID[$i])
		If IsArray($TimeT) Then	$TimeP[$i] = $TimeT[1] + $TimeT[2]
	Next

	Local $npl = ProcessList()
	Local $aMem = MemGetStats()
	FileWriteLine($logFile, @HOUR & ":" & @MIN & ":" & @SEC)
	Local $aData = _WinAPI_GetPerformanceInfo()
	Local $aLine = 'Physical Memory (MB) ' & @TAB
	$aLine &= 'Total: ' & Floor($aData[3] / 1024 / 1024)
	$aLine &= ', Available: ' & Floor($aData[4] / 1024 / 1024)
	$aLine &= ', Cached: ' & Floor($aData[5] / 1024 / 1024)
	$aLine &= ', Free: ' & Floor($aData[6] / 1024 / 1024)
	$aLine &= ', Usage: ' & $aMem[0] & '%.'
	FileWriteLine($logFile, $aLine)
	Local $rep = ($aMem[0] > 40)

	$aLine = 'Kernel Memory (MB) ' & @TAB
	$aLine &= 'Paged: ' & Floor($aData[7] / 1024 / 1024)
	$aLine &= ', Nonpaged: ' & Floor($aData[8] / 1024 / 1024)
	FileWriteLine($logFile, $aLine)

	$aLine = 'Page Size (MB) ' & @TAB & @TAB
	$aLine &= 'Total: ' & Round($aMem[3] /1024)
	$aLine &= ', Available: ' & Round($aMem[4] /1024)
	FileWriteLine($logFile, $aLine)

	$aLine = 'Virtual Memory (MB) ' & @TAB
	$aLine &= 'Total: ' & Round($aMem[5] /1024)
	$aLine &= ', Available: ' & Round($aMem[6] /1024)
	FileWriteLine($logFile, $aLine)

	$aLine = 'System Status' & @TAB & @TAB
	$aLine &= 'Handles: ' & $aData[10]
	$aLine &= ', Processes: ' & $aData[11]
	$aLine &= ', Threads: ' & $aData[12]
	FileWriteLine($logFile, $aLine)

	If $rep Then FileWriteLine($logFile, "")

	;FileWriteLine($logFile, "Memory usage " & $aMem[0] & "%, available physical RAM " & $aMem[2] & ", total pagefile " & $aMem[3] & ", available pagefile " & $aMem[4] & ", total virtual " & $aMem[5] & ", available virtual " & $aMem[6] & ".")

	Local $j
	Local $added

	For $i = 0 to UBound($npl, $UBOUND_ROWS)-1
		$added = True	; default is added until find a match in old list
		For $j = 0 To UBound($pl, $UBOUND_ROWS)-1
			If $npl[$i][1] = $pl[$j][1] Then
				$pl[$j][1] = -1
				$added = False
				ExitLoop
			EndIf
		Next

		$aLine = $added ? "+ " : ""
		If $rep Then $aLine &= "Memory list: "

		If $aLine Then
			$aLine &= $npl[$i][1] & @TAB & $npl[$i][0] & @TAB
			$aMem = ProcessGetStats($npl[$i][1])
			If IsArray($aMem) Then
				If $added Or ($aMem[0] > 20000000) Then
					FileWriteLine($logFile, $aLine & Round($aMem[0] / 1024 / 1024) & "MB" & @TAB & Round($aMem[1] / 1024 /1024) & "MB")
				EndIf
			Else
				If $added Then FileWriteLine($logFile, $aLine & "#" & @TAB & "#")
			EndIf
		EndIf

		For $j = 0 To 4
			If StringLower($npl[$i][0]) = StringLower($pName[$j]) Then
				$PID[$j] = $npl[$i][1]
				$pName[$j] = $npl[$i][0]
			EndIf
		Next
	Next

	FileWriteLine($logFile, "")

	For $j = 0 To UBound($pl, $UBOUND_ROWS)-1
		If $pl[$j][1] >= 0 Then FileWriteLine($logFile, "- " & $pl[$j][1] & @TAB & $pl[$j][0] & @TAB & "#" & @TAB & "#")
	Next
	$pl = $npl

	Sleep(500)
	Local $mUsage
	Local $cUsage
	$TimeT = _WinAPI_GetSystemTimes()
	$Time0 = 100 / ($TimeT[1] + $TimeT[2] - $TimeS[1] - $TimeS[2]) ; The system time
	For $i = 0 To 4
		$aMem = ProcessGetStats($PID[$i])
		$mUsage = "#, #"
		If IsArray($aMem) Then
			$mUsage = "WSSize: " & Round($aMem[0] /1024 / 1024) & "MB, PeakSize: " & Round($aMem[1] / 1024 / 1024) & "MB"
		EndIf

		$TimeT = _WinAPI_GetProcessTimes($PID[$i])
		$cUsage = "PID=" & $PID[$i] & " : " & $TimeP[$i]
		If IsArray($TimeT) And $TimeP[$i] > 0 Then
			$cUsage = "CPU: " & Round(($TimeT[1] + $TimeT[2] - $TimeP[$i] ) * $Time0) & "%"
		EndIf

		FileWriteLine($logFile, $pName[$i] & @TAB & $cUsage & @TAB & $mUsage)
	Next
	FileWriteLine($logFile, "")
EndFunc

Func _ProcessGetHandle($ioProcName)
    Local $sStatus = Run(@ComSpec & " /c WMIC PROCESS GET handlecount,description,processid,threadcount,virtualsize", @SystemDir, @SW_HIDE, 8)
    Local $sBuf
    While 1
        $sBuf = StdoutRead($sStatus)
        If @Error then ExitLoop ; We have lift off, let's go!
		$sBuf = StringStripCR($sBuf)
    WEnd
    $sBuf = StringStripCR($sBuf)
    $sBuf = StringStripWS($sBuf, $STR_STRIPLEADING+$STR_STRIPTRAILING)
    $sBuf = StringRegExpReplace($sBuf, "\s.", " ")
    Return $sBuf
EndFunc

;#####################################################################
;# Function: GetCPUUsage()
;# Gets the utilization of the CPU, compatible with multicore
;# Return:   Array
;#           Array[0] Count of CPU, error if negative
;#           Array[n] Utilization of CPU #n in percent
;# Error:    -1 Error at 1st Dll-Call
;#           -2 Error at 2nd Dll-Call
;#           -3 Error at 3rd Dll-Call
;# Author:   Bitboy  (AutoIt.de)
;#####################################################################
Func GetCPUUsage()
    Local Const $SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = 8
    Local Const $SYSTEM_TIME_INFO = 3
    Local Const $tagS_SPPI = "int64 IdleTime;int64 KernelTime;int64 UserTime;int64 DpcTime;int64 InterruptTime;long InterruptCount"

    Local $CpuNum, $IdleOldArr[1],$IdleNewArr[1], $tmpStruct
    Local $timediff = 0, $starttime = 0
    Local $S_SYSTEM_TIME_INFORMATION, $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION
    Local $RetArr[1]

    Local $S_SYSTEM_INFO = DllStructCreate("ushort dwOemId;short wProcessorArchitecture;dword dwPageSize;ptr lpMinimumApplicationAddress;" & _
    "ptr lpMaximumApplicationAddress;long_ptr dwActiveProcessorMask;dword dwNumberOfProcessors;dword dwProcessorType;dword dwAllocationGranularity;" & _
    "short wProcessorLevel;short wProcessorRevision")

    $err = DllCall("Kernel32.dll", "none", "GetSystemInfo", "ptr",DllStructGetPtr($S_SYSTEM_INFO))

    If @error Or Not IsArray($err) Then
        Return $RetArr[0] = -1
    Else
        $CpuNum = DllStructGetData($S_SYSTEM_INFO, "dwNumberOfProcessors")
        ReDim $RetArr[$CpuNum+1]
        $RetArr[0] = $CpuNum
    EndIf
    $S_SYSTEM_INFO = 0

    While 1
        $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = DllStructCreate($tagS_SPPI)
        $StructSize = DllStructGetSize($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION)
        $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = DllStructCreate("byte puffer[" & $StructSize * $CpuNum & "]")
        $pointer = DllStructGetPtr($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION)

        $err = DllCall("ntdll.dll", "int", "NtQuerySystemInformation", _
            "int", $SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION, _
            "ptr", DllStructGetPtr($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION), _
            "int", DllStructGetSize($S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION), _
            "int", 0)

        If $err[0] Then
            Return $RetArr[0] = -2
        EndIf

        Local $S_SYSTEM_TIME_INFORMATION = DllStructCreate("int64;int64;int64;uint;int")
        $err = DllCall("ntdll.dll", "int", "NtQuerySystemInformation", _
            "int", $SYSTEM_TIME_INFO, _
            "ptr", DllStructGetPtr($S_SYSTEM_TIME_INFORMATION), _
            "int", DllStructGetSize($S_SYSTEM_TIME_INFORMATION), _
            "int", 0)

        If $err[0] Then
            Return $RetArr[0] = -3
        EndIf

        If $starttime = 0 Then
            ReDim $IdleOldArr[$CpuNum]
            For $i = 0 to $CpuNum -1
                $tmpStruct = DllStructCreate($tagS_SPPI, $Pointer + $i*$StructSize)
                $IdleOldArr[$i] = DllStructGetData($tmpStruct,"IdleTime")
            Next
            $starttime = DllStructGetData($S_SYSTEM_TIME_INFORMATION, 2)
            Sleep(100)
        Else
            ReDim $IdleNewArr[$CpuNum]
            For $i = 0 to $CpuNum -1
                $tmpStruct = DllStructCreate($tagS_SPPI, $Pointer + $i*$StructSize)
                $IdleNewArr[$i] = DllStructGetData($tmpStruct,"IdleTime")
            Next

            $timediff = DllStructGetData($S_SYSTEM_TIME_INFORMATION, 2) - $starttime

            For $i=0 to $CpuNum -1
                $RetArr[$i+1] = Round(100-(($IdleNewArr[$i] - $IdleOldArr[$i]) * 100 / $timediff))
            Next

            Return $RetArr
        EndIf

        $S_SYSTEM_PROCESSOR_PERFORMANCE_INFORMATION = 0
        $S_SYSTEM_TIME_INFORMATION = 0
        $tmpStruct = 0
    WEnd
EndFunc
