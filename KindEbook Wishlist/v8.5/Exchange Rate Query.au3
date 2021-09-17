#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=C:\Program Files\Tools\AutoIt3\Aut2Exe\Icons\AutoIt_Main_v10_256x256_RGB-A.ico
#AutoIt3Wrapper_Add_Constants=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                       ;;
;;  AutoIt Version: 3.3.0.0                                                              ;;
;;                                                                                       ;;
;;  Template AutoIt script.                                                              ;;
;;                                                                                       ;;
;;  AUTHOR:  TheSaint <thsaint@ihug.com.au>                                              ;;
;;                                                                                       ;;
;;  SCRIPT FUNCTION:   Program to query the Exchange Rate from European Central Bank.    ;;
;;                                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#include <INet.au3>
#include <File.au3>

Global $a, $array, $AUD, $from, $inifle, $line, $rate, $time, $to, $URL, $USD, $xml, $xmlfle

$inifle = @ScriptDir & "\Settings.ini"
$xmlfle = @ScriptDir & "\Source.xml"

$from = IniRead($inifle, "Conversion", "from", "USD")
$to = IniRead($inifle, "Conversion", "currency", "AUD")

$URL = IniRead($inifle, "Conversion", "url", "")
If $URL = "" Then
	$URL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
	;$URL = "https://www.xe.com/currencyconverter/convert/?Amount=1&From=" & $from & "&To=" & $to & '"'
	;$URL = "https://www.xe.com/currencyconverter/"
	IniWrite($inifle, "Conversion", "url", $URL)
EndIf

$rate = ""

$xml = _INetGetSource($URL)
If @error = 1 Then
	MsgBox(262192, "Source Error", "Cannot get data from the web!", 0)
Else
	If FileExists($xmlfle) Then FileDelete($xmlfle)
	Sleep(500)
	FileWriteLine($xmlfle, $xml)
	Sleep(500)
	If FileExists($xmlfle) Then
		;$array = FileReadToArray($xmlfle)
		_FileReadToArray($xmlfle, $array)
		If IsArray($array) Then
			$USD = ""
			$AUD = ""
;~ 			If $from = "EUR" Then $USD = "1.0"
;~ 			If $to = "EUR" Then $AUD = "1.0"
;~ 			;For $a = 0 To UBound($array)
			For $a = 1 To $array[0]
				$line = $array[$a]
				If StringInStr($line, "currency='" & $from & "'") Then
					$USD = StringSplit($line, "rate='", 1)
					If $USD[0] = 2 Then
						$USD = $USD[2]
						$USD = StringSplit($USD, "'/>", 1)
						If $USD[0] = 2 Then
							$USD = $USD[1]
							If StringIsDigit(StringReplace($USD, ".", "")) = 0 Then
								$USD = ""
							EndIf
						Else
							$USD = ""
							ExitLoop
						EndIf
					Else
						$USD = ""
						ExitLoop
					EndIf
				ElseIf StringInStr($line, "currency='" & $to & "'") Then
					$AUD = StringSplit($line, "rate='", 1)
					If $AUD[0] = 2 Then
						$AUD = $AUD[2]
						$AUD = StringSplit($AUD, "'/>", 1)
						If $AUD[0] = 2 Then
							$AUD = $AUD[1]
							If StringIsDigit(StringReplace($AUD, ".", "")) = 0 Then
								$AUD = ""
							EndIf
						Else
							$AUD = ""
							ExitLoop
						EndIf
					Else
						$AUD = ""
						ExitLoop
					EndIf
				ElseIf $USD <> "" And $AUD <> "" Then
					ExitLoop
				EndIf
			Next
			If $USD = "" Then
				MsgBox(262192, "Exchange Rate Error", "Could not obtain " & $from & " value!", 0)
			ElseIf $AUD = "" Then
				MsgBox(262192, "Exchange Rate Error", "Could not obtain " & $to & " value!", 0)
			Else
				$rate = Round($AUD / $USD, 2)
				IniWrite($inifle, "Exchange Rate", "value", $rate)
				IniWrite($inifle, "Conversion", "rate", $rate)
				;MsgBox(262192, "Exchange Rate", $rate, 0)
			EndIf
		Else
			MsgBox(262192, "Read Error", "No Array created!", 0)
		EndIf
	Else
		MsgBox(262192, "Read Error", "Source.xml file not found!", 0)
	EndIf
EndIf

If $rate = "" Then
	$time = ""
Else
	$time = _NowCalc()
EndIf
IniWrite($inifle, "Conversion", "time", $time)

Exit
