;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                                                       ;;
;;  AutoIt Version: 3.2.4.9                                                              ;;
;;                                                                                       ;;
;;  Template AutoIt script.                                                              ;;
;;                                                                                       ;;
;;  AUTHOR:  TheSaint <thsaint@ihug.com.au>                                              ;;
;;                                                                                       ;;
;;  SCRIPT FUNCTION:  Checks until a window exists, then sets it on top                  ;;
;;                                                                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#NoTrayIcon

Global $win

If $CmdLine[0] <> "" Then
	$win = $CmdLine[1]
	WinWaitActive($win, "", 5)
    If WinExists($win, "") Then
		;MsgBox(262160, "Exists", "Exists")
		WinSetOnTop($win, "", 1)
    EndIf
EndIf

Exit