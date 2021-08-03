/* tong（【自动切换输入法键盘布局】）
    脚本: Kawvin_AutoIME
    作用: 根据设置自动切换输入法，右下角显示窗口切换后的输入法，不支持手动切换后的显示，支持默认输入法
    作者: 无名氏，删了很多本人不需要的代码，该脚本长时间没更新，所以备注也删了，重新写了备注
    改动: 删了很多我不需要的代码，该脚本长时间没更新，有些地方不太好用，比如alt+tab，新开和创建有点重复，编辑器模式我也不太需要，备注不太完整，重新写了备注
    设置方法：无托盘，无菜单，可以依托于RunAny使用，与Kawvin_AutoIME.ini文件一同复制到RunAny的RunPlugins文件夹中，RunAny设置脚本自启
			编辑配置文件Kawvin_AutoIME.ini，在相应的内容项目下填写内容
	清单：
		1.Kawvin_AutoIME_tong_v2.0.0.ahk 	必要		主脚本文件
		2.Kawvin_AutoIME.ini 				必要		配置文件
		3.get_keyboard_2.0.0.ahk					非必要	开启后可使用F10来获取当前的键盘布局代码
		4.AU3_Spy.exe 						非必要	用来获取窗口的ahk_exe，用来配置应用
	使用方法：
		1.配置好ini文件，相应程序打开即可自动切换输入法
		2.英文输入法可在windows-设置-时间和语言-语言-添加英语
		3.全局手动切换需要自己在系统里面设置切换键盘布局的快捷键，默认win+空格，建议中文输入法设置取消shift切换中英文，避免误触
;------------------------------------------------------------------------------------------------------------------------------------------------------------
;【改编者信息】	;{
	; 脚本名称：IME2
	; 脚本版本号：v2.0.0
	; AHK版本：RunAny版本v5.7.6
	; 语言：中文
	; v2.0.0 改编者：tong
	; 脚本功能：自动切换输入法，并显示切换GUI
	;---------------------------------------------------
	; 版本信息
	; v2.0.0：2021年8月1日
	;	1.修复了在windows下alt+tab切换太快不生效的问题
	;	2.添加了输入法右下角提示
	;	3.增加默认输入法
	;	4.删除编辑器、窗口切换，统一新开窗口和切换窗口的切换
	;	5.去除光标、菜单
	;	6.增加更多可配置项
	;	7.均采用自动切换输入法，系统建议win+空格切换输入法
	;	8.win+空格切换键盘布局显示GUI
	;	9.解决uwp应用的键盘布局获取问题，修改xshell键盘获取，以命令行对应的键盘布局为准，每次切换自动对焦到xshell命令行
	;---------------------------------------------------
	;---v2.0.0使用说明
	;-----切换方式
	;	仍然为"切换键盘布局方法"，需要同时安装中文输入法和英文输入法
	;-----配置文件
	; 	1.Kawvin_AutoIME.ini配置文件中设置相关选项，中文代码和英文代码已默认配置好，可使用get_keyboard_2.0.0.ahk获取键盘布局代码，目前微软自带英文键盘和搜狗输入法使用没有问题
	;	2.未设置应用默认为中文输入法，因此中文窗口选项可以不设置，只需将需要切换英文的应用进行设置即可
	;	3.打开AU3_Spy.exe文件，点击对应的窗口可获取对应窗口的ahk_exe，复制添加至Kawvin_AutoIME.ini配置文件即可
	;	4.建议与RunAny(https://hui-zz.gitee.io/runany/#/)一起使用，作为其插件运行。
	;	5.建议使用的中文输入法取消shift切换英文，一般在设置中取消，仅使用win+空格切换输入法，避免误触
;}
;------------------------------------------------------------------------------------------------------------------------------------------------------------
;【原改编者信息】;{
	; 脚本名称：IME2
	; 脚本版本号：v1.04
	; AHK版本：1.1.30
	; 语言：中文
	; v1.04 改编者：心如止水<QQ:2531574300>   <Autohotkey高手群（348016704)> 
	; 脚本功能：自动切换输入法
	; ^_^： 如果您有什么新的想法,或者有什么改进意见,欢迎加我的QQ,一起探讨改进 ：^_^
	;---------------------------------------------------
	; 版本信息
	; v0.3：在原作基础上增加了检测功能，切换更智能了
	; v1.0：9月24日 切换方式暂改为"切换键盘布局",切换更智能，更流畅,几乎不会出错
	; v1.01：9月24日 默认停掉编辑器内手动切换 这个非常容易误触，还是采取全局切换的那个比较好,修复了窗口切换时切换输入法失效的问题
	; v1.02：9月24日 在 编辑器内/全局手动时 默认停掉提示
	; v1.03：9月24日 1,针对中文输入法英文模式的情况，进行了针对性优化(仍需要您手动检测情况，填写代号) 2,输入法切换方法支持忽略延迟
	; v1.04：9月25日 1,修复了"中文布局+中文输入法下切换"时,"通知提示消失/忽略延迟不起作用"的问题 2,把注释放到了前面
	;---------------------------------------------------
	;---v1.0使用说明
	; 切换方法改为更稳定的"切换键盘布局方法",还可以在其它键盘布局上放英文输入法，提高效率(v1.0)
	;-----如何设置键盘布局？
	; 	可以去百度或谷歌上搜一下,默认的大概是中文(简体),新增加一个英文(美国)
	;-----如何使用？
	; 	切换和检测的方法,都需要特定的号码,但是这个号码是不一样的,你需要获取，然后更改
	;-----小技巧
	; 	1.英文输入法在打字的时候可以给出英文提示,有点类似于IDE的效果,很多人工作中和英语打交道比较少,偶尔用到之后，发现很多词都忘了，需要翻字典,有了英文输入	;	法这种现象就大大的改善了
	; 	2.英文输入法可以用一下Triivi ,口碑还是不错的
	; 	3.检测方法以及切换思路来自 https://autohotkey.com/board/topic/18343-dllcall-loadkeyboardlayout-problem/
	; 感谢 无关风月 的帮助测试,将来还会持续更新优化
;}
;------------------------------------------------------------------------------------------------------------------------------------------------------------
;【原作者信息】	;{
	; AHK版本：1.1.29.01
	; 语言：中文
	; 作者：lspcieee <lspcieee@gmail.com>
	; 网站：http://www.lspcieee.com/
	; 脚本功能：自动切换输入法
	;---------------------------------------------------
	;---关于原作者：
	; 原作者的脚本网址和使用方法介绍 https://faxian.appinn.com/747
	; 我这个脚本改进自该作者，所以先要看原来的说明文档才可以懂
;}
*/

