/* tong(【自动切换输入法键盘布局_v2.0.2】)
    脚本: tong_KBLAutoSwitch
    作用: 根据设置自动切换输入法，右下角显示窗口切换后的输入法，不支持手动切换后的显示，支持默认输入法
    作者: tong
    地址: https://gitee.com/aktongliang/KBLAutoSwitch
    改动: 删了很多我不需要的代码，该脚本长时间没更新，有些地方有bug，比如alt+tab，uwp应用等，新开和创建有点重复，编辑器模式我也不需要，对一些应用场景优化，增加功能，具体见更新日志
    设置方法: 无托盘，无菜单，可以依托于RunAny使用，与tong_KBLAutoSwitch.ini文件一同复制到RunAny的RunPlugins文件夹中，RunAny设置脚本自启
			在RunAny中添加快捷添加快捷键，在对应应用窗口使用快捷键将对应应用设置为默认、中文、英文输入法
	清单：
		1.tong_KBLAutoSwitch.ahk 	【必要】		主脚本文件
		2.tong_KBLAutoSwitch.ini 	【必要】		配置文件
		3.AU3_Spy.exe 				【非必要】		可用来获取窗口的信息，部分窗口自动无法设置时可使用，进行手动配置。【建议】窗口直接使用【快捷键】【自动配置】
	使用方法：
		1.下载安装【RunAny】 https://hui-zz.gitee.io/runany/#/
		2.将【tong_KBLAutoSwitch.ahk】和【tong_KBLAutoSwitch.ini】添加至【RunAny】的【RunPlugins】文件夹，在RunAny中【开启】并设置为【自启】，右下角出现中英文提示表示成功
		3.打开RunAny.ini或RunAny2.ini文件，添加以下内容，可自定义快捷键，替换【F9】【F10】【F11】【F12】【F9】
			当前窗口添加至英文(&A)	F12|tong_KBLAutoSwitch[AddToEn]()
			当前窗口添加至中文(&S)	F11|tong_KBLAutoSwitch[AddToCn]()
			当前窗口移除(&D)			F10|tong_KBLAutoSwitch[RemoveFromAll]()
			获取当前键盘布局号码(&F)	F9|tong_KBLAutoSwitch[GetKeyBoard]()
		4.在【指定窗口】上使用3中设置的快捷键，将自动添加到相应中英文窗口
		5.英文输入法可在windows-设置-时间和语言-语言-添加英语
		6.全局手动切换需要自己在系统里面设置切换键盘布局的快捷键，默认win+空格，建议中文输入法设置取消shift切换中文输入法的中英文，避免误触
*/
;----------------------------------------------------------------------RunAny插件----------------------------------------------------------------------------

#Include *i %A_ScriptDir%\RunAny_ObjReg.ahk

;作为RunAny插件使用的图标
global RunAny_Plugins_Icon:="%A_ScriptDir%\RunIcon\IconCustom-phrase\Plugin.ico"

class RunAnyObj {
	;当前窗口添加至英文(&A)	F12|tong_KBLAutoSwitch[AddToEn]()
	AddToEn() {
		gosub, Add_To_En
		return
	}
	;当前窗口添加至中文(&S)	F11|tong_KBLAutoSwitch[AddToCn]()
	AddToCn() {
		gosub, Add_To_Cn
		return
	}
	;当前窗口移除(&D)			F10|tong_KBLAutoSwitch[RemoveFromAll]()
	RemoveFromAll() {
		gosub, Remove_From_All
		return
	}
	;获取当前键盘布局号码(&F)			F9|tong_KBLAutoSwitch[GetKeyBoard]()
	GetKeyBoard() {
		gosub, Get_KeyBoard
		return
	}
}

