;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                       ;;
;;  AutoIt Version: 3.3.14.2                                                             ;;
;;                                                                                       ;;
;;  Template AutoIt script.                                                              ;;
;;                                                                                       ;;
;;  AUTHOR:  TheSaint                                                                    ;;
;;                                                                                       ;;
;;  SCRIPT FUNCTION:  A program to check specific Kobo ebook prices                      ;;
;;                                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; FUNCTIONS
; DetailsGUI(), FileSelectorGUI(), EnableDisableControls($state), LoadTheList($loading)

#include <Constants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <ColorConstants.au3>
#include <EditConstants.au3>
#include <ListViewConstants.au3>
#include <StaticConstants.au3>
#include <StringConstants.au3>
#include <GuiListView.au3>
#include <Misc.au3>
#include <File.au3>
#include <Date.au3>
#include <Inet.au3>
#include <IE.au3>

Local $exe, $script, $status, $w, $wins

Global $handle, $pid, $Scriptname, $updated, $version

$updated = "(updated September 2021)"
$version = "v1.7"
$Scriptname = "KoboChecker " & $version

$status = _Singleton("kobo-checker-thsaint", 1)
If $status = 0 Then
	; Attempt to retore and activate a non-active or minimized window.
	If @Compiled = 1 Then
		$pid = ProcessExists(@ScriptName)
		$exe = @ScriptName
	Else
		$pid = ProcessExists("AutoIt3.exe")
		$exe = "AutoIt3.exe"
	EndIf
	$script = @AutoItPID
	If $script <> $pid Then
		$wins = WinList($Scriptname, "")
		For $w = 1 to $wins[0][0]
			$handle = $wins[$w][1]
			If WinGetProcess($handle, "") = $pid Then
				WinSetState($handle, "", @SW_RESTORE)
				WinActivate($handle, "")
				ExitLoop
			EndIf
		Next
		Exit
	EndIf
EndIf

Global $Button_add, $Button_check, $Button_detail, $Button_favs, $Button_info, $Button_quit, $Button_reload, $Button_rem, $Button_vip, $Button_web
Global $Checkbox_cancel, $Combo_select, $Combo_shutdown, $Group_ebooks, $Label_user, $ListView_ebooks, $Radio_none, $Radio_selall

Global $author, $begin, $catfle, $check, $checking, $commence, $cnt, $cost, $detail, $diff, $download, $entries, $entry, $ents, $err
Global $hours, $html, $ID, $ids, $idx, $imgfld, $imgfle, $inifle, $kobofle, $koboini, $koboURL, $line, $lines, $load, $logfle, $lowid
Global $method, $mins, $num, $numb, $oIE, $price, $prior, $s, $secs, $section, $sections, $SelectorGUI, $state, $status, $styles, $taken
Global $time, $title, $url, $user, $vip

$imgfld = @ScriptDir & "\Kobo Covers"
$inifle = @ScriptDir & "\Settings.ini"
$logfle = @ScriptDir & "\Kobo.log"
$kobofle = @ScriptDir & "\Kobo.html"
$koboini = @ScriptDir & "\Kobolist.ini"

$method = 2

FileSelectorGUI()

Exit

