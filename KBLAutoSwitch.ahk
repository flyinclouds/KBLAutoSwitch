/*tong(【自动切换输入法】)
	脚本: KBLAutoSwitch自动切换输入法
	作者: tong
*/

Label_ScriptSetting: ;脚本前参数设置
	Process, Priority, , Realtime					;脚本高优先级
	#MenuMaskKey vkE8
	#Persistent										;让脚本持久运行(关闭或ExitApp)
	#SingleInstance Force							;允许多例运行，通过Single_Run限制单例
	#WinActivateForce								;强制激活窗口
	#MaxHotkeysPerInterval 200						;时间内按热键最大次数
	#HotkeyModifierTimeout 100						;按住modifier后(不用释放后再按一次)可隐藏多个当前激活窗口
	SetBatchLines, -1								;脚本全速执行
	SetControlDelay -1								;控件修改命令自动延时,-1无延时，0最小延时
	CoordMode Menu Window							;坐标相对活动窗口
	CoordMode Mouse Screen							;鼠标坐标相对于桌面(整个屏幕)
	ListLines, Off									;不显示最近执行的脚本行
	SendMode Input									;更速度和可靠方式发送键盘点击
	SetTitleMatchMode 2								;窗口标题模糊匹配;RegEx正则匹配
	DetectHiddenWindows on							;显示隐藏窗口

Label_DefVar: ;初始化变量	
	;设置初始化变量，用于读取并保存INI配置文件参数
	global INI := A_ScriptDir "\KBLAutoSwitch.ini"
	global APPName := "KBLAutoSwitch"
	global APPVersion := "2.1.2"
	;根据Win主题设置图标所在路径
	global SystemUsesLightTheme
	RegRead, SystemUsesLightTheme, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
	If (SystemUsesLightTheme=0){
		Aico_path = %A_ScriptDir%\Icos\white_A.ico
		CNico_path = %A_ScriptDir%\Icos\white_Cn.ico
		ENico_path = %A_ScriptDir%\Icos\white_En.ico	
	}Else{
		Aico_path = %A_ScriptDir%\Icos\black_A.ico
		CNico_path = %A_ScriptDir%\Icos\black_Cn.ico
		ENico_path = %A_ScriptDir%\Icos\black_En.ico	
	}
	;基础变量
	global shell_msg_num := 0		;接受窗口切换等消息
	global State_ShowTime := 1000
	;INI配置文件参数变量初始化
	global CN_Code,EN_Code,Switch_Display,X_Pos_Coef,Y_Pos_Coef,Display_Time_GUI,Display_Time_ToolTip
	global Font_Color,Font_Size,Font_Weight,Font_Transparency
	global Display_Cn,Display_En,Default_Keyboard
	global Auto_Reload_MTime,Tray_Display_KBL,Tray_Display_Menu,Double_Click_Open_KBL
	global is_Show_CapsLock:=1,is_Show_CapsLock_key:=1
	global Switch_Model:=1,Launch_Admin:=1,Auto_Launch:=0,ImmGetDefaultIMEWnd
	global Disable_App_List
	global Cur_Launch,Cur_Format
	global Hotkey_Add_To_Cn,Hotkey_Add_To_CnEn,Hotkey_Add_To_En,Hotkey_Remove_From_All
	global Hotkey_Set_Chinese,Hotkey_Set_ChineseEnglish,Hotkey_Set_English,Hotkey_Display_KBL,Hotkey_Reset_KBL
	global Hotkey_Stop_KBLAS,Hotkey_Get_KeyBoard
	global Hotkey_Left_Shift,Hotkey_Right_Shift,Hotkey_Left_Ctrl,Hotkey_Right_Ctrl,Hotkey_Left_Alt,Hotkey_Right_Alt

	;配置文件不存在则初始化INI配置文件，存在则检测下是否是最新的配置文件版本
	if !FileExist(INI)
		initINI()

Label_AdminLaunch: ;管理员启动,保证管理员权限软件也可生效
	iniread, Launch_Admin, %INI%, 基本设置, 管理员启动, 1
	full_command_line := DllCall("GetCommandLine", "str")
	if (!(A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) && Launch_Admin=1)
	{
	    try
	    {
	        if A_IsCompiled
	            Run *RunAs "%A_ScriptFullPath%" /restart
	        else
	            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
	    }catch{
	    	MsgBox, 1,, 以【管理员权限】启动失败！将以普通权限启动，管理员应用窗口将失效！
			IfMsgBox OK
			{
				if A_IsCompiled
	            	Run "%A_ScriptFullPath%" /restart
	       		else
	            	Run "%A_AhkPath%" /restart "%A_ScriptFullPath%"
			}
	    }
	    ExitApp
	}

Label_SystemVersion: ;获取win系统版本
	global OSVersion := StrReplace(A_OSVersion, ".")
	If (OSVersion>=10022000)
		OSVersion := 11
	Else 
		OSVersion := 10

Label_SystemVersion_Var: ;win系统版本对应变量
	global Ico_path := Object()
	global Ico_num := Object()
	If (OSVersion=11){
		Ico_path["关闭菜单"] := "imageres.dll",Ico_num["关闭菜单"] := 234
		Ico_path["语言首选项"] := "imageres.dll",Ico_num["语言首选项"] := 110
		Ico_path["设置"] := "shell32.dll",Ico_num["设置"] := 315
		Ico_path["关于"] := "imageres.dll",Ico_num["关于"] := 77
		Ico_path["停止"] := "imageres.dll",Ico_num["停止"] := 208
		Ico_path["重启"] := "imageres.dll",Ico_num["重启"] := 230
		Ico_path["退出"] := "imageres.dll",Ico_num["退出"] := 231
	}Else If (OSVersion=10){
		Ico_path["关闭菜单"] := "imageres.dll",Ico_num["关闭菜单"] := 233
		Ico_path["语言首选项"] := "imageres.dll",Ico_num["语言首选项"] := 110
		Ico_path["设置"] := "shell32.dll",Ico_num["设置"] := 317
		Ico_path["关于"] := "imageres.dll",Ico_num["关于"] := 77
		Ico_path["停止"] := "imageres.dll",Ico_num["停止"] := 208
		Ico_path["重启"] := "imageres.dll",Ico_num["重启"] := 229
		Ico_path["退出"] := "imageres.dll",Ico_num["退出"] := 230
	}

Label_KBLDetect: ;从注册表检测KBL
	KBLObj := Object()
	Loop, Reg, HKEY_CURRENT_USER\Keyboard Layout\Preload, V
	{
	    RegRead, OutputVar
	    OutputVar := SubStr(OutputVar,-2)
	    KBLObj[OutputVar] := 1
	}
	If KBLObj.HasKey(804){
	    If KBLObj.HasKey(409)
	        KBLEnglish_Exist := 1
	    Else
	        KBLEnglish_Exist := 0
	}Else{
		MsgBox,未安装【中文】输入法，请安装中文输入法后重试！
		ExitApp
	}