;------------------------------------------------------------------------------------------------------------------------------------------------------------
/*;【改编者信息】	;{
	; 脚本名称KBLAutoSwitch
	; 脚本版本号: v2.0.2
	; AHK版本: 1.1.33.09 RunAny版本: v5.7.6
	; 语言: 中文
	; 改编者: tong
	; 脚本功能: 自动切换输入法，显示切换GUI，快速设置指定程序持久中英文
	;---------------------------------------------------
	; 版本信息
	; v2.0.0: 2021年8月1日
	;	1.修复了在windows下alt+tab切换太快不生效的问题
	;	2.添加了输入法右下角提示
	;	3.增加默认输入法
	;	4.删除编辑器、窗口切换，统一新开窗口和切换窗口的切换
	;	5.去除光标、菜单
	;	6.增加更多可配置项
	;	7.均采用自动切换输入法，系统建议win+空格切换输入法
	;	8.win+空格切换键盘布局显示GUI
	;	9.解决uwp应用的键盘布局获取问题，修改xshell键盘获取，以命令行对应的键盘布局为准，每次切换自动对焦到xshell命令行
	;--------------------
    ; v2.0.1: 2021年8月
    ;	1.添加快捷添加功能，一键在在【指定窗口】上使用快捷键，将自动添加到相应窗口，并自动重启应用，【F12】添加当前窗口到【英文】，【F11】添加当前窗口到【中文】，【F10】移除当前窗口将恢复【默认输入法】，可通过配置文件【关闭】该功能
    ;	2.添加了焦点控件切换窗口，解决部分应用出现【切换显示错误】
    ;	3.取消win底部任务栏切换，保证切换显示的正确性
    ;	4.增加配置初始化，删除配置文件重启应用将自动初始化配置文件
    ;	5.添加修改ini文件自动重启功能，配置文件修改后将自动重启应用，可设置重启时间
    ;	6.优化了一些系统窗口的输入法切换规则，提升使用体验，比如任务栏的上三角不再造成输入法的切换，任务栏的变动
    ;	7.有一丢丢的速度提升
    ;--------------------
    ; v2.0.2: 2021年8月
    ;	1.修复cmd切换显示问题
    ;	2.快捷键添加可作为RunAny插件功能，可自定义原【F10】【F11】【F12】功能，原检测键盘布局号码功能也作为插件功能
    ;		1.打开RunAny.ini或RunAny2.ini文件
    ;		2.添加以下内容，可自定义快捷键，替换【F9】【F10】【F11】【F12】
    ;			当前窗口添加至英文(&A)	F12|tong_KBLAutoSwitch[AddToEn]()
	;			当前窗口添加至中文(&S)	F11|tong_KBLAutoSwitch[AddToCn]()
	;			当前窗口移除(&D)			F10|tong_KBLAutoSwitch[RemoveFromAll]()
	;			获取当前键盘布局号码(&F)	F9|tong_KBLAutoSwitch[GetKeyBoard]()
	;		3.保存RunAny.ini或RunAny2.ini文件
	;	3.修复原来右下角切换显示的颜色错误
	;---------------------------------------------------
	;---v2.0.2使用说明
	;-----切换方式
	;	切换采用【切换键盘布局方法】，需要同时安装【中文】输入法和【英文】输入法
	;-----使用建议
	; 	1.使用【RunAny】作为【插件】使用
	;	2.【中文】使用【搜狗输入法】、【手心输入法】、【小鹤音形】等第三方非微软自带中文输入法
	;	3.【英文】使用【微软自带】英文输入法键盘
	;	4.【中文】输入法取消【shift】切换英文
	;	5.使用【win+空格】切换输入法，避免误触
;}
;------------------------------------------------------------------------------------------------------------------------------------------------------------
;【上改编者信息】;{
	; 脚本名称: IME2
	; 脚本版本号: v1.04
	; AHK版本: 1.1.30
	; 语言: 中文
	; 改编者: 心如止水<QQ:2531574300>   <Autohotkey高手群(348016704)> 
	; 脚本功能: 自动切换输入法
	; ^_^: 如果您有什么新的想法，或者有什么改进意见，欢迎加我的QQ，一起探讨改进 ：^_^
	;---------------------------------------------------
	; 版本信息
	; v0.3: 在原作基础上增加了检测功能，切换更智能了
	; v1.0: 9月24日 切换方式暂改为"切换键盘布局"，切换更智能，更流畅，几乎不会出错
	; v1.01: 9月24日 默认停掉编辑器内手动切换 这个非常容易误触，还是采取全局切换的那个比较好，修复了窗口切换时切换输入法失效的问题
	; v1.02: 9月24日 在 编辑器内/全局手动时 默认停掉提示
	; v1.03: 9月24日 1.针对中文输入法英文模式的情况，进行了针对性优化(仍需要您手动检测情况，填写代号) 2.输入法切换方法支持忽略延迟
	; v1.04: 9月25日 1.修复了"中文布局+中文输入法下切换"时，"通知提示消失/忽略延迟不起作用"的问题 2.把注释放到了前面
	;---------------------------------------------------
	;---v1.0使用说明
	; 切换方法改为更稳定的"切换键盘布局方法"，还可以在其它键盘布局上放英文输入法，提高效率(v1.0)
	;-----如何设置键盘布局？
	; 	可以去百度或谷歌上搜一下，默认的大概是中文(简体)，新增加一个英文(美国)
	;-----如何使用？
	; 	切换和检测的方法，都需要特定的号码，但是这个号码是不一样的，你需要获取，然后更改
	;-----小技巧
	; 	1.英文输入法在打字的时候可以给出英文提示，有点类似于IDE的效果，很多人工作中和英语打交道比较少，偶尔用到之后，发现很多词都忘了，需要翻字典，有了英文输入	;	法这种现象就大大的改善了
	; 	2.英文输入法可以用一下Triivi，口碑还是不错的
	; 	3.检测方法以及切换思路来自 https://autohotkey.com/board/topic/18343-dllcall-loadkeyboardlayout-problem/
	; 感谢 无关风月 的帮助测试，将来还会持续更新优化
;}
;------------------------------------------------------------------------------------------------------------------------------------------------------------
;【原作者信息】	;{
	; AHK版本: 1.1.29.01
	; 语言: 中文
	; 作者: lspcieee <lspcieee@gmail.com>
	; 网站: http://www.lspcieee.com/
	; 脚本功能: 自动切换输入法
	;---------------------------------------------------
	;---关于原作者: 
	; 原作者的脚本网址和使用方法介绍 https://faxian.appinn.com/747
	; 我这个脚本改进自该作者，所以先要看原来的说明文档才可以懂
;}
*/

