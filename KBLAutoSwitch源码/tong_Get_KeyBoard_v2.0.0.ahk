;************************
;* 【手动检测键盘布局号码，F10获取当前输入法键盘布局号码】 *
;************************
; 可在windows右下角设置键盘布局，然后使用F10获取键盘布局号码
#Persistent             ;~让脚本持久运行
#SingleInstance,Force   ;~运行替换旧实例
;#NoTrayIcon 			;隐藏托盘图标

;手动检测键盘布局号码
F10::
	SetFormat, Integer, H
	WinGet, WinID,, A
	ThreadID:=DllCall("GetWindowThreadProcessId", "UInt", WinID, "UInt", 0)
	InputLocaleID:=DllCall("GetKeyboardLayout", "UInt", ThreadID)
	Clipboard:=InputLocaleID
	MsgBox, 键盘布局号码：%InputLocaleID%`n`n已复制到剪贴板
Return