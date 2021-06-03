#cs ----------------------------------------------------------------------------
	AutoIt Version:   3.3.14.2
	Scite Version:    3.7.3
	Author:           kevingrillet
	Name:             AutoIt_Idle
	Version:          1.0.0.2
	Script Function:  Script to prevent Windows to idle.
#ce ----------------------------------------------------------------------------

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=AutoIt_Idle.ico
#AutoIt3Wrapper_Outfile=AutoIt_Idle.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=Script to prevent Windows to idle.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.2
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (C) 2021
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Field=Compiler Date|%date%
#AutoIt3Wrapper_Res_Field=Compiler Heure|%time%
#AutoIt3Wrapper_Res_Field=Compiler Version|AutoIt v%AutoItVer%
#AutoIt3Wrapper_Res_Field=Author|kevingrillet
#AutoIt3Wrapper_Res_Field=Github|https://github.com/kevingrillet/AutoIt-Idle
#AutoIt3Wrapper_Add_Constants=n
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#Region ### START INCLUDES ###
; *** Start added by AutoIt3Wrapper ***
#include <AutoItConstants.au3>
#include <ButtonConstants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <StringConstants.au3>
#include <TabConstants.au3>
#include <Timers.au3>
#include <TrayConstants.au3>
#include <WindowsConstants.au3>
#include <WinAPISys.au3>
#include <WinAPIsysinfoConstants.au3>
; *** End added by AutoIt3Wrapper ***
#EndRegion ### START INCLUDES ###

#Region ### START VARIABLES ###
Local $bRunning = True
Local $iIdleTime = 0
Local $iIdleTimeOld = 0
Local $iScreensaverTime = 5 * 60 * 1000 ; 5 min
Local $sPathIni = @ScriptDir & "\AutoIt_Idle.ini"
Local $sPathLog = @ScriptDir & "\AutoIt_Idle.log"
Local $sPathTmpSystem = @ScriptDir & "\AutoIt_Idle.tmp"
Local $sProcess = ""
#EndRegion ### START VARIABLES ###

#Region ### START OPT ###
Opt("GUIOnEventMode", 1) ;0=disabled, 1=OnEvent mode enabled
Opt("MustDeclareVars", 1) ;0=no, 1=require pre-declaration
Opt("TrayAutoPause", 0) ;0=no pause, 1=Pause
Opt("TrayMenuMode", 3) ;0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return
Opt("TrayOnEventMode", 1) ;0=disable, 1=enable
#EndRegion ### START OPT ###

#Region ### START Koda GUI section ### Form=.\koda\forms\form1.kxf
Local $fAutoItIdle = GUICreate("AutoIt Idle", 390, 392, -1, -1, $WS_SYSMENU)
GUISetOnEvent($GUI_EVENT_CLOSE, "fAutoItIdleClose")
Local $tAutoItIdle = GUICtrlCreateTab(3, 3, 380, 356)
Local $tsOptions = GUICtrlCreateTabItem("Options")
GUICtrlCreateLabel("Idle timer (min)", 15, 40, 100, 17)
Local $iMin = GUICtrlCreateInput("", 100, 34, 65, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_RIGHT, $ES_NUMBER))
GUICtrlSetTip(-1, "Will wake up 10s before this idle time")
GUICtrlSetOnEvent($iMin, "iMinChange")
Local $bSave = GUICtrlCreateButton("Save", 300, 36, 70, 17)
GUICtrlSetOnEvent($bSave, "bSaveClick")
Local $cbEnable = GUICtrlCreateCheckbox("Enable", 15, 65, 97, 17)
GUICtrlSetState($cbEnable, $GUI_CHECKED)
GUICtrlSetOnEvent($cbEnable, "cbEnableClick")
Local $gMode = GUICtrlCreateGroup("", 16, 92, 353, 41)
Local $rAlways = GUICtrlCreateRadio("Always", 24, 108, 113, 17)
GUICtrlSetState($rAlways, $GUI_CHECKED)
GUICtrlSetOnEvent($rAlways, "rClick")
Local $rCheckProcess = GUICtrlCreateRadio("Check Process", 208, 108, 113, 17)
GUICtrlSetOnEvent($rCheckProcess, "rClick")
GUICtrlCreateGroup("", -99, -99, 1, 1)
Local $eProcess = GUICtrlCreateEdit("", 15, 136, 353, 213)
Local $tsLog = GUICtrlCreateTabItem("Log")
Local $cbLog = GUICtrlCreateCheckbox("Save log", 15, 36, 97, 17)
Local $eLog = GUICtrlCreateEdit("", 15, 72, 353, 277)
GUICtrlCreateTabItem("System")
GUICtrlCreateLabel("Screensaver (min)", 15, 36, 100, 17)
Local $iScreensaver = GUICtrlCreateInput("0", 150, 34, 65, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_RIGHT, $ES_NUMBER))
GUICtrlSetState($iScreensaver, $GUI_DISABLE)
GUICtrlCreateLabel("Sleep (min)", 15, 72, 100, 17)
Local $iSleep = GUICtrlCreateInput("0", 150, 70, 65, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_RIGHT, $ES_NUMBER))
GUICtrlSetState($iSleep, $GUI_DISABLE)
GUICtrlCreateLabel("Hibernate (min)", 15, 108, 100, 17)
Local $iHibernate = GUICtrlCreateInput("0", 150, 106, 65, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_RIGHT, $ES_NUMBER))
GUICtrlSetState($iHibernate, $GUI_DISABLE)
Local $bRefresh = GUICtrlCreateButton("Refresh", 15, 332, 353, 17)
GUICtrlSetOnEvent($bRefresh, "bRefreshClick")
GUICtrlCreateTabItem("")
Local $miShow = TrayCreateItem("Show AutoIt Idle")
TrayItemSetOnEvent($miShow, "__Show")
Local $miShutDown = TrayCreateItem("Shut Down AutoIt Idle")
TrayItemSetOnEvent($miShutDown, "__Exit")
TraySetOnEvent($TRAY_EVENT_PRIMARYDOUBLE, "__Show")
TraySetToolTip("AutoIt Idle")
#EndRegion ### END Koda GUI section ###