Func FileSelectorGUI()
	Local $Group_status, $Group_select, $Input_author, $Input_title, $Label_overlay, $Label_price, $Label_shut, $Label_time
	;
	Local $a, $ans, $b, $blurb, $cancel, $checked, $checker, $checkit, $cursor, $ebookfle, $edge, $favorites, $first, $half, $height, $hidden
	Local $icoI, $icoR, $icoX, $image, $ind, $last, $left, $ping, $prices, $releasedate, $reload, $replace, $select, $series, $set, $shell
	Local $shutdown, $skip, $start, $titcheck, $top, $user32, $wide, $width, $winpos
	;
	$width = 870
	$height = 405
	$left = IniRead($inifle, "Kobo Check", "left", @DesktopWidth - $width - 25)
	$top = IniRead($inifle, "Kobo Check", "top", @DesktopHeight - $height - 60)
	$styles = $WS_OVERLAPPED + $WS_CAPTION + $WS_MINIMIZEBOX ; + $WS_POPUP
	$SelectorGUI = GuiCreate("Kobo Ebooks Selector - Price Checker", $width - 5, $height, $left, $top, $styles + $WS_SIZEBOX + $WS_VISIBLE, $WS_EX_TOPMOST)
	GUISetBkColor(0xBBFFBB, $SelectorGUI)
	; CONTROLS
	$Group_ebooks = GuiCtrlCreateGroup("Ebooks To Check", 10, 10, $width - 25, 322)
	GUICtrlSetResizing($Group_ebooks, $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKHEIGHT + $GUI_DOCKRIGHT)
	$Label_user = GUICtrlCreateLabel("", ($width / 2) - 60, 5, 120, 20, $SS_CENTER + $SS_CENTERIMAGE) ; + $SS_SUNKEN
	GUICtrlSetResizing($Label_user, $GUI_DOCKLEFT + $GUI_DOCKAUTO)
	GUICtrlSetFont($Label_user, 9, 600)
	GUICtrlSetTip($Label_user, "Current User!")
	$Button_reload = GuiCtrlCreateButton("R", $width - 50, 4, 25, 22, $BS_ICON)
	GUICtrlSetResizing($Button_reload, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_reload, "Reload the list of ebooks!")
	$Label_overlay = GuiCtrlCreateLabel("", 20, 30, $width - 65, 260)
	GUICtrlSetBkColor($Label_overlay, $GUI_BKCOLOR_TRANSPARENT) ;$GUI_BKCOLOR_TRANSPARENT $COLOR_BLACK
	$ListView_ebooks = GUICtrlCreateListView("No.|Title|Author|Prior|Price|ID", 20, 30, $width - 45, 260, $LVS_SHOWSELALWAYS + $LVS_SINGLESEL + $LVS_REPORT, _
													$LVS_EX_FULLROWSELECT + $LVS_EX_GRIDLINES + $LVS_EX_CHECKBOXES) ; + $LVS_NOCOLUMNHEADER
	GUICtrlSetBkColor($ListView_ebooks, 0xF0D0F0)
	GUICtrlSetResizing($ListView_ebooks, $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKHEIGHT + $GUI_DOCKRIGHT)
	$Input_title = GUICtrlCreateInput("", 20, 300, ($width / 2) + 25, 20)
	GUICtrlSetResizing($Input_title, $GUI_DOCKLEFT + $GUI_DOCKAUTO)
	GUICtrlSetTip($Input_title, "Selected ebook title!")
	$Input_author = GUICtrlCreateInput("", ($width / 2) + 50, 300, ($width / 2) - 120, 20)
	GUICtrlSetResizing($Input_author, $GUI_DOCKRIGHT + $GUI_DOCKAUTO + $GUI_DOCKHCENTER)
	GUICtrlSetTip($Input_author, "Selected ebook author!")
	;
	$Button_vip = GuiCtrlCreateButton("VIP", $width - 65, 299, 40, 22)
	GUICtrlSetFont($Button_vip, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_vip, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_vip, "Selected ebook qualifies for VIP price!")
	;
	$Group_select = GuiCtrlCreateGroup("Select Ebooks", 10, $height - 65, 150, 55)
	GUICtrlSetResizing($Group_select, $GUI_DOCKLEFT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	$Radio_selall = GUICtrlCreateRadio("ALL", 20, $height - 44,  42, 21)
	GUICtrlSetFont($Radio_selall, 7, 400, 0, "Small Fonts")
	GUICtrlSetResizing($Radio_selall, $GUI_DOCKLEFT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Radio_selall, "Select ALL ebook entries!")
	GUICtrlSetBkColor($Radio_selall, 0xFFD5FF)
	$Radio_none = GUICtrlCreateRadio("None", 62, $height - 44,  44, 21)
	GUICtrlSetFont($Radio_none, 7, 400, 0, "Small Fonts")
	GUICtrlSetResizing($Radio_none, $GUI_DOCKLEFT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Radio_none, "Deselect ALL ebook entries!")
	GUICtrlSetBkColor($Radio_none, 0xFFD5FF)
	$Combo_select = GUICtrlCreateCombo("", 107, $height - 44, 45, 21)
	GUICtrlSetResizing($Combo_select, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Combo_select, "Select options!")
	;
	$Group_status = GuiCtrlCreateGroup("Status", 170, $height - 65, 185, 55)
	GUICtrlSetResizing($Group_status, $GUI_DOCKLEFT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	$Label_time = GuiCtrlCreateLabel("", 180, $height - 45, 65, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetResizing($Label_time, $GUI_DOCKLEFT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetBkColor($Label_time, $COLOR_WHITE)
	GUICtrlSetTip($Label_time, "Check Time!")
	;
	$Label_wait = GuiCtrlCreateLabel("", 255, $height - 45, 89, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetResizing($Label_wait, $GUI_DOCKLEFT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetBkColor($Label_wait, $COLOR_WHITE)
	GUICtrlSetTip($Label_wait, "Process Status!")
	;
	$Label_price = GuiCtrlCreateLabel("", 365, $height - 59, 55, 20, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetResizing($Label_price, $GUI_DOCKLEFT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetBkColor($Label_price, $COLOR_WHITE)
	GUICtrlSetTip($Label_price, "Selected price result!")
	;
	$Button_detail = GuiCtrlCreateButton("DETAIL", 365, $height - 32, 55, 22)
	GUICtrlSetFont($Button_detail, 6, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_detail, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_detail, "Detail for selected ebook!")
	;
	$Button_add = GuiCtrlCreateButton("ADD", 430, $height - 60, 60, 25)
	GUICtrlSetFont($Button_add, 8, 600)
	GUICtrlSetResizing($Button_add, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_add, "ADD a Kobo ebook to the list!")
	;
	$Button_rem = GuiCtrlCreateButton("REMOVE", 430, $height - 30, 60, 20)
	GUICtrlSetFont($Button_rem, 6, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_rem, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_rem, "Remove a Kobo ebook from the list!")
	;
	$Label_shut = GuiCtrlCreateLabel("SHUTDOWN", $width - 368, $height - 59, 83, 27, $SS_CENTER + $SS_CENTERIMAGE + $SS_SUNKEN)
	GUICtrlSetResizing($Label_shut, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetFont($Label_shut, 7, 600, 0, "Small Fonts")
	GUICtrlSetBkColor($Label_shut, $COLOR_SKYBLUE) ;$COLOR_BLACK
	GUICtrlSetColor($Label_shut, $COLOR_WHITE)
	$Combo_shutdown = GUICtrlCreateCombo("", $width - 368, $height - 32, 83, 21)
	GUICtrlSetResizing($Combo_shutdown, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Combo_shutdown, "Shutdown options!")
	;
	$Button_web = GuiCtrlCreateButton("WEB", $width - 274, $height - 60, 54, 28)
	GUICtrlSetFont($Button_web, 7, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_web, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_web, "Go to the web page for selected ebook!")
	;
	$Checkbox_cancel = GUICtrlCreateCheckbox("Cancel ", $width - 271, $height - 28, 50, 20)
	GUICtrlSetResizing($Checkbox_cancel, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Checkbox_cancel, "Cancel checking after the current process has finished!")
	;
	;$Button_check = GuiCtrlCreateButton("CHECK", $width - 210, $height - 60, 80, 50)
	$Button_check = GuiCtrlCreateButton("CHECK", $width - 210, $height - 60, 80, 28)
	GUICtrlSetFont($Button_check, 9, 600)
	GUICtrlSetResizing($Button_check, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_check, "Check selected ebooks!")
	;
	$Button_favs = GuiCtrlCreateButton("FAVORITES", $width - 210, $height - 28, 80, 20)
	GUICtrlSetFont($Button_favs, 6, 600, 0, "Small Fonts")
	GUICtrlSetResizing($Button_favs, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_favs, "Set the selected entries as favorites!")
	;
	$Button_info = GuiCtrlCreateButton("Info", $width - 120, $height - 60, 50, 50, $BS_ICON)
	GUICtrlSetResizing($Button_info, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_info, "Program Information!")
	;
	$Button_quit = GuiCtrlCreateButton("EXIT", $width - 60, $height - 60, 45, 50, $BS_ICON)
	GUICtrlSetResizing($Button_quit, $GUI_DOCKRIGHT + $GUI_DOCKALL + $GUI_DOCKSIZE)
	GUICtrlSetTip($Button_quit, "Exit / Close / Quit the window!")
	;
	$lowid = $Button_quit + 1
	;
	; OS SETTINGS
	$user32 = @SystemDir & "\user32.dll"
	$shell = @SystemDir & "\shell32.dll"
	$icoI = -5
	$icoR = -239
	$icoX = -4
	;
	; SETTINGS
	GUICtrlSetImage($Button_reload, $shell, $icoR, 0)
	GUICtrlSetImage($Button_info, $user32, $icoI, 1)
	GUICtrlSetImage($Button_quit, $user32, $icoX, 1)
	;
	GUICtrlSetData($Combo_select, "||Half|10|20|Favs|Rest", "")
	;
	GUICtrlSetData($Combo_shutdown, "none|Hibernate|Logoff|Powerdown|Reboot|Shutdown|Standby", "none")
	;
	$status = ""
	EnableDisableControls($GUI_DISABLE, "")
	LoadTheList("load")
	EnableDisableControls($GUI_ENABLE, "")
	;
	$checker = 0
	$select = ""
	$set = ""
	$hidden = 1
	$reload = ""
	$ids = ""
	;
	;$cursor = MouseGetCursor()

	GuiSetState()
	;
	;Sleep(2000)
	GUICtrlSetState($Label_overlay, $GUI_HIDE)
	GUICtrlSetState($Listview_ebooks, $GUI_FOCUS)
					;_GUICtrlListView_SetItemSelected($ListView_ebooks, -1, True, False)
					;_GUICtrlListView_ClickItem($Listview_ebooks, 0, "left", False, 1, 1)
	While 1
		$msg = GuiGetMsg()
		Select
		Case $msg = $GUI_EVENT_CLOSE Or $msg = $Button_quit
			; Exit / Close / Quit the window
			$winpos = WinGetPos($SelectorGUI, "")
			$left = $winpos[0]
			If $left < 0 Then
				$left = 2
			ElseIf $left > @DesktopWidth - $width Then
				$left = @DesktopWidth - $width - 25
			EndIf
			IniWrite($inifle, "Kobo Check", "left", $left)
			$top = $winpos[1]
			If $top < 0 Then
				$top = 2
			ElseIf $top > @DesktopHeight - ($height + 20) Then
				$top = @DesktopHeight - $height - 60
			EndIf
			IniWrite($inifle, "Kobo Check", "top", $top)
			;
			GUIDelete($SelectorGUI)
			ExitLoop
		Case $msg = $GUI_EVENT_RESIZED
			$winpos = WinGetPos($SelectorGUI, "")
			$wide = $winpos[2]
			If $left > @DesktopWidth - $wide Then
				$edge = @DesktopWidth - $wide - 20
			ElseIf $wide < $width Then
				$wide = $width + 10
			Else
				$edge = $left
			EndIf
			WinMove($SelectorGUI, "", $edge, $top, $wide, $height + 38)
			If $wide > $width Then
				$resize = $wide - $width
				_GUICtrlListView_SetColumnWidth($ListView_ebooks, 1, 305 + $resize)
			Else
				_GUICtrlListView_SetColumnWidth($ListView_ebooks, 1, 305)
			EndIf
		Case $msg = $Button_web
			; Go to the web page for selected ebook
			$ind = _GUICtrlListView_GetSelectedIndices($ListView_ebooks, True)
			If IsArray($ind) Then
				If $ind[0] > 0 Then
					$ind = $ind[1]
					If $ind > -1 Then
						$ID = _GUICtrlListView_GetItemText($ListView_ebooks, $ind, 5)
						$koboURL = IniRead($catfle, $ID, "kobo_url", "")
						If $koboURL = "" Then $koboURL = IniRead($koboini, $ID, "kobo_url", "")
						If $koboURL <> "" Then
							ShellExecute($koboURL)
						Else
							MsgBox(262192, "Web Error", "URL not found!", 0, $SelectorGUI)
						EndIf
					Else
						MsgBox(262192, "Selection Error", "Entry is incorrectly selected!", 0, $SelectorGUI)
					EndIf
				Else
					MsgBox(262192, "Selection Error", "Selected entry count is wrong!", 0, $SelectorGUI)
				EndIf
			Else
				MsgBox(262192, "Selection Error", "No entry selected!", 0, $SelectorGUI)
			EndIf
		Case $msg = $Button_vip
			; elected ebook qualifies for VIP price
			$ind = _GUICtrlListView_GetSelectedIndices($ListView_ebooks, True)
			If IsArray($ind) Then
				If $ind[0] > 0 Then
					$ind = $ind[1]
					If $ind > -1 Then
						$ID = _GUICtrlListView_GetItemText($ListView_ebooks, $ind, 5)
						$koboURL = IniRead($catfle, $ID, "kobo_url", "")
						If $koboURL = "" Then
							$price = IniRead($koboini, $ID, "kobo_price", "")
							$vip = IniRead($koboini, $ID, "vip", "")
							If $vip = "" Then
								$vip = 1
							Else
								$vip = ""
							EndIf
							IniWrite($koboini, $ID, "vip", $vip)
						Else
							$price = IniRead($catfle, $ID, "kobo_price", "")
							$vip = IniRead($catfle, $ID, "vip", "")
							If $vip = "" Then
								$vip = 1
							Else
								$vip = ""
							EndIf
							IniWrite($catfle, $ID, "vip", $vip)
						EndIf
						If $vip = 1 Then
							$cost = StringTrimLeft($price, 1)
							$check = (10 * $cost) / 100
							$check = $cost - $check
							$check = Round($check, 2)
							If StringInStr($check, ".") < 1 Then
								$check = $check & ".00"
							Else
								$cost = StringSplit($check, ".")
								If StringLen($cost[$cost[0]]) = 1 Then
									$check = $check & "0"
								EndIf
							EndIf
							$price = StringLeft($price, 1) & $check
							GUICtrlSetColor($lowid + $ind, $COLOR_MAROON)
						Else
							GUICtrlSetColor($lowid + $ind, $COLOR_BLACK)
						EndIf
						_GUICtrlListView_SetItemText($ListView_ebooks, $ind, $price, 4)
					Else
						MsgBox(262192, "Selection Error", "Entry is incorrectly selected!", 0, $SelectorGUI)
					EndIf
				Else
					MsgBox(262192, "Selection Error", "Selected entry count is wrong!", 0, $SelectorGUI)
				EndIf
			Else
				MsgBox(262192, "Selection Error", "No entry selected!", 0, $SelectorGUI)
			EndIf
		Case $msg = $Button_rem
			; Remove a Kobo ebook from the list
			$ind = _GUICtrlListView_GetSelectedIndices($ListView_ebooks, True)
			If IsArray($ind) Then
				If $ind[0] > 0 Then
					$ind = $ind[1]
					If $ind > -1 Then
						$ID = _GUICtrlListView_GetItemText($ListView_ebooks, $ind, 5)
						$koboURL = IniRead($koboini, $ID, "kobo_url", "")
						If $koboURL = "" Then
							MsgBox(262192, "Removal Error", "Only Kobo ebooks manually added can be removed!", 0, $SelectorGUI)
						Else
							$ans = MsgBox(262177 + 256, "Removal Query", "This will be a permanent change." & @LF & @LF & _
								"OK = Remove (Delete) the selected ebook.", 0, $SelectorGUI)
							If $ans = 1 Then
								IniDelete($koboini, $ID)
								$reload = 1
							EndIf
						EndIf
					Else
						MsgBox(262192, "Selection Error", "Entry is incorrectly selected!", 0, $SelectorGUI)
					EndIf
				Else
					MsgBox(262192, "Selection Error", "Selected entry count is wrong!", 0, $SelectorGUI)
				EndIf
			Else
				MsgBox(262192, "Selection Error", "No entry selected!", 0, $SelectorGUI)
			EndIf
		Case $msg = $Button_reload Or $reload = 1
			; Reload the list of ebooks
			EnableDisableControls($GUI_DISABLE, "")
			_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
			$set = ""
			$reload = ""
			If GUICtrlRead($Radio_selall) = $GUI_CHECKED Then
				GUICtrlSetState($Radio_selall, $GUI_UNCHECKED)
			ElseIf GUICtrlRead($Radio_none) = $GUI_CHECKED Then
				GUICtrlSetState($Radio_none, $GUI_UNCHECKED)
			EndIf
			If $select <> "" Then
				GUICtrlSetData($Combo_select, "||Half|10|20|Favs|Rest", "")
			EndIf
			_GUICtrlListView_DeleteAllItems($ListView_ebooks)
			LoadTheList("reload")
			EnableDisableControls($GUI_ENABLE, "")
		Case $msg = $Button_info
			; Program Information
			$titcheck = IniRead($inifle, "Kobo Check", "last", "")
			$ans = MsgBox(262209 + 256, "Program Information", _
				"This program is a companion to my KindEbook Wishlist program," & @LF & _
				"which is required to populate the 'Ebooks To Check' Kobo list." & @LF & @LF & _
				"Kobo urls are taken from the ebooks of the current user set in the" & @LF & _
				"KindEbook Wishlist program - set via a right-click list option, that" & @LF & _
				"presents the 'Image & Text' window, that provides Kobo options." & @LF & @LF & _
				"Only successful price checks are stored (saved & updated)." & @LF & @LF & _
				"If a price cannot be extracted from the source returned, then the" & @LF & _
				"'Price' field is shown as empty. If the HTML source isn't returned," & @LF & _
				"then the 'Price' field displays 'fail'. These are not saved (stored)." & @LF & @LF & _
				"Just the entries you want to check, can optionally be selected." & @LF & @LF & _
				"Clicking the 'Half' option, selects the first or second lot of entries." & @LF & _
				"Clicking on '10' or '20', selects that many entries. Re-clicking acts" & @LF & _
				"as a next, and selects the next lot of 10 or 20 (including after half)." & @LF & @LF & _
				"'Cancel' will only work between selected ebook entry processing," & @LF & _
				"and may take some time to show the checkbox selection." & @LF & @LF & _
				"A 'Shutdown' option can be set for after all checks have finished." & @LF & @LF & _
				"Program window can be widened." & @LF & @LF & _
				"NOTE - Formerly this checking was done in KindEbook Wishlist," & @LF & _
				"but it no longer works. The modification to make it work, takes" & @LF & _
				"a lot longer, which is why it is now a mostly separate program." & @LF & _
				"For me, each entry takes between 20 to 40 seconds to check." & @LF & @LF & _
				"Last checked = " & $titcheck & @LF & @LF & _
				"© July 2021 - " & $Scriptname & " created by TheSaint." & @LF & _
				$updated & " (thsaint@ihug.com.au)", 0, $SelectorGUI)
			If $ans = 1 Then
				If FileExists($logfle) Then ShellExecute($logfle)
			EndIf
;~ 			If $hidden = 1 Then
;~ 				$hidden = ""
;~ 				;$cursor = MouseGetCursor()
;~ 				;_GUICtrlListView_SetItemSelected($ListView_ebooks, -1, True, False)
;~ 				_GUICtrlListView_ClickItem($Listview_ebooks, $ind + 1, "left", False, 1, 1)
;~ 				;GUICtrlSetState($Label_overlay, $GUI_SHOW)
;~ 				;GUISetCursor(15, 1, $SelectorGUI)
;~ 			Else
;~ 				$hidden = 1
;~ 				;GUICtrlSetState($Label_overlay, $GUI_HIDE)
;~ 				GUICtrlSetState($Listview_ebooks, $GUI_FOCUS)
;~ 				;GUISetCursor($cursor, 1, $SelectorGUI)
;~ 			EndIf
		Case $msg = $Button_favs
			; Set the selected entries as favorites
			EnableDisableControls($GUI_DISABLE, "")
			$favorites = ""
			GUICtrlSetBkColor($Label_wait, $COLOR_RED)
			GUICtrlSetData($Label_wait, "Please Wait!")
			GUICtrlSetState($Listview_ebooks, $GUI_FOCUS)
			For $a = 0 To $ents - 1
				If _GUICtrlListView_GetItemChecked($ListView_ebooks, $a) = True Then
					$ID = _GUICtrlListView_GetItemText($ListView_ebooks, $a, 5)
					If $favorites = "" Then
						$favorites = "|" & $ID & "|"
					Else
						$favorites = $favorites & $ID & "|"
					EndIf
				EndIf
			Next
			IniWrite($inifle, "Favorites", "ids", $favorites)
			GUICtrlSetBkColor($Label_wait, $COLOR_LIME)
			GUICtrlSetData($Label_wait, "Favorites Saved!")
			EnableDisableControls($GUI_ENABLE, "")
			;_GUICtrlListView_SetItemSelected($ListView_ebooks, -1, True, False)
		Case $msg = $Button_detail
			; Detail for selected ebook
			$ind = _GUICtrlListView_GetSelectedIndices($ListView_ebooks, True)
			If IsArray($ind) Then
				If $ind[0] > 0 Then
					$ind = $ind[1]
					If $ind > -1 Then
						$ID = _GUICtrlListView_GetItemText($ListView_ebooks, $ind, 5)
						$koboURL = IniRead($catfle, $ID, "kobo_url", "")
						If $koboURL = "" Then
							$koboURL = IniRead($koboini, $ID, "kobo_url", "")
							$title = IniRead($koboini, $ID, "title", "")
							$author = IniRead($koboini, $ID, "author", "")
							$price = IniRead($koboini, $ID, "kobo_price", "")
							$prior = IniRead($koboini, $ID, "kobo_prior", "")
							$start = IniRead($koboini, $ID, "kobo_start", "")
							$prices = IniRead($koboini, $ID, "kobo_prices", "")
							$series = IniRead($koboini, $ID, "series", "")
							$blurb = IniRead($koboini, $ID, "description", "")
							$image = IniRead($koboini, $ID, "image", "")
							$releasedate = IniRead($koboini, $ID, "releasedate", "")
						Else
							$title = IniRead($catfle, $ID, "title", "")
							$author = IniRead($catfle, $ID, "author", "")
							$price = IniRead($catfle, $ID, "kobo_price", "")
							$prior = IniRead($catfle, $ID, "kobo_prior", "")
							$start = IniRead($catfle, $ID, "kobo_start", "")
							$prices = IniRead($catfle, $ID, "kobo_prices", "")
						EndIf
						$detail = "Title = " & $title & @LF & _
							"Author = " & $author & @LF & _
							"MOBI-ASIN = " & $ID & @LF & _
							"URL = " & $koboURL & @LF & _
							"Current Price = " & $price & @LF & _
							"Prior Price = " & $prior & @LF & _
							"Start Price = " & $start & @LF & _
							"Prices so far = " & $prices
						If $blurb = "" And $image = "" Then
							$ans = MsgBox(262209 + 256, "Ebook Detail", $detail & @LF & @LF & _
								"OK = Copy to clipboard.", 0, $SelectorGUI)
							If $ans = 1 Then ClipPut($detail)
						Else
							$detail = StringReplace($detail, "MOBI-ASIN", "ISBN")
							$detail = $detail & @LF & _
								"Series = " & $series & @LF & _
								"Release Date = " & $releasedate & @LF & _
								"Description = " & $blurb
							If $image = "" Then
								$ans = MsgBox(262209 + 256, "Ebook Detail", $detail & @LF & @LF & _
									"OK = Copy to clipboard.", 0, $SelectorGUI)
								If $ans = 1 Then ClipPut($detail)
							Else
								$imgfle = $imgfld & "\" & $ID & ".jpg"
								GUISetState(@SW_DISABLE, $SelectorGUI)
								DetailsGUI()
								GUISetState(@SW_ENABLE, $SelectorGUI)
							EndIf
						EndIf
					Else
						MsgBox(262192, "Selection Error", "Entry is incorrectly selected!", 0, $SelectorGUI)
					EndIf
				Else
					MsgBox(262192, "Selection Error", "Selected entry count is wrong!", 0, $SelectorGUI)
				EndIf
			Else
				MsgBox(262192, "Selection Error", "No entry selected!", 0, $SelectorGUI)
			EndIf
		Case $msg = $Button_check
			; Check selected ebooks
			Local $test = ""
			$cursor = MouseGetCursor()
			If GUICtrlRead($Checkbox_cancel) = $GUI_CHECKED Then
				MsgBox(262192, "Checking Error", "Cancel is selected!", 0, $SelectorGUI)
			Else
				$cancel = ""
				$ping = Ping("kobo.com", 4000)
				If $ping > 0 Or $test = 1 Then
					GUICtrlSetState($Label_overlay, $GUI_SHOW)
					EnableDisableControls($GUI_DISABLE, "check")
					$checkit = ""
					GUICtrlSetData($Label_time, "00:00:00")
					;SplashTextOn("", "Please Wait!", 200, 120, -1, -1, 33)
					GUICtrlSetBkColor($Label_wait, $COLOR_RED)
					GUICtrlSetData($Label_wait, "Please Wait!")
					GUISetCursor(15, 1, $SelectorGUI)
					GUICtrlSetState($Listview_ebooks, $GUI_FOCUS)
					For $a = 0 To $ents - 1
						If _GUICtrlListView_GetItemChecked($ListView_ebooks, $a) = True Then
							$ID = _GUICtrlListView_GetItemText($ListView_ebooks, $a, 5)
							If $checkit = "" Then
								$checkit = $ID & ":" & $a
							Else
								$checkit = $checkit & "|" & $ID & ":" & $a
							EndIf
						EndIf
					Next
					If $checkit <> "" Then
						$begin = TimerInit()
						$oIE = _IECreate("", 0, 0, 1, 0)
						If @error = 0 Then
							If $ids = "" Then $ids = "|"
							$sections = StringSplit($checkit, "|", 1)
							For $s = 1 To $sections[0]
								$section = $sections[$s]
								$ID = StringSplit($section, ":", 1)
								$ind = $ID[2]
								$ID = $ID[1]
								$koboURL = IniRead($catfle, $ID, "kobo_url", "")
								If $koboURL = "" Then
									$koboURL = IniRead($koboini, $ID, "kobo_url", "")
									If $koboURL <> "" Then $ebookfle = $koboini
								Else
									$ebookfle = $catfle
								EndIf
								If $koboURL <> "" Then
									$title = IniRead($ebookfle, $ID, "title", "")
									IniWrite($inifle, "Kobo Check", "last", $title)
									$author = IniRead($ebookfle, $ID, "author", "")
									$entry = $title & " - " & $author
									$commence = TimerInit()
									_FileCreate($kobofle)
									GUICtrlSetState($Label_overlay, $GUI_HIDE)
									_GUICtrlListView_SetItemSelected($ListView_ebooks, $ind, True, True)
									_GUICtrlListView_EnsureVisible($ListView_ebooks, $ind, False)
									_GUICtrlListView_ClickItem($Listview_ebooks, $ind, "left", False, 1, 1)
									If $title <> "" Then
										$title = ""
										GUICtrlSetData($Input_title, $title)
										$author = ""
										GUICtrlSetData($Input_author, $author)
									EndIf
									GUICtrlSetData($Label_price, "")
									$checker = $checker + 1
									GUICtrlSetState($Label_overlay, $GUI_SHOW)
									;$oIE = _IECreate($koboURL, 0, 0, 1, 0)
									_IENavigate($oIE, $koboURL, 1)
									$err = @error
									If $err = 0 Then
										$html = _IEDocReadHTML($oIE)
										;_FileWriteToLine($kobofle, 1, $html, 1)
										FileWrite($kobofle, $html)
									Else
										$html = ""
									EndIf
									;_IEQuit($oIE)
									$diff = TimerDiff($begin)
									_TicksToTime($diff, $hours, $mins, $secs)
									$time = StringRight("0" & $hours, 2) & ":" & StringRight("0" & $mins, 2) & ":" & StringRight("0" & $secs, 2)
									GUICtrlSetData($Label_time, $time)
									$diff = TimerDiff($commence)
									$taken = Ceiling($diff / 1000) & " secs"
									GUICtrlSetBkColor($Label_wait, $COLOR_YELLOW)
									GUICtrlSetData($Label_wait, "Selected Done!")
									If $html <> "" Then
										$cost = StringSplit($html, '<span class="price">', 1)
										If $cost[0] > 1 Then
											If StringInStr($cost[2], 'class="active-price">Your price') > 0 Then
												$cost = $cost[3]
											Else
												$cost = $cost[2]
											EndIf
											$cost = StringSplit($cost, '</span>', 1)
											$cost = $cost[1]
											$cost = StringStripWS($cost, 8)
											$check = StringReplace($cost, "$", "")
											;$check = StringReplace($check, $csign, "")
											$check = StringReplace($check, ".", "")
											If StringIsDigit($check) = 0 Then $cost = ""
										Else
											$cost = ""
										EndIf
										_FileWriteLog($logfle, "(" & $cost & ") " & $entry, 1)
										GUICtrlSetState($Label_overlay, $GUI_HIDE)
										GUICtrlSetData($Label_price, $cost)
										If $cost <> "" Then
											;MsgBox(262192, "Extract Result", "Price = " & $cost & @LF & @LF & $taken, 3)
											$price = IniRead($ebookfle, $ID, "kobo_price", "")
											$prior = IniRead($ebookfle, $ID, "kobo_prior", "")
											If $price <> $cost Then
												GUICtrlSetBkColor($lowid + $ind, $COLOR_YELLOW)
												If $price <> $prior Then
													$prior = $price
													IniWrite($ebookfle, $ID, "kobo_prior", $prior)
													_GUICtrlListView_SetItemText($ListView_ebooks, $ind, $prior & "x", 3)
												Else
													_GUICtrlListView_SetItemText($ListView_ebooks, $ind, $prior & "x", 3)
												EndIf
												$price = $cost
												IniWrite($ebookfle, $ID, "kobo_price", $price)
												$vip = IniRead($ebookfle, $ID, "vip", "")
												If $vip = 1 Then
													$cost = StringTrimLeft($price, 1)
													$check = (10 * $cost) / 100
													$check = $cost - $check
													$check = Round($check, 2)
													If StringInStr($check, ".") < 1 Then
														$check = $check & ".00"
													Else
														$cost = StringSplit($check, ".")
														If StringLen($cost[$cost[0]]) = 1 Then
															$check = $check & "0"
														EndIf
													EndIf
													$cost = $price
													$price = StringLeft($price, 1) & $check
												EndIf
												_GUICtrlListView_SetItemText($ListView_ebooks, $ind, $price & "*", 4)
												$ids = $ids & $ID & "*|"
												$price = $cost
											Else
												_GUICtrlListView_SetItemText($ListView_ebooks, $ind, $prior & "x", 3)
												$ids = $ids & $ID & "|"
											EndIf
											$start = IniRead($ebookfle, $ID, "kobo_start", "")
											If $start = "" Then
												If $prior = "" Then
													$start = $price
												Else
													$start = $prior
												EndIf
												IniWrite($ebookfle, $ID, "kobo_start", $start)
											EndIf
											$prices = IniRead($ebookfle, $ID, "kobo_prices", "")
											If $prices = "" Then
												If $prior = "" Then
													$prices = "|" & $price & "|"
												Else
													$prices = "|" & $prior & "|" & $price & "|"
												EndIf
												IniWrite($ebookfle, $ID, "kobo_prices", $prices)
											Else
												If StringInStr($prices, "|" & $price & "|") < 1 Then
													$prices = $prices & $price & "|"
													IniWrite($ebookfle, $ID, "kobo_prices", $prices)
												EndIf
											EndIf
										Else
											GUICtrlSetBkColor($lowid + $ind, 0xFF8000)
											_GUICtrlListView_SetItemText($ListView_ebooks, $ind, "", 4)
											MsgBox(262192, "Extract Error", "Price check failed." & @LF & @LF & $taken, 2)
										EndIf
										GUICtrlSetState($Label_overlay, $GUI_SHOW)
									Else
										GUICtrlSetState($Label_overlay, $GUI_HIDE)
										_GUICtrlListView_SetItemText($ListView_ebooks, $ind, "fail", 4)
										GUICtrlSetState($Label_overlay, $GUI_SHOW)
										MsgBox(262192, "Retrieval Error", "Downloading URL source failed." & @LF & @LF & $taken, 2)
									EndIf
								Else
									MsgBox(262192, "URL Missing", "Provide a Kobo ebook page URL.", 2)
								EndIf
								If $s <> $sections[0] Then
									If GUICtrlRead($Checkbox_cancel) = $GUI_CHECKED Then
										$ans = MsgBox(262209 + 256, "Cancel Query", "Do you want to cancel remaining checks?", 0, $SelectorGUI)
										If $ans = 1 Then
											$cancel = 1
											ExitLoop
										EndIf
									EndIf
									Sleep(500)
									GUICtrlSetBkColor($Label_wait, $COLOR_RED)
									GUICtrlSetData($Label_wait, "Please Wait!")
								EndIf
							Next
							_IEQuit($oIE)
							;SplashOff()
							GUICtrlSetBkColor($Label_wait, $COLOR_LIME)
							GUICtrlSetData($Label_wait, "ALL Finished!")
							GUISetCursor($cursor, 1, $SelectorGUI)
							If $cancel = "" Then
								$shutdown = GUICtrlRead($Combo_shutdown)
								If $shutdown <> "none" Then
									Local $code
									$ans = MsgBox(262193, "Shutdown Query", _
										"PC is set to shutdown in 99 seconds." & @LF & @LF & _
										"OK = Shutdown." & @LF & _
										"CANCEL = Abort shutdown.", 99, $SelectorGUI)
									If $ans = 1 Or $ans = -1 Then
										If $shutdown = "Shutdown" Then
											; Shutdown
											$code = 1 + 4 + 16
										ElseIf $shutdown = "Hibernate" Then
											; Hibernate
											$code = 64
										ElseIf $shutdown = "Standby" Then
											; Standby
											$code = 32
										ElseIf $shutdown = "Powerdown" Then
											; Powerdown
											$code = 8 + 4 + 16
										ElseIf $shutdown = "Logoff" Then
											; Logoff
											$code = 0 + 4 + 16
										ElseIf $shutdown = "Reboot" Then
											; Reboot
											$code = 2 + 4 + 16
										EndIf
										Shutdown($code)
										Exit
									EndIf
								EndIf
							EndIf
						Else
							MsgBox(262192, "Program Error", "Could not create a browser object!", 0, $SelectorGUI)
						EndIf
					Else
						MsgBox(262192, "Program Error", "Nothing to check!", 0, $SelectorGUI)
					EndIf
					GUICtrlSetState($Label_overlay, $GUI_HIDE)
					EnableDisableControls($GUI_ENABLE, "check")
					_GUICtrlListView_SetItemSelected($ListView_ebooks, -1, True, False)
				Else
					MsgBox(262192, "Web Error", "No connection detected!", 0, $SelectorGUI)
				EndIf
			EndIf
		Case $msg = $Button_add
			; ADD a Kobo ebook to the list
			$koboURL = ClipGet()
			If StringLeft($koboURL, 4) <> "http" Then $koboURL = ""
			$koboURL = InputBox("ADD An Ebook To The List", "Enter the Kobo store web page URL for the Kobo ebook.", $koboURL, "", 500, 130, Default, Default, 0, $SelectorGUI)
			If $koboURL <> "" Then
				If StringLeft($koboURL, 4) = "http" Then
					EnableDisableControls($GUI_DISABLE, "check")
					GUICtrlSetBkColor($Label_wait, $COLOR_RED)
					GUICtrlSetData($Label_wait, "Please Wait!")
					GUICtrlSetData($Input_title, "")
					GUICtrlSetData($Input_author, "")
					_GUICtrlListView_SetItemSelected($ListView_ebooks, -1, False, False)
					$ping = Ping("kobo.com", 4000)
					If $ping > 0 Or $test = 1 Then
						$oIE = _IECreate("", 0, 0, 1, 0)
						If @error = 0 Then
							_IENavigate($oIE, $koboURL, 1)
							$err = @error
							If $err = 0 Then
								$html = _IEDocReadHTML($oIE)
								FileWrite($kobofle, $html)
								If $html <> "" Then
									$ID = StringSplit($html, '"isbn":', 1)
									If $ID[0] > 1 Then
										$ID = $ID[2]
									Else
										$ID = StringSplit($html, '"sku":', 1)
										If $ID[0] > 1 Then
											$ID = $ID[2]
										Else
											$ID = ""
										EndIf
									EndIf
									$author = ""
									$title = ""
									$blurb = ""
									$price = ""
									$replace = ""
									$skip = ""
									If $ID <> "" Then
										$ID = StringSplit($ID, '"', 1)
										If $ID[0] > 1 Then
											$ID = $ID[2]
											$ID = StringSplit($ID, '",', 1)
											$ID = $ID[1]
											If StringIsDigit($ID) Then
												If IniRead($koboini, $ID, "isbn", "") = $ID Then
													$ans = MsgBox(262177 + 256, "Replace Query", "This ebook entry already exists." & @LF & @LF & _
														"OK = Replace (Overwrite) the existing entry.", 0, $SelectorGUI)
													If $ans = 1 Then
														$replace = 1
													Else
														$skip = 1
													EndIf
												EndIf
												If $skip = "" Then
													IniWrite($koboini, $ID, "isbn", $ID)
													IniWrite($koboini, $ID, "kobo_url", $koboURL)
													$author = StringSplit($html, '"author":"', 1)
													If $author[0] > 1 Then
														$author = $author[2]
														$author = StringSplit($author, '"', 1)
														$author = $author[1]
													Else
														$author = StringSplit($html, '"book-author"', 1)
														If $author[0] > 1 Then
															$author = $author[2]
															$author = StringSplit($author, '</span>', 1)
															$author = $author[1]
															$author = StringSplit($author, '>', 1)
															$author = $author[$author[0]]
														Else
															$author = ""
														EndIf
													EndIf
													If $author <> "" Then
														IniWrite($koboini, $ID, "author", $author)
														$title = StringSplit($html, '"@type": "Product",', 1)
														If $title[0] > 1 Then
															$title = $title[2]
															$title = StringSplit($title, '"name":', 1)
															If $title[0] > 1 Then
																$title = $title[2]
																$title = StringSplit($title, '",', 1)
																$title = $title[1]
																$title = StringSplit($title, '"', 1)
																If $title[0] > 1 Then
																	$title = $title[2]
																Else
																	$title = ""
																EndIf
															Else
																$title = ""
															EndIf
														Else
															$title = ""
														EndIf
														If $title = "" Then
															$title = StringSplit($html, 'sub-section-title item-title', 1)
															If $title[0] > 1 Then
																$title = $title[2]
																$title = StringSplit($title, '<', 1)
																$title = $title[1]
																$title = StringSplit($title, '>', 1)
																If $title[0] > 1 Then
																	$title = $title[2]
																Else
																	$title = ""
																EndIf
															Else
																$title = ""
															EndIf
														EndIf
														If $title <> "" Then
															IniWrite($koboini, $ID, "title", $title)
															GUICtrlSetData($Input_title, $title)
															GUICtrlSetData($Input_author, $author)
															$series = StringSplit($html, '"book-series"', 1)
															If $series[0] > 1 Then
																$series = $series[2]
																$series = StringSplit($series, '<', 1)
																$series = $series[1]
																$series = StringSplit($series, '>', 1)
																If $series[0] > 1 Then
																	$series = $series[2]
																Else
																	$series = ""
																EndIf
															Else
																$series = ""
															EndIf
															If $series <> "" Then
																IniWrite($koboini, $ID, "series", $series)
															EndIf
															$blurb = StringSplit($html, '"description": "', 1)
															If $blurb[0] > 1 Then
																$blurb = $blurb[2]
																$blurb = StringSplit($blurb, '",', 1)
																$blurb = $blurb[1]
															Else
																$blurb = ""
															EndIf
															If $blurb <> "" Then
																IniWrite($koboini, $ID, "description", $blurb)
															EndIf
															$image = StringSplit($html, '"image": "', 1)
															If $image[0] > 1 Then
																$image = $image[2]
																$image = StringSplit($image, '",', 1)
																$image = $image[1]
																$image = StringReplace($image, "/180/1000/", "/353/569/90/")
																If Not FileExists($imgfld) Then DirCreate($imgfld)
																$imgfle = $imgfld & "\" & $ID & ".jpg"
																InetGet($image, $imgfle, 1, 0)
																;https://kbimages1-a.akamaihd.net/afd62c50-18aa-4436-a42d-8c3dbe77062d/180/1000/False/the-irish-end-games-books-1-12.jpg
																;https://kbimages1-a.akamaihd.net/afd62c50-18aa-4436-a42d-8c3dbe77062d/353/569/90/False/the-irish-end-games-books-1-12.jpg
																If Not FileExists($imgfle) Then
																	$image = StringReplace($image, "/353/569/90/", "/180/1000/")
																	InetGet($image, $imgfle, 1, 0)
																EndIf
															Else
																$image = ""
															EndIf
															If $image <> "" Then
																IniWrite($koboini, $ID, "image", $image)
															EndIf
															$releasedate = StringSplit($html, '"releasedate": "', 1)
															If $releasedate[0] > 1 Then
																$releasedate = $releasedate[2]
																$releasedate = StringSplit($releasedate, '",', 1)
																$releasedate = $releasedate[1]
																$releasedate = StringLeft($releasedate, 10)
															Else
																$releasedate = ""
															EndIf
															If $releasedate <> "" Then
																IniWrite($koboini, $ID, "releasedate", $releasedate)
															EndIf
															$cost = StringSplit($html, '<span class="price">', 1)
															If $cost[0] > 1 Then
																$cost = $cost[2]
																$cost = StringSplit($cost, '</span>', 1)
																$cost = $cost[1]
																$cost = StringStripWS($cost, 8)
																$check = StringReplace($cost, "$", "")
																;$check = StringReplace($check, $csign, "")
																$check = StringReplace($check, ".", "")
																If StringIsDigit($check) = 0 Then $cost = ""
															Else
																$cost = ""
															EndIf
															$price = $cost
															IniWrite($koboini, $ID, "kobo_price", $price)
															$prior = ""
															IniWrite($koboini, $ID, "kobo_prior", $prior)
															If $cost <> "" Then
																$start = $price
																IniWrite($koboini, $ID, "kobo_start", $start)
																$prices = "|" & $price & "|"
																IniWrite($koboini, $ID, "kobo_prices", $prices)
															EndIf
															If $replace = 1 Then
																$ind = _GUICtrlListView_FindInText($ListView_ebooks, $ID, -1, False, False)
															Else
																$num = $num + 1
																$numb = StringRight("000" & $num, 4)
																$entry = $numb & "|" & $title & "|" & $author & "|" & $prior & "|" & $price & "|" & $ID
																;MsgBox(262208, "Entry Information", $entry, 0, $SelectorGUI)
																$idx = GUICtrlCreateListViewItem($entry, $ListView_ebooks)
																If IsInt($idx / 2) = 1 Then GUICtrlSetBkColor($idx, 0xC0F0C0)
																;$ents = _GUICtrlListView_GetItemCount($ListView_ebooks)
																$ents = $num
																GUICtrlSetData($Group_ebooks, "Ebooks To Check (" & $ents & ")")
																$ind = $idx - $lowid
															EndIf
															_GUICtrlListView_SetItemSelected($ListView_ebooks, $ind, True, True)
															_GUICtrlListView_EnsureVisible($ListView_ebooks, $ind, False)
															_GUICtrlListView_ClickItem($Listview_ebooks, $ind, "left", False, 1, 1)
														EndIf
													Else
														;
													EndIf
												Else
													$ind = _GUICtrlListView_FindInText($ListView_ebooks, $ID, -1, False, False)
													_GUICtrlListView_SetItemSelected($ListView_ebooks, $ind, True, True)
													_GUICtrlListView_EnsureVisible($ListView_ebooks, $ind, False)
													_GUICtrlListView_ClickItem($Listview_ebooks, $ind, "left", False, 1, 1)
												EndIf
											Else
												$ID = ""
											EndIf
										Else
											$ID = ""
										EndIf
									EndIf
									If $skip = "" Then
										If $ID = "" Then
											MsgBox(262192, "ADD Error", "ID (ISBN) detection failed!", 0, $SelectorGUI)
										ElseIf $author = "" Then
											MsgBox(262192, "ADD Error", "Author Name detection failed!", 0, $SelectorGUI)
										ElseIf $title = "" Then
											MsgBox(262192, "ADD Error", "Ebook Title detection failed!", 0, $SelectorGUI)
										ElseIf $price = "" Then
											MsgBox(262192, "Retrieve Error", "Price detection failed!", 0, $SelectorGUI)
										ElseIf $blurb = "" Then
											MsgBox(262192, "Retrieve Error", "Ebook description detection failed!", 0, $SelectorGUI)
										EndIf
									EndIf
								EndIf
							Else
								$html = ""
							EndIf
							If $html = "" Then
								MsgBox(262192, "Fetch Error", "Ebook web page could not be downloaded!", 0, $SelectorGUI)
							EndIf
						Else
							MsgBox(262192, "Program Error", "Could not create a browser object!", 0, $SelectorGUI)
						EndIf
						_IEQuit($oIE)
					Else
						MsgBox(262192, "Web Error", "No connection detected!", 0, $SelectorGUI)
					EndIf
					GUICtrlSetBkColor($Label_wait, $COLOR_LIME)
					GUICtrlSetData($Label_wait, "Finished!")
					EnableDisableControls($GUI_ENABLE, "check")
				Else
					MsgBox(262192, "ADD Error", "Not a URL!", 0, $SelectorGUI)
				EndIf
			Else
				If @error = 0 then MsgBox(262192, "ADD Error", "Nothing to add!", 0, $SelectorGUI)
			EndIf
		Case $msg = $Combo_select
			$select = GUICtrlRead($Combo_select)
			If $select <> "" Then
				If GUICtrlRead($Radio_selall) = $GUI_CHECKED Then
					GUICtrlSetState($Radio_selall, $GUI_UNCHECKED)
				ElseIf GUICtrlRead($Radio_none) = $GUI_CHECKED Then
					GUICtrlSetState($Radio_none, $GUI_UNCHECKED)
				EndIf
				If $select = "Half" Then
					_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
					If $ents > 1 Then
						EnableDisableControls($GUI_DISABLE, "")
						;_GUICtrlListView_SetItemChecked($ListView_ebooks, 0, True)
						$half = Floor($ents / 2)
						If $set <> "first" Then
							$set = "first"
							$first = 0
							$last = $half - 1
						ElseIf $set = "first" Then
							$set = "second"
							$first = $half
							$last = $ents - 1
						EndIf
						$checked = 0
						For $a = $first To $last
							_GUICtrlListView_SetItemChecked($ListView_ebooks, $a, True)
							$checked = $checked + 1
						Next
						EnableDisableControls($GUI_ENABLE, "")
					ElseIf $ents = 1 Then
						_GUICtrlListView_SetItemChecked($ListView_ebooks, 0, True)
					EndIf
				ElseIf $select = "10" Then
					If $set = "second" Then $set = ""
					If $set = "" Then _GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
					If $ents > 1 Then
						EnableDisableControls($GUI_DISABLE, "")
						For $a = 0 To $ents - 1
							If _GUICtrlListView_GetItemChecked($ListView_ebooks, $a) = True Then
								_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
								If $set = "10" Then
									$a = $a + 10
								ElseIf $set = "20" Then
									$a = $a + 20
								ElseIf $set = "first" Then
									$a = $a + $half
								EndIf
								ExitLoop
							EndIf
						Next
						If $a > $ents - 1 Then $a = 0
						$first = $a
						$last = $a + 9
						;MsgBox(262192, "$first $last", $first & " - " & $last, 0, $SelectorGUI)
						$checked = 0
						For $b = $first To $last
							If $b > $ents - 1 Then ExitLoop
							_GUICtrlListView_SetItemChecked($ListView_ebooks, $b, True)
							$checked = $checked + 1
						Next
						EnableDisableControls($GUI_ENABLE, "")
					ElseIf $ents = 1 Then
						_GUICtrlListView_SetItemChecked($ListView_ebooks, 0, True)
					EndIf
					$set = "10"
				ElseIf $select = "20" Then
					If $set = "second" Then $set = ""
					If $set = "" Then _GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
					If $ents > 1 Then
						EnableDisableControls($GUI_DISABLE, "")
						For $a = 0 To $ents - 1
							If _GUICtrlListView_GetItemChecked($ListView_ebooks, $a) = True Then
								_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
								If $set = "10" Then
									$a = $a + 10
								ElseIf $set = "20" Then
									$a = $a + 20
								ElseIf $set = "first" Then
									$a = $a + $half
								EndIf
								ExitLoop
							EndIf
						Next
						If $a > $ents - 1 Then $a = 0
						$first = $a
						$last = $a + 19
						;MsgBox(262192, "$first $last", $first & " - " & $last, 0, $SelectorGUI)
						$checked = 0
						For $b = $first To $last
							If $b > $ents - 1 Then ExitLoop
							_GUICtrlListView_SetItemChecked($ListView_ebooks, $b, True)
							$checked = $checked + 1
						Next
						EnableDisableControls($GUI_ENABLE, "")
					ElseIf $ents = 1 Then
						_GUICtrlListView_SetItemChecked($ListView_ebooks, 0, True)
					EndIf
					$set = "20"
				ElseIf $select = "Favs" Then
					_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
					If $set <> "" Then $set = ""
					If $ents > 1 Then
						EnableDisableControls($GUI_DISABLE, "")
						$favorites = IniRead($inifle, "Favorites", "ids", "")
						If $favorites <> "" Then
							$checked = 0
							For $a = 0 To $ents - 1
								$ID = _GUICtrlListView_GetItemText($ListView_ebooks, $a, 5)
								If StringInStr($favorites, "|" & $ID & "|") > 0 Then
									_GUICtrlListView_SetItemChecked($ListView_ebooks, $a, True)
									$checked = $checked + 1
								EndIf
							Next
						EndIf
						EnableDisableControls($GUI_ENABLE, "")
					EndIf
				ElseIf $select = "Rest" Then
					_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
					If $set <> "" Then $set = ""
					If $ents > 1 Then
						EnableDisableControls($GUI_DISABLE, "")
						$checked = 0
						For $a = 0 To $ents - 1
							$prior = _GUICtrlListView_GetItemText($ListView_ebooks, $a, 3)
							If StringInStr($prior, "x") < 1 Then
								_GUICtrlListView_SetItemChecked($ListView_ebooks, $a, True)
								$checked = $checked + 1
							EndIf
						Next
						EnableDisableControls($GUI_ENABLE, "")
					EndIf
				EndIf
				If $ents > 0 Then
					GUICtrlSetData($Group_ebooks, "Ebooks To Check (" & $ents & ")  Selected  (" & $checked & ")")
				Else
					GUICtrlSetData($Group_ebooks, "Ebooks To Check")
				EndIf
			EndIf
		Case $msg = $ListView_ebooks Or $msg > $Button_quit
			; Ebooks To Check
			If $checker < 2 Then
				If $checker = 1 Then $checker = 0
				$checked = 0
				For $a = 0 To $ents - 1
					If _GUICtrlListView_GetItemChecked($ListView_ebooks, $a) = True Then
						$checked = $checked + 1
					EndIf
				Next
				If $checked = 0 Then
					If $ents > 0 Then
						GUICtrlSetData($Group_ebooks, "Ebooks To Check (" & $ents & ")")
					Else
						GUICtrlSetData($Group_ebooks, "Ebooks To Check")
					EndIf
				Else
					GUICtrlSetData($Group_ebooks, "Ebooks To Check (" & $ents & ")  Selected  (" & $checked & ")")
				EndIf
				$ind = _GUICtrlListView_GetSelectedIndices($ListView_ebooks, True)
				If IsArray($ind) Then
					If $ind[0] > 0 Then
						$ind = $ind[1]
						If $ind > -1 Then
							$title = _GUICtrlListView_GetItemText($ListView_ebooks, $ind, 1)
							GUICtrlSetData($Input_title, $title)
							$author = _GUICtrlListView_GetItemText($ListView_ebooks, $ind, 2)
							GUICtrlSetData($Input_author, $author)
							;GUICtrlSetBkColor($Button_quit + $ind + 1, $COLOR_RED)
						Else
							$title = ""
							GUICtrlSetData($Input_title, $title)
							$author = ""
							GUICtrlSetData($Input_author, $author)
						EndIf
					EndIf
				EndIf
			Else
				$checker = $checker - 1
			EndIf
		Case $msg = $Radio_selall
			; Select ALL ebook entries
			_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, True)
			$set = ""
			If $select <> "" Then GUICtrlSetData($Combo_select, "||Half|10|20|Favs|Rest", "")
			If $ents > 0 Then
				GUICtrlSetData($Group_ebooks, "Ebooks To Check (" & $ents & ")  Selected  (" & $ents & ")")
			Else
				GUICtrlSetData($Group_ebooks, "Ebooks To Check")
			EndIf
		Case $msg = $Radio_none
			; Deselect ALL ebooks
			_GUICtrlListView_SetItemChecked($ListView_ebooks, -1, False)
			$set = ""
			If $select <> "" Then GUICtrlSetData($Combo_select, "||Half|10|20|Favs|Rest", "")
			If $ents > 0 Then
				GUICtrlSetData($Group_ebooks, "Ebooks To Check (" & $ents & ")")
			Else
				GUICtrlSetData($Group_ebooks, "Ebooks To Check")
			EndIf
			GUICtrlSetState($Radio_none, $GUI_UNCHECKED)
			;GUICtrlSetState($Radio_selall, $GUI_UNCHECKED)
		Case Else
			;;;
		EndSelect
	WEnd
EndFunc ;=> FileSelectorGUI

Func DetailsGUI()
	Local $Edit_detail, $Group_detail, $Group_image, $Pic_image
	Local $DetailGUI, $details
	;
	$DetailGUI = GuiCreate("Selected Kobo Ebook Detail", 350, 600, Default, Default, $WS_OVERLAPPED + $WS_CAPTION + $WS_SYSMENU + $WS_VISIBLE, $WS_EX_TOPMOST, $SelectorGUI)
	; CONTROLS
	$Group_image = GuiCtrlCreateGroup("", 10, 10, 330, 410) ;Kobo Cover
	$Pic_image = GUICtrlCreatePic($imgfle, 20, 25, 310, 385)
	;
	$Group_detail = GuiCtrlCreateGroup("", 10, 430, 330, 160)
	$Edit_detail = GUICtrlCreateEdit("", 20, 445, 310, 135, $ES_WANTRETURN + $WS_VSCROLL + $ES_AUTOVSCROLL + $ES_MULTILINE)
	;
	; SETTINGS
	$details = StringReplace($detail, @LF, @CRLF)
	GUICtrlSetData($Edit_detail, $details)

	GuiSetState()
	While 1
		$msg = GuiGetMsg()
		Select
		Case $msg = $GUI_EVENT_CLOSE
			; Exit / Close / Quit the window
			GUIDelete($DetailGUI)
			ExitLoop
		Case Else
			;;;
		EndSelect
	WEnd
EndFunc ;=> DetailsGUI


Func EnableDisableControls($state, $checking)
	GUICtrlSetState($Button_reload, $state)
	GUICtrlSetState($Button_vip, $state)
	GUICtrlSetState($Radio_selall, $state)
	GUICtrlSetState($Radio_none, $state)
	GUICtrlSetState($Combo_select, $state)
	GUICtrlSetState($Button_detail, $state)
	GUICtrlSetState($Button_add, $state)
	GUICtrlSetState($Button_rem, $state)
	GUICtrlSetState($Button_web, $state)
	If $checking = "" Then
		GUICtrlSetState($Combo_shutdown, $state)
		GUICtrlSetState($Checkbox_cancel, $state)
	EndIf
	If $status = "" Then GUICtrlSetState($Button_check, $state)
	GUICtrlSetState($Button_favs, $state)
	GUICtrlSetState($Button_info, $state)
	GUICtrlSetState($Button_quit, $state)
EndFunc ;=> EnableDisableControls

Func LoadTheList($load)
	;$pinged = ""
	If $ids = "|" Then $ids = ""
	$num = 0
	$user = IniRead($inifle, "User", "name", "")
	If $user = "" Then
		$entries = ""
	Else
		GUICtrlSetData($Label_user, '"' & $user & '"')
		SplashTextOn("", "Please Wait!" & @LF & @LF & "(Loading List)", 180, 130, Default, Default, 33)
		$catfle = @ScriptDir & "\" & $user & ".ini"
		$cnt = _FileCountLines($catfle)
		If $cnt > 0 Then
			$entries = FileRead($catfle)
			$sections = StringSplit($entries, "[", 1)
			For $s = 1 To $sections[0]
				$section = $sections[$s]
				If StringInStr($section, "kobo_url=") > 0 Then
					$lines = StringSplit($section, @CRLF, 1)
					$line = $lines[1]
					If StringRight($line, 1) = "]" Then
						$ID = StringTrimRight($line, 1)
						$title = IniRead($catfle, $ID, "title", "")
						$author = IniRead($catfle, $ID, "author", "")
						$url = IniRead($catfle, $ID, "kobo_url", "")
						$price = IniRead($catfle, $ID, "kobo_price", "")
						$vip = IniRead($catfle, $ID, "vip", "")
						If $vip = 1 Then
							$cost = StringTrimLeft($price, 1)
							$check = (10 * $cost) / 100
							$check = $cost - $check
							$check = Round($check, 2)
							If StringInStr($check, ".") < 1 Then
								$check = $check & ".00"
							Else
								$cost = StringSplit($check, ".")
								If StringLen($cost[$cost[0]]) = 1 Then
									$check = $check & "0"
								EndIf
							EndIf
							$price = StringLeft($price, 1) & $check
						EndIf
						$prior = IniRead($catfle, $ID, "kobo_prior", "")
						If $ids <> "" Then
							If StringInStr($ids, "|" & $ID & "|") > 0 Then
								$prior = $prior & "x"
							ElseIf StringInStr($ids, "|" & $ID & "*|") > 0 Then
								$price = $price & "*"
								$prior = $prior & "x"
							EndIf
						EndIf
						$num = $num + 1
						$numb = StringRight("000" & $num, 4)
						$entry = $numb & "|" & $title & "|" & $author & "|" & $prior & "|" & $price & "|" & $ID
						;MsgBox(262208, "Entry Information", $entry, 0, $SelectorGUI)
						$idx = GUICtrlCreateListViewItem($entry, $ListView_ebooks)
						If StringRight($price, 1) = "*" Then
							GUICtrlSetBkColor($idx, $COLOR_YELLOW)
						Else
							If IsInt($idx / 2) = 1 Then GUICtrlSetBkColor($idx, 0xC0F0C0)
						EndIf
						;GUICtrlSetBkColor($idx, $color)
						If $vip = 1 Then GUICtrlSetColor($idx, $COLOR_MAROON)
					EndIf
				EndIf
			Next
		Else
			$entries = ""
		EndIf
		$cnt = _FileCountLines($koboini)
		If $cnt > 0 Then
			$entries = FileRead($koboini)
			$sections = StringSplit($entries, "[", 1)
			For $s = 1 To $sections[0]
				$section = $sections[$s]
				If StringInStr($section, "kobo_url=") > 0 Then
					$lines = StringSplit($section, @CRLF, 1)
					$line = $lines[1]
					If StringRight($line, 1) = "]" Then
						$ID = StringTrimRight($line, 1)
						$title = IniRead($koboini, $ID, "title", "")
						$author = IniRead($koboini, $ID, "author", "")
						$url = IniRead($koboini, $ID, "kobo_url", "")
						$price = IniRead($koboini, $ID, "kobo_price", "")
						$vip = IniRead($koboini, $ID, "vip", "")
						If $vip = 1 Then
							$cost = StringTrimLeft($price, 1)
							$check = (10 * $cost) / 100
							$check = $cost - $check
							$check = Round($check, 2)
							If StringInStr($check, ".") < 1 Then
								$check = $check & ".00"
							Else
								$cost = StringSplit($check, ".")
								If StringLen($cost[$cost[0]]) = 1 Then
									$check = $check & "0"
								EndIf
							EndIf
							$price = StringLeft($price, 1) & $check
						EndIf
						$prior = IniRead($koboini, $ID, "kobo_prior", "")
						If $ids <> "" Then
							If StringInStr($ids, "|" & $ID & "|") > 0 Then
								$prior = $prior & "x"
							ElseIf StringInStr($ids, "|" & $ID & "*|") > 0 Then
								$price = $price & "*"
							EndIf
						EndIf
						$num = $num + 1
						$numb = StringRight("000" & $num, 4)
						$entry = $numb & "|" & $title & "|" & $author & "|" & $prior & "|" & $price & "|" & $ID
						;MsgBox(262208, "Entry Information", $entry, 0, $SelectorGUI)
						$idx = GUICtrlCreateListViewItem($entry, $ListView_ebooks)
						If StringRight($price, 1) = "*" Then
							GUICtrlSetBkColor($idx, $COLOR_YELLOW)
						Else
							If IsInt($idx / 2) = 1 Then GUICtrlSetBkColor($idx, 0xC0F0C0)
						EndIf
						;GUICtrlSetBkColor($idx, $color)
						If $vip = 1 Then GUICtrlSetColor($idx, $COLOR_MAROON)
					EndIf
				EndIf
			Next
		EndIf
		SplashOff()
	EndIf
	;
	_GUICtrlListView_JustifyColumn($ListView_ebooks, 0, 0)
	_GUICtrlListView_JustifyColumn($ListView_ebooks, 1, 0)
	_GUICtrlListView_JustifyColumn($ListView_ebooks, 2, 0)
	_GUICtrlListView_JustifyColumn($ListView_ebooks, 3, 2)
	_GUICtrlListView_JustifyColumn($ListView_ebooks, 4, 2)
	_GUICtrlListView_JustifyColumn($ListView_ebooks, 5, 0)
	_GUICtrlListView_SetColumnWidth($ListView_ebooks, 0, 55)
	_GUICtrlListView_SetColumnWidth($ListView_ebooks, 1, 320)
	_GUICtrlListView_SetColumnWidth($ListView_ebooks, 2, 210)
	_GUICtrlListView_SetColumnWidth($ListView_ebooks, 3, 60)
	_GUICtrlListView_SetColumnWidth($ListView_ebooks, 4, 60)
	_GUICtrlListView_SetColumnWidth($ListView_ebooks, 5, 99)
	;$LVSCW_AUTOSIZE_USEHEADER
	If $entries = "" Then
		$ents = 0
		GUICtrlSetData($Group_ebooks, "Ebooks To Check")
	Else
		$ents = _GUICtrlListView_GetItemCount($ListView_ebooks)
		GUICtrlSetData($Group_ebooks, "Ebooks To Check (" & $ents & ")")
	EndIf
	If $user = "Bought" Or $user = "Paid" Or StringRight($user, 3) = "(b)" Then
		If $load = "load" Then
			GUICtrlSetState($Button_check, $GUI_DISABLE)
		ElseIf $load = "reload" Then
			If $status = "" Then
				GUICtrlSetState($Button_check, $GUI_DISABLE)
			EndIf
		EndIf
		$status = $load
	ElseIf $status <> "" Then
		GUICtrlSetState($Button_check, $GUI_ENABLE)
		$status = ""
	EndIf
EndFunc ;=> LoadTheList