Start_With_Admin: ;强制以管理员身份运行，避免有些场景不生效
	full_command_line := DllCall("GetCommandLine", "str")
	if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
	{
	    try
	    {
	        if A_IsCompiled
	            Run *RunAs "%A_ScriptFullPath%" /restart
	        else
	            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
	    }
	    ExitApp
	}

Label_ScriptSetting: ;脚本前参数设置
	Process, Priority, , High						;脚本高优先级
	#MenuMaskKey vkE8
	#NoTrayIcon										;隐藏托盘图标
	#NoEnv											;不检查空变量是否为环境变量
	#Persistent										;让脚本持久运行(关闭或ExitApp)
	#SingleInstance Force							;跳过对话框并自动替换旧实例
	#WinActivateForce								;强制激活窗口
	#MaxHotkeysPerInterval 200						;时间内按热键最大次数
	#HotkeyModifierTimeout 100						;按住modifier后(不用释放后再按一次)可隐藏多个当前激活窗口
	SetBatchLines -1								;脚本全速执行
	SetControlDelay -1								;控件修改命令自动延时,-1无延时，0最小延时
	CoordMode Menu Window							;坐标相对活动窗口
	CoordMode Mouse Screen							;鼠标坐标相对于桌面(整个屏幕)
	ListLines, Off									;不显示最近执行的脚本行
	SendMode Input									;更速度和可靠方式发送键盘点击
	SetTitleMatchMode 2								;窗口标题模糊匹配;RegEx正则匹配
	DetectHiddenWindows on							;显示隐藏窗口

Label_DefVar: ;初始化变量	
	;设置初始化变量，用于读取并保存INI配置文件参数
	global INI
	INI = %A_ScriptDir%\tong_KBLAutoSwitch.ini
	global APPName := "KBLAutoSwitch"
	global APPVersion := "2.0.2"
	;INI配置文件参数变量初始化
	global CN_Code := 0x08040804
	global EN_Code := 0x04090409
	global Switch_Display := 0
	global X_Pos_Coef := 0.92
	global Y_Pos_Coef := 0.88
	global Display_Time_GUI := 1500
	global Display_Time_ToolTip := 800
	global Font_Color := "1f4f89"
	global Font_Size := 28
	global Font_Weight := 700
	global Font_Transparency := 200
	global Display_Cn := "中 文"
	global Display_En := "英 文"
	global Default_Keyboard := 1
	global Is_Microsoft_Input := 0
	global Auto_Reload_MTime := 2000

	;配置文件不存在则初始化INI配置文件
	IfNotExist, %INI%
		initINI()

