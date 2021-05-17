#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=AutoIt_AFK.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiEdit.au3>
#include <TabConstants.au3>
#include <Timers.au3>
#include <WindowsConstants.au3>

Opt("GUIOnEventMode", 1)

#Region ### START Koda GUI section ### Form=autoit-afk\koda\forms\form1.kxf
$fAutoItAFK = GUICreate("AutoIt AFK", 390, 390, -1, -1, $WS_SYSMENU)
GUISetOnEvent($GUI_EVENT_CLOSE, "fAutoItAFKClose")
$tsLog = GUICtrlCreateTab(3, 3, 380, 356)
$tsOptions = GUICtrlCreateTabItem("Options")
$cbCheckProcess = GUICtrlCreateCheckbox("Check Process", 15, 60, 97, 17)
GUICtrlSetOnEvent($cbCheckProcess, "cbCheckProcessClick")
$eProcess = GUICtrlCreateEdit("", 15, 84, 353, 265)
$bSave = GUICtrlCreateButton("Save", 295, 36, 75, 17)
GUICtrlSetOnEvent($bSave, "bSaveClick")
$cbEnable = GUICtrlCreateCheckbox("Enable", 15, 36, 97, 17)
GUICtrlSetState($cbEnable, $GUI_CHECKED)
GUICtrlSetOnEvent($cbEnable, "cbEnableClick")
$tsLog = GUICtrlCreateTabItem("Log")
$eLog = GUICtrlCreateEdit("", 16, 40, 353, 305)
;~ GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

Local $iIdleTime = 0
Local $iScreensaverTime = 5 * 60 * 1000 ; 5 min
Local $sIniPath = @ScriptDir & "\AutoIt-AFK.ini"
Local $sProcess = ""

_LoadIni()
GUISetState(@SW_SHOW)

While 1
	Sleep(100)
	If GUICtrlRead($cbEnable) = $GUI_CHECKED Then
		; If _idle_time + 10s > screensaver_time
		$iIdleTime = _Timer_GetIdleTime() + 10 * 1000
		If $iIdleTime > $iScreensaverTime Then
			If GUICtrlRead($cbCheckProcess) = $GUI_CHECKED Then
				_GUICtrlEdit_InsertText($eLog, @LF & _NowCalc() & " run")
				; Send ver num 2 times
				Send("{NUMLOCK}")
				Send("{NUMLOCK}")
			Else
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
			EndIf
		EndIf
	EndIf
WEnd

Func bSaveClick()
	; Read multiple lines
	$sOriginal = GUICtrlRead($eProcess)
	; Convert EOLs into dummy strings
	$sConverted = StringReplace($sOriginal, @CRLF, "{ENTER}")
	$sConverted = StringReplace($sConverted, @LF, "{ENTER}")
	; Which is written to the ini
	IniWrite($sIniPath, "AutoIt-AFK", "Process", $sConverted)
	IniWrite($sIniPath, "AutoIt-AFK", "Enable", GUICtrlRead($cbEnable))
	IniWrite($sIniPath, "AutoIt-AFK", "CheckProcess", GUICtrlRead($cbCheckProcess))
EndFunc   ;==>bSaveClick
Func cbCheckProcessClick()
	If GUICtrlRead($cbCheckProcess) = $GUI_CHECKED Then
		GUICtrlSetState($eProcess, $GUI_ENABLE)
	Else
		GUICtrlSetState($eProcess, $GUI_DISABLE)
	EndIf

EndFunc   ;==>cbCheckProcessClick
Func cbEnableClick()
	If GUICtrlRead($cbEnable) = $GUI_CHECKED Then
		GUICtrlSetState($cbCheckProcess, $GUI_ENABLE)
	Else
		GUICtrlSetState($cbCheckProcess, $GUI_UNCHECKED)
		GUICtrlSetState($cbCheckProcess, $GUI_DISABLE)
	EndIf
	cbCheckProcessClick()
EndFunc   ;==>cbEnableClick
Func fAutoItAFKClose()
	GUISetState(@SW_HIDE)
EndFunc   ;==>fAutoItAFKClose
Func _LoadIni()
	GUICtrlSetState($cbEnable, IniRead($sIniPath, "AutoIt-AFK", "Enable", $GUI_CHECKED))
	cbEnableClick()
	GUICtrlSetState($cbCheckProcess, IniRead($sIniPath, "AutoIt-AFK", "CheckProcess", $GUI_UNCHECKED))
	cbCheckProcessClick()
	$sOriginal = IniRead($sIniPath, "AutoIt-AFK", "Process", "")
	; Read the string from the ini
	$sOriginal = IniRead($sIniPath, "AutoIt-AFK", "Process", "")
	; Convert the dummies back into EOLs
	$sConverted = StringReplace($sOriginal, "{ENTER}", @LF)
	; Which we replace in the edit
	GUICtrlSetData($eProcess, $sConverted)
EndFunc   ;==>_LoadIni