Label_ScriptSetting:	;{ 脚本前参数设置
	Process, Priority, , High						;脚本高优先级
	#MenuMaskKey vkE8
	#NoEnv											;不检查空变量是否为环境变量
	#Persistent										;让脚本持久运行(关闭或ExitApp)
	#SingleInstance Force							;跳过对话框并自动替换旧实例
	#WinActivateForce								;强制激活窗口
	#MaxHotkeysPerInterval 200						;时间内按热键最大次数
	#HotkeyModifierTimeout 100 						;按住modifier后（不用释放后再按一次）可隐藏多个当前激活窗口
	;SetBatchLines 10ms								;脚本全速执行
	SetControlDelay -1								;控件修改命令自动延时,-1无延时，0最小延时
	CoordMode Menu Window							;坐标相对活动窗口
	CoordMode Mouse Screen							;鼠标坐标相对于桌面(整个屏幕)
	ListLines,Off           						;不显示最近执行的脚本行
	SendMode Input									;更速度和可靠方式发送键盘点击
	SetTitleMatchMode 2								;窗口标题模糊匹配;RegEx正则匹配
	DetectHiddenWindows on							;显示隐藏窗口
;}

Label_DefVar:	;{ 初始化变量	
	;设置初始化变量，用于读取并保存INI配置文件参数
	global INI
	INI=%A_ScriptDir%\Kawvin_AutoIME.ini
	global CN_Code:=0x08040804
	global EN_Code:=0x04090409
	global Switch_Display:=1
	global x_pos_coef:=0.925
	global y_pos_coef:=0.89
	global Display_Time_GUI:=1500
	global Display_Time_ToolTip:=800
	global Font_Color:="2e62cd"
	global Font_Size:=25
	global Font_Weight:=700
	global Font_Transparency:=200
	global Display_Cn:="中 文"
	global Display_En:="英 文"
	global Display_Start:=1
	global Default_Keyboard:=1

	;配置文件不存在则初始化INI配置文件
	IfNotExist,%INI%
	{
		FileAppend,[基本设置]`n,%INI%
		FileAppend,中文代码=0x8040804`n,%INI%
		FileAppend,英文代码=0x4090409`n`n,%INI%
		FileAppend,[中文窗口]`n,%INI%
		FileAppend,Item=`n`n,%INI%
		FileAppend,[英文窗口]`n,%INI%
		FileAppend,Item=`n`n,%INI%
	}
;}