Label_ReadINI: ;读取INI配置文件
	;读取基本配置
	iniread, CN_Code, %INI%, 基本设置, 中文代码, 0x08040804
	iniread, EN_Code, %INI%, 基本设置, 英文代码, 0x04090409
	iniread, Switch_Display, %INI%, 基本设置, 切换提示, 1
	iniread, X_Pos_Coef, %INI%, 基本设置, 水平系数, 92
	iniread, Y_Pos_Coef, %INI%, 基本设置, 垂直系数, 88
	iniread, Display_Time_GUI, %INI%, 基本设置, 显示时间_GUI, 1500
	iniread, Display_Time_ToolTip, %INI%, 基本设置, 显示时间_ToolTip, 1500
	iniread, Font_Color, %INI%, 基本设置, 字体颜色, 1f4f89
	iniread, Font_Size, %INI%, 基本设置, 字体大小, 28
	iniread, Font_Weight, %INI%, 基本设置, 字体粗细, 700
	iniread, Font_Transparency, %INI%, 基本设置, 字体透明度, 200
	iniread, Display_Cn, %INI%, 基本设置, 中文提示, 中
	iniread, Display_En, %INI%, 基本设置, 英文提示, 英
	iniread, Default_Keyboard, %INI%, 基本设置, 默认输入法, 1
	iniread, Auto_Reload_MTime, %INI%, 基本设置,重启时间, 2000
	iniread, Tray_Display_KBL, %INI%, 基本设置,图标显示输入法, 1
	iniread, Tray_Display_Menu, %INI%, 基本设置,托盘右键显示菜单, 1
	iniread, Double_Click_Open_KBL, %INI%, 基本设置,双击打开语言首选项, 1
	iniread, Switch_Model, %INI%, 基本设置,切换模式, 1
	iniread, Auto_Launch, %INI%, 基本设置,开机自启, 0
	iniread, Cur_Launch, %INI%, 基本设置,鼠标指针显示输入法, 1
	iniread, Cur_Format, %INI%, 基本设置,鼠标指针格式, 0
	iniread, Disable_App_List, %INI%, 基本设置,热键屏蔽程序列表, %A_Space%

	;读取热键
	iniread, Hotkey_Add_To_Cn, %INI%, 热键设置,添加至中文窗口, %A_Space%
	iniread, Hotkey_Add_To_CnEn, %INI%, 热键设置,添加至英文(中文)窗口, %A_Space%
	iniread, Hotkey_Add_To_En, %INI%, 热键设置,添加至英文输入法窗口, %A_Space%
	iniread, Hotkey_Remove_From_All, %INI%, 热键设置,移除从中英文窗口, %A_Space%

	iniread, Hotkey_Set_Chinese, %INI%, 热键设置,切换中文, %A_Space%
	iniread, Hotkey_Set_ChineseEnglish, %INI%, 热键设置,切换英文(中文), %A_Space%
	iniread, Hotkey_Set_English, %INI%, 热键设置,切换英文输入法, %A_Space%
	iniread, Hotkey_Display_KBL, %INI%, 热键设置,显示当前输入法, %A_Space%
	iniread, Hotkey_Reset_KBL, %INI%, 热键设置,重置当前输入法, %A_Space%
	iniread, Hotkey_Stop_KBLAS, %INI%, 热键设置,停止自动切换, %A_Space%
	iniread, Hotkey_Get_KeyBoard, %INI%, 热键设置,获取输入法IME代码, %A_Space%

	;读取特殊热键
	iniread, Hotkey_Left_Shift, %INI%, 特殊热键,左Shift, 1
	iniread, Hotkey_Right_Shift, %INI%, 特殊热键,右Shift, 2
	iniread, Hotkey_Left_Ctrl, %INI%, 特殊热键,左Ctrl, 0
	iniread, Hotkey_Right_Ctrl, %INI%, 特殊热键,右Ctrl, 0
	iniread, Hotkey_Left_Alt, %INI%, 特殊热键,左Alt, 0
	iniread, Hotkey_Right_Alt, %INI%, 特殊热键,右Alt, 0

	;读取分组
	iniread, INI_CN, %INI%, 中文窗口
	IniRead, INI_EN, %INI%, 英文窗口
	IniRead, INI_ENEN, %INI%, 英文输入法窗口
	IniRead, INI_Focus_Control, %INI%, 焦点控件切换窗口
	
	;分组配置-中文窗口
	getINISwitchWindows(INI_CN,"cn_ahk_group") ;中文输入法中文模式窗口
	getINISwitchWindows(INI_EN,"en_ahk_group")  ;中文输入法英文文模式窗口
	If (KBLEnglish_Exist=0 && Switch_Model=1)
		getINISwitchWindows(INI_ENEN,"en_ahk_group") ;英文输入法窗口
	Else
		getINISwitchWindows(INI_ENEN,"enen_ahk_group") ;英文输入法窗口
	;-------------------------------------------------------
	;焦点控件切换窗口
	getINISwitchWindows(INI_Focus_Control,"focus_control_ahk_group")
	;不切换窗口，为微软内部窗口，与上一个窗口输入法保持一致，可提高使用体验
	;任务栏、窗口切换等
	GroupAdd, unswitch_ahk_group_after, ahk_class Shell_TrayWnd
	GroupAdd, unswitch_ahk_group_after, ahk_class NotifyIconOverflowWindow
	GroupAdd, unswitch_ahk_group_after, ahk_class Qt5QWindowToolSaveBits
	GroupAdd, unswitch_ahk_group_after, ahk_class Windows.UI.Core.CoreWindow
	GroupAdd, unswitch_ahk_group_after, ahk_exe HipsTray.exe
	GroupAdd, unswitch_ahk_group_after, ahk_exe rundll32.exe

	GroupAdd, unswitch_ahk_group_before, ahk_class MultitaskingViewFrame
	GroupAdd, unswitch_ahk_group_before, ahk_class Progman
	;默认焦点控件切换窗口：uwp、资源管理器
	GroupAdd, focus_control_ahk_group, ahk_exe ApplicationFrameHost.exe
	GroupAdd, focus_control_ahk_group, ahk_exe explorer.exe
	GroupAdd, focus_control_ahk_group, ahk_exe RunAny.exe

Label_CurLaunch: ;鼠标指针初始化
	If (Cur_Launch=1){
		global OCR_IBEAM := 32513
		global OCR_NORMAL := 32512
		global OCR_APPSTARTING := 32650
		global OCR_WAIT := 32514
		global OCR_HAND := 32649
		Cur_Suffix := "ani"
		If (Cur_Format=0)
			Cur_Suffix := "cur"
		global ACur_IBEAM_path := A_ScriptDir "\Curs\IBEAM_A." Cur_Suffix
		global CNCur_IBEAM_path := A_ScriptDir "\Curs\IBEAM_Cn." Cur_Suffix
		global ENCur_IBEAM_path := A_ScriptDir "\Curs\IBEAM_En." Cur_Suffix
		global ACur_NORMAL_path := A_ScriptDir "\Curs\NORMAL_A." Cur_Suffix
		global CNCur_NORMAL_path := A_ScriptDir "\Curs\NORMAL_Cn." Cur_Suffix
		global ENCur_NORMAL_path := A_ScriptDir "\Curs\NORMAL_En." Cur_Suffix
		global Cur_APPSTARTING_path := A_ScriptDir "\Curs\APPSTARTING." Cur_Suffix
		global Cur_WAIT_path := A_ScriptDir "\Curs\WAIT." Cur_Suffix
		global Cur_HAND_path := A_ScriptDir "\Curs\HAND." Cur_Suffix
	}	