Label_ReadINI: ;读取INI配置文件
	;读取键盘代码、切换提示、默认键盘、GUI位置系数等
	iniread, CN_Code, %INI%, 基本设置, 中文代码, %A_Space%
	iniread, EN_Code, %INI%, 基本设置, 英文代码, %A_Space%
	iniread, Switch_Display, %INI%, 基本设置, 切换提示, %A_Space%
	iniread, X_Pos_Coef, %INI%, 基本设置, 水平系数, %A_Space%
	iniread, Y_Pos_Coef, %INI%, 基本设置, 垂直系数, %A_Space%
	iniread, Display_Time_GUI, %INI%, 基本设置, 显示时间_GUI, %A_Space%
	iniread, Display_Time_ToolTip, %INI%, 基本设置, 显示时间_ToolTip, %A_Space%
	iniread, Font_Color, %INI%, 基本设置, 字体颜色, %A_Space%
	iniread, Font_Size, %INI%, 基本设置, 字体大小, %A_Space%
	iniread, Font_Weight, %INI%, 基本设置, 字体粗细, %A_Space%
	iniread, Font_Transparency, %INI%, 基本设置, 字体透明度, %A_Space%
	iniread, Display_Cn, %INI%, 基本设置, 中文提示, %A_Space%
	iniread, Display_En, %INI%, 基本设置, 英文提示, %A_Space%
	iniread, Default_Keyboard, %INI%, 基本设置, 默认输入法, %A_Space%
	iniread, Is_Microsoft_Input, %INI%, 基本设置, 是否微软输入法, %A_Space%
	iniread, Auto_Reload_MTime, %INI%, 基本设置,重启时间, %A_Space%

	;读取分组
	iniread, INI_CN, %INI%, 中文窗口
	IniRead, INI_EN, %INI%, 英文窗口
	IniRead, INI_Focus_Control, %INI%, 焦点控件切换窗口
	
	;分组配置-中文窗口
	Loop, parse, INI_CN, `n, `r
	{
		if (A_LoopField = "")
			continue
		MyVar_Key := RegExReplace(A_LoopField, "=.*?$")
		MyVar_Val := RegExReplace(A_LoopField, "^.*?=") 
		if (MyVar_Key && MyVar_Val) 
			GroupAdd, cn_ahk_group, %MyVar_Val%
	}
	;分组配置-英文窗口
	Loop, parse, INI_EN, `n, `r
	{
		if (A_LoopField = "")
			continue
		MyVar_Key := RegExReplace(A_LoopField, "=.*?$")
		MyVar_Val := RegExReplace(A_LoopField, "^.*?=") 
		if (MyVar_Key && MyVar_Val) 
			GroupAdd, en_ahk_group, %MyVar_Val%
	}
	;-------------------------------------------------------
	;焦点控件切换窗口
	Loop, parse, INI_Focus_Control , `n,`r
	{
		if (A_LoopField = "")
			continue
		MyVar_Key := RegExReplace(A_LoopField, "=.*?$")
		MyVar_Val := RegExReplace(A_LoopField, "^.*?=") 
		if (MyVar_Key && MyVar_Val) 
			GroupAdd, focus_control_ahk_group, %MyVar_Val%
	}
	;不切换窗口，为微软内部窗口，与上一个窗口输入法保持一致，可提高使用体验
	GroupAdd, unswitch_ahk_group, ahk_class Shell_TrayWnd
	GroupAdd, unswitch_ahk_group, ahk_class NotifyIconOverflowWindow
	GroupAdd, unswitch_ahk_group, ahk_class Qt5QWindowToolSaveBits
	GroupAdd, unswitch_ahk_group, ahk_class Windows.UI.Core.CoreWindow
	GroupAdd, unswitch_ahk_group, ahk_class AutoHotkeyGUI
	GroupAdd, unswitch_ahk_group, ahk_exe HipsTray.exe
	GroupAdd, unswitch_ahk_group, ahk_exe rundll32.exe

