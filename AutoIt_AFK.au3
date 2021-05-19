#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=AutoIt_AFK.ico
#AutoIt3Wrapper_Outfile=.\Build\AutoIt_AFK.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Script to prevent Windows from going to sleep or the screensaver.
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (C) 2021
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_Field=Compiler Date|%date%
#AutoIt3Wrapper_Res_Field=Compiler Heure|%time%
#AutoIt3Wrapper_Res_Field=Compiler Version|AutoIt v%AutoItVer%
#AutoIt3Wrapper_Res_Field=Auteur|kevingrillet
#AutoIt3Wrapper_Add_Constants=y
#AutoIt3Wrapper_Run_Tidy=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------
	AutoIt Version:   3.3.14.2
	Scite Version:    3.7.3
	Author:           kevingrillet
	Name:             AutoIt_AFK
	Version:          1
	Script Function:  The purpose of this small script is to prevent Windows from going to sleep or the screensaver.
#ce ----------------------------------------------------------------------------

;~ ========== INCLUDES ==========
#include <ButtonConstants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <TabConstants.au3>
#include <Timers.au3>
#include <WindowsConstants.au3>

;~ ========== VARIABLES ==========
Local $bRunning = True
Local $iIdleTime = 0
Local $iScreensaverTime = 5 * 60 * 1000 ; 5 min
Local $sIniPath = @ScriptDir & "\AutoIt-AFK.ini"
Local $sLogPath = @ScriptDir & "\AutoIt-AFK.log"
Local $sProcess = ""

;~ ========== OPT ==========
Opt("GUIOnEventMode", 1)
Opt("TrayAutoPause", 0) ;0=no pause, 1=Pause
Opt("TrayMenuMode", 3) ;0=append, 1=no default menu, 2=no automatic check, 4=menuitemID  not return
Opt("TrayOnEventMode", 1) ;0=disable, 1=enable

;~ ========== GUI ==========
#Region ### START Koda GUI section ### Form=.\koda\forms\form1.kxf
$fAutoItAFK = GUICreate("AutoIt AFK", 390, 392, -1, -1, $WS_SYSMENU)
GUISetOnEvent($GUI_EVENT_CLOSE, "fAutoItAFKClose")
$Log = GUICtrlCreateTab(3, 3, 380, 356)
$tsOptions = GUICtrlCreateTabItem("Options")
$cbEnable = GUICtrlCreateCheckbox("Enable", 15, 36, 97, 17)
GUICtrlSetState($cbEnable, $GUI_CHECKED)
GUICtrlSetOnEvent($cbEnable, "cbEnableClick")
$iMin = GUICtrlCreateInput("", 168, 34, 65, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_NUMBER))
GUICtrlSetOnEvent($iMin, "iMinChange")
$bSave = GUICtrlCreateButton("Save", 295, 36, 75, 17)
GUICtrlSetOnEvent($bSave, "bSaveClick")
$gMode = GUICtrlCreateGroup("", 16, 56, 353, 41)
$rAlways = GUICtrlCreateRadio("Always", 24, 72, 113, 17)
GUICtrlSetState($rAlways, $GUI_CHECKED)
GUICtrlSetOnEvent($rAlways, "rClick")
$rCheckProcess = GUICtrlCreateRadio("Check Process", 208, 72, 113, 17)
GUICtrlSetOnEvent($rCheckProcess, "rClick")
GUICtrlCreateGroup("", -99, -99, 1, 1)
$eProcess = GUICtrlCreateEdit("", 15, 100, 353, 249)
$tsLog = GUICtrlCreateTabItem("Log")
$eLog = GUICtrlCreateEdit("", 15, 36, 353, 313)
GUICtrlCreateTabItem("")
$miShow = TrayCreateItem("Show AutoIt AFK")
TrayItemSetOnEvent($miShow, "_Show")
$miShutDown = TrayCreateItem("Shut Down AutoIt AFK")
TrayItemSetOnEvent($miShutDown, "_Exit")
;~ GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