Label_ReadINI: ;{ 读取INI配置文件
	;读取键盘代码、切换提示、默认键盘、GUI位置系数等
	iniread,CN_Code,%INI%,基本设置,中文代码,%A_Space%
	iniread,EN_Code,%INI%,基本设置,英文代码,%A_Space%
	iniread,Switch_Display,%INI%,基本设置,切换提示,%A_Space%
	iniread,x_pos_coef,%INI%,基本设置,水平系数,%A_Space%
	iniread,y_pos_coef,%INI%,基本设置,垂直系数,%A_Space%
	iniread,Display_Time_GUI,%INI%,基本设置,显示时间_GUI,%A_Space%
	iniread,Display_Time_ToolTip,%INI%,基本设置,显示时间_ToolTip,%A_Space%
	iniread,Font_Color,%INI%,基本设置,字体颜色,%A_Space%
	iniread,Font_Size,%INI%,基本设置,字体大小,%A_Space%
	iniread,Font_Weight,%INI%,基本设置,字体粗细,%A_Space%
	iniread,Font_Transparency,%INI%,基本设置,字体透明度,%A_Space%
	iniread,Display_Cn,%INI%,基本设置,中文提示,%A_Space%
	iniread,Display_En,%INI%,基本设置,英文提示,%A_Space%
	iniread,Display_Start,%INI%,基本设置,开启提示,%A_Space%
	iniread,Default_Keyboard,%INI%,基本设置,默认输入法,%A_Space%
	
	;读取分组
	iniread,INI_CN,%INI%,中文窗口
	IniRead,INI_EN,%INI%,英文窗口
	
	;分组配置-中文窗口
	Loop,parse,INI_CN,`n,`r
	{
		if (A_LoopField="")
			continue
		MyVar_Key:=RegExReplace(A_LoopField,"=.*?$")
		MyVar_Val:=RegExReplace(A_LoopField,"^.*?=") 
		if (MyVar_Key && MyVar_Val ) 
			GroupAdd,cn,%MyVar_Val%
	}
	;分组配置-英文窗口
	Loop,parse,INI_EN,`n,`r
	{
		if (A_LoopField="")
			continue
		MyVar_Key:=RegExReplace(A_LoopField,"=.*?$")
		MyVar_Val:=RegExReplace(A_LoopField,"^.*?=") 
		if (MyVar_Key && MyVar_Val ) 
			GroupAdd,en,%MyVar_Val%
	}
;}

Label_Init:	;{ 初始化	
	;获取输入法切换显示GUI位置
	DPI_Screen :=Get_Display_Pos()
	global x_pos:=DPI_Screen[0]
	global y_pos:=DPI_Screen[1]
	;保存文本控件ID，用以更改切换显示的内容
	global MyEditHwnd:=0
	;初始化切换显示GUI
	initGui()
;}


Label_Main:	;{ 主运行脚本
	;监控消息回调ShellMessage，新建窗口和切换窗口自动设置输入法
	hWnd := WinExist()
	DllCall( "RegisterShellHookWindow", UInt,hWnd )
	MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
	OnMessage( MsgNum, "ShellMessage")
	If (Display_Start=1)
		Show_Switch()
;}

;截取win+空格显示切换提示
~#Space UP::
	KeyWait, LWin
	Sleep, 10
	Show_Switch()
;下面不再执行，为函数调用
return


Show_Switch(){  ;选择显示中英文
	If (IMELA_GET()=CN_Code) {
		Show_Switch_Code(Display_Cn)
	}
	If (IMELA_GET()=EN_Code) {
		Show_Switch_Code(Display_En)
	}
}

Show_Switch_Code(Msg=""){  ;选择以何种方式显示
	if (Switch_Display=1){
		ShowSwitchGui(Msg)
	}
	if (Switch_Display=2){
		ShowSwitchToolTip(Msg)
	}
}

IMELA_GET(){ ;激活窗口键盘布局检测方法,减少了不必要的切换,切换更流畅了
	SetFormat, Integer, H
	WinGet, WinID,, A
	WinGet, ProName ,ProcessName, A
	;针对uwp应用
	if(ProName="ApplicationFrameHost.exe"){
		WinGet, WinIDs,ControlListHwnd, A
		Loop, Parse, WinIDs, `n
		{	
			if(A_Index=2){
				winID:=A_LoopField
				Break
			}
		}
	}
	;针对xshell应用，
	if(ProName="Xshell.exe"){
		WinGet, WinIDs,ControlListHwnd, A
		Loop, Parse, WinIDs, `n
		{	
			if(A_Index=34){
				winID:=A_LoopField
				ControlFocus,AfxFrameOrView1101
				Break
			}
		}
	}

	ThreadID:=DllCall("GetWindowThreadProcessId", "UInt", WinID, "UInt", 0)
	InputLocaleID:=DllCall("GetKeyboardLayout", "UInt", ThreadID)
	return %InputLocaleID%
}