;~ ========== MAINLOOP ==========
__Log("Starting")
__LoadIni()
If Not FileExists($sPathIni) Then
	__Show()
EndIf

While 1
	Sleep(1000)
	If GUICtrlRead($cbEnable) = $GUI_CHECKED Then
		$iIdleTimeOld = $iIdleTime
		$iIdleTime = _Timer_GetIdleTime() + 10 * 1000
		If $iIdleTimeOld > $iIdleTime Then
			$bRunning = True
		EndIf
		; If _idle_time + 10s > screensaver_time
		If $bRunning And $iIdleTime > $iScreensaverTime Then
			If GUICtrlRead($rCheckProcess) = $GUI_CHECKED Then
				; Stop the ctrls if process is not found, to avoid infinite check ProcessExists
				$bRunning = False
				; If process is running (loop edit lines)
				For $iLine = 0 To _GUICtrlEdit_GetLineCount($eProcess)
					$sProcess = _GUICtrlEdit_GetLine($eProcess, $iLine)
					If ProcessExists($sProcess) Then
						__Log("Run [" & $sProcess & "]")
						; Send ver num 2 times
						Send("{NUMLOCK}")
						Send("{NUMLOCK}")
						$bRunning = True
						ExitLoop
					EndIf
				Next
			Else
				__Log("Run")
				; Send ver num 2 times
				Send("{NUMLOCK}")
				Send("{NUMLOCK}")
			EndIf
		EndIf
	EndIf
WEnd

;~ ========== FUNC ==========
Func __Exit()
	__SaveIni()
	__Log("Exiting")
	Exit
EndFunc   ;==>__Exit
Func __LoadIni()
	__Log("LoadIni")
	GUICtrlSetData($iMin, IniRead($sPathIni, "AutoIt_Idle", "Min", 5))
	iMinChange()
	GUICtrlSetState($cbEnable, IniRead($sPathIni, "AutoIt_Idle", "Enable", $GUI_CHECKED))
	cbEnableClick()
	GUICtrlSetState($rCheckProcess, IniRead($sPathIni, "AutoIt_Idle", "CheckProcess", $GUI_UNCHECKED))
	rClick()
	GUICtrlSetState($cbLog, IniRead($sPathIni, "AutoIt_Idle", "Log", $GUI_UNCHECKED))
	; Read the string from the ini
	Local $sOriginal = IniRead($sPathIni, "AutoIt_Idle", "Process", "")
	; Convert the dummies back into EOLs
	Local $sConverted = StringReplace($sOriginal, "{ENTER}", @CRLF)
	; Which we place in the edit
	GUICtrlSetData($eProcess, $sConverted)
EndFunc   ;==>__LoadIni
Func __Log($sToLog)
	_GUICtrlEdit_InsertText($eLog, _NowCalc() & " : " & $sToLog & @CRLF)
	If GUICtrlRead($cbLog) = $GUI_CHECKED Then
		_FileWriteLog($sPathLog, $sToLog & @CRLF)
	EndIf
