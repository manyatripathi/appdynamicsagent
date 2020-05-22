'' AppDynamics for Database Windows WMI Performance Monitoring Script 27-06-2013

On Error Resume Next

Set objWbemLocator = CreateObject( "WbemScripting.SWbemLocator" )
Const wbemFlagReturnImmediately = &h10
Const wbemFlagForwardOnly = &h20

if Err.Number Then
	WScript.Echo vbCrLf & "Error # " & Hex(Err.Number) & " " & Err.Description
End If
On Error GoTo 0	

booCheckInv = false

On Error Resume Next
Select Case WScript.Arguments.Count
	Case 1
		strComputer = Wscript.Arguments(0)
		Set objWMIService = objWbemLocator.ConnectServer( strComputer,"Root\CIMV2" )
	Case 2
		strComputer = Wscript.Arguments(0)
		Set objWMIService = objWbemLocator.ConnectServer( strComputer,"Root\CIMV2" )
		if Wscript.Arguments(1) = "Inventory" then
			booCheckInv = true
		end if
	Case 3
		strComputer = Wscript.Arguments(0)
		strUsername = Wscript.Arguments(1)
		strPassword = Unescape(Wscript.Arguments(2))
		Set objWMIService = objWbemLocator.ConnectServer( strComputer, "Root\CIMV2", strUsername, strPassword )
	Case 4
		strComputer = Wscript.Arguments(0)
		strUsername = Wscript.Arguments(1)
		strPassword = Unescape(Wscript.Arguments(2))
		Set objWMIService = objWbemLocator.ConnectServer( strComputer, "Root\CIMV2", strUsername, strPassword )
		if Wscript.Arguments(3) = "Inventory" then
			booCheckInv = true
		end if
	Case Else
		strMsg = "Error # in parameters passed"
		WScript.Echo strMsg
		WScript.Quit(0)
End Select

if Err.Number Then
	WScript.Echo "Error=" & Hex(Err.Number) & " " & Err.Description & " " & Err.Source
End If    

'' Start Inventory Info
if booCheckInv = true then
	Set colOSes = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
	For Each objOS in colOSes
	  Wscript.Echo "Inv_HOSTNAME=" & objOS.CSName
	  Wscript.Echo "Inv_OS_Caption=" & objOS.Caption
	  Wscript.Echo "Inv_OS_Version=" & objOS.Version
	  Wscript.Echo "Inv_OS_Language=" & objOS.OSLanguage
	  Wscript.Echo "Inv_OS_BuildType=" & objOS.BuildType
	  Wscript.Echo "Inv_OS_OSProductSuite=" & objOS.OSProductsuite
	  Wscript.Echo "Inv_OS_OSArchitecture=" & objOS.OSArchitecture
	  Wscript.Echo "Inv_OS_WOWEnvironment=" & objOS.WOWEnvironment
	  Wscript.Echo "Inv_OS_OSType=" & objOS.OSType
	  Wscript.Echo "Inv_OS_PhysicalMemory=" & objOS.TotalVisibleMemorySize
	  WScript.Echo "Inv_OS_ServicePackMajorVersion=" & objOS.ServicePackMajorVersion & "." & objOS.ServicePackMinorVersion
	Next

	Set colCompSys = objWMIService.ExecQuery("Select * from Win32_ComputerSystem")
	For Each objCS in colCompSys
	  WScript.Echo "Inv_CPU_NumberOfProcessors=" & objCS.NumberOfProcessors
	Next

	Set colProcessors = objWMIService.ExecQuery("Select * from Win32_Processor")
	For Each objProcessor in colProcessors
	  WScript.Echo "Inv_CPU_Manufacturer=" & objProcessor.Manufacturer
	  WScript.Echo "Inv_CPU_Name=" & objProcessor.Name
	  WScript.Echo "Inv_CPU_Description=" & objProcessor.Description
	  WScript.Echo "Inv_CPU_Architecture=" & objProcessor.Architecture
	  WScript.Echo "Inv_CPU_AddressWidth=" & objProcessor.AddressWidth
	  WScript.Echo "Inv_CPU_NumberOfCores=" & objProcessor.NumberOfCores
	  WScript.Echo "Inv_CPU_Family=" & objProcessor.Family
	  WScript.Echo "Inv_CPU_MaximumClockSpeed=" & objProcessor.MaxClockSpeed
	Next
	
	Set colDisk = objWMIService.ExecQuery("Select * from Win32_PerfFormattedData_PerfDisk_LogicalDisk")
	For Each objDisk in colDisk
	   diskInfo = diskInfo & objDisk.Name & " " & Round( (objDisk.FreeMegabytes/1024), 2 ) & "GB Free - " & objDisk.PercentFreeSpace & "%<br/>"
	Next
	WScript.Echo "Inv_DISK_FreeSpace=" & diskInfo