IME_GET(WinTitle=""){ ;借鉴了某日本人脚本中的获取输入法状态的内容,减少了不必要的切换,切换更流畅了
;-----------------------------------------------------------
; IMEの状態の取得
;    対象： AHK v1.0.34以降
;   WinTitle : 対象Window (省略時:アクティブウィンドウ)
;   戻り値  1:ON 0:OFF
;-----------------------------------------------------------
    ifEqual WinTitle,,  SetEnv,WinTitle,A
    WinGet,hWnd,ID,%WinTitle%
    DefaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)

    ;Message : WM_IME_CONTROL  wParam:IMC_GETOPENSTATUS
    DetectSave := A_DetectHiddenWindows
    DetectHiddenWindows,ON
    SendMessage 0x283, 0x005,0,,ahk_id %DefaultIMEWnd%
    DetectHiddenWindows,%DetectSave%
    Return ErrorLevel
}

setChineseLayout(h=0){	;中文简体键盘布局切换主方法，h=0忽略延迟,h=1打开默认延迟
	;开启提示
	Show_Switch_Code(Display_Cn)
	;智能检测,如果发现不是中文,则切换
	If (IMELA_GET()!=CN_Code) {
		if (h=1){
			Sleep,120
		}
		PostMessage, 0x50,, %CN_Code%,,	A
		if (h=1){
			Sleep,35
		}
	}Else{
		;发现是中文，则判断是否为中文输入法内置英文模式，是则改,改的方法很简单粗暴,切成英文，再切成中文,如果你有快捷键也可以用，但不一定比这个更稳
		If (IME_GET()=0){
			if (h=1){
				Sleep,30
			}
			PostMessage, 0x50,, %CN_Code%,,	A
			if (h=1){
				Sleep,30
			}
			PostMessage, 0x50,, %CN_Code%,,	A
		}
	}
	return
}

setEnglishLayout(h=0){ ;英文美国键盘布局切换主方法，h=0忽略延迟,h=1打开默认延迟
	;开启提示
	Show_Switch_Code(Display_En)
	;智能检测,如果发现不是英文,则切换
	If (IMELA_GET()!=EN_Code){
		if (h=1){
			Sleep,120
		}
		PostMessage, 0x50,, %EN_Code%,, A
		if (h=1){
			Sleep,35
		}
	}
	return
}

ShellMessage( wParam,lParam ) { ;接受系统窗口回调消息切换输入法键盘布局
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
	If ( wParam = 1 || wParam = 32772 )	{
		;快速切换alt+tab会导致切换输入法失效，每次sleep 100ms可解决，同时必须在切换输入法前显示切换信息
		Sleep, 100
		IfWinActive,ahk_group cn
		{
			setChineseLayout()
			return
		}
		IfWinActive,ahk_group en
		{
			setEnglishLayout()
			return
		}
		if(Default_Keyboard=0)
			setEnglishLayout()
		if(Default_Keyboard=1)
			setChineseLayout()
		return
	}
}


ShowSwitchGui(Msg:=""){	;显示切换或当前的输入法状态，以GUI方式显示
	GuiControl, Text, %MyEditHwnd% , %Msg%
	Gui, Show, x%x_pos% y%y_pos% NoActivate  ; NoActivate 让当前活动窗口继续保持活动状态.
	SetTimer, Hide_Gui, %Display_Time_GUI%
	Return

	Hide_Gui:  ;隐藏GUI
		Gui, Hide
	return
}

ShowSwitchToolTip(Msg:=""){	;显示切换或当前的输入法状态，以ToolTip形式显示
	ToolTip, %Msg%
	SetTimer, Timer_RemoveToolTip, %Display_Time_ToolTip%
	return
	
	Timer_RemoveToolTip:  ;移除ToolTip
		SetTimer, Timer_RemoveToolTip, Off
		ToolTip
	return
}

initGui(){ ;创建切换显示GUI
	CustomColor := Font_Color
	Gui +LastFound +AlwaysOnTop -Caption +ToolWindow
	Gui, Color, %CustomColor%
	Gui, Font, s%Font_Size% w%Font_Weight%,Segoe UI
	Gui, Add, Text, HwndMyEditHwnd,Display_Cn
	WinSet, TransColor, %CustomColor% %Font_Transparency%
}

Get_Display_Pos(){ ;根据屏幕的分辨率获取输入法切换显示位置
	posArray := Object()
	SysGet, Mon, Monitor
	ratio := MonRight/MonBottom
	posArray[0]:=MonRight*x_pos_coef
	posArray[1]:=MonBottom*y_pos_coef
	return posArray
}