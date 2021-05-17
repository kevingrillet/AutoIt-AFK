#cs ----------------------------------------------------------------------------
	AutoIt Version:   3.3.14.2
	Scite Version:    3.7.3
	Author:           kevingrillet
	Name:             AutoIt_AFK
	Version:          1
	Script Function:  The purpose of this small script is to prevent Windows from going to sleep or the screensaver.
#ce ----------------------------------------------------------------------------

;~ ========== COMPILATION ==========
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_OutFile = ./AutoIt_AFK.exe
#AutoIt3Wrapper_OutFile_Type = exe
#AutoIt3Wrapper_Res_Description = AutoIt_AFK
#AutoIt3Wrapper_Res_Comment = AutoIt_AFK
#AutoIt3Wrapper_Res_Fileversion = 1
#AutoIt3Wrapper_Res_Field = Compilation Date|%date%
#AutoIt3Wrapper_Res_Field = Compilation Heure|%time%
#AutoIt3Wrapper_Res_Field = Version du Compilateur|AutoIt v%AutoItVer%
#AutoIt3Wrapper_Res_Field = Auteur|kevingrillet
#AutoIt3Wrapper_Res_LegalCopyright = Copyright (C) 2021
#AutoIt3Wrapper_Res_Language = 0x0409
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

;~ ========== INCLUDES ==========
#include <ButtonConstants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <TabConstants.au3>
#include <Timers.au3>
#include <WindowsConstants.au3>

;~ ========== VARIABLES ==========
Local $iIdleTime = 0
Local $iMsg = 0
Local $iScreensaverTime = 5 * 60 * 1000 ; 5 min
Local $sIniPath = @ScriptDir & "\AutoIt-AFK.ini"
Local $sProcess = ""

;~ ========== GUI ==========
Opt("GUIOnEventMode", 1)
#Region ### START Koda GUI section ###
$fAutoItAFK = GUICreate("AutoIt AFK", 390, 392, -1, -1, $WS_SYSMENU)
$Log = GUICtrlCreateTab(3, 3, 380, 356)
$tsOptions = GUICtrlCreateTabItem("Options")
$cbEnable = GUICtrlCreateCheckbox("Enable", 15, 36, 97, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent($cbEnable, "cbEnableClick")
$iMin = GUICtrlCreateInput("", 168, 34, 65, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_NUMBER))
GUICtrlSetOnEvent($iMin, "iMinChange")
$bSave = GUICtrlCreateButton("Save", 295, 36, 75, 17)
GUICtrlSetOnEvent($bSave, "bSaveClick")
$gMode = GUICtrlCreateGroup("", 16, 56, 353, 41)
$rAlways = GUICtrlCreateRadio("Always", 24, 72, 113, 17)
GUICtrlSetOnEvent($rAlways, "rClick")
$rCheckProcess = GUICtrlCreateRadio("Check Process", 208, 72, 113, 17)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent($rCheckProcess, "rClick")
GUICtrlCreateGroup("", -99, -99, 1, 1)
$eProcess = GUICtrlCreateEdit("", 15, 100, 353, 249)
$tsLog = GUICtrlCreateTabItem("Log")
$eLog = GUICtrlCreateEdit("", 15, 36, 353, 313)
GUICtrlCreateTabItem("")
;~ $miShow = TrayCreateItem("Show AutoIt AFK")
;~ GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

;~ ========== MAINLOOP ==========
_LoadIni()
;~ If Not FileExists($sIniPath) Then
	GUISetState(@SW_SHOW)
;~ EndIf

While 1
	Sleep(100)
	If GUICtrlRead($cbEnable) = $GUI_CHECKED Then
		; If _idle_time + 10s > screensaver_time
		$iIdleTime = _Timer_GetIdleTime() + 10 * 1000
		If $iIdleTime > $iScreensaverTime Then
			If GUICtrlRead($rCheckProcess) = $GUI_CHECKED Then
				; If process is running
				For $iLine = 0 To _GUICtrlEdit_GetLineCount($eProcess)
					$sProcess = _GUICtrlEdit_GetLine($eProcess, $iLine)
					If ProcessExists($sProcess) Then
						_GUICtrlEdit_InsertText($eLog, @LF & _NowCalc() & " run [" & $sProcess & "]")
						; Send ver num 2 times
						Send("{NUMLOCK}")
						Send("{NUMLOCK}")
					EndIf
				Next
			Else
				_GUICtrlEdit_InsertText($eLog, @LF & _NowCalc() & " run")
				; Send ver num 2 times
				Send("{NUMLOCK}")
				Send("{NUMLOCK}")
			EndIf
		EndIf
	EndIf
	$iMsg = TrayGetMsg()
	If $iMsg = $miShow Then
		GUISetState(@SW_SHOW)
	EndIf
WEnd

;~ ========== FUNC ==========
Func _LoadIni()
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
	$sConverted = StringReplace($sOriginal, "{ENTER}", @LF)
	; Which we replace in the edit
	GUICtrlSetData($eProcess, $sConverted)
EndFunc   ;==>_LoadIni
Func _SaveIni()
	; Read multiple lines
	$sOriginal = GUICtrlRead($eProcess)
	; Convert EOLs into dummy strings
	$sConverted = StringReplace($sOriginal, @CRLF, "{ENTER}")
	$sConverted = StringReplace($sConverted, @LF, "{ENTER}")
	; Which is written to the ini
	IniWrite($sIniPath, "AutoIt-AFK", "Process", $sConverted)
	IniWrite($sIniPath, "AutoIt-AFK", "Enable", GUICtrlRead($cbEnable))
	IniWrite($sIniPath, "AutoIt-AFK", "CheckProcess", GUICtrlRead($rCheckProcess))
	IniWrite($sIniPath, "AutoIt-AFK", "Min", GUICtrlRead($iMin))
EndFunc   ;==>_SaveIni
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