Label_Init: ;初始化
	;获取输入法切换显示GUI位置
	dpi_screen := getDisplayPos()
	global X_Pos := dpi_screen[0]
	global Y_Pos := dpi_screen[1]
	;保存文本控件ID，用以更改切换显示的内容
	global My_Edit_Hwnd := 0
	;初始化切换显示GUI
	initGui()
	;记录ini文件修改时间，定时检测配置文件
	initResetINI()

Label_Main: ;主运行脚本
	;监控消息回调shellMessage，新建窗口和切换窗口自动设置输入法
	hWnd := WinExist()
	DllCall( "RegisterShellHookWindow", UInt,hWnd )
	msg_num := DllCall( "RegisterWindowMessage", Str, "SHELLHOOK" )
	OnMessage( msg_num, "shellMessage")
	shellMessage(1, 0)

~#Space UP:: ;截取win+空格显示切换提示
	KeyWait, LWin
	Sleep, 10
	showSwitch()
	return
return

Add_To_En: ;添加到英文窗口
	item_key_val := getINIItem()
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	If (item_key = "")
	{
		Return
	}
	IniRead, res, %INI%, 英文窗口, %item_key%
	If (res != "ERROR")
	{
		fail = 【%item_key%】 【添加】到【英文】窗口【失败】！
		success = 【%item_key%】已存在于 【英文】窗口！
	}Else
	{
		IniDelete, %INI%, 中文窗口 , %item_key%
		IniWrite, %item_val%, %INI%, 英文窗口, %item_key%
		fail = 【%item_key%】 【添加】到【英文】窗口【失败】！
		success = 【%item_key%】 【添加】到【英文】窗口【成功】！
	}
	if (ErrorLevel = 1)
	{
		showSwitchToolTip(fail)
	}Else
	{
		showSwitchToolTip(success)
	}
return

Add_To_Cn: ;添加到中文窗口
	item_key_val := getINIItem()
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	If (item_key = "")
	{
		Return
	}
	IniRead, res, %INI%, 中文窗口, %item_key%
	If (res != "ERROR")
	{
		fail = 【%item_key%】 【添加】到【中文】窗口【失败】！
		success = 【%item_key%】已存在于 【中文】窗口！
	}Else
	{
		IniDelete, %INI%, 英文窗口, %item_key%
		IniWrite, %item_val%, %INI%, 中文窗口, %item_key%
		fail = 【%item_key%】 【添加】到【中文】窗口【失败】！
		success = 【%item_key%】 【添加】到【中文】窗口【成功】！
	}
	if (ErrorLevel = 1)
	{
		showSwitchToolTip(fail)
	}Else
	{
		showSwitchToolTip(success)
	}
return

Remove_From_All: ;从配置窗口中移除，恢复为默认输入法
	item_key_val := getINIItem()
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	If (item_key = "")
	{
		Return
	}
	IniDelete, %INI%, 英文窗口, %item_key%
	IniDelete, %INI%, 中文窗口, %item_key%
	fail = 【%item_key%】 【移除】【失败】！
	success = 【%item_key%】 【移除】【成功】，已恢复为【默认】输入法！
	if (ErrorLevel = 1)
	{
		showSwitchToolTip(fail)
	}Else
	{
		showSwitchToolTip(success)
	}
return

Get_KeyBoard: ;手动检测键盘布局号码
	SetFormat, Integer, H
	WinGet, WinID,, A
	ThreadID:=DllCall("GetWindowThreadProcessId", "UInt", WinID, "UInt", 0)
	InputLocaleID:=DllCall("GetKeyboardLayout", "UInt", ThreadID)
	Clipboard:=InputLocaleID
	MsgBox, 键盘布局号码：%InputLocaleID%`n`n已复制到剪贴板
return

Auto_Reload_MTime: ;定时重新加载脚本
	RegRead, mtime_ini_path_reg, HKEY_CURRENT_USER, Software\KBLAutoSwitch, %INI%
	FileGetTime, mtime_ini_path, %INI%, M  ; 获取修改时间.
	if (mtime_ini_path_reg != mtime_ini_path)
	{
		gosub, Menu_Reload
	}
Return

Menu_Reload: ;重新加载脚本
	try Reload
	Sleep, 1000
	Run, %A_AhkPath%%A_Space%"%A_ScriptFullPath%"
	ExitApp