Label_DisableAppList: ;读取热键屏蔽程序列表
	Loop,parse,Disable_App_List,`,
		GroupAdd,DisableAppList_ahk_group,ahk_exe %A_LoopField%

Label_AutoRun: ;判断是否开机自启
	SplitPath, A_ScriptName , , , , OutNameNoExt
	RegRead, Auto_Launch_reg, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, %OutNameNoExt%
	Auto_Launch_reg := Auto_Launch_reg=A_ScriptDir "\" OutNameNoExt ".exe" ? 1 : 0
	If(Auto_Launch!=Auto_Launch_reg){
		Auto_Launch_reg:=Auto_Launch
		If(Auto_Launch){
			RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, %OutNameNoExt%, %A_ScriptDir%\%OutNameNoExt%.exe
		}Else{
			RegDelete, HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run, %OutNameNoExt%
		}
	}

Label_Detection: ;运行前检测
	If (Tray_Display_KBL = 1 && (!FileExist(Aico_path) || !FileExist(CNico_path) || !FileExist(ENico_path))){
		MsgBox, 用于显示输入法的【托盘图标】文件不存在，请检查下列图标文件是否存在`n1.%Aico_path%`n2.%CNico_path%`n3.%ENico_path%`n将不显示托盘图标！如需不显示托盘图标，请在配置文件中设置！
		Tray_Display_KBL := 0
	}Else{
		global AIcon := LoadPicture(Aico_path,,ImageType)
		global CNIcon := LoadPicture(CNico_path,,ImageType)
		global ENIcon := LoadPicture(ENico_path,,ImageType)
	}

Label_Init: ;初始化
	;获取输入法切换显示GUI位置
	dpi_screen := getDisplayPos(X_Pos_Coef,Y_Pos_Coef)
	global X_Pos := dpi_screen[0]
	global Y_Pos := dpi_screen[1]
	;保存文本控件ID，用以更改切换显示的内容
	global My_Edit_Hwnd,SwitchGui_id
	global LastKBLState,LastCapsState
	;初始化切换显示GUI
	initGui()
	;记录ini文件修改时间，定时检测配置文件
	initResetINI()
	;是否创建托盘右键菜单和使用大写键
	If (KBLEnglish_Exist=1){
		Hotkey, ~#Space UP, WinSpace_Detect
	}
	ImmGetDefaultIMEWnd := DllCall("GetProcAddress", "Ptr", DllCall("LoadLibrary", "Str", "imm32", "Ptr"), "AStr", "ImmGetDefaultIMEWnd", "Ptr")
	If (KBLObj.Length()>1){
		createTray()
		Gosub,Tray_Detect
		SetTimer, Tray_Detect, 100
	}
	If (is_Show_CapsLock_key=1 && Switch_Display!=0){
		Hotkey, ~CapsLock UP, CapsLock_Detect
	}

Label_CreateHotkey:	;创建热键
	Hotkey, IfWinNotActive, ahk_group DisableAppList_ahk_group
	if (Hotkey_Add_To_Cn != "")
		Hotkey, %Hotkey_Add_To_Cn%, Add_To_Cn
	if (Hotkey_Add_To_CnEn != "")
		Hotkey, %Hotkey_Add_To_CnEn%, Add_To_CnEn
	if (Hotkey_Add_To_En != "")
		Hotkey, %Hotkey_Add_To_En%, Add_To_En
	if (Hotkey_Remove_From_All != "")
		Hotkey, %Hotkey_Remove_From_All%, Remove_From_All

	if (Hotkey_Set_Chinese != "")
		Hotkey, %Hotkey_Set_Chinese%, Set_Chinese
	if (Hotkey_Set_ChineseEnglish != "")
		Hotkey, %Hotkey_Set_ChineseEnglish%, Set_ChineseEnglish
	if (Hotkey_Set_English != "")
		Hotkey, %Hotkey_Set_English%, Set_English
	if (Hotkey_Display_KBL != "")
		Hotkey, %Hotkey_Display_KBL%, Display_KBL
	if (Hotkey_Reset_KBL != "")
		Hotkey, %Hotkey_Reset_KBL%, Reset_KBL

	if (Hotkey_Stop_KBLAS != "")
		Hotkey, %Hotkey_Stop_KBLAS%, Stop_KBLAS
	if (Hotkey_Get_KeyBoard != "")
		Hotkey, %Hotkey_Get_KeyBoard%, Get_KeyBoard

Label_BoundHotkey:	;绑定特殊热键
	BoundHotkey("~LShift",Hotkey_Left_Shift)
	BoundHotkey("~RShift",Hotkey_Right_Shift)
	BoundHotkey("~LCtrl",Hotkey_Left_Ctrl)
	BoundHotkey("~RCtrl",Hotkey_Right_Ctrl)
	BoundHotkey("~LAlt",Hotkey_Left_Alt)
	BoundHotkey("~RAlt",Hotkey_Right_Alt)

Label_Main: ;主运行脚本
	;监控消息回调shellMessage，新建窗口和切换窗口自动设置输入法
	DllCall("ChangeWindowMessageFilter", "UInt", 0x004A, "UInt" , 1)	; 接受非管理员权限RA消息
	DllCall("RegisterShellHookWindow", UInt, A_ScriptHwnd)
	shell_msg_num := DllCall("RegisterWindowMessage", Str, "SHELLHOOK")
	OnMessage(shell_msg_num, "shellMessage")
	OnMessage(0x004A, "Receive_WM_COPYDATA")
	shellMessage(1, 0)

Label_Release_Var: ;释放对象
	OnExit("ExitFunc") ;退出执行
	VarSetCapacity(Ico_path, 0)
	VarSetCapacity(Ico_num, 0)

Label_Return: ;结束标志
Return

WinSpace_Detect: ;截取win+空格显示切换提示
	KeyWait, LWin
	showSwitch(Switch_Display)
Return

CapsLock_Detect: ;CapsLock按下提示
	showSwitch(Switch_Display)
Return

Tray_Detect: ;托盘图标切换提示
	showSwitch(0)
Return

Auto_Reload_MTime: ;定时重新加载脚本
	RegRead, mtime_ini_path_reg, HKEY_CURRENT_USER, Software\KBLAutoSwitch, %INI%
	FileGetTime, mtime_ini_path, %INI%, M  ; 获取修改时间.
	RegRead, SystemUsesLightTheme_new, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
	if (mtime_ini_path_reg != mtime_ini_path || SystemUsesLightTheme_new != SystemUsesLightTheme){
		gosub, Menu_Reload
	}
	SystemUsesLightTheme := SystemUsesLightTheme_new
Return

getINISwitchWindows(INIVar:="",groupName:=""){ ;从配置文件读取切换窗口
	Loop, parse, INIVar, `n, `r
	{
		if (A_LoopField = "")
			continue
		MyVar_Key := RegExReplace(A_LoopField, "=.*?$")
		MyVar_Val := RegExReplace(A_LoopField, "^.*?=") 
		if (MyVar_Key && MyVar_Val) {
			prefix := SubStr(MyVar_Val, 1, 3)
			If (prefix = "uwp"){
				uwp_app := SubStr(MyVar_Val, 5)
				GroupAdd, %groupName%, ahk_exe ApplicationFrameHost.exe, %uwp_app%
				GroupAdd, %groupName%, %uwp_app%
			}Else{
				GroupAdd, %groupName%, %MyVar_Val%
			}
		}
	}
}

showSwitch(Switch_Display=1) { ;选择显示中英文
	winid := getIMEwinid()
	If (getIMEKBL(winid)!=EN_Code && getIMECode(winid)=1){
		showSwitchCode(Display_Cn,Switch_Display)
		Tray_Display_KBL(0)
	}Else{
		showSwitchCode(Display_En,Switch_Display)
		Tray_Display_KBL(1)
	}
}

showSwitchCode(Msg="", Switch_Display=1) { ;选择以何种方式显示
	If (is_Show_CapsLock){
		CapsLockState := DllCall("GetKeyState", UInt, 20) & 1
		Msg .= DllCall("GetKeyState", UInt, 20) & 1 ? " | A" : " | a"
	}
	if (Switch_Display = 1)
		showSwitchGui(Msg, Display_Time_GUI)
	Else if (Switch_Display = 2)
		showSwitchToolTip(Msg, Display_Time_ToolTip)
}

getIMEwinid(){
	if WinActive("ahk_class ConsoleWindowClass"){
		WinGet, win_id, , ahk_exe conhost.exe
	}Else if WinActive("ahk_group focus_control_ahk_group"){	;改动：添加部分应用获取焦点控件ID，解决部分应用显示问题
		ControlGetFocus, CClassNN, A
		If (CClassNN = "")
			WinGet, win_id, , A
		Else
			ControlGet, win_id, Hwnd, , %CClassNN%
	}Else
		WinGet, win_id, , A
	Return win_id
}

getIMEKBL(win_id:="") { ;激活窗口键盘布局检测
	thread_id := DllCall("GetWindowThreadProcessId", "UInt", win_id, "UInt", 0)
	input_locale_id := DllCall("GetKeyboardLayout", "UInt", thread_id)
	Return %input_locale_id%
}

getIMECode(win_id:="") { ;激活窗口键盘原输入法和英文
	DefaultIMEWnd := DllCall(ImmGetDefaultIMEWnd, Uint, win_id, Uint)
	SendMessage 0x283, 0x005, 0, , ahk_id %DefaultIMEWnd%
	input_locale_id := ErrorLevel
	Return %input_locale_id%
}

setIME(setSts, WinTitle="") { ;设置输入法状态
;-----------------------------------------------------------
; IMEの状態をセット
;    対象： AHK v1.0.34以降
;   SetSts  : 1:ON 0:OFF
;   WinTitle: 対象Window (省略時:アクティブウィンドウ)
;   戻り値  1:ON 0:OFF
;-----------------------------------------------------------
    win_id := getIMEwinid()
    DefaultIMEWnd := DllCall(ImmGetDefaultIMEWnd, Uint, win_id, Uint)
    SendMessage 0x283, 0x006, setSts, , ahk_id %DefaultIMEWnd%
    Return ErrorLevel
}

setKBLlLayout(KBL:=0){
	winid := getIMEwinid()	
	If (KBL=0){ ;切换中文输入法
		showSwitchCode(Display_Cn,Switch_Display)
		If (getIMEKBL(winid)=CN_Code){
			If (getIMECode(winid)!=1)
				setIME(1)
		}Else{
			SendMessage, 0x50, , %CN_Code%, , A,,,,100
			setIME(1)
		}
	}Else If (KBL=1){ ;切换英文(中文)输入法
		showSwitchCode(Display_En,Switch_Display)
		If (getIMEKBL(winid)=CN_Code){
			If (getIMECode(winid)!=0)
				setIME(0)
		}Else{
			SendMessage, 0x50, , %CN_Code%, , A,,,,100
			setIME(0)
		}
	}Else If (KBL=2){ ;切换英文输入法
		showSwitchCode(Display_En,Switch_Display)
		If (getIMEKBL(winid)!=EN_Code)
			PostMessage, 0x50, , %EN_Code%, , A
	}
}

shellMessage(wParam, lParam) { ;接受系统窗口回调消息切换输入法键盘布局
	;如果应用不切换，使用showSwitchToolTip(wParam)查看消息
	;窗口创建、窗口切换时、uwp应用创建时触发
	Critical on
	If ( wParam=1 || wParam=32772 || wParam=5 ){	
		If WinActive("ahk_group unswitch_ahk_group_before"){ ;没必要切换的窗口前，保证切换显示逻辑的正确
			showSwitch(Switch_Display)
		}Else If WinActive("ahk_group cn_ahk_group"){
			setKBLlLayout(0)
		}Else If WinActive("ahk_group en_ahk_group"){
			setKBLlLayout(1)
		}Else If WinActive("ahk_group enen_ahk_group"){
			setKBLlLayout(2)
		}Else If WinActive("ahk_group unswitch_ahk_group_after"){ ;没必要切换的窗口后，保证切换显示逻辑的正确
			showSwitch(Switch_Display)
		}Else If (Default_Keyboard=1){
			setKBLlLayout(0)
		}Else If (Default_Keyboard=0){
			setKBLlLayout(1)
		}
	}
	Critical off
}

showSwitchGui(Msg="", ShowTime=1500) { ;显示切换或当前的输入法状态，以GUI方式显示
	GuiControl, Text, %My_Edit_Hwnd%, %Msg%
	Gui SwitchGui:+AlwaysOnTop
	Gui, SwitchGui:Show, x%X_Pos% y%Y_Pos% NoActivate ; NoActivate 让当前活动窗口继续保持活动状态.
	SetTimer, Hide_Gui, %ShowTime%
	Return

	Hide_Gui:  ;隐藏GUI
		SetTimer, Hide_Gui, Off
		Gui, SwitchGui:Hide
	Return
}

showSwitchToolTip(Msg="", ShowTime=1000, is_input=0) { ;显示切换或当前的输入法状态，以ToolTip形式显示
	If (is_input=1){
		CoordMode, Caret, Window
		ToolTip, %Msg%, A_CaretX-45, A_CaretY-28
	}Else{
		ToolTip, %Msg%
	}
	SetTimer, Timer_Remove_ToolTip, %ShowTime%
	Return
	
	Timer_Remove_ToolTip:  ;移除ToolTip
		SetTimer, Timer_Remove_ToolTip, Off
		ToolTip
	Return
}

getDisplayPos(X,Y) { ;根据屏幕的分辨率获取输入法切换显示位置
	pos_array := Object()
	SysGet, Mon, Monitor
	ratio := MonRight/MonBottom
	pos_array[0] := MonRight*X*0.01
	pos_array[1] := MonBottom*Y*0.01
	Return pos_array
}

initResetINI() { ;定时重新加载配置文件
	FileGetTime, mtime_ini_path, %INI%, M  ; 获取修改时间.
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\KBLAutoSwitch, %INI%, %mtime_ini_path%
	if (Auto_Reload_MTime>0)
		SetTimer, Auto_Reload_MTime, %Auto_Reload_MTime%
}

initGui() { ;创建切换显示GUI
	Gui SwitchGui:+LastFound +AlwaysOnTop -Caption +ToolWindow +Disabled +HwndSwitchGui_id +E0x20
	Gui, SwitchGui:Color, FFFFFF
	Gui, SwitchGui:Font,Q3 s%Font_Size% w%Font_Weight% c%Font_Color%, Segoe UI
	Gui, SwitchGui:Add, Text, HwndMy_Edit_Hwnd, %Display_Cn% | A
	WinSet, TransColor, FFFFFF %Font_Transparency%,ahk_id %SwitchGui_id%
}

Tray_Display_KBL(KBL_Flag=0) { ;更改托盘图标
	CapsLockState := DllCall("GetKeyState", UInt, 20) & 1
	If (CapsLockState=1 && LastCapsState=CapsLockState)
		Return
	If (LastKBLState=KBL_Flag && LastCapsState=CapsLockState)
		Return
	LastKBLState:=KBL_Flag
	LastCapsState:=CapsLockState
	If (Tray_Display_KBL = 0)
		Menu, Tray, NoIcon
	Else{
		If (CapsLockState=1)
			Menu, Tray, Icon, HICON:*%AIcon%
		Else If (KBL_Flag=0)
			Menu, Tray, Icon, HICON:*%CNIcon%
		Else
			Menu, Tray, Icon, HICON:*%ENIcon%
	}
	If (Cur_Launch=1){
		If (CapsLockState = 1){
			Cur_IBEAM := DllCall("LoadCursorFromFile", "Str",ACur_IBEAM_path, "Ptr")
			Cur_NORMAL := DllCall("LoadCursorFromFile", "Str",ACur_NORMAL_path, "Ptr")
		}Else If (KBL_Flag=0){
			Cur_IBEAM := DllCall("LoadCursorFromFile", "Str",CNCur_IBEAM_path, "Ptr")
			Cur_NORMAL := DllCall("LoadCursorFromFile", "Str",CNCur_NORMAL_path, "Ptr")
		}Else{
			Cur_IBEAM := DllCall("LoadCursorFromFile", "Str",ENCur_IBEAM_path, "Ptr")
			Cur_NORMAL := DllCall("LoadCursorFromFile", "Str",ENCur_NORMAL_path, "Ptr")
		}
		Cur_APPSTARTING := DllCall("LoadCursorFromFile", "Str",Cur_APPSTARTING_path, "Ptr")
		Cur_WAIT := DllCall("LoadCursorFromFile", "Str",Cur_WAIT_path, "Ptr")
		Cur_HAND := DllCall("LoadCursorFromFile", "Str",Cur_HAND_path, "Ptr")
		DllCall("SetSystemCursor", "Ptr", Cur_IBEAM, "Int", OCR_IBEAM)
		DllCall("SetSystemCursor", "Ptr", Cur_NORMAL, "Int", OCR_NORMAL)
		DllCall("SetSystemCursor", "Ptr", Cur_APPSTARTING, "Int", OCR_APPSTARTING)
		DllCall("SetSystemCursor", "Ptr", Cur_WAIT, "Int", OCR_WAIT)
		DllCall("SetSystemCursor", "Ptr", Cur_HAND, "Int", OCR_HAND)
	}
}

initINI() { ;初始化INI
	FileAppend,;--------------------------------********************【基础配置】********************--------------------------------`n, %INI%
	FileAppend,;如需初始化配置，可直接删除该文件，重启应用，配置文件将自动初始化，前提是重启时间设置大于0`n, %INI%
	FileAppend,[基本设置]`n, %INI%
	FileAppend,中文代码=0x8040804`n, %INI%
	FileAppend,英文代码=0x4090409`n, %INI%
	FileAppend,;【是否显示切换后的右下角提示，0是不显示，1是右下角显示GUI，2是显示ToolTip并跟随鼠标位置】`n, %INI%
	FileAppend,切换提示=1`n, %INI%
	FileAppend,;【显示的位置系数范围建议为[0，1]，不然可能会跳出屏幕，[0，1]对应左到右和上到下，默认值是屏幕的右下角，GUI或ToolTip显示时间为ms】`n, %INI%
	FileAppend,水平系数=87`n, %INI%
	FileAppend,垂直系数=88`n, %INI%
	FileAppend,显示时间_GUI=1500`n, %INI%
	FileAppend,显示时间_ToolTip=1500`n, %INI%
	FileAppend,字体颜色=1f4f89`n, %INI%
	FileAppend,字体大小=28`n, %INI%
	FileAppend,字体粗细=700`n, %INI%
	FileAppend,字体透明度=200`n, %INI%
	FileAppend,中文提示=中 文`n, %INI%
	FileAppend,英文提示=英 文`n, %INI%
	FileAppend,默认输入法=1`n, %INI%
	FileAppend,重启时间=2000`n, %INI%
	FileAppend,图标显示输入法=1`n, %INI%
	FileAppend,托盘右键显示菜单=1`n, %INI%
	FileAppend,双击打开语言首选项=1`n, %INI%
	FileAppend,切换模式=1`n, %INI%
	FileAppend,管理员启动=1`n, %INI%
	FileAppend,开机自启=0`n, %INI%
	FileAppend,鼠标指针显示输入法=1`n, %INI%
	FileAppend,鼠标指针格式=0`n, %INI%
	FileAppend,热键屏蔽程序列表=deadcells.exe`n, %INI%
	FileAppend,`n;--------------------------------********************【热键配置】********************--------------------------------`n, %INI%
	FileAppend,[热键设置]`n, %INI%
	FileAppend,添加至中文窗口=`n, %INI%
	FileAppend,添加至英文(中文)窗口=`n, %INI%
	FileAppend,添加至英文输入法窗口=`n, %INI%
	FileAppend,移除从中英文窗口=`n, %INI%
	FileAppend,切换中文=`n, %INI%
	FileAppend,切换英文(中文)=`n, %INI%
	FileAppend,切换英文输入法=`n, %INI%
	FileAppend,显示当前输入法=`n, %INI%
	FileAppend,重置当前输入法=`n, %INI%
	FileAppend,停止自动切换=`n, %INI%
	FileAppend,获取输入法IME代码=`n, %INI%

	FileAppend,[特殊热键]`n, %INI%
	FileAppend,左Shift=1`n, %INI%
	FileAppend,右Shift=2`n, %INI%
	FileAppend,左Ctrl=0`n, %INI%
	FileAppend,右Ctrl=0`n, %INI%
	FileAppend,左Alt=0`n, %INI%
	FileAppend,右Alt=0`n, %INI%
	FileAppend,`n;--------------------------------********************【窗口配置】********************--------------------------------`n, %INI%
	FileAppend,[中文窗口]`n, %INI%
	;win搜索栏
	FileAppend,SearchApp=ahk_exe SearchApp.exe`n, %INI%
	FileAppend,OneNote for Windows 10=uwp OneNote for Windows 10`n, %INI%
	FileAppend,[英文窗口]`n, %INI%
	;win桌面
	FileAppend,WorkerW=ahk_class WorkerW`n, %INI%
	FileAppend,Photoshop=ahk_exe Photoshop.exe`n, %INI%
	FileAppend,Steam=ahk_exe Steam.exe`n, %INI%
	FileAppend,cmd=ahk_exe cmd.exe`n, %INI%
	FileAppend,idea64=ahk_exe idea64.exe`n, %INI%
	FileAppend,Xshell=ahk_exe Xshell.exe`n, %INI%
	FileAppend,sublime_text=ahk_exe sublime_text.exe`n, %INI%
	FileAppend,IDMan=ahk_exe IDMan.exe`n, %INI%
	;火绒流量窗口，如果使用了火绒流量窗口，则每次桌面最小化焦点会在该窗口
	FileAppend,HRNETFLOWTRAY=ahk_class HRNETFLOWTRAY`n, %INI%
	FileAppend,[英文输入法窗口]`n, %INI%
	FileAppend,deadcells=ahk_exe deadcells.exe`n, %INI%
	FileAppend,闹钟和时钟=uwp 闹钟和时钟`n, %INI%
	FileAppend,`n;--------------------------------*******************【非必要配置】*******************--------------------------------`n, %INI%
	FileAppend,;部分应用需要根据焦点控件对应线程设置输入法，如出现【切换显示错误】在【焦点控件切换窗口】中添加`n, %INI%
	FileAppend,[焦点控件切换窗口]`n, %INI%
	FileAppend,Xshell=ahk_exe Xshell.exe`n, %INI%
	FileAppend,Steam=ahk_exe Steam.exe`n, %INI%
}

createTray() { ;右键托盘菜单
	;初始化托盘提示
	TrayTipContent := A_IsAdmin=1?"中英文自动切换（管理员）":"中英文自动切换（非管理员）"
	Menu, Tray, Tip, %TrayTipContent%
	Menu, Tray, NoStandard
	If (Double_Click_Open_KBL=1){
		Menu, Tray, Click, 2
		Menu, Tray, Add, 关闭菜单, menu_close
		Menu, Tray, Icon, 关闭菜单, % Ico_path["关闭菜单"], % Ico_num["关闭菜单"]
		Menu, Tray, Add, 语言首选项, Menu_Language
		Menu, Tray, Icon, 语言首选项, % Ico_path["语言首选项"], % Ico_num["语言首选项"]
		Menu, Tray, Default ,语言首选项
	}
	If (Tray_Display_Menu=0){
		Return
	}
	Menu, Tray, Add, 关闭菜单, menu_close
	Menu, Tray, Icon, 关闭菜单, % Ico_path["关闭菜单"], % Ico_num["关闭菜单"]
	Menu, Tray, Add, 语言首选项, Menu_Language
	Menu, Tray, Icon, 语言首选项, % Ico_path["语言首选项"], % Ico_num["语言首选项"]
	Menu, Tray, Add 
	Menu, Tray, Add, 设置, Menu_Settings_Gui
	Menu, Tray, Icon, 设置, % Ico_path["设置"], % Ico_num["设置"]
	Menu, Tray, Add 
	Menu, Tray, Add, 关于, Menu_About
	Menu, Tray, Icon, 关于, % Ico_path["关于"], % Ico_num["关于"]
	Menu, Tray, Add 
	Menu, Tray, Add, 停止, Menu_Stop
	Menu, Tray, Icon, 停止, % Ico_path["停止"], % Ico_num["停止"]
	Menu, Tray, unCheck, 停止
	Menu, Tray, Add, 重启, Menu_Reload
	Menu, Tray, Icon, 重启, % Ico_path["重启"], % Ico_num["重启"]
	Menu, Tray, Add, 退出, Menu_Exit
	Menu, Tray, Icon, 退出, % Ico_path["退出"], % Ico_num["退出"]
}

iniRun(ini) { ;打开指定文件
	try{
		if(!FileExist(ini)){
			MsgBox,16,%ini%,没有找到配置文件：%ini%
		}
		Run,"%ini%"
	}catch{
		Run,notepad.exe "%ini%"
	}
}

menu_close: ;关闭菜单
Return

Menu_Language: ;打开语言首选项
	Run,ms-settings:regionlanguage
Return

Menu_Settings_Gui: ;设置页面GUI
	Critical
	global EditSliderobj := Object()
	Edit_Hwnd:="",Slider_Hwnd:=""
	tab_width_66 = 480
	group_width_66 = 460
	group_list_width_66 = 440
	text_width = 100
	Gui, 55:Destroy
	Gui, 55:Default
	Gui, 55:Margin, 30, 20
	Gui, 55:Font, W400, Microsoft YaHei
	Gui, 55:Add, Tab3, x10 y10 w%tab_width_66% h550 vConfigTab, 基础设置1|基础设置2|热键配置|窗口配置
	
	Gui, 55:Tab, 基础设置1
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_66% h70, 启动设置
	Gui, 55:Add, Text, xm+10 yp+30, 开机自启
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vAuto_Launch, 禁止|开启
	GuiControl, Choose, Auto_Launch, % Auto_Launch+1
	Gui, 55:Add, Text, x+82 yp+1, 启动权限
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vLaunch_Admin, 普通|管理员
	GuiControl, Choose, Launch_Admin, % Launch_Admin+1


	Gui, 55:Add, GroupBox, xm-10 y+27 w%group_width_66% h70, 输入法切换设置
	Gui, 55:Add, Text, xm+10 yp+30, 切换提示
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vSwitch_Display, 关闭|GUI|ToolTip
	GuiControl, Choose, Switch_Display, % Switch_Display+1
	Gui, 55:Add, Text, x+82 yp+1, 切换模式
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vSwitch_Model, 严格切换|智能切换
	GuiControl, Choose, Switch_Model, % Switch_Model+1

	Gui, 55:Add, GroupBox, xm-10 y+30 w%group_width_66% h220, 切换显示设置
	Gui, 55:Add, Text, xm+10 yp+30, 水平系数
	Gui, 55:Add, Edit, +HwndEdit_Hwnd x+5 yp-2 w45 h23 vX_Pos_Coef gSliderChange, %X_Pos_Coef%
	Gui, 55:Add, Slider, +HwndSlider_Hwnd x+0 yp w55 h23 ToolTip Range0-100 gSliderChange AltSubmit TickInterval20 Line1, %X_Pos_Coef%
	EditSliderobj[Slider_Hwnd]:=Edit_Hwnd
	Gui, 55:Add, Text, x+82 yp+1, 垂直系数
	Gui, 55:Add, Edit, +HwndEdit_Hwnd x+5 yp-1 w45 h23 vY_Pos_Coef gSliderChange, %Y_Pos_Coef%
	Gui, 55:Add, Slider, +HwndSlider_Hwnd x+0 yp w55 h23 ToolTip Range0-100 gSliderChange AltSubmit TickInterval20 Line1, %Y_Pos_Coef%
	EditSliderobj[Slider_Hwnd]:=Edit_Hwnd
	Gui, 55:Add, Text, xm+10 yp+40, 字体颜色
	Gui, 55:Add, Edit, x+5 yp-2 w45 h23 vFont_Color gSliderChange, %Font_Color%
	Gui, 55:Add, Button, x+10 yp w45 h23 gbtn,取色
	Gui, 55:Add, Text, x+82 yp+1, 字体大小
	Gui, 55:Add, Edit, +HwndEdit_Hwnd x+5 yp-1 w45 h23 vFont_Size gSliderChange, %Font_Size%
	Gui, 55:Add, Slider, +HwndSlider_Hwnd x+0 yp w55 h23 ToolTip Range1-35 Line1 TickInterval7 gSliderChange AltSubmit, %Font_Size%
	EditSliderobj[Slider_Hwnd]:=Edit_Hwnd
	Gui, 55:Add, Text, xm+10 yp+40, 字体粗细
	Gui, 55:Add, Edit, +HwndEdit_Hwnd x+5 yp-2 w45 h23 vFont_Weight gSliderChange, %Font_Weight%
	Gui, 55:Add, Slider, +HwndSlider_Hwnd x+0 yp w55 h23 ToolTip Range0-1000 Line10 TickInterval200 gSliderChange AltSubmit, %Font_Weight%
	EditSliderobj[Slider_Hwnd]:=Edit_Hwnd
	Gui, 55:Add, Text, x+70 yp+1, 字体透明度
	Gui, 55:Add, Edit, +HwndEdit_Hwnd x+5 yp-1 w45 h23 vFont_Transparency, %Font_Transparency%
	Gui, 55:Add, Slider, +HwndSlider_Hwnd x+0 yp w55 h23 ToolTip Range0-255 Line5 TickInterval51 gSliderChange AltSubmit, %Font_Transparency%
	EditSliderobj[Slider_Hwnd]:=Edit_Hwnd
	Gui, 55:Add, Text, xm+10 yp+40, 中文提示
	Gui, 55:Add, Edit, x+5 yp-2 w%text_width% h23 vDisplay_Cn gSliderChange, %Display_Cn%
	Gui, 55:Add, Text, x+82 yp+1, 英文提示
	Gui, 55:Add, Edit, x+5 yp-1 w%text_width% h23 vDisplay_En gSliderChange, %Display_En%
	Gui, 55:Add, Text, xm+10 yp+32, GUI显示`n停留时间
	Gui, 55:Add, Edit, x+5 yp+6 w%text_width% h23 vDisplay_Time_GUI, %Display_Time_GUI%
	Gui, 55:Add, Text, x+62 yp-6, ToolTip显示`n%A_Space%%A_Space%停留时间
	Gui, 55:Add, Edit, x+5 yp+6 w%text_width% h23 vDisplay_Time_ToolTip, %Display_Time_ToolTip%

	Gui, 55:Add, GroupBox, xm-10 y+27 w%group_width_66% h117, 图标及其他设置
	Gui, 55:Add, Text, xm+18 yp+22, %A_Space%%A_Space%默认`n输入法%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp+6 w%text_width% vDefault_Keyboard, 英文|中文
	GuiControl, Choose, Default_Keyboard, % Default_Keyboard+1
	Gui, 55:Add, Text, x+48 yp+1, 图标显示输入法
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vTray_Display_KBL, 关闭|显示
	GuiControl, Choose, Tray_Display_KBL, % Tray_Display_KBL+1
	Gui, 55:Add, Text, xm+10 yp+35, 托盘右键`n显示菜单
	Gui, 55:Add, DropDownList, x+5 yp+6 w%text_width% vTray_Display_Menu, 关闭|显示
	GuiControl, Choose, Tray_Display_Menu, % Tray_Display_Menu+1
	Gui, 55:Add, Text, x+60 yp-6, 双击图标打开`n%A_Space%语言首选项
	Gui, 55:Add, DropDownList, x+5 yp+6 w%text_width% vDouble_Click_Open_KBL, 禁止|开启
	GuiControl, Choose, Double_Click_Open_KBL, % Double_Click_Open_KBL+1

	Gui, 55:Tab
	Gui, 55:Add, Button, Default w75 x110 yp+70 GSet_OK, 确定
	Gui, 55:Add, Button, w75 x+20 yp G55GuiClose, 取消
	Gui, 55:Add, Button, w75 x+20 yp GSet_ReSet, 恢复默认
	gui, 55:Font, underline
	Gui, 55:Add, Text, Cblue w75 x+50 yp GMenu_Config, 点击打开`n配置文件
	Gui, 55:Font, norm , Microsoft YaHei

	Gui, 55:Tab, 基础设置2
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_66% h70, 鼠标指针设置
	Gui, 55:Add, Text, xm-2 yp+22, %A_Space%鼠标指针`n显示输入法
	Gui, 55:Add, DropDownList, x+5 yp+6 w%text_width% vCur_Launch, 禁止|开启
	GuiControl, Choose, Cur_Launch, % Cur_Launch+1
	Gui, 55:Add, Text, x+58 yp+1, 鼠标指针格式
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vCur_Format, cur|ani
	GuiControl, Choose, Cur_Format, % Cur_Format+1
	Gui, 55:Add, GroupBox, xm-10 y+27 w%group_width_66% h160, 屏蔽设置
	Gui, 55:Add, Text, xm yp+25, 热键屏蔽程序列表
	Gui, 55:Add, Edit, xm yp+20 w%group_list_width_66% r5 vDisable_App_List, %Disable_App_List%

	Gui, 55:Tab, 热键配置
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_66% h110, 窗口添加移除快捷键
	Gui, 55:Add, Text, xm+10 yp+22, %A_Space%添加至`n中文窗口
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Add_To_Cn, %Hotkey_Add_To_Cn%
	Gui, 55:Add, Text, x+70 yp-6,  添加至英文`n(中文)窗口
	Gui, 55:Add, Hotkey, x+5 yp+5 w%text_width% vHotkey_Add_To_CnEn, %Hotkey_Add_To_CnEn%
	Gui, 55:Add, Text, xm-2 yp+35, 添加至英文`n输入法窗口
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Add_To_En, %Hotkey_Add_To_En%
	Gui, 55:Add, Text, x+70 yp-6,  %A_Space%%A_Space%移除从`n中英文窗口
	Gui, 55:Add, Hotkey, x+5 yp+5 w%text_width% vHotkey_Remove_From_All, %Hotkey_Remove_From_All%

	Gui, 55:Add, GroupBox, xm-10 y+27 w%group_width_66% h150, 输入法快捷键
	Gui, 55:Add, Text, xm-2 yp+22, %A_Space%%A_Space%%A_Space%显示`n当前输入法
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Display_KBL, %Hotkey_Display_KBL%
	Gui, 55:Add, Text, x+70 yp-6, %A_Space%%A_Space%%A_Space%重置`n当前输入法
	Gui, 55:Add, Hotkey, x+5 yp+5 w%text_width% vHotkey_Reset_KBL, %Hotkey_Reset_KBL%
	Gui, 55:Add, Text, xm+10 yp+43, 切换中文
	Gui, 55:Add, Hotkey, x+5 yp-2 w%text_width% vHotkey_Set_Chinese, %Hotkey_Set_Chinese%
	Gui, 55:Add, Text, x+50 yp+1, 切换英文(中文)
	Gui, 55:Add, Hotkey, x+5 yp-2 w%text_width% vHotkey_Set_ChineseEnglish, %Hotkey_Set_ChineseEnglish%
	Gui, 55:Add, Text, xm+10 yp+35, 切换英文`n%A_Space%输入法
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Set_English, %Hotkey_Set_English%

	Gui, 55:Add, GroupBox, xm-10 y+27 w%group_width_66% h70, 自动切换程序快捷键
	Gui, 55:Add, Text, xm+10 yp+22, %A_Space%%A_Space%停止`n自动切换
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Stop_KBLAS, %Hotkey_Stop_KBLAS%
	Gui, 55:Add, Text, x+70 yp-6, 获取输入法`n%A_Space%%A_Space%IME代码
	Gui, 55:Add, Hotkey, x+5 yp+5 w%text_width% vHotkey_Get_KeyBoard, %Hotkey_Get_KeyBoard%

	Gui, 55:Add, GroupBox, xm-10 y+27 w%group_width_66% h150, 特殊热键
	Gui, 55:Add, Text, xm+17 yp+30, 左Shift%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Left_Shift, 无|切换中文|切换英文(中文)|切换英文输入法|切换中英文(中文)|切换中英文输入法
	GuiControl, Choose, Hotkey_Left_Shift, % Hotkey_Left_Shift+1
	Gui, 55:Add, Text, x+89 yp+1, 右Shift%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Right_Shift, 无|切换中文|切换英文(中文)|切换英文输入法|切换中英文(中文)|切换中英文输入法
	GuiControl, Choose, Hotkey_Right_Shift, % Hotkey_Right_Shift+1
	Gui, 55:Add, Text, xm+22 yp+43, 左Ctrl%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Left_Ctrl, 无|切换中文|切换英文(中文)|切换英文输入法|切换中英文(中文)|切换中英文输入法
	GuiControl, Choose, Hotkey_Left_Ctrl, % Hotkey_Left_Ctrl+1
	Gui, 55:Add, Text, x+94 yp+1, 右Ctrl%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Right_Ctrl, 无|切换中文|切换英文(中文)|切换英文输入法|切换中英文(中文)|切换中英文输入法
	GuiControl, Choose, Hotkey_Right_Ctrl, % Hotkey_Right_Ctrl+1
	Gui, 55:Add, Text, xm+27 yp+43, 左Alt%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Left_Alt, 无|切换中文|切换英文(中文)|切换英文输入法|切换中英文(中文)|切换中英文输入法
	GuiControl, Choose, Hotkey_Left_Alt, % Hotkey_Left_Alt+1
	Gui, 55:Add, Text, x+99 yp+1, 右Alt%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Right_Alt, 无|切换中文|切换英文(中文)|切换英文输入法|切换中英文(中文)|切换中英文输入法
	GuiControl, Choose, Hotkey_Right_Alt, % Hotkey_Right_Alt+1

	Gui, 55:Tab, 窗口配置
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_66% h508, 中英文窗口应用记录(如需手动添加，请按照示例格式，在下方添加)
	Gui, 55:Add, Text, xm yp+25, 中文窗口
	Gui, 55:Add, Edit, xm yp+20 w%group_list_width_66% r5 vINI_CN, %INI_CN%
	Gui, 55:Add, Text, xm yp+103, 英文窗口（中文输入法）
	Gui, 55:Add, Edit, xm yp+20 w%group_list_width_66% r9 vINI_EN, %INI_EN%
	Gui, 55:Add, Text, xm yp+173, 英文窗口（英文输入法）
	Gui, 55:Add, Edit, xm yp+20 w%group_list_width_66% r7 vINI_ENEN, %INI_ENEN%

	TrayTipContent := A_IsAdmin=1?"（管理员）":"（非管理员）"
	Gui, 55:Show,w500, %APPName%设置_v%APPVersion%%TrayTipContent%
	SetTimer, Hide_Gui, Off
	Gui, SwitchGui:Show, x%X_Pos% y%Y_Pos%
Return

SliderChange(CtrlHwnd, GuiEvent, EventInfo, ErrLevel:=""){
	GuiControlGet, OutputVar,,%CtrlHwnd%
	GuiControl,, % EditSliderobj[CtrlHwnd], %OutputVar%
	GuiControlGet, temp_Font_Size,,Font_Size
	GuiControlGet, temp_Font_Weight,,Font_Weight
	GuiControlGet, temp_Font_Color,,Font_Color
	GuiControlGet, temp_Display_Cn,,Display_Cn
	GuiControlGet, temp_X_Pos,,X_Pos_Coef
	GuiControlGet, temp_Y_Pos,,Y_Pos_Coef
	GuiControlGet, temp_Font_Transparency,,Font_Transparency
	temp_Font_Size := temp_Font_Size=""?1:temp_Font_Size
	temp_Font_Weight := temp_Font_Weight=""?0:temp_Font_Weight
	temp_X_Pos := temp_X_Pos=""?0:temp_X_Pos
	temp_Y_Pos := temp_Y_Pos=""?0:temp_Y_Pos
	temp_Font_Transparency := temp_Font_Transparency=""?0:temp_Font_Transparency
	dpi_screen := getDisplayPos(temp_X_Pos,temp_Y_Pos)
	temp_X_Pos := dpi_screen[0]
	temp_Y_Pos := dpi_screen[1]
	GuiControl, Text, %My_Edit_Hwnd%, %temp_Display_Cn% | A
	Gui, SwitchGui:Font,Q3 s%temp_Font_Size% w%temp_Font_Weight% c%temp_Font_Color%, Segoe UI
	GuiControl, Font, %My_Edit_Hwnd%
	WinSet, TransColor, FFFFFF %temp_Font_Transparency%,ahk_id %SwitchGui_id%
	Gui, SwitchGui:Show, x%temp_X_Pos% y%temp_Y_Pos% NoActivate
}

Menu_About: ;关于页面GUI
	Gui, 99:Destroy
	Gui, 99:Color, FFFFFF
	Gui, 99:Add, ActiveX, x0 y0 w700 h550 voWB, shell explorer
	oWB.Navigate("about:blank")
	vHtml = 
	(
		<html>
			<meta http-equiv="X-UA-Compatible" content="IE=edge">
			<title>APPName</title>
			<body style="font-family:Microsoft YaHei">
				<h2 align="center">【%APPName%】</h2>
				<h3 align="center">自动切换输入法_v%APPVersion%</h3>
				<b>最新版本：</b><img alt="GitHub release" style="vertical-align:middle" src="https://img.shields.io/github/v/release/flyinclouds/KBLAutoSwitch?label=KBLAutoSwitch"/>
				<b>AHK版本：</b><img alt="Autohotkey" style="vertical-align:middle" src="https://raster.shields.io/badge/autohotkey-1.1.33.10-blue.svg"/>
				<h4>软件特色</h4>
				<ol>
				  <li>根据程序窗口切换中英文输入法</li>
				  <li>包括GUI、Tooltip、图标、鼠标指针四种显示输入法状态功能</li>
				  <li>设置快捷键快速添加指定窗口</li>
				</ol>
				<h4>使用建议</h4>
				<ol>
				  <li>【中文】使用【搜狗输入法】、【手心输入法】、【小鹤音形】等第三方非微软自带中文输入法</li>
				  <li>【中文】输入法取消【<kbd>Shift</kbd>】切换中英文</li>
				  <li>输入法切换快捷键在软件内设置，而非在输入法中设置</li>
				</ol>
				<h4>特殊说明</h4>
				<ol>
				  <li style="color:red">暂不支持微软中文输入法</li>
				  <li>有任何问题可以加入【RunAny交流群】一起交流讨论（强大的快捷启动工具）</li>
				</ol>
			</body>
		</html>
	)
	oWB.document.write(vHtml)
	oWB.Refresh()
	Gui, 99:Font, s11 Bold, Microsoft YaHei
	Gui, 99:Add, Link, xm+18 y+10, 软件使用文档：<a href="https://docs.qq.com/doc/DWHFxVXBNbWNxcWpa">腾讯文档：https://docs.qq.com/doc/DWHFxVXBNbWNxcWpa</a>
	Gui, 99:Add, Link, xm+18 y+10, 软件github地址：<a href="https://github.com/flyinclouds/KBLAutoSwitch">https://github.com/flyinclouds/KBLAutoSwitch</a>
	Gui, 99:Add, Link, xm+18 y+10, 软件下载地址：<a href="https://wwr.lanzoui.com/b02i9dmsd">蓝奏云下载：https://wwr.lanzoui.com/b02i9dmsd 密码：fd5v</a>
	Gui, 99:Add, Link, xm+18 y+10, RunAny官网：<a href="https://hui-zz.gitee.io/runany/#/">https://hui-zz.gitee.io/runany/#/</a>
	Gui, 99:Add, Link, xm+18 y+10, RunAny交流群：<a href="https://jq.qq.com/?_wv=1027&k=445Ug7u">246308937【RunAny快速启动一劳永逸】</a>
	Gui, 99:Add, Link, xm+18 y+10, AHK中文论坛：<a href="https://www.autoahk.com/">https://www.autoahk.com/</a>
	Gui, 99:Font
	Gui, 99:Show, AutoSize Center, 关于%APPName%_v%APPVersion%
return

Menu_Stop: ;停止脚本
	Gui, Hide
	If (A_IsSuspended){
		If (Tray_Display_Menu=1)
			Menu, Tray, UnCheck, 停止
		OnMessage(shell_msg_num, "shellMessage")
		shellMessage(1, 0)
	}Else{
		If (Tray_Display_Menu=1)
			Menu, Tray, Check, 停止
		OnMessage(shell_msg_num, "")
	}
	Suspend
Return

Menu_Reload: ;重新加载脚本
	try Reload
	Sleep, 1000
	Run, %A_AhkPath%%A_Space%"%A_ScriptFullPath%"
	ExitApp
Return

Menu_Exit: ;重新加载脚本
	ExitApp
Return

99GuiClose:
	gosub,Menu_Reload
Return

55GuiClose: ;取消按钮的功能
	gosub,Menu_Reload
return

Set_OK: ;确认按钮的功能
	Gui, Submit
	Switch_Display := Switch_Display="关闭"?0:(Switch_Display="GUI"?1:2)
	Switch_Model := Switch_Model="严格切换"?0:1
	Default_Keyboard := Default_Keyboard="英文"?0:1
	Tray_Display_KBL := Tray_Display_KBL="关闭"?0:1
	Tray_Display_Menu := Tray_Display_Menu="关闭"?0:1
	Double_Click_Open_KBL := Double_Click_Open_KBL="禁止"?0:1
	Launch_Admin := Launch_Admin="普通"?0:1
	Auto_Launch := Auto_Launch="禁止"?0:1
	Cur_Launch := Cur_Launch="禁止"?0:1
	Cur_Format := Cur_Format="cur"?0:1
	Hotkey_Left_Shift := Hotkey_Left_Shift="无"?0:(Hotkey_Left_Shift="切换中文"?1:(Hotkey_Left_Shift="切换英文(中文)"?2:(Hotkey_Left_Shift="切换英文输入法"?3:(Hotkey_Left_Shift="切换中英文(中文)"?4:5))))
	Hotkey_Right_Shift := Hotkey_Right_Shift="无"?0:(Hotkey_Right_Shift="切换中文"?1:(Hotkey_Right_Shift="切换英文(中文)"?2:(Hotkey_Right_Shift="切换英文输入法"?3:(Hotkey_Right_Shift="切换中英文(中文)"?4:5))))
	Hotkey_Left_Ctrl := Hotkey_Left_Ctrl="无"?0:(Hotkey_Left_Ctrl="切换中文"?1:(Hotkey_Left_Ctrl="切换英文(中文)"?2:(Hotkey_Left_Ctrl="切换英文输入法"?3:(Hotkey_Left_Ctrl="切换中英文(中文)"?4:5))))
	Hotkey_Right_Ctrl := Hotkey_Right_Ctrl="无"?0:(Hotkey_Right_Ctrl="切换中文"?1:(Hotkey_Right_Ctrl="切换英文(中文)"?2:(Hotkey_Right_Ctrl="切换英文输入法"?3:(Hotkey_Right_Ctrl="切换中英文(中文)"?4:5))))
	Hotkey_Left_Alt := Hotkey_Left_Alt="无"?0:(Hotkey_Left_Alt="切换中文"?1:(Hotkey_Left_Alt="切换英文(中文)"?2:(Hotkey_Left_Alt="切换英文输入法"?3:(Hotkey_Left_Alt="切换中英文(中文)"?4:5))))
	Hotkey_Right_Alt := Hotkey_Right_Alt="无"?0:(Hotkey_Right_Alt="切换中文"?1:(Hotkey_Right_Alt="切换英文(中文)"?2:(Hotkey_Right_Alt="切换英文输入法"?3:(Hotkey_Right_Alt="切换中英文(中文)"?4:5))))
	IniWrite, %Switch_Display%, %INI%, 基本设置, 切换提示
	IniWrite, %Switch_Model%, %INI%, 基本设置, 切换模式
	IniWrite, %X_Pos_Coef%, %INI%, 基本设置, 水平系数
	IniWrite, %Y_Pos_Coef%, %INI%, 基本设置, 垂直系数
	IniWrite, %Font_Color%, %INI%, 基本设置, 字体颜色
	IniWrite, %Font_Size%, %INI%, 基本设置, 字体大小
	IniWrite, %Font_Weight%, %INI%, 基本设置, 字体粗细
	IniWrite, %Font_Transparency%, %INI%, 基本设置, 字体透明度
	IniWrite, %Display_Cn%, %INI%, 基本设置, 中文提示
	IniWrite, %Display_En%, %INI%, 基本设置, 英文提示
	IniWrite, %Display_Time_GUI%, %INI%, 基本设置, 显示时间_GUI
	IniWrite, %Display_Time_ToolTip%, %INI%, 基本设置, 显示时间_ToolTip
	IniWrite, %Default_Keyboard%, %INI%, 基本设置, 默认输入法
	IniWrite, %Tray_Display_KBL%, %INI%, 基本设置, 图标显示输入法
	IniWrite, %Tray_Display_Menu%, %INI%, 基本设置, 托盘右键显示菜单
	IniWrite, %Double_Click_Open_KBL%, %INI%, 基本设置, 双击打开语言首选项
	IniWrite, %Launch_Admin%, %INI%, 基本设置, 管理员启动
	IniWrite, %Auto_Launch%, %INI%, 基本设置, 开机自启
	IniWrite, %Cur_Launch%, %INI%, 基本设置, 鼠标指针显示输入法
	IniWrite, %Cur_Format%, %INI%, 基本设置, 鼠标指针格式
	IniWrite, %Disable_App_List%, %INI%, 基本设置, 热键屏蔽程序列表

	IniWrite, %Hotkey_Add_To_Cn%, %INI%, 热键设置, 添加至中文窗口
	IniWrite, %Hotkey_Add_To_CnEn%, %INI%, 热键设置, 添加至英文(中文)窗口
	IniWrite, %Hotkey_Add_To_En%, %INI%, 热键设置, 添加至英文输入法窗口
	IniWrite, %Hotkey_Remove_From_All%, %INI%, 热键设置, 移除从中英文窗口

	IniWrite, %Hotkey_Set_Chinese%, %INI%, 热键设置, 切换中文
	IniWrite, %Hotkey_Set_ChineseEnglish%, %INI%, 热键设置, 切换英文(中文)
	IniWrite, %Hotkey_Set_English%, %INI%, 热键设置, 切换英文输入法
	IniWrite, %Hotkey_Display_KBL%, %INI%, 热键设置, 显示当前输入法
	IniWrite, %Hotkey_Reset_KBL%, %INI%, 热键设置, 重置当前输入法

	IniWrite, %Hotkey_Stop_KBLAS%, %INI%, 热键设置, 停止自动切换
	IniWrite, %Hotkey_Get_KeyBoard%, %INI%, 热键设置, 获取输入法IME代码

	IniWrite, %Hotkey_Left_Shift%, %INI%, 特殊热键, 左Shift
	IniWrite, %Hotkey_Right_Shift%, %INI%, 特殊热键, 右Shift
	IniWrite, %Hotkey_Left_Ctrl%, %INI%, 特殊热键, 左Ctrl
	IniWrite, %Hotkey_Right_Ctrl%, %INI%, 特殊热键, 右Ctrl
	IniWrite, %Hotkey_Left_Alt%, %INI%, 特殊热键, 左Alt
	IniWrite, %Hotkey_Right_Alt%, %INI%, 特殊热键, 右Alt

	IniWrite, %INI_CN%, %INI%, 中文窗口
	IniWrite, %INI_EN%, %INI%, 英文窗口
	IniWrite, %INI_ENEN%, %INI%, 英文输入法窗口
	gosub, Menu_Reload
return

Set_ReSet: ;重置按钮的功能
	MsgBox, 49, 重置已有配置,此操作会删除所有KBLAutoSwitch本地配置，确认删除重置吗？
	IfMsgBox Ok
	{
		RegDelete, HKEY_CURRENT_USER, Software\KBLAutoSwitch
		FileDelete, %INI%
		gosub, Menu_Reload
	}
return

Menu_Config: ;打开配置文件功能
	iniRun(INI)
return

;-----------------------------------【取色功能】---https://www.autoahk.com/archives/40279
btn:
    S_Color := Dlg_Color("自定义取色窗口",hTest,CustomColors*)
    if S_Color!=False
		GuiControl, Text, Font_Color, %S_Color%
Return

Dlg_Color(WinTitle:="",hOwner:=0, Palette*){
    Static CHOOSECOLOR, A_CustomColors
    if !VarSetCapacity(A_CustomColors){
        If !objLength(Palette){
            Palette:=[0x1C7399,0xEEEEEC,0x014E8B,0x444444,0x009FE8,0xDEF9FA,0xF8B62D,0x90FC0F,0x0078D7,0x0D1B0A,0xB9D497,0x00ADEF,0x1778BF,0xFDF6E3,0x002B36,0xDEDEDE]
        }
        VarSetCapacity(A_CustomColors,64,0)
        for Index, Value in Palette
            NumPut(Value, A_CustomColors, 4*(Index - 1), "UInt")
    }
    l_Color:=((l_Color&0xFF)<<16)+(l_Color&0xFF00)+((l_Color>>16)&0xFF)
    ;-- 创建并填充CHOOSECOLOR结构
    lStructSize:=VarSetCapacity(CHOOSECOLOR,(A_PtrSize=8) ? 72:36,0)
    NumPut(lStructSize,CHOOSECOLOR,0,"UInt")            ;-- lStructSize
    NumPut(hOwner,CHOOSECOLOR,(A_PtrSize=8) ? 8:4,"Ptr")
    ;-- hwndOwner
    NumPut(l_Color,CHOOSECOLOR,(A_PtrSize=8) ? 24:12,"UInt")
    ;-- RGB结果
    NumPut(&A_CustomColors,CHOOSECOLOR,(A_PtrSize=8) ? 32:16,"Ptr")
    ;-- lpCustColors
    NumPut(0x00000103,CHOOSECOLOR,(A_PtrSize=8) ? 40:20,"UInt")
    ;-- Flags
    if (WinTitle!="")
        SetTimer, AsynchronousWinWait, -1
    RC:=DllCall("comdlg32\ChooseColor" . (A_IsUnicode ? "W":"A"),"Ptr",&CHOOSECOLOR)
    ;-- 按下“取消”按钮或关闭对话框
    if (RC=0)
        Return False
    ;-- 收集所选颜色
    l_Color:=NumGet(CHOOSECOLOR,(A_PtrSize=8) ? 24:12,"UInt")
    ;-- 转换为RGB
    TempColor:=((l_Color&0xFF)<<16)+(l_Color&0xFF00)+((l_Color>>16)&0xFF)
    Return Format("{:06X}",TempColor)
    AsynchronousWinWait:
    if WinActive("ahk_class #32770", "颜色") or (n=60)
        Goto ChangeTitle
    n := n="" ? 1 : ++n
    SetTimer AsynchronousWinWait, -10
    Return
    
    ChangeTitle:
    WinSetTitle, ahk_class #32770, 颜色, %WinTitle%
    Return
}


;-----------------------------------【快捷添加功能】-----------------------------------------------
Add_To_Cn: ;添加到中文窗口
	item_key_val := getINIItem()
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	If (item_key = "")
		Return
	IniRead, res, %INI%, 中文窗口, %item_key%
	If (res != "ERROR"){
		fail = 【%item_key%】 【添加】到【中文】窗口【失败】！
		success = 【%item_key%】已存在于 【中文】窗口！
	}Else{
		IniDelete, %INI%, 英文窗口, %item_key%
		IniDelete, %INI%, 英文输入法窗口, %item_key%
		IniWrite, %item_val%, %INI%, 中文窗口, %item_key%
		fail = 【%item_key%】 【添加】到【中文】窗口【失败】！
		success = 【%item_key%】 【添加】到【中文】窗口【成功】！
	}
	If (ErrorLevel = 1)
		showSwitchToolTip(fail, State_ShowTime)
	Else
		showSwitchToolTip(success, State_ShowTime)
Return

Add_To_CnEn: ;添加到英文窗口（中文）
	item_key_val := getINIItem()
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	If (item_key = "")
		Return
	IniRead, res, %INI%, 英文窗口, %item_key%
	If (res != "ERROR"){
		fail = 【%item_key%】 【添加】到【英文(中文)】窗口【失败】！
		success = 【%item_key%】已存在于 【英文(中文)】窗口！
	}Else{
		IniDelete, %INI%, 中文窗口 , %item_key%
		IniDelete, %INI%, 英文输入法窗口 , %item_key%
		IniWrite, %item_val%, %INI%, 英文窗口, %item_key%
		fail = 【%item_key%】 【添加】到【英文(中文)】窗口【失败】！
		success = 【%item_key%】 【添加】到【英文(中文)】窗口【成功】！
	}
	If (ErrorLevel = 1)
		showSwitchToolTip(fail, State_ShowTime)
	Else
		showSwitchToolTip(success, State_ShowTime)
Return

Add_To_En: ;添加到英文输入法窗口
	item_key_val := getINIItem()
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	If (item_key = "")
		Return
	IniRead, res, %INI%, 英文输入法窗口, %item_key%
	If (res != "ERROR"){
		fail = 【%item_key%】 【添加】到【英文输入法】窗口【失败】！
		success = 【%item_key%】已存在于 【英文输入法】窗口！
	}Else{
		IniDelete, %INI%, 中文窗口 , %item_key%
		IniDelete, %INI%, 英文窗口 , %item_key%
		IniWrite, %item_val%, %INI%, 英文输入法窗口, %item_key%
		fail = 【%item_key%】 【添加】到【英文输入法】窗口【失败】！
		success = 【%item_key%】 【添加】到【英文输入法】窗口【成功】！
	}
	If (ErrorLevel = 1)
		showSwitchToolTip(fail, State_ShowTime)
	Else
		showSwitchToolTip(success, State_ShowTime)
Return

Add_To_DisableApp: ;添加到英文输入法窗口
	WinGet, ahk_value, ProcessName, A
	Disable_App_List := Disable_App_List "," ahk_value
	IniWrite, %Disable_App_List%, %INI%, 基本设置, 热键屏蔽程序列表
Return

Remove_From_All: ;从配置窗口中移除，恢复为默认输入法
	item_key_val := getINIItem()
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	If (item_key = "")
		Return
	IniRead, res1, %INI%, 中文窗口, %item_key%
	IniRead, res2, %INI%, 英文窗口, %item_key%
	IniRead, res3, %INI%, 英文输入法窗口, %item_key%
	If (res1 = "ERROR" && res2 = "ERROR" && res3 = "ERROR"){
		fail = 【%item_key%】 【移除】从【中文】窗口【失败】！
		success = 【%item_key%】不存在于 【中文】和【英文】窗口,为【默认】输入法！
	}Else{
		IniDelete, %INI%, 中文窗口, %item_key%
		IniDelete, %INI%, 英文窗口, %item_key%
		IniDelete, %INI%, 英文输入法窗口, %item_key%
		fail = 【%item_key%】 【移除】【失败】！
		success = 【%item_key%】 【移除】【成功】，已恢复为【默认】输入法！
	}
	If (ErrorLevel = 1)
		showSwitchToolTip(fail, State_ShowTime)
	Else
		showSwitchToolTip(success, State_ShowTime)
Return

Set_Chinese: ;当前窗口设为中文
	setKBLlLayout(0)
Return

Set_ChineseEnglish: ;当前窗口设为英文（中文输入法）
	setKBLlLayout(1)
Return

Set_English: ;当前窗口设为英文
	setKBLlLayout(2)
Return

toggle_CN_CNEN: ;切换中英文(中文)
	winid := getIMEwinid()
	If (getIMEKBL(winid)!=EN_Code && getIMECode(winid)=1)
		setKBLlLayout(1)
	Else
		setKBLlLayout(0)
Return

toggle_CN_EN: ;切换中英文输入法
	winid := getIMEwinid()
	If (getIMEKBL(winid)!=EN_Code && getIMECode(winid)=1){
		If (KBLEnglish_Exist=1)
			setKBLlLayout(2)
		Else
			setKBLlLayout(1)
	}Else
		setKBLlLayout(0)
Return

Display_KBL: ;显示当前的输入法状态
	showSwitch(1)
Return

Reset_KBL: ;重置当前输入法键盘布局
	shellMessage(1,0)
Return

Stop_KBLAS: ;停止输入法自动切换
	gosub, Menu_Stop
Return

Get_KeyBoard: ;手动检测键盘布局号码
	InputLocaleID := Format("{1:#x}", getIMEKBL())
	Clipboard := InputLocaleID
	MsgBox, 键盘布局号码：%InputLocaleID%`n`n已复制到剪贴板
Return

getINIItem() { ;获取设置INI文件的key-val
	item_key_val := Object()
	WinGet, ahk_value, ProcessName, A
	If (ahk_value = "explorer.exe") ;针对explorer的优化
	{
		WinGetClass, ahk_value, , A
		item_key := SubStr(ahk_value, 1, StrLen(ahk_value))
		item_val = ahk_class %ahk_value%
	}Else If (ahk_value = "ApplicationFrameHost.exe") ;针对uwp应用的优化
	{
		WinGetText, uwp_text , A
		item_key := SubStr(uwp_text, 1, StrLen(uwp_text)-2)
		item_val = uwp %item_key%
	}Else{
		item_key := SubStr(ahk_value, 1, StrLen(ahk_value)-4)
		item_val = ahk_exe %ahk_value%
	}
	item_key_val[0] := item_key
	item_key_val[1] := item_val
	Return item_key_val
}

BoundHotkey(BoundHotkey,Hotkey_Fun){ ;绑定特殊热键
	If (Hotkey_Fun=1)
		Hotkey, %BoundHotkey%, Set_Chinese
	If (Hotkey_Fun=2)
		Hotkey, %BoundHotkey%, Set_ChineseEnglish
	If (Hotkey_Fun=3)
		Hotkey, %BoundHotkey%, Set_English
	If (Hotkey_Fun=4)
		Hotkey, %BoundHotkey%, toggle_CN_CNEN
	If (Hotkey_Fun=5)
		Hotkey, %BoundHotkey%, toggle_CN_EN
}

ExitFunc(){ ;退出执行
	DllCall( "SystemParametersInfo", "UInt",0x57, "UInt",0, "UInt",0, "UInt",0 ) ;还原鼠标指针
}

;-----------------------------------【接收消息功能】-----------------------------------------------
Receive_WM_COPYDATA(ByRef wParam,ByRef lParam){
    StringAddress := NumGet(lParam + 2*A_PtrSize)  ; 获取 CopyDataStruct 的 lpData 成员.
    CopyOfData := StrGet(StringAddress)  ; 从结构中复制字符串.
    Remote_Dyna_Run(CopyOfData)
    return 1  ; 返回 1(true) 是回复此消息的传统方式.
}

;~;[外部动态运行函数和插件]
Remote_Dyna_Run(remoteRun){
	if(IsLabel(remoteRun)){
		Gosub,%remoteRun%
		return
	}
}

Send_WM_COPYDATA(ByRef StringToSend, ByRef TargetScriptTitle, wParam:=0){
    VarSetCapacity(CopyDataStruct, 3*A_PtrSize, 0)  ; 分配结构的内存区域.
    ; 首先设置结构的 cbData 成员为字符串的大小, 包括它的零终止符:
    SizeInBytes := (StrLen(StringToSend) + 1) * (A_IsUnicode ? 2 : 1)
    NumPut(SizeInBytes, CopyDataStruct, A_PtrSize)  ; 操作系统要求这个需要完成.
    NumPut(&StringToSend, CopyDataStruct, 2*A_PtrSize)  ; 设置 lpData 为到字符串自身的指针.
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows On
    SetTitleMatchMode 2
    TimeOutTime := 4000  ; 可选的. 等待 receiver.ahk 响应的毫秒数. 默认是 5000
    ; 必须使用发送 SendMessage 而不是投递 PostMessage.
    SendMessage, 0x004A, %wParam%, &CopyDataStruct,, %TargetScriptTitle%  ; 0x004A 为 WM_COPYDAT
    DetectHiddenWindows %Prev_DetectHiddenWindows%  ; 恢复调用者原来的设置.
    SetTitleMatchMode %Prev_TitleMatchMode%         ; 同样.
    return ErrorLevel  ; 返回 SendMessage 的回复给我们的调用者.
}