end if
'' End Inventory Info

i=0
Set logicalDisk = objWMIService.ExecQuery("Select * from Win32_LogicalDisk")
For Each objDisk in logicalDisk
	if objDisk.size <> "" then
		WScript.Echo "DiskInfo" & i & "=" & objDisk.Name & " " & objDisk.Description & ";" & objDisk.freeSpace & ";" & Round( ( objDisk.size / 1024 ), 2 )
		i=i+1
	end if
Next

Set colItems = objWMIService.ExecQuery( "SELECT * FROM Win32_PerfRawData_PerfOS_Processor where name ='_Total'", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )
For Each objItem In colItems
	D1 = objItem.TimeStamp_Sys100NS
	B1 = objItem.Frequency_Sys100NS
	N1 = objItem.PercentProcessorTime
	S1 = objItem.PercentPrivilegedTime
	U1 = objItem.PercentUserTime
next

Wscript.Echo "Timestamp=" & D1
Wscript.Echo "TickFrequency=" & B1
Wscript.Echo "TotalCPU_RATEP=" & (CDbl(S1)+CDbl(U1))
Wscript.Echo "SystemCPU_RATEP=" & S1
Wscript.Echo "UserCPU_RATEP=" & U1

Set colItems = objWMIService.ExecQuery( "SELECT * FROM Win32_PerfFormattedData_PerfOS_System", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )
For Each objItem In colItems
	Wscript.Echo "Procs_ACT=" & objItem.Processes
	Wscript.Echo "RQ_ACT=" & objItem.ProcessorQueueLength
next

Set colItems = objWMIService.ExecQuery( "SELECT * FROM Win32_PerfRawData_PerfDisk_PhysicalDisk", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )
For Each objItem In colItems
	if objItem.name = "_Total" then
		DQ = objItem.AvgDiskReadQueueLength
	else
		if Instr( objItem.name, ":" ) <> -1 then
			totalMBS = totalMBS + ( objItem.DiskBytesPerSec / 1024 )
			readMBS = readMBS + ( objItem.DiskReadBytesPerSec / 1024 )
			writeMBS = writeMBS + ( objItem.DiskWriteBytesPerSec / 1024 )
			readOPS = readOPS + ( objItem.DiskReadsPersec )
			writeOPS = writeOPS + ( objItem.DiskWritesPersec )
		end if
	end if
next

Wscript.Echo "DiskQueueLength_RATEN=" & DQ
Wscript.Echo "TotalMBS_PCBC=" & totalMBS 
Wscript.Echo "ReadMBS_PCBC=" & readMBS 
Wscript.Echo "WriteMBS_PCBC=" & writeMBS
Wscript.Echo "ReadOPS_PCC=" & readOPS 
Wscript.Echo "WriteOPS_PCC=" &  writeOPS

Set colItems = objWMIService.ExecQuery( "Select * from Win32_OperatingSystem", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )

For Each objItem in colItems
	FM = objItem.FreePhysicalMemory
	TM = objItem.TotalVisibleMemorySize
Next

Wscript.Echo "UsedMemory_ACT=" & ( TM - FM )
WScript.Echo "FreeMemory_ACT=" & FM 
Wscript.Echo "PercMemoryUsed_ACT=" & Round( ((TM-FM)/TM)*100,2 )


dim bytesRecieved, bytesSent, receivedErrors, sentErrors
Set colItems = objWMIService.ExecQuery( "SELECT * FROM Win32_PerfRawData_Tcpip_NetworkInterface", "WQL", wbemFlagReturnImmediately + wbemFlagForwardOnly )

For Each objItem in colItems
	bytesRecieved = bytesRecieved + ( Cdbl( ReinterpretSignedAsUnsigned( objItem.BytesReceivedPerSec ) )/1024 )
	bytesSent = bytesSent + ( Cdbl( ReinterpretSignedAsUnsigned( objItem.BytesSentPerSec ) )/1024 )
	receivedErrors = receivedErrors + Cdbl( objItem.PacketsReceivedErrors )
	sentErrors = sentErrors + Cdbl( objItem.PacketsOutboundErrors )
Next

WScript.Echo "NetRecvKBS_RATES=" & bytesRecieved
WScript.Echo "NetSendKBS_RATES=" & bytesSent
WScript.Echo "NetRecvErrors_CUM=" & receivedErrors
WScript.Echo "NetSendErrors_CUM=" & sentErrors

Function ReinterpretSignedAsUnsigned(ByVal x)
  If x < 0 Then x = x + 2^32
  ReinterpretSignedAsUnsigned = x
End Function