#include <WinAPISys.au3>
#include <WinAPIProc.au3>

$PID = ProcessExists("notepad.exe")
Local $PID = 7796

While Sleep(500)
  ToolTip($PID & ": " & _GetProcUsage($PID))
WEnd

Func _GetProcUsage($PID)
  If Not ProcessExists($PID) Then Return -1
  Local Static $Prev1, $Prev2
  Local $Time1 = _WinAPI_GetProcessTimes($PID)
  Local $Time2 = _WinAPI_GetSystemTimes()
  If Not IsArray($Time1) Then Return -2
  If Not IsArray($Time2) Then Return -3
  $Time1 = $Time1[1] + $Time1[2]
  $Time2 = $Time2[1] + $Time2[2]
  $CPU = Round(($Time1 - $Prev1) / ($Time2 - $Prev2) * 100)
  $Prev1 = $Time1
  $Prev2 = $Time2
  Return $CPU
EndFunc