EndFunc   ;==>__Log
Func __SaveIni()
	__Log("SaveIni")
	; Read multiple lines
	Local $sOriginal = GUICtrlRead($eProcess)
	; Convert EOLs into dummy strings
	Local $sConverted = StringReplace($sOriginal, @CRLF, "{ENTER}")
	; Which is written to the ini
	IniWrite($sPathIni, "AutoIt_Idle", "Process", $sConverted)
	IniWrite($sPathIni, "AutoIt_Idle", "Enable", GUICtrlRead($cbEnable))
	IniWrite($sPathIni, "AutoIt_Idle", "CheckProcess", GUICtrlRead($rCheckProcess))
	IniWrite($sPathIni, "AutoIt_Idle", "Min", GUICtrlRead($iMin))
	IniWrite($sPathIni, "AutoIt_Idle", "Log", GUICtrlRead($cbLog))
EndFunc   ;==>__SaveIni
Func __Show()
	GUISetState(@SW_SHOW)
EndFunc   ;==>__Show

Func bRefreshClick()
	__Log("Refresh System")
	; Screensaver
	Local $sOutput = ""
	_WinAPI_SystemParametersInfo($SPI_GETSCREENSAVETIMEOUT, 0, $sOutput)
	If $sOutput = "" Then
		$sOutput = "0"
	EndIf
	GUICtrlSetData($iScreensaver, $sOutput)

	Local $iPID = Run("powercfg /Q SCHEME_CURRENT", "", @SW_HIDE, $STDOUT_CHILD)
	$sOutput = ""
	While 1
		$sOutput = StdoutRead($iPID)
		If @error Then ExitLoop ; Exit the loop if the process closes or StdoutRead returns an error.
		FileWrite($sPathTmpSystem, $sOutput)
	WEnd

	Local $aTmp
	Local $iTmp = 0
	Local $bSleep = False
	Local $bHibernate = False
	Local $sLine = ""
	FileOpen($sPathTmpSystem, 0)
	For $i = 1 To _FileCountLines($sPathTmpSystem)
		$sLine = FileReadLine($sPathTmpSystem, $i)

		; Line 0		Power Setting GUID
		; Line 1		STANDBYIDLE // HIBERNATEIDLE
		If StringRegExp($sLine, "\bSTANDBYIDLE\b") = 1 Then
			$bSleep = True
			$iTmp = 0
		ElseIf StringRegExp($sLine, "\bHIBERNATEIDLE\b") = 1 Then
			$bHibernate = True
			$iTmp = 0
		EndIf
		; Line 6		Current AC Power Setting Index: 0x00000000
		; Line 7		Current DC Power Setting Index: 0x00000000
		If $bSleep Or $bHibernate Then
			If $iTmp = 6 Then
				$aTmp = StringRegExp($sLine, "\b0x(\d*)\b", $STR_REGEXPARRAYMATCH)
				If $bSleep Then
					$bSleep = False
					GUICtrlSetData($iSleep, Dec($aTmp[0]) / 60)
				ElseIf $bHibernate Then
					$bHibernate = False
					GUICtrlSetData($iHibernate, Dec($aTmp[0]) / 60)
				EndIf
			EndIf
			$iTmp += 1
		EndIf
	Next
	FileClose($sPathTmpSystem)
	FileDelete($sPathTmpSystem)
EndFunc   ;==>bRefreshClick
Func bSaveClick()
	__SaveIni()
EndFunc   ;==>bSaveClick
Func cbEnableClick()
	If GUICtrlRead($cbEnable) = $GUI_CHECKED Then
		GUICtrlSetState($rCheckProcess, $GUI_ENABLE)
	Else
		GUICtrlSetState($rCheckProcess, $GUI_UNCHECKED)
		GUICtrlSetState($rCheckProcess, $GUI_DISABLE)
	EndIf
	rClick()
EndFunc   ;==>cbEnableClick
Func fAutoItIdleClose()
	GUISetState(@SW_HIDE)
EndFunc   ;==>fAutoItIdleClose
Func iMinChange()
	$iScreensaverTime = GUICtrlRead($iMin) * 60 * 1000
EndFunc   ;==>iMinChange
Func rClick()
	If GUICtrlRead($rCheckProcess) = $GUI_CHECKED Then
		GUICtrlSetState($eProcess, $GUI_ENABLE)
	Else
		GUICtrlSetState($eProcess, $GUI_DISABLE)
	EndIf
EndFunc   ;==>rClick