return

getINIItem() { ;获取设置INI文件的key-val
	item_key_val := Object()
	IfNotExist, %INI%
		initINI()
	WinGet, ahk_value, ProcessName, A
	if (ahk_value = "explorer.exe")
	{
		WinGetClass, ahk_value, , A
		item_key := SubStr(ahk_value, 1, StrLen(ahk_value))
		item_val = ahk_class %ahk_value%
	}Else
	{
		item_key := SubStr(ahk_value, 1, StrLen(ahk_value)-4)
		item_val = ahk_exe %ahk_value%
	}
	item_key_val[0] := item_key
	item_key_val[1] := item_val
	return item_key_val
}

showSwitch() { ;选择显示中英文
	code_now := getIMEKBL()
	If (code_now = CN_Code)
	{
		showSwitchCode(Display_Cn)
	}
	If (code_now = EN_Code)
	{
		showSwitchCode(Display_En)
	}
}

showSwitchCode(Msg="") { ;选择以何种方式显示
	if (Switch_Display = 1)
	{
		showSwitchGui(Msg)
	}
	if (Switch_Display = 2)
	{
		showSwitchToolTip(Msg)
	}
}

getIMEKBL() { ;激活窗口键盘布局检测方法,减少了不必要的切换,切换更流畅了
	SetFormat, Integer, H
	;解决cmd切换现实问题
	if WinActive("ahk_exe cmd.exe")
	{
		WinGet, win_id, , ahk_exe conhost.exe
	}Else if WinActive("ahk_group focus_control_ahk_group")
	{	;改动：添加部分应用获取焦点控件ID，解决部分应用显示问题
		ControlGetFocus, CClassNN, A
		If (CClassNN = "")
		{
			WinGet, win_id, , A
		}Else
		{
			ControlGet, win_id, Hwnd, , %CClassNN%
		}
	}Else
	{
		WinGet, win_id, , A
	}
	thread_id := DllCall("GetWindowThreadProcessId", "UInt", win_id, "UInt", 0)
	input_locale_id := DllCall("GetKeyboardLayout", "UInt", thread_id)
	return %input_locale_id%
}

getIME(WinTitle="") { ;借鉴了某日本人脚本中的获取输入法状态的内容,减少了不必要的切换,切换更流畅了
;-----------------------------------------------------------
; IMEの状態の取得
;    対象： AHK v1.0.34以降
;   WinTitle : 対象Window (省略時:アクティブウィンドウ)
;   戻り値  1:ON 0:OFF
;-----------------------------------------------------------
    ifEqual WinTitle, , SetEnv, WinTitle, A
    WinGet, hWnd, ID, %WinTitle%
    DefaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", Uint, hWnd, Uint)

    ;Message : WM_IME_CONTROL  wParam:IMC_GETOPENSTATUS
    DetectSave := A_DetectHiddenWindows
    DetectHiddenWindows, ON
    SendMessage 0x283, 0x005, 0, , ahk_id %DefaultIMEWnd%
    DetectHiddenWindows, %DetectSave%
    Return ErrorLevel
}

setIME(setSts, WinTitle="") { ;设置输入法状态
;目前该函数存在问题：微软输入法在桌面不会切换成中文
;-----------------------------------------------------------
; IMEの状態をセット
;    対象： AHK v1.0.34以降
;   SetSts  : 1:ON 0:OFF
;   WinTitle: 対象Window (省略時:アクティブウィンドウ)
;   戻り値  1:ON 0:OFF
;-----------------------------------------------------------
    ifEqual WinTitle, , SetEnv, WinTitle, A
    WinGet, hWnd, ID, %WinTitle%
    DefaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", Uint, hWnd, Uint)
 
    ;Message : WM_IME_CONTROL  wParam:IMC_SETOPENSTATUS
    DetectSave := A_DetectHiddenWindows
    DetectHiddenWindows, ON
    SendMessage 0x283, 0x006, setSts, , ahk_id %DefaultIMEWnd%
    DetectHiddenWindows, %DetectSave%
    Return ErrorLevel
}

