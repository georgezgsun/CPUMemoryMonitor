This App helps to monitor the CPU and memory usage while CopTrax is running together with NetMotion.

1. To start the monitor, run CPUMemoryMonitor.exe at on the target DVR.
2. The monitor tries to record the CPU and memory usage of CopTrax and NetMotion every minute. The records are saved as text at C:\CopTrax Support\CPUMemoryMonitor.log.
3. To stop the monitor, press alt-shift-q on the target DVR at any time. No more monitor or recording after reboot of the DVR.
4. You may run the SetupCPUMemoryMonitor.bat as administrator if you want to start the recording every time the DVR reboot.
5. You may run the SetupCPUMemoryMonitor.bat as administrator again if you want to stop the monitor next time the DVR reboot.
6. This monitors by default IncaXPCApp.exe (CopTrax), nomtray.exe (NetMotion main), wa_3rd_party_host_32.exe (NetMotion attached, easy to collapse), mesproc.exe (NetMotion related), and mobilecam.exe (Body Camera). You may change the processes to be monitored in config.txt.