;~ ========== MAINLOOP ==========
_Log(" Starting")
_LoadIni()
If Not FileExists($sIniPath) Then
	_Show()
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
				; If process is running
				$bRunning = False
				For $iLine = 0 To _GUICtrlEdit_GetLineCount($eProcess)
					$sProcess = _GUICtrlEdit_GetLine($eProcess, $iLine)
					If ProcessExists($sProcess) Then
						_Log(" Run [" & $sProcess & "]")
						; Send ver num 2 times
						Send("{NUMLOCK}")
						Send("{NUMLOCK}")
						$bRunning = True
						ExitLoop
					EndIf
				Next
			Else
				_Log(" Run")
				; Send ver num 2 times
				Send("{NUMLOCK}")
				Send("{NUMLOCK}")
			EndIf
		EndIf
	EndIf
WEnd

;~ ========== FUNC ==========
Func _Exit()
	_SaveIni()
	_Log(" Exiting")
	Exit
EndFunc   ;==>_Exit
Func _LoadIni()
	_Log(" LoadIni")
	GUICtrlSetData($iMin, IniRead($sIniPath, "AutoIt-AFK", "Min", 5))
	iMinChange()
	GUICtrlSetState($cbEnable, IniRead($sIniPath, "AutoIt-AFK", "Enable", $GUI_CHECKED))
	cbEnableClick()
	GUICtrlSetState($rCheckProcess, IniRead($sIniPath, "AutoIt-AFK", "CheckProcess", $GUI_UNCHECKED))
	rClick()
	$sOriginal = IniRead($sIniPath, "AutoIt-AFK", "Process", "")
	; Read the string from the ini
	$sOriginal = IniRead($sIniPath, "AutoIt-AFK", "Process", "")
	; Convert the dummies back into EOLs
	$sConverted = StringReplace($sOriginal, "{ENTER}", @CRLF)
	; Which we replace in the edit
	GUICtrlSetData($eProcess, $sConverted)
EndFunc   ;==>_LoadIni
Func _Log($sToLog)
	_GUICtrlEdit_InsertText($eLog, _NowCalc() & $sToLog & @CRLF)
	_FileWriteLog($sLogPath, _NowCalc() & $sToLog & @CRLF)
EndFunc   ;==>_Log
Func _SaveIni()
	_Log(" SaveIni")
	; Read multiple lines
	$sOriginal = GUICtrlRead($eProcess)
	; Convert EOLs into dummy strings
	$sConverted = StringReplace($sOriginal, @CRLF, "{ENTER}")
	; Which is written to the ini
	IniWrite($sIniPath, "AutoIt-AFK", "Process", $sConverted)
	IniWrite($sIniPath, "AutoIt-AFK", "Enable", GUICtrlRead($cbEnable))
	IniWrite($sIniPath, "AutoIt-AFK", "CheckProcess", GUICtrlRead($rCheckProcess))
	IniWrite($sIniPath, "AutoIt-AFK", "Min", GUICtrlRead($iMin))
EndFunc   ;==>_SaveIni
Func _Show()
	GUISetState(@SW_SHOW)
EndFunc   ;==>_Show
Func bSaveClick()
	_SaveIni()
EndFunc   ;==>bSaveClick
Func rClick()
	If GUICtrlRead($rCheckProcess) = $GUI_CHECKED Then
		GUICtrlSetState($eProcess, $GUI_ENABLE)
	Else
		GUICtrlSetState($eProcess, $GUI_DISABLE)
	EndIf
EndFunc   ;==>rClick
Func cbEnableClick()
	If GUICtrlRead($cbEnable) = $GUI_CHECKED Then
		GUICtrlSetState($rCheckProcess, $GUI_ENABLE)
	Else
		GUICtrlSetState($rCheckProcess, $GUI_UNCHECKED)
		GUICtrlSetState($rCheckProcess, $GUI_DISABLE)
	EndIf
	rClick()
EndFunc   ;==>cbEnableClick
Func fAutoItAFKClose()
	GUISetState(@SW_HIDE)
EndFunc   ;==>fAutoItAFKClose
Func iMinChange()
	$iScreensaverTime = GUICtrlRead($iMin) * 60 * 1000
EndFunc   ;==>iMinChange