setChineseLayout(h=0) { ;中文简体键盘布局切换主方法，h=0忽略延迟,h=1打开默认延迟
	;开启提示
	showSwitchCode(Display_Cn)
	;智能检测,如果发现不是中文,则切换
	If (getIMEKBL() != CN_Code)
	{
		if (h = 1)
		{
			Sleep, 120
		}
		PostMessage, 0x50, , %CN_Code%, , A
		if (h = 1)
		{
			Sleep, 35
		}
	}
	return
}

setEnglishLayout(h=0) { ;英文美国键盘布局切换主方法，h=0忽略延迟,h=1打开默认延迟
	;开启提示
	showSwitchCode(Display_En)
	;智能检测,如果发现不是英文,则切换
	If (getIMEKBL()!=EN_Code)
	{
		if (h = 1)
		{
			Sleep, 120
		}
		PostMessage, 0x50, , %EN_Code%, , A
		if (h = 1)
		{
			Sleep, 35
		}
	}
	return
}

shellMessage( wParam, lParam ) { ;接受系统窗口回调消息切换输入法键盘布局
	;1 顶级窗体被创建 
	;2 顶级窗体即将被关闭 
	;3 SHELL 的主窗体将被激活 
	;4 顶级窗体被激活 
	;5 顶级窗体被最大化或最小化 
	;6 Windows 任务栏被刷新，也可以理解成标题变更
	;7 任务列表的内容被选中 
	;8 中英文切换或输入法切换 		测试没有用
	;9 显示系统菜单 
	;10 顶级窗体被强制关闭 
	;11 
	;12 没有被程序处理的APPCOMMAND。见WM_APPCOMMAND 
	;13 wParam=被替换的顶级窗口的hWnd 
	;14 wParam=替换顶级窗口的窗口hWnd 
	;&H8000& 掩码 
	;53 全屏
	;54 退出全屏
	;32772 窗口切换

	;窗口创建和窗口切换时触发
	If ( wParam = 1 || wParam = 32772 )
	{
		;快速切换alt+tab会导致切换输入法失效，每次sleep 100ms可解决，同时必须在切换输入法前显示切换信息
		Sleep, 100
		IfWinActive, ahk_group cn_ahk_group
		{
			setChineseLayout()
			return
		}
		IfWinActive, ahk_group en_ahk_group
		{
			setEnglishLayout()
			return
		}
		IfWinActive, ahk_group unswitch_ahk_group	;没必要切换的窗口，保证切换显示逻辑的正确
		{
			return
		}
		if (Default_Keyboard = 0)
			setEnglishLayout()
		if (Default_Keyboard = 1)
			setChineseLayout()
		return
	}
}

showSwitchGui(Msg:="") {	;显示切换或当前的输入法状态，以GUI方式显示
	GuiControl, Text, %My_Edit_Hwnd%, %Msg%
	Gui, Show, x%X_Pos% y%Y_Pos% NoActivate  ; NoActivate 让当前活动窗口继续保持活动状态.
	SetTimer, Hide_Gui, %Display_Time_GUI%
	Return

	Hide_Gui:  ;隐藏GUI
		Gui, Hide
	return
}

showSwitchToolTip(Msg) {	;显示切换或当前的输入法状态，以ToolTip形式显示
	ToolTip, %Msg%
	SetTimer, Timer_Remove_ToolTip, %Display_Time_ToolTip%
	return
	
	Timer_Remove_ToolTip:  ;移除ToolTip
		SetTimer, Timer_Remove_ToolTip, Off
		ToolTip
	return
}

getDisplayPos() { ;根据屏幕的分辨率获取输入法切换显示位置
	pos_array := Object()
	SysGet, Mon, Monitor
	ratio := MonRight/MonBottom
	pos_array[0] := MonRight*X_Pos_Coef
	pos_array[1] := MonBottom*Y_Pos_Coef
	return pos_array
}

initResetINI() { ;定时重新加载配置文件
	FileGetTime, mtime_ini_path, %INI%, M  ; 获取修改时间.
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\KBLAutoSwitch, %INI%, %mtime_ini_path%
	if (Auto_Reload_MTime>0)
	{
		SetTimer, Auto_Reload_MTime, %Auto_Reload_MTime%
	}
}

initGui() { ;创建切换显示GUI
	custom_color := Font_Color
	Gui +LastFound +AlwaysOnTop -Caption +ToolWindow +Hwndid +E0x20
	Gui, Color, FFFFFF
	Gui, Font,Q3 s%Font_Size% w%Font_Weight% c%custom_color%, Segoe UI
	Gui, Add, Text, HwndMy_Edit_Hwnd, Display_Cn
	WinSet, TransColor, FFFFFF %Font_Transparency%,ahk_id %id%
}

initINI() { ;初始化INI
	FileAppend,【自动切换输入法键盘布局配置文件】, %INI%
	FileAppend,`n;--------------------------------********************【基础配置】**********************--------------------------------`n, %INI%
	FileAppend,;如需初始化配置，可直接删除该文件，重启应用，配置文件将自动初始化，前提是重启时间设置大于0`n, %INI%
	FileAppend,[基本设置]`n, %INI%
	FileAppend,中文代码=0x8040804`n, %INI%
	FileAppend,英文代码=0x4090409`n, %INI%
	FileAppend,;【是否显示切换后的右下角提示，0是不显示，1是右下角显示GUI，2是显示ToolTip并跟随鼠标位置】`n, %INI%
	FileAppend,切换提示=1`n, %INI%
	FileAppend,;【显示的位置系数范围建议为[0，1]，不然可能会跳出屏幕，[0，1]对应左到右和上到下，默认值是屏幕的右下角，GUI或ToolTip显示时间为ms】`n, %INI%
	FileAppend,水平系数=0.92`n, %INI%
	FileAppend,垂直系数=0.88`n, %INI%
	FileAppend,显示时间_GUI=1500`n, %INI%
	FileAppend,显示时间_ToolTip=800`n, %INI%
	FileAppend,字体颜色=1f4f89`n, %INI%
	FileAppend,字体大小=28`n, %INI%
	FileAppend,字体粗细=700`n, %INI%
	FileAppend,字体透明度=200`n, %INI%
	FileAppend,;【英文提示和中文提示需保持字符长度相同，否则实际显示长度是以中文为准，短于英文会导致英文提示不全】`n, %INI%
	FileAppend,中文提示=中 文`n, %INI%
	FileAppend,英文提示=英 文`n, %INI%
	FileAppend,;【设置没有写入配置文件的应用默认输入法，0是英文，1是中文】`n, %INI%
	FileAppend,默认输入法=1`n, %INI%
	FileAppend,;【配置文件修改后，自动重启脚本的时间ms，添加窗口后可自动生效】`n, %INI%
	FileAppend,重启时间=2000`n, %INI%
	FileAppend,`n;--------------------------------********************【窗口配置】**********************--------------------------------`n, %INI%
	FileAppend,;前【1】个内置添加的中文窗口，建议保留，可提高使用体验，分别为微软搜索栏;前【1】个内置添加的英文窗口，建议保留，可提高使用体验，分别为微软桌面`n,%INI%
	FileAppend,[中文窗口]`n, %INI%
	FileAppend,SearchApp=ahk_exe SearchApp.exe`n, %INI%
	FileAppend,[英文窗口]`n, %INI%
	FileAppend,WorkerW=ahk_class WorkerW`n, %INI%
	FileAppend,Photoshop=ahk_exe Photoshop.exe`n, %INI%
	FileAppend,cmd=ahk_exe cmd.exe`n, %INI%
	FileAppend,idea64=ahk_exe idea64.exe`n, %INI%
	FileAppend,Xshell=ahk_exe Xshell.exe`n, %INI%
	FileAppend,sublime_text=ahk_exe sublime_text.exe`n, %INI%
	FileAppend,IDMan=ahk_exe IDMan.exe`n, %INI%
	FileAppend,deadcells=ahk_exe deadcells.exe`n, %INI%
	FileAppend,`n;--------------------------------********************【非必要配置】**********************--------------------------------`n, %INI%
	FileAppend,;部分应用需要根据焦点控件对应线程设置输入法，如出现【切换显示错误】在【焦点控件切换窗口】中添加`n, %INI%
	FileAppend,[焦点控件切换窗口]`n, %INI%
	FileAppend,Xshell=ahk_exe Xshell.exe`n, %INI%
	FileAppend,ApplicationFrameHost=ahk_exe ApplicationFrameHost.exe`n, %INI%
	FileAppend,Steam=ahk_exe Steam.exe`n, %INI%
}