/*tong(【自动切换输入法】)
	脚本: KBLAutoSwitch自动切换输入法
	作者: tong
*/

Label_ScriptSetting: ; 脚本前参数设置
	Process, Priority, , Realtime					;脚本高优先级
	#MenuMaskKey vkE8
	#Persistent										;让脚本持久运行(关闭或ExitApp)
	#SingleInstance Force							;允许多例运行，通过Single_Run限制单例
	#WinActivateForce								;强制激活窗口
	#MaxHotkeysPerInterval 2000						;时间内按热键最大次数
	#HotkeyModifierTimeout 100						;按住modifier后(不用释放后再按一次)可隐藏多个当前激活窗口
	SetBatchLines, -1								;脚本全速执行
	SetControlDelay -1								;控件修改命令自动延时,-1无延时，0最小延时
	CoordMode Menu Window							;坐标相对活动窗口
	CoordMode Mouse Screen							;鼠标坐标相对于桌面(整个屏幕)
	ListLines, Off									;不显示最近执行的脚本行
	SendMode Input									;更速度和可靠方式发送键盘点击
	SetTitleMatchMode 2								;窗口标题模糊匹配;RegEx正则匹配
	DetectHiddenWindows on							;显示隐藏窗口
	SetWorkingDir, %A_ScriptDir%
	global root:=RTrim(GetAbsPath(A_WorkingDir "\..\"), "\")

	StartTick:=A_TickCount ; 启动时间

Label_DefVar: ; 初始化变量
	global ScriptIniting := 1 ; 脚本初始化中
	global AutoSwitchFrequency := 0 ; 自动切换次数统计
	global INI := A_ScriptDir "\KBLAutoSwitch.ini" ; 配置文件
	global APPName := "KBLAutoSwitch"
	global APPVersion := "2.3.3"
	global APPType := RegExMatch(APPVersion, "\d*\.\d*\.\d*\.\d*")?"（测试版）":"",APPVersion := APPVersion APPType
	; 固定变量初始化
	global State_ShowTime := 1000 ; 信息提示时间
	global FontType := "Microsoft YaHei" ; 字体类型
	global CN_Code:=0x804,EN_Code:=0x409 ; KBL代码
	global Display_Cn := "中",Display_CnEn := "英",Display_En := "En" ; KBL提示信息
	global Auto_Reload_MTime:=2000 ; 自动重载时间
	; 创建INI配置文件参数变量
	global Auto_Launch,Launch_Admin,Auto_Switch,Default_Keyboard
	global TT_OnOff_Style,TT_Display_Time,TT_Font_Size,TT_Transparency,TT_Shift,TT_Pos_Coef
	global Tray_Display,Tray_Display_KBL,Tray_Double_Click,Tray_Display_Style
	global Disable_HotKey_App_List,Disable_Switch_App_List,Disable_TTShow_App_List,No_TwiceSwitch_App_List,FocusControl_App_List
	global Cur_Launch,Cur_Launch_Style,Cur_Size
	global Hotkey_Add_To_Cn,Hotkey_Add_To_CnEn,Hotkey_Add_To_En,Hotkey_Remove_From_All
	global Hotkey_Set_Chinese,Hotkey_Set_ChineseEnglish,Hotkey_Set_English,Hotkey_Display_KBL,Hotkey_Reset_KBL,Hotkey_Toggle_CN_CNEN,Hotkey_Toggle_CN_EN
	global Hotkey_Stop_KBLAS,Hotkey_Get_KeyBoard
	global Hotkey_Left_Shift,Hotkey_Right_Shift,Hotkey_Left_Ctrl,Hotkey_Right_Ctrl,Hotkey_Left_Alt,Hotkey_Right_Alt
	global Open_Ext,Outer_InputKey_Compatible,Left_Mouse_ShowKBL,Left_Mouse_ShowKBL_Up,SetTimer_Reset_KBL,Reset_CapsLock,Enter_Inputing_Content,GuiTTColor,TrayTipContent
	global Custom_Win_Group,Custom_Hotstring
	global INI_CN,INI_CNEN,INI_EN

Label_AdminLaunch: ; 管理员启动
	iniread, Launch_Admin, %INI%, 基本设置, 管理员启动, 1
	if (!A_IsAdmin && Launch_Admin=1)
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

Label_SystemVersion: ; 获取win系统版本
	global OSVersion := StrReplace(A_OSVersion, ".")
	If (OSVersion="WIN_7")
		OSVersion := 7
	Else If (OSVersion<10022000)
		OSVersion := 10
	Else If (OSVersion>=10022000)
		OSVersion := 11
	Else
		OSVersion := 0

Label_WindowsMonitor: ; 获取windows显示器信息
	OnMessage(0x007E, "monitorChange")
	SysGet, MonitorCount, MonitorCount
	global MonitorAreaObjects := Object()
	Loop, %MonitorCount%
	{
	    SysGet, Monitor, Monitor, %A_Index%
	    MonitorAreaObject := Object()
	    MonitorAreaObject[1] := MonitorLeft
	    MonitorAreaObject[2] := MonitorTop
	    MonitorAreaObject[3] := MonitorRight
	    MonitorAreaObject[4] := MonitorBottom
	    MonitorAreaObject[5] := Abs(MonitorRight-MonitorLeft)<Abs(MonitorBottom-MonitorTop)?Abs(MonitorRight-MonitorLeft):Abs(MonitorBottom-MonitorTop)
	    MonitorAreaObjects[A_Index] := MonitorAreaObject
	}

Label_SystemVersion_Var: ; 设置win系统版本对应变量
	global Ico_path := Object()
	global Ico_num := Object()
	If (OSVersion=10){
		Ico_path["关闭菜单"] := "imageres.dll",Ico_num["关闭菜单"] := 233
		Ico_path["帮助文档"] := "imageres.dll",Ico_num["帮助文档"] := 100
		Ico_path["语言首选项"] := "imageres.dll",Ico_num["语言首选项"] := 110
		Ico_path["设置"] := "shell32.dll",Ico_num["设置"] := 317
		Ico_path["关于"] := "imageres.dll",Ico_num["关于"] := 77
		Ico_path["停止"] := "imageres.dll",Ico_num["停止"] := 208
		Ico_path["重启"] := "imageres.dll",Ico_num["重启"] := 229
		Ico_path["退出"] := "imageres.dll",Ico_num["退出"] := 230
	}Else If (OSVersion=11){
		Ico_path["关闭菜单"] := "imageres.dll",Ico_num["关闭菜单"] := 234
		Ico_path["帮助文档"] := "imageres.dll",Ico_num["帮助文档"] := 110
		Ico_path["语言首选项"] := "imageres.dll",Ico_num["语言首选项"] := 110
		Ico_path["设置"] := "shell32.dll",Ico_num["设置"] := 315
		Ico_path["关于"] := "imageres.dll",Ico_num["关于"] := 77
		Ico_path["停止"] := "imageres.dll",Ico_num["停止"] := 208
		Ico_path["重启"] := "imageres.dll",Ico_num["重启"] := 230
		Ico_path["退出"] := "imageres.dll",Ico_num["退出"] := 231
	}Else If (OSVersion=7){
		Ico_path["关闭菜单"] := "imageres.dll",Ico_num["关闭菜单"] := 102
		Ico_path["帮助文档"] := "imageres.dll",Ico_num["帮助文档"] := 110
		Ico_path["语言首选项"] := "imageres.dll",Ico_num["语言首选项"] := 110
		Ico_path["设置"] := "imageres.dll",Ico_num["设置"] := 64
		Ico_path["关于"] := "imageres.dll",Ico_num["关于"] := 77
		Ico_path["停止"] := "imageres.dll",Ico_num["停止"] := 207
		Ico_path["重启"] := "shell32.dll",Ico_num["重启"] := 239
		Ico_path["退出"] := "shell32.dll",Ico_num["退出"] := 216
	}Else If (OSVersion=0){
		Ico_path["关闭菜单"] := "shell32.dll",Ico_num["关闭菜单"] := 3
		Ico_path["帮助文档"] := "shell32.dll",Ico_num["帮助文档"] := 3
		Ico_path["语言首选项"] := "shell32.dll",Ico_num["语言首选项"] := 3
		Ico_path["设置"] := "shell32.dll",Ico_num["设置"] := 3
		Ico_path["关于"] := "shell32.dll",Ico_num["关于"] := 3
		Ico_path["停止"] := "shell32.dll",Ico_num["停止"] := 3
		Ico_path["重启"] := "shell32.dll",Ico_num["重启"] := 3
		Ico_path["退出"] := "shell32.dll",Ico_num["退出"] := 3
	}

Label_KBLDetect: ; 从注册表检测KBL
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

Label_ReadINI: ; 读取INI配置文件
	if !FileExist(INI)
		Gosub,Label_Init_INI

	; 读取基本设置
	iniread, Auto_Launch, %INI%, 基本设置,开机自启, 0
	iniread, Auto_Switch, %INI%, 基本设置, 自动切换, 1
	iniread, Default_Keyboard, %INI%, 基本设置, 默认输入法, 1

	iniread, TT_OnOff_Style, %INI%, 基本设置, 切换提示, 4
	iniread, TT_Display_Time, %INI%, 基本设置, 切换提示时间, 1500
	iniread, TT_Font_Size, %INI%, 基本设置, 切换提示文字大小, 15,30
	iniread, TT_Transparency, %INI%, 基本设置, 切换提示透明度, 235,180
	iniread, TT_Shift, %INI%, 基本设置, 切换提示偏移, 0,0
	iniread, TT_Pos_Coef, %INI%, 基本设置, 切换提示固定位置, 50,30

	iniread, Tray_Display, %INI%, 基本设置,托盘图标显示, 1
	iniread, Tray_Double_Click, %INI%, 基本设置,托盘图标双击, 2
	iniread, Tray_Display_KBL, %INI%, 基本设置,托盘图标显示输入法, 1
	iniread, Tray_Display_Style, %INI%, 基本设置,托盘图标样式, 原版
	iniread, Cur_Launch, %INI%, 基本设置,鼠标指针显示输入法, 1
	iniread, Cur_Launch_Style, %INI%, 基本设置,鼠标指针样式, 原版
	iniread, Cur_Size, %INI%, 基本设置,鼠标指针对应分辨率, 0

	; 读取屏蔽窗口列表
	iniread, Disable_HotKey_App_List, %INI%, 热键屏蔽窗口列表
	iniread, Disable_Switch_App_List, %INI%, 切换屏蔽窗口列表
	iniread, Disable_TTShow_App_List, %INI%, 切换提示屏蔽窗口列表
	iniread, No_TwiceSwitch_App_List, %INI%, 二次切换屏蔽窗口列表
	iniread, FocusControl_App_List, %INI%, 焦点控件切换窗口列表

	; 读取热键
	iniread, Hotkey_Add_To_Cn, %INI%, 热键设置,添加至中文窗口, %A_Space%
	iniread, Hotkey_Add_To_CnEn, %INI%, 热键设置,添加至英文(中文)窗口, %A_Space%
	iniread, Hotkey_Add_To_En, %INI%, 热键设置,添加至英文输入法窗口, %A_Space%
	iniread, Hotkey_Remove_From_All, %INI%, 热键设置,移除从中英文窗口, %A_Space%

	iniread, Hotkey_Set_Chinese, %INI%, 热键设置,切换中文, %A_Space%
	iniread, Hotkey_Set_ChineseEnglish, %INI%, 热键设置,切换英文(中文), %A_Space%
	iniread, Hotkey_Set_English, %INI%, 热键设置,切换英文输入法, %A_Space%
	iniread, Hotkey_Toggle_CN_CNEN, %INI%, 热键设置,切换中英文(中文), %A_Space%
	iniread, Hotkey_Toggle_CN_EN, %INI%, 热键设置,切换中英文输入法, %A_Space%
	iniread, Hotkey_Display_KBL, %INI%, 热键设置,显示当前输入法, %A_Space%
	iniread, Hotkey_Reset_KBL, %INI%, 热键设置,重置当前输入法, %A_Space%
	iniread, Hotkey_Stop_KBLAS, %INI%, 热键设置,停止自动切换, %A_Space%
	iniread, Hotkey_Get_KeyBoard, %INI%, 热键设置,获取输入法IME代码, %A_Space%

	; 读取特殊热键
	iniread, Hotkey_Left_Shift, %INI%, 特殊热键,左Shift, 1
	iniread, Hotkey_Right_Shift, %INI%, 特殊热键,右Shift, 2
	iniread, Hotkey_Left_Ctrl, %INI%, 特殊热键,左Ctrl, 0
	iniread, Hotkey_Right_Ctrl, %INI%, 特殊热键,右Ctrl, 0
	iniread, Hotkey_Left_Alt, %INI%, 特殊热键,左Alt, 0
	iniread, Hotkey_Right_Alt, %INI%, 特殊热键,右Alt, 0
	
	; 读取高级设置
	iniread, Open_Ext, %INI%, 高级设置, 内部关联, %A_Space%
	iniread, Outer_InputKey_Compatible, %INI%, 高级设置, 快捷键兼容, 1
	iniread, Left_Mouse_ShowKBL, %INI%, 高级设置, 左键点击输入位置显示输入法状态, 1|全局窗口
	iniread, Left_Mouse_ShowKBL_Up, %INI%, 高级设置, 左键弹起后提示输入法状态生效窗口, Code.exe
	iniread, SetTimer_Reset_KBL, %INI%, 高级设置, 定时重置输入法, 60|编辑器
	iniread, Reset_CapsLock, %INI%, 高级设置, 切换重置大小写, 1
	iniread, Enter_Inputing_Content, %INI%, 高级设置, 上屏字符内容, 2|1
	iniread, GuiTTColor, %INI%, 高级设置, 提示颜色, 333434|dfe3e3|02ecfb|ff0000
	iniread, TrayTipContent, %INI%, 高级设置, 托盘提示内容, %A_Space%

	; 读取自定义窗口组和自定义操作
	iniread, Custom_Win_Group, %INI%, 自定义窗口组
	iniread, Custom_Hotstring, %INI%, 自定义操作
	
	; 读取分组
	iniread, INI_CN, %INI%, 中文窗口
	IniRead, INI_CNEN, %INI%, 英文窗口
	IniRead, INI_EN, %INI%, 英文输入法窗口

	; 设置自定义窗口组
	global WinMenuObj := Object()
	global Custom_Win_Group_Cn,Custom_Win_Group_CnEn,Custom_Win_Group_En
	global groupNameList := "无",groupNameObj := Object(),groupNumObj := Object()
	groupNameObj["无"] := 0
	groupNumObj[0] := "无"
	Loop, parse, Custom_Win_Group, `n, `r
	{
		MyVar := StrSplit(Trim(A_LoopField), "=")
		groupNum := MyVar[1]
		groupName := MyVar[2]
		groupState := MyVar[3]
		groupVal := MyVar[4]			
		groupNameList .= "|" groupName
		groupNameObj[groupName] := groupNum
		groupNumObj[groupNum] := groupName
		getINISwitchWindows(groupVal,groupName,"|")
		If (Auto_Switch=1){ ; 添加自定组到自动切换组
			Switch groupState
			{
				Case 1:GroupAdd, cn_ahk_group_custom, ahk_group%A_Space%%groupName%
				Case 2:GroupAdd, cnen_ahk_group_custom, ahk_group%A_Space%%groupName%
				Case 3:GroupAdd, en_ahk_group_custom, ahk_group%A_Space%%groupName%
			}
		}
	}

	; 设置自动切换输入法窗口组
If (Auto_Switch=1) {
	getINISwitchWindows(INI_CN,"cn_ahk_group") ; 中文输入法中文模式窗口
	getINISwitchWindows(INI_CNEN,"cnen_ahk_group")  ; 中文输入法英文文模式窗口
	If (KBLEnglish_Exist=0)
		getINISwitchWindows(INI_EN,"cnen_ahk_group") ; 英文输入法窗口
	Else
		getINISwitchWindows(INI_EN,"en_ahk_group") ; 英文输入法窗口
	;-------------------------------------------------------
	; 不切换窗口组
	GroupAdd, unswitch_ahk_group, ahk_class tooltips_class32 ; 任务栏小箭头
	GroupAdd, unswitch_ahk_group_after, ahk_class Qt5QWindowToolSaveBits
	GroupAdd, unswitch_ahk_group_after, ahk_class Windows.UI.Core.CoreWindow
	GroupAdd, unswitch_ahk_group_after, ahk_exe HipsTray.exe
	GroupAdd, unswitch_ahk_group_after, ahk_exe rundll32.exe
	GroupAdd, unswitch_ahk_group_before, ahk_class MultitaskingViewFrame ; alt+tab切换
	GroupAdd, unswitch_ahk_group_before, ahk_class TaskListThumbnailWnd ; 窗口缩略图
	GroupAdd, unswitch_ahk_group_before, ahk_class Shell_TrayWnd ; 任务栏
	GroupAdd, unswitch_ahk_group_before, ahk_class NotifyIconOverflowWindow ; 任务栏小箭头
}
	; 默认焦点控件窗口
	GroupAdd, focus_control_ahk_group, ahk_exe ApplicationFrameHost.exe ; uwp应用
	GroupAdd, focus_control_ahk_group, ahk_exe explorer.exe ; 文件资源管理器
	
	; 获取输入光标位置sleep组
	GroupAdd, GetCaretSleep_ahk_group, ahk_class Chrome_WidgetWin_1 ; Chromium类应用
	
	; 输入法输入候选窗口
	GroupAdd, IMEInput_ahk_group, ahk_class SoPY_Comp			; 搜狗输入法
	GroupAdd, IMEInput_ahk_group, ahk_class SoWB_Comp			; 搜狗五笔输入法
	GroupAdd, IMEInput_ahk_group, ahk_class QQWubiCompWndII		; QQ五笔输入法
	GroupAdd, IMEInput_ahk_group, ahk_class QQPinyinCompWndTSF	; QQ拼音输入法
	GroupAdd, IMEInput_ahk_group, ahk_class PalmInputUICand 	; 手心输入法
	GroupAdd, IMEInput_ahk_group, ahk_class i)^ATL: 			; 冰凌五笔输入法


Label_DisableAppList: ; 读取屏蔽窗口列表
	getINISwitchWindows(Disable_HotKey_App_List,"DisableHotKeyAppList_ahk_group") ; 热键屏蔽
	getINISwitchWindows(Disable_Switch_App_List,"DisableSwitchAppList_ahk_group") ; 切换屏蔽
	getINISwitchWindows(Disable_TTShow_App_List,"DisableTTShowAppList_ahk_group") ; 切换提示屏蔽
	getINISwitchWindows(No_TwiceSwitch_App_List,"NoTwiceSwitchAppList_ahk_group") ; 二次切换屏蔽窗口列表
	getINISwitchWindows(FocusControl_App_List,"focus_control_ahk_group")
Label_Hotstring: ; 自定义操作
	global TarFunList := Object(),TarHotFunFlag := 0
	Loop, parse, Custom_Hotstring, `n, `r
	{
		MyVar := StrSplit(Trim(A_LoopField), "=")
		TargroupName := groupNumObj[MyVar[2]]
		TarHotFlag := SubStr(MyVar[3], 1, 2)
		TarHotVal := SubStr(MyVar[3], 3)
		Hotkey, IfWinActive, ahk_group%A_Space%%TargroupName%
		Loop, parse, TarHotVal, "|"
		{
			TarFunList[A_LoopField] := MyVar[4]
			If (TarHotFlag="s-")
				Hotstring(":*XB0:" A_LoopField, "TarHotFun")
			Else If (TarHotFlag="k-")
				try Hotkey, %A_LoopField%, TarHotFun
		}
	}

Label_ReadExtRunList: ; 读取内部关联
	If (Open_Ext!=""){
		global openExtRunList := Object() ; 内部关联路径加参数
    	global openExtRunList_Parm := Object() ; 内部关联参数
    	global openExtRunList_num := ReadExtRunList(Open_Ext,"ini|folder") ; 读取内部关联返回数量
	}  

Label_IcoLaunch: ; 根据Win明暗主题设置图标所在路径
	Gosub, Label_ReadExistIcoStyles
	global SystemUsesLightTheme
	RegRead, SystemUsesLightTheme, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
	SystemUsesLightTheme_Str := SystemUsesLightTheme=0?"black":"white"
	If (Tray_Display=1 && Tray_Display_KBL=1){
		ACNico_path = %A_ScriptDir%\Icos\%Tray_Display_Style%\%SystemUsesLightTheme_Str%_A_CN.ico
		AENico_path = %A_ScriptDir%\Icos\%Tray_Display_Style%\%SystemUsesLightTheme_Str%_A_EN.ico
		CNico_path = %A_ScriptDir%\Icos\%Tray_Display_Style%\%SystemUsesLightTheme_Str%_Cn.ico
		CNENico_path = %A_ScriptDir%\Icos\%Tray_Display_Style%\%SystemUsesLightTheme_Str%_CnEn.ico
		ENico_path = %A_ScriptDir%\Icos\%Tray_Display_Style%\%SystemUsesLightTheme_Str%_En.ico	
		global ACNIcon := LoadPicture(ACNico_path,,ImageType)
		global AENIcon := LoadPicture(AENico_path,,ImageType)
		global CNIcon := LoadPicture(CNico_path,,ImageType)
		global CNENIcon := LoadPicture(CNENico_path,,ImageType)
		global ENIcon := LoadPicture(ENico_path,,ImageType)
	}

Label_CurLaunch: ; 鼠标指针初始化
	Gosub, Label_ReadExistCurStyles
	global ExistCurSize := "" ; 鼠标指针分辨率字符串
	Loop Files, %A_ScriptDir%\Curs\%Cur_Launch_Style%\*, D
		ExistCurSize := ExistCurSize "|" A_LoopFileName
	If (Cur_Launch=1){
		global OCR_IBEAM := 32513,OCR_NORMAL := 32512,OCR_APPSTARTING := 32650,OCR_WAIT := 32514,OCR_HAND := 32649
		global OCR_CROSS:=32515,OCR_HELP:=32651,OCR_NO:=32648,OCR_UP:=32516
		global OCR_SIZEALL:=32646,OCR_SIZENESW:=32643,OCR_SIZENS:=32645,OCR_SIZENWSE:=32642,OCR_SIZEWE:=32644
		global 	CurPathObjs := Object()
		Loop, % MonitorAreaObjects.Length(){
			WindowsHeight := MonitorAreaObjects[A_Index][5]
			realWindowsHeight := WindowsHeight
			If (!FileExist(A_ScriptDir "\Curs\" Cur_Launch_Style "\" realWindowsHeight)){
				Loop, parse, ExistCurSize, |
				{
					If (A_Index=1)
						Continue
					Else If (A_Index=2)
						realWindowsHeight := A_LoopField
					Else
						realWindowsHeight := Abs(A_LoopField-WindowsHeight)<Abs(WindowsHeight-realWindowsHeight)?A_LoopField:realWindowsHeight
				}
			}
			If (Cur_Size!=0)
				realWindowsHeight := Cur_Size
			MonitorAreaObjects[A_Index][5] := realWindowsHeight
			CurPathObjs[MonitorAreaObjects[A_Index][5]] := 1
		}
		For k, v in CurPathObjs{
			CurPathObj := Object()
			CurPathObj[1] := getCurPath(Cur_Launch_Style,k,"IBEAM_Cn_A")
			CurPathObj[2] := getCurPath(Cur_Launch_Style,k,"IBEAM_En_A")
			CurPathObj[3] := getCurPath(Cur_Launch_Style,k,"IBEAM_Cn")
			CurPathObj[4] := getCurPath(Cur_Launch_Style,k,"IBEAM_En")
			CurPathObj[5] := getCurPath(Cur_Launch_Style,k,"NORMAL_Cn_A")
			CurPathObj[6] := getCurPath(Cur_Launch_Style,k,"NORMAL_En_A")
			CurPathObj[7] := getCurPath(Cur_Launch_Style,k,"NORMAL_Cn")
			CurPathObj[8] := getCurPath(Cur_Launch_Style,k,"NORMAL_En")
			CurPathObj[9] := getCurPath(Cur_Launch_Style,k,"APPSTARTING")
			CurPathObj[10] := getCurPath(Cur_Launch_Style,k,"WAIT")
			CurPathObj[11] := getCurPath(Cur_Launch_Style,k,"HAND")
			
			CurPathObj[12] := getCurPath(Cur_Launch_Style,k,"CROSS")
			CurPathObj[13] := getCurPath(Cur_Launch_Style,k,"HELP")
			CurPathObj[14] := getCurPath(Cur_Launch_Style,k,"NO")
			CurPathObj[15] := getCurPath(Cur_Launch_Style,k,"UP")

			CurPathObj[16] := getCurPath(Cur_Launch_Style,k,"SIZEALL")
			CurPathObj[17] := getCurPath(Cur_Launch_Style,k,"SIZENESW")
			CurPathObj[18] := getCurPath(Cur_Launch_Style,k,"SIZENS")
			CurPathObj[19] := getCurPath(Cur_Launch_Style,k,"SIZENWSE")
			CurPathObj[20] := getCurPath(Cur_Launch_Style,k,"SIZEWE")
			
			CurPathObjs[k] := CurPathObj
		}
	}

Label_AutoRun: ; 判断是否开机自启
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

Label_NecessaryVar:	; 定义必要变量
	global lastKBLCode56,LastKBLState56 ; 切换输入法标志
	global shellMessageFlag := 1 ; 窗口切换标志
	global NextChangeFlag := 0 ; 下次切换标志
	global SwitchTT_id,TT_Edit_Hwnd,TT_Edit_Hwnd1 ; Gui和控件句柄
	global LastKBLState,LastCapsState,LastMonitorNum,gl_Active_IMEwin_id ; 前一个KBL、大小写、屏幕编号状态，及激活窗口IME句柄
	GuiTTColorObj := StrSplit(GuiTTColor, "|") ; Gui颜色
	global GuiTTBackCnColor:=GuiTTColorObj[1],GuiTTBackEnColor:=GuiTTColorObj[2],GuiTTCnColor:=GuiTTColorObj[3],GuiTTEnColor:=GuiTTColorObj[4]
	Enter_Inputing_ContentObj := StrSplit(Enter_Inputing_Content, "|")
	global Enter_Inputing_Content_Core := Enter_Inputing_ContentObj[1],Enter_Inputing_Content_CnTo := Enter_Inputing_ContentObj[2]
	global ImmGetDefaultIMEWnd := DllCall("GetProcAddress", "Ptr", DllCall("LoadLibrary", "Str", "imm32", "Ptr"), "AStr", "ImmGetDefaultIMEWnd", "Ptr")
	
	; 自定义变量
	global 启动时间 := A_YYYY "/" A_MM "/" A_DD "  " A_Hour ":" A_Min ":" A_Sec
	global 权限 := A_IsAdmin=1?"管理员":"非管理员"
	global 版本 := APPVersion
	global 启动时长 := 0

Label_DropDownListData: ; 下拉列表数据
	global OnOffState := "禁止|开启"
	global KBLSwitchState := "无|中文|英文(中文)|英文"
	global TrayFuncState := "无|语言首选项|设置|停止"
	global OperationState := "无|切换至中文|切换至英文(中文)|切换至英文输入法|切换中英文(中文)|切换中英文输入法|重置输入法"
	global ListViewKBLState := "无|中|英(中)|英"
	global DefaultCapsLockState := "无|小写|大写"

Label_Init: ; 初始化操作
	Gosub, Label_Init_ShowKBLGui ; 初始化切换显示GUI
	Gosub, Label_Init_ResetINI ; 定时检测配置文件
	
Label_Left_Mouse_ShowKBL: ; 左键显示输入法
	StrSplit(Left_Mouse_ShowKBL,"|",,2)
	Left_Mouse_ShowKBL_temp := StrSplit(Left_Mouse_ShowKBL,"|",,2)
	Left_Mouse_ShowKBL_State := Left_Mouse_ShowKBL_temp[1]
	getINISwitchWindows(Left_Mouse_ShowKBL_temp[2],"Left_Mouse_ShowKBL_WinGroup","|")
	Hotkey, IfWinActive, ahk_group Left_Mouse_ShowKBL_WinGroup
	If (Left_Mouse_ShowKBL_State=1 && TT_OnOff_Style!=0){
		Hotkey, ~LButton, Label_Click_showSwitch
		Hotkey, ~WheelUp, Label_Hide_All
		Hotkey, ~WheelDown, Label_Hide_All
	}
	getINISwitchWindows(Left_Mouse_ShowKBL_Up,"Left_Mouse_ShowKBL_Up_WinGroup","|")

Label_CreateHotkey:	; 创建热键
	Hotkey, IfWinNotActive, ahk_group DisableHotKeyAppList_ahk_group
	if (Hotkey_Add_To_Cn != "")
		Hotkey, %Hotkey_Add_To_Cn%, Add_To_Cn
	if (Hotkey_Add_To_CnEn != "")
		Hotkey, %Hotkey_Add_To_CnEn%, Add_To_CnEn
	if (Hotkey_Add_To_En != "")
		Hotkey, %Hotkey_Add_To_En%, Add_To_En
	if (Hotkey_Remove_From_All != "")
		Hotkey, %Hotkey_Remove_From_All%, Remove_From_All

	if (Hotkey_Set_Chinese != ""){
		TarFunList[Hotkey_Set_Chinese] := 1
		try Hotkey, %Hotkey_Set_Chinese%, TarHotFun
	}
	if (Hotkey_Set_ChineseEnglish != ""){
		TarFunList[Hotkey_Set_ChineseEnglish] := 2
		try Hotkey, %Hotkey_Set_ChineseEnglish%, TarHotFun
	}
	if (Hotkey_Set_English != ""){
		TarFunList[Hotkey_Set_English] := 3
		try Hotkey, %Hotkey_Set_English%, TarHotFun
	}
	if (Hotkey_Toggle_CN_CNEN != ""){
		TarFunList[Hotkey_Toggle_CN_CNEN] := 4
		try Hotkey, %Hotkey_Toggle_CN_CNEN%, TarHotFun
	}
	if (Hotkey_Toggle_CN_EN != ""){
		TarFunList[Hotkey_Toggle_CN_EN] := 5
		try Hotkey, %Hotkey_Toggle_CN_EN%, TarHotFun
	}
	if (Hotkey_Reset_KBL != ""){
		TarFunList[Hotkey_Reset_KBL] := 6
		try Hotkey, %Hotkey_Reset_KBL%, TarHotFun
	}

	if (Hotkey_Display_KBL != "")
		Hotkey, %Hotkey_Display_KBL%, Display_KBL
	if (Hotkey_Stop_KBLAS != "")
		Hotkey, %Hotkey_Stop_KBLAS%, Stop_KBLAS
	if (Hotkey_Get_KeyBoard != "")
		Hotkey, %Hotkey_Get_KeyBoard%, Get_KeyBoard

Label_BoundHotkey: ; 绑定特殊热键
	If (Outer_InputKey_Compatible=1)
		extraKey := " Up"
	BoundHotkey("~LShift" extraKey,Hotkey_Left_Shift)
	BoundHotkey("~RShift" extraKey,Hotkey_Right_Shift)
	BoundHotkey("~LControl" extraKey,Hotkey_Left_Ctrl)
	BoundHotkey("~RControl" extraKey,Hotkey_Right_Ctrl)
	BoundHotkey("~LAlt" extraKey,Hotkey_Left_Alt)
	BoundHotkey("~RAlt" extraKey,Hotkey_Right_Alt)

Label_SetTimer: ; 定时器等功能
	If (KBLObj.Length()>1){ ; 定时KBL状态检测
		If (Tray_Display=1)
			try Gosub, Label_Create_Tray
		If ((Tray_Display=1 && Tray_Display_KBL=1) || Cur_Launch=1 || TT_OnOff_Style!=0){
			Gosub, Label_KBLState_Detect
			SetTimer, Label_KBLState_Detect, 100
		}
	}
	; 定时重置输入法
	SetTimer_Reset_KBL_temp := StrSplit(SetTimer_Reset_KBL,"|",,2)
	SetTimer_Reset_KBL_Time := SetTimer_Reset_KBL_temp[1]
	getINISwitchWindows(SetTimer_Reset_KBL_temp[2],"SetTimer_Reset_KBL_WinGroup","|")

	global Reset_CapsLock_State := SubStr(Reset_CapsLock, 1, 1)
	getINISwitchWindows(SubStr(Reset_CapsLock, 3),"Inner_AHKGroup_NoCapsLock","|")

Label_AutoSwitch: ; 监听窗口切换输入法
	DllCall("ChangeWindowMessageFilter", "UInt", 0x004A, "UInt" , 1) ; 接受非管理员权限RA消息
	If (Auto_Switch=1){ ; 监听窗口消息
		DllCall("RegisterShellHookWindow", UInt, A_ScriptHwnd)
		global shell_msg_num := DllCall("RegisterWindowMessage", Str, "SHELLHOOK")
		OnMessage(shell_msg_num, "shellMessage")		
		shellMessage(1,1)
	}
	OnMessage(0x004A, "Receive_WM_COPYDATA")

Label_End: ; 收尾工作
	OnExit("ExitFunc") ; 退出执行
	VarSetCapacity(Ico_path, 0)
	VarSetCapacity(Ico_num, 0)
	ScriptIniting := 0 ; 脚本初始化结束
	启动时长 := Round((A_TickCount-StartTick)/1000,3) " 秒"
	Gosub, Label_Change_TrayTip ; 更新托盘提示
	SetTimer,Label_ClearMEM,-1000 ; 清理内存

Label_Return: ; 结束标志
Return

Label_KBLState_Detect: ; 输入法状态检测
	showSwitch()
Return

Label_AutoReload_MTime: ; 定时重新加载脚本
	RegRead, mtime_ini_path_reg, HKEY_CURRENT_USER, Software\KBLAutoSwitch, %INI%
	FileGetTime, mtime_ini_path, %INI%, M  ; 获取修改时间.
	RegRead, SystemUsesLightTheme_new, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize, SystemUsesLightTheme
	if (mtime_ini_path_reg != mtime_ini_path || SystemUsesLightTheme_new != SystemUsesLightTheme){
		gosub, Menu_Reload
	}
	SystemUsesLightTheme := SystemUsesLightTheme_new
Return

Label_Init_ResetINI: ; 配置文件更改后自动重新加载配置文件
	FileGetTime, mtime_ini_path, %INI%, M  ; 获取修改时间.
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\KBLAutoSwitch, %INI%, %mtime_ini_path%
	if (Auto_Reload_MTime>0)
		SetTimer, Label_AutoReload_MTime, %Auto_Reload_MTime%
Return

Label_Init_ShowKBLGui: ; 创建输入法状态GUI
	If (TT_OnOff_Style!=0){
		TT_Transparency := StrReplace(TT_Transparency, "，", ",")
		TT_Transparency_Input := StrSplit(TT_Transparency, ",")[1]
		TT_Transparency_Fix := StrSplit(TT_Transparency, ",")[2]
		TT_Transparency_Fix := TT_Transparency_Fix=""?TT_Transparency_Input:TT_Transparency_Fix
		TT_Font_Size := StrReplace(TT_Font_Size, "，", ",")
		TT_Font_Size_Input := StrSplit(TT_Font_Size, ",")[1]
		TT_Font_Size_Fix := StrSplit(TT_Font_Size, ",")[2]
		TT_Font_Size_Fix := TT_Font_Size_Fix=""?TT_Font_Size_Input:TT_Font_Size_Fix	
		TT_Shift := StrReplace(TT_Shift, "，", ",")
		TT_Shift_X := StrSplit(TT_Shift, ",")[1]
		TT_Shift_Y := StrSplit(TT_Shift, ",")[2]
		TT_Shift_X := TT_Shift_X=""?0:TT_Shift_X,TT_Shift_Y := TT_Shift_Y=""?0:TT_Shift_Y
		TT_Pos_Coef := StrReplace(TT_Pos_Coef, "，", ",")
		global TT_Pos_Coef_X := StrSplit(TT_Pos_Coef, ",")[1]
		global TT_Pos_Coef_Y := StrSplit(TT_Pos_Coef, ",")[2]
		TT_Pos_Coef_X := TT_Pos_Coef_X=""?0:TT_Pos_Coef_X,TT_Pos_Coef_Y := TT_Pos_Coef_Y=""?0:TT_Pos_Coef_Y
		If (TT_OnOff_Style!=3){
			Gui, SwitchTT:Destroy
			Gui, SwitchTT:-SysMenu +ToolWindow +AlwaysOnTop -Caption -DPIScale +HwndSwitchTT_id +E0x20
			Gui, SwitchTT:Color, %GuiTTBackCnColor%
			Gui, SwitchTT:Font, c%GuiTTCnColor% s%TT_Font_Size_Input%, %FontType%
			Gui, SwitchTT:Add,Text, x18 y3 HwndTT_Edit_Hwnd Center, %Display_En%
			ControlGetPos, , , Text_W, Text_H, , ahk_id %TT_Edit_Hwnd%
			global TT_W := Text_W+18
			global TT_H := Text_H+8
			WinSet, Transparent,%TT_Transparency_Input%, ahk_id %SwitchTT_id%
			WinSet, Region, 10-0 W%TT_W% H%TT_H% R5-5, ahk_id %SwitchTT_id%
			global TT_Shift_X_Real:=TT_Shift_X-TT_W-12
			global TT_Shift_Y_Real:=TT_Shift_Y-2-TT_H
		}
		If (TT_OnOff_Style=3 || TT_OnOff_Style=4){
			Gui, SwitchTT1:Destroy
			Gui, SwitchTT1:-SysMenu +ToolWindow +AlwaysOnTop -Caption -DPIScale +HwndSwitchTT_id1 +E0x20
			Gui, SwitchTT1:Color, %GuiTTBackCnColor%
			Gui, SwitchTT1:Font, c%GuiTTCnColor% s%TT_Font_Size_Fix%, %FontType%
			Gui, SwitchTT1:Add,Text, x18 y3 HwndTT_Edit_Hwnd1 Center, %Display_En%
			ControlGetPos, , , Text_W, Text_H, , ahk_id %TT_Edit_Hwnd1%
			global TT_W1 := Text_W+18
			global TT_H1 := Text_H+8
			WinSet, Transparent,%TT_Transparency_Fix%, ahk_id %SwitchTT_id1%
			WinSet, Region, 10-0 W%TT_W1% H%TT_H1% R5-5, ahk_id %SwitchTT_id1%
		}
	}
Return

shellMessage(wParam, lParam) { ; 接受系统窗口回调消息切换输入法, 第一次是实时，第二次是保障
	If ( wParam=1 || wParam=32772 || wParam=5 || wParam=4) {
		Gosub, Label_KBLSwitch
	}Else If (wParam=56){
		NextChangeFlag := 1
		lastKBLCode56 := getIMEKBL(gl_Active_IMEwin_id)
		LastKBLState56 := (lastKBLCode56!=EN_Code?(getIMECode(gl_Active_IMEwin_id)!=0?0:1):2)
	}Else If (NextChangeFlag=1 && wParam=2){
		NextChangeFlag := 0
		KBLCode56 := getIMEKBL(gl_Active_IMEwin_id)
		If (KBLCode56=CN_Code && KBLCode56=lastKBLCode56 && LastKBLState56!=2)
			SetTimer, Label_KBLSwitch_LastKBLState56, -100
		Else If (KBLCode56=CN_Code && KBLCode56!=lastKBLCode56)
			SetTimer, Label_KBLSwitch_LastKBLState561, -100
		lastKBLCode56 := KBLCode56
	}
}
Label_KBLSwitch_LastKBLState561: ; 英文输入法切换到中文输入法时
	If WinActive("ahk_group cn_ahk_group"){ ;切换中文输入法
		setKBLlLayout(0,1)
	}Else If WinActive("ahk_group cnen_ahk_group"){ ;切换英文(中文)输入法
		setKBLlLayout(1,1)
	}Else If WinActive("ahk_group cn_ahk_group_custom"){ ;窗口组切换中文输入法
		setKBLlLayout(0,1)
	}Else If WinActive("ahk_group cnen_ahk_group_custom"){ ;窗口组切换英文(中文)输入法
		setKBLlLayout(1,1)
	}
Return

Label_KBLSwitch_LastKBLState56: ; 中文输入法切换到中文输入法时
	setKBLlLayout(LastKBLState56,1)
Return

Label_KBLSwitch: ; 切换输入法
	shellMessageFlag := 1
	SetTimer, Label_SetTimer_ResetshellMessageFlag,-500
	Gosub, Label_Shell_KBLSwitch
	If !WinActive("ahk_group NoTwiceSwitchAppList_ahk_group")
		SetTimer, Label_Shell_KBLSwitch, -100
Return

Label_SetTimer_ResetshellMessageFlag:
	shellMessageFlag := 0
Return

Label_Shell_KBLSwitch: ; 根据激活窗口切换输入法
	Critical On
	If (SetTimer_Reset_KBL_Time>0 && WinActive("ahk_group SetTimer_Reset_KBL_WinGroup")) ; 无操作定时重置输入法
		SetTimer, Label_SetTimer_ResetKBL, % SetTimer_Reset_KBL_Time*1000/60
	Else If (SetTimer_Reset_KBL_Time>0)
		SetTimer, Label_SetTimer_ResetKBL, Delete
	If WinActive("ahk_group unswitch_ahk_group") ;不进行切换的屏蔽程序
		Return
	If WinActive("ahk_group DisableSwitchAppList_ahk_group"){ ;不进行切换的屏蔽程序
		showSwitch()
	}Else If WinActive("ahk_group unswitch_ahk_group_before"){ ;没必要切换的窗口前，保证切换显示逻辑的正确
		setKBLlLayout(LastKBLState)
	}Else If WinActive("ahk_group cn_ahk_group"){ ;切换中文输入法
		setKBLlLayout(0,1)
	}Else If WinActive("ahk_group cnen_ahk_group"){ ;切换英文(中文)输入法
		setKBLlLayout(1,1)
	}Else If WinActive("ahk_group en_ahk_group"){ ;切换英文输入法
		setKBLlLayout(2,1)
	}Else If WinActive("ahk_group cn_ahk_group_custom"){ ;窗口组切换中文输入法
		setKBLlLayout(0,1)
	}Else If WinActive("ahk_group cnen_ahk_group_custom"){ ;窗口组切换英文(中文)输入法
		setKBLlLayout(1,1)
	}Else If WinActive("ahk_group en_ahk_group_custom"){ ;窗口组切换英文输入法
		setKBLlLayout(2,1)
	}Else If WinActive("ahk_group unswitch_ahk_group_after"){ ;没必要切换的窗口后，保证切换显示逻辑的正确
		setKBLlLayout(LastKBLState)
	}Else {
		setKBLlLayout(Default_Keyboard-1,1)
	}
	Critical Off
Return

getINISwitchWindows(INIVar:="",groupName:="",Delimiters:="`n") { ; 从配置文件读取切换窗口
	Loop, parse, INIVar, %Delimiters%, `r
	{
		MyVar := StrSplit(Trim(A_LoopField), "=")
		MyVar_Key := MyVar[1]
		MyVar_Val := MyVar[2]
		If (MyVar_Key="")
			continue
		If (MyVar_Val="")
			MyVar_Val := MyVar_Key
		prefix := SubStr(MyVar_Val, 1, 4)
		If (MyVar_Val="AllGlobalWin")
			GroupAdd, %groupName%
		Else If (groupNameObj.HasKey(MyVar_Val))
			GroupAdd, %groupName%, ahk_group%A_Space%%MyVar_Val%
		Else If (prefix="uwp "){
			uwp_app := SubStr(MyVar_Val, 5)
			GroupAdd, %groupName%, ahk_exe ApplicationFrameHost.exe, %uwp_app%
			GroupAdd, %groupName%, %uwp_app%
		}Else If (!InStr(MyVar_Val, A_Space) && SubStr(MyVar_Val, -3)=".exe")
	    	GroupAdd, %groupName%, ahk_exe %MyVar_Val%
	    Else
	    	GroupAdd, %groupName%, %MyVar_Val%
	}
}

showSwitch(KBLState:="",CapsLockState:="",ForceShowSwitch:=0) { ; 显示中英文状态（托盘图标、鼠标光标、Gui、TT）
	If (KBLState=""){
		gl_Active_IMEwin_id := getIMEwinid()
		LastKBLCode := getIMEKBL(gl_Active_IMEwin_id)
		KBLState := (LastKBLCode!=EN_Code?(getIMECode(gl_Active_IMEwin_id)!=0?0:1):2)
	}
	WinGetClass, class, A
	If (class="" || class="ForegroundStaging") ; alt+tab出现的ahk_class
		KBLState := LastKBLState
	If (CapsLockState="")
		CapsLockState := DllCall("GetKeyState", UInt, 20) & 1
	If (Cur_Size!=0)
		MonitorNum := 1
	Else{
		CoordMode, Mouse , Screen
		MouseGetPos, OutputVarX, OutputVarY
		MonitorNum := getMonitorNum(OutputVarX,OutputVarY)
	}
	Display_KBL_Flag := Object()
	If (ForceShowSwitch=0 && LastKBLState=KBLState && LastCapsState=CapsLockState && LastMonitorNum=MonitorNum)
		Return
	If (ForceShowSwitch!=0 || LastKBLState!=KBLState || LastCapsState!=CapsLockState){
		LastKBLState:=KBLState
		LastCapsState:=CapsLockState
		If (Display_KBL_Flag[1]!=1){
			Display_KBL_Flag[1]:=1
			TT_Display_KBL(KBLState,LastCapsState)
		}
		If (Display_KBL_Flag[2]!=1){
			Display_KBL_Flag[2]:=1
			Tray_Display_KBL(KBLState,CapsLockState)
		}
		If (Display_KBL_Flag[3]!=1){
			Display_KBL_Flag[3]:=1
			Cur_Display_KBL(KBLState,CapsLockState,MonitorNum)
		}
	}
	If (ForceShowSwitch!=0 && LastMonitorNum!=MonitorNum){
		LastMonitorNum := MonitorNum
		static 	LastMonitorW:=0
		If (Display_KBL_Flag[3]!=1 && LastMonitorW!=MonitorAreaObjects[MonitorNum][5]){
			Display_KBL_Flag[3]:=1
			LastMonitorW := MonitorAreaObjects[MonitorNum][5]
			Cur_Display_KBL(KBLState,CapsLockState,MonitorNum)
		}
	}

}

TT_Display_KBL(KBLState,CapsLockState) { ; 显示输入法状态-TT方式
	If (TT_OnOff_Style=0 || WinExist("ahk_class #32768") || WinActive("ahk_group DisableTTShowAppList_ahk_group")){
		Gosub, Label_Hide_All
		Return
	}
	KBLMsg := CapsLockState!=0?"A":KBLState=0?Display_Cn:KBLState=1?Display_CnEn:Display_En
	TT_Shift_flag := 0
	If (TT_OnOff_Style=1){
		MouseGetPos, CaretX, CaretY	
	}Else{
		If (TT_OnOff_Style=3){
			Caret := getDisplayPos(TT_Pos_Coef_X,TT_Pos_Coef_Y,TT_W1,TT_H1)
			CaretX := Caret["x"],CaretY := Caret["y"]
			TT_Shift_flag := 1
		}Else{
			GetCaret(CaretX, CaretY)
			If (TT_OnOff_Style=2 && A_Cursor="IBeam" && CaretX=0 && CaretY=0)
				MouseGetPos, CaretX, CaretY
			Else If (TT_OnOff_Style=4 && CaretX=0 && CaretY=0){
				Caret := getDisplayPos(TT_Pos_Coef_X,TT_Pos_Coef_Y,TT_W1,TT_H1)
				CaretX := Caret["x"],CaretY := Caret["y"]
				TT_Shift_flag := 1
			}
		}
	}
	If (TT_Shift_flag=0){
		Gui, SwitchTT1:Hide
		Gosub, Label_Change_SwitchTT
		CaretX := CaretX+TT_Shift_X_Real, CaretY := CaretY+TT_Shift_Y_Real
		try Gui, SwitchTT:Show, x%CaretX% y%CaretY% NoActivate
	}Else{
		Gui, SwitchTT:Hide
		Gosub, Label_Change_SwitchTT
		try Gui, SwitchTT1:Show, x%CaretX% y%CaretY% NoActivate
	}
	SetTimer, Hide_TT, %TT_Display_Time%
	Return

	Hide_TT: ;隐藏GUI
		SetTimer, Hide_TT, Off
		Gui, SwitchTT:Hide
		Gui, SwitchTT1:Hide
	Return

	Label_Change_SwitchTT: ; 更新SwitchTT
		If (KBLState=0){
			If (TT_OnOff_Style!=3){
				Gui, SwitchTT:Color, %GuiTTBackCnColor%
				Gui, SwitchTT:Font, c%GuiTTCnColor%, %FontType%
			}
			If (TT_OnOff_Style=3 || TT_OnOff_Style=4){
				Gui, SwitchTT1:Color, %GuiTTBackCnColor%
				Gui, SwitchTT1:Font, c%GuiTTCnColor%, %FontType%
			}
		}Else{
			If (TT_OnOff_Style!=3){
				Gui, SwitchTT:Color, %GuiTTBackEnColor%
				Gui, SwitchTT:Font, c%GuiTTEnColor%, %FontType%
			}
			If (TT_OnOff_Style=3 || TT_OnOff_Style=4){
				Gui, SwitchTT1:Color, %GuiTTBackEnColor%
				Gui, SwitchTT1:Font, c%GuiTTEnColor%, %FontType%
			}
		}
		If (TT_OnOff_Style!=3){
			GuiControl, Text, %TT_Edit_Hwnd%, %KBLMsg%
			GuiControl, Font, %TT_Edit_Hwnd%
			Gui SwitchTT:+AlwaysOnTop
		}
		If (TT_OnOff_Style=3 || TT_OnOff_Style=4){
			GuiControl, Text, %TT_Edit_Hwnd1%, %KBLMsg%
			GuiControl, Font, %TT_Edit_Hwnd1%
			Gui SwitchTT:+AlwaysOnTop
		}
	Return
}

Tray_Display_KBL(KBL_Flag:=0,CapsLock_Flag:=0) { ; 显示输入法状态-托盘图标方式
	If (Tray_Display=0){
		Menu, Tray, NoIcon
	}Else If (Tray_Display_KBL=0){
		Menu, Tray, Icon, %A_AhkPath%
	}Else{
		try{
			If (KBL_Flag=0)
				If (CapsLock_Flag=1)
					Menu, Tray, Icon, HICON:*%ACNIcon%
				Else
					Menu, Tray, Icon, HICON:*%CNIcon%
			Else If (KBL_Flag=1)
				If (CapsLock_Flag=1)
					Menu, Tray, Icon, HICON:*%AENIcon%
				Else
					Menu, Tray, Icon, HICON:*%CNENIcon%
			Else If (KBL_Flag=2)
				If (CapsLock_Flag=1)
					Menu, Tray, Icon, HICON:*%AENIcon%
				Else
					Menu, Tray, Icon, HICON:*%ENIcon%
		}		
	}
}

Cur_Display_KBL(KBL_Flag:=0,CapsLock_Flag:=0,MonitorNum:=0) { ; 显示输入法状态-鼠标光标方式
	If (Cur_Launch!=1)
		Return
	If (KBL_Flag=0){
		If (CapsLock_Flag = 1){
			Cur_IBEAM := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][1], "Ptr")
			Cur_NORMAL := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][5], "Ptr")
		}Else{	
			Cur_IBEAM := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][3], "Ptr")
			Cur_NORMAL := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][7], "Ptr")
		}
	}Else{
		If (CapsLock_Flag = 1){
			Cur_IBEAM := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][2], "Ptr")
			Cur_NORMAL := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][6], "Ptr")
		}Else{
			Cur_IBEAM := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][4], "Ptr")
			Cur_NORMAL := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][8], "Ptr")
		}
	}
	DllCall("SetSystemCursor", "Ptr", Cur_IBEAM, "Int", OCR_IBEAM)
	DllCall("SetSystemCursor", "Ptr", Cur_NORMAL, "Int", OCR_NORMAL)
	If (ScriptIniting=1){
		Cur_APPSTARTING := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][9], "Ptr")
		Cur_WAIT := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][10], "Ptr")
		Cur_HAND := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][11], "Ptr")
		Cur_CROSS := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][12], "Ptr")
		Cur_HELP := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][13], "Ptr")
		Cur_NO := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][14], "Ptr")
		Cur_UP := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][15], "Ptr")
		Cur_SIZEALL := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][16], "Ptr")
		Cur_SIZENESW := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][17], "Ptr")
		Cur_SIZENS := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][18], "Ptr")
		Cur_SIZENWSE := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][19], "Ptr")
		Cur_SIZEWE := DllCall("LoadCursorFromFile", "Str",CurPathObjs[MonitorAreaObjects[MonitorNum][5]][20], "Ptr")
		DllCall("SetSystemCursor", "Ptr", Cur_APPSTARTING, "Int", OCR_APPSTARTING)
		DllCall("SetSystemCursor", "Ptr", Cur_WAIT, "Int", OCR_WAIT)
		DllCall("SetSystemCursor", "Ptr", Cur_HAND, "Int", OCR_HAND)
		DllCall("SetSystemCursor", "Ptr", Cur_CROSS, "Int", OCR_CROSS)
		DllCall("SetSystemCursor", "Ptr", Cur_HELP, "Int", OCR_HELP)
		DllCall("SetSystemCursor", "Ptr", Cur_NO, "Int", OCR_NO)
		DllCall("SetSystemCursor", "Ptr", Cur_UP, "Int", OCR_UP)		
		DllCall("SetSystemCursor", "Ptr", Cur_SIZEALL, "Int", OCR_SIZEALL)
		DllCall("SetSystemCursor", "Ptr", Cur_SIZENESW, "Int", OCR_SIZENESW)
		DllCall("SetSystemCursor", "Ptr", Cur_SIZENS, "Int", OCR_SIZENS)
		DllCall("SetSystemCursor", "Ptr", Cur_SIZENWSE, "Int", OCR_SIZENWSE)
		DllCall("SetSystemCursor", "Ptr", Cur_SIZEWE, "Int", OCR_SIZEWE)
	}
}

getIMEwinid() { ; 获取激活窗口IME线程id
	If WinActive("ahk_class ConsoleWindowClass"){
		WinGet, win_id, , ahk_exe conhost.exe
	}Else If WinActive("ahk_group focus_control_ahk_group"){
		ControlGetFocus, CClassNN, A
		If (CClassNN = "")
			WinGet, win_id, , A
		Else
			ControlGet, win_id, Hwnd, , %CClassNN%
	}Else
		WinGet, win_id, , A
	IMEwin_id := DllCall(ImmGetDefaultIMEWnd, Uint, win_id, Uint)
	Return IMEwin_id
}

getIMEKBL(win_id:="") { ; 获取激活窗口键盘布局
	thread_id := DllCall("GetWindowThreadProcessId", "UInt", win_id, "UInt", 0)
	IME_State := DllCall("GetKeyboardLayout", "UInt", thread_id)
	Switch IME_State
	{
		Case 134481924:Return 2052
		Case 67699721:Return 1033
		Default:Return IME_State
	}
}

getIMECode(win_id:="") { ; 获取激活窗口键盘布局中英文状态
	SendMessage 0x283, 0x005, 0, , ahk_id %win_id%,,,,1000
	IME_Input_State := ErrorLevel
	If (IME_Input_State=1){		
		SendMessage 0x283, 0x001, 0, , ahk_id %win_id%,,,,1000
		IME_Input_State := 1&ErrorLevel
	}
	Return IME_Input_State
}

setIME(setSts, win_id:="") { ; 设置输入法状态-获取状态-末位设置
	SendMessage 0x283, 0x001, 0, , ahk_id %win_id%,,,,1000
	CONVERSIONMODE := 2046&ErrorLevel, CONVERSIONMODE += setSts
    SendMessage 0x283, 0x002, CONVERSIONMODE, , ahk_id %win_id%,,,,1000
    SendMessage 0x283, 0x006, setSts, , ahk_id %win_id%,,,,1000
    Return ErrorLevel
}

setKBLlLayout(KBL:=0,Source:=0) { ; 设置输入法键盘布局
	AutoSwitchFrequency += Source
	gl_Active_IMEwin_id := getIMEwinid()
	CapsLockState := LastCapsState
	If !WinActive("ahk_group Inner_AHKGroup_NoCapsLock") { ; 设置大小写
		Switch Reset_CapsLock_State
		{
			Case 1: SetCapsLockState, Off
			Case 2: SetCapsLockState, On
		}
		If (Reset_CapsLock_State>0)
			CapsLockState := Reset_CapsLock_State-1
	}
	LastKBLCode := getIMEKBL(gl_Active_IMEwin_id)
	If (KBL=0){ ; 切换中文输入法
		If (LastKBLCode=CN_Code){
			setIME(1,gl_Active_IMEwin_id)
		}Else{
			SendMessage, 0x50, , %CN_Code%, , ahk_id %gl_Active_IMEwin_id%,,,,1000
			Sleep,50
			setIME(1,gl_Active_IMEwin_id)
		}
	}Else If (KBL=1){ ; 切换英文(中文)输入法
		If (LastKBLCode=CN_Code){
			setIME(0,gl_Active_IMEwin_id)
		}Else{
			SendMessage, 0x50, , %CN_Code%, , ahk_id %gl_Active_IMEwin_id%,,,,1000
			Sleep,50
			setIME(0,gl_Active_IMEwin_id)
		}
	}Else If (KBL=2){ ; 切换英文输入法
		If (LastKBLCode!=EN_Code)
			PostMessage, 0x50, , %EN_Code%, , ahk_id %gl_Active_IMEwin_id%
	}
	try showSwitch(KBL,CapsLockState,1)
	SetTimer, Label_Change_TrayTip, -1000
}

showToolTip(Msg="", ShowTime=1000) { ; ToolTip提示信息
	ToolTip, %Msg%
	SetTimer, Timer_Remove_ToolTip, %ShowTime%
	Return
	
	Timer_Remove_ToolTip:  ; 移除ToolTip
		SetTimer, Timer_Remove_ToolTip, Off
		ToolTip
	Return
}

monitorChange(ByRef wParam,ByRef lParam) { ; 显示器分辨率更改-重启脚本
    SetTimer, Menu_Reload, -1000
}

getDisplayPos(X=0, Y=0, W=0, H=0) { ; 根据屏幕的分辨率获取输入法状态显示位置
	WinGetPos, WinX, WinY, , , A
	MonitorNum := getMonitorNum(WinX,WinY)
	SysGet, Mon, MonitorWorkArea, MonitorNum
	MonWidth := MonRight-MonLeft
	MonHeight := MonBottom-MonTop
	X := MonLeft+MonWidth*X*0.01
	Y := MonTop+MonHeight*Y*0.01
	X := X+W>MonWidth-10?MonWidth-W-10:X
	Y := Y+H>MonHeight-10?MonHeight-H-10:Y
	return {x:X, y:Y}
}

getMonitorNum(X,Y) { ; 获取指定位置所在显示器编号
    Loop,% MonitorAreaObjects.Length()
    {
        If (X>MonitorAreaObjects[A_Index][1] && X<MonitorAreaObjects[A_Index][3] && Y>MonitorAreaObjects[A_Index][2] && Y<MonitorAreaObjects[A_Index][4])
        	Return A_Index
    }
    Return 1
}

Label_Init_INI: ; 初始化配置文件INI
	FileAppend,[基本设置]`n, %INI%
	FileAppend,开机自启=0`n, %INI%
	FileAppend,管理员启动=1`n, %INI%
	FileAppend,自动切换=1`n, %INI%
	FileAppend,默认输入法=1`n, %INI%

	FileAppend,切换提示=4`n, %INI%
	FileAppend,切换提示时间=1500`n, %INI%
	FileAppend,切换提示文字大小=15,30`n, %INI%
	FileAppend,切换提示透明度=235,180`n, %INI%
	FileAppend,切换提示偏移=0,0`n, %INI%
	FileAppend,切换提示固定位置=50,30`n, %INI%

	FileAppend,托盘图标显示=1`n, %INI%
	FileAppend,托盘图标显示输入法=1`n, %INI%
	FileAppend,托盘图标双击=2`n, %INI%

	FileAppend,鼠标指针显示输入法=1`n, %INI%
	FileAppend,鼠标指针对应分辨率=0`n, %INI%

	FileAppend,[热键屏蔽窗口列表]`n, %INI%
	FileAppend,[切换屏蔽窗口列表]`n, %INI%
	FileAppend,[切换提示屏蔽窗口列表]`n, %INI%
	FileAppend,窗口切换=ahk_class MultitaskingViewFrame`n, %INI%
	FileAppend,[二次切换屏蔽窗口列表]`n, %INI%
	FileAppend,TC新建文件夹=ahk_class TCOMBOINPUT`n, %INI%
	FileAppend,TC搜索=ahk_class TFindFile`n, %INI%
	FileAppend,TC快搜=ahk_class TQUICKSEARCH`n, %INI%
	FileAppend,[焦点控件切换窗口列表]`n, %INI%
	FileAppend,Xshell=ahk_exe Xshell.exe`n, %INI%
	FileAppend,Steam=ahk_exe Steam.exe`n, %INI%
	FileAppend,有道词典=ahk_exe YoudaoDict.exe`n, %INI%

	FileAppend,[热键设置]`n, %INI%
	FileAppend,添加至中文窗口=`n, %INI%
	FileAppend,添加至英文(中文)窗口=`n, %INI%
	FileAppend,添加至英文输入法窗口=`n, %INI%
	FileAppend,移除从中英文窗口=`n, %INI%
	FileAppend,切换中文=`n, %INI%
	FileAppend,切换英文(中文)=`n, %INI%
	FileAppend,切换英文输入法=`n, %INI%
	FileAppend,切换中英文(中文)=`n, %INI%
	FileAppend,切换中英文输入法=`n, %INI%
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

	FileAppend,[高级设置]`n, %INI%
	FileAppend,内部关联=..\RunAny\RunAnyConfig.ini`n, %INI%
	FileAppend,快捷键兼容=1`n, %INI%
	FileAppend,左键点击输入位置显示输入法状态=1|全局窗口`n, %INI%
	FileAppend,左键弹起后提示输入法状态生效窗口=Code.exe`n, %INI%
	FileAppend,定时重置输入法=60|编辑器`n, %INI%
	FileAppend,切换重置大小写=1`n, %INI%
	FileAppend,上屏字符内容=2|1`n, %INI%
	FileAppend,提示颜色=333434|dfe3e3|02ecfb|ff0000`n, %INI%
	FileAppend,托盘提示内容=KBLAutoSwitch（`%权限`%）``n`%启动时间`%``n版本：`%版本`%``n自动切换统计：`%自动切换次数`%`n, %INI%

	FileAppend,[自定义窗口组]`n, %INI%
	FileAppend,1=全局窗口=0=AllGlobalWin=全局窗口组`n, %INI%
	FileAppend,2=编辑器=2=sublime_text.exe|Code.exe=编辑器窗口组`n, %INI%
	FileAppend,3=不重置大小写组=1=RunAny_SearchBar ahk_exe RunAny.exe=切换窗口不重置大小写`n, %INI%
	FileAppend,4=TC=2=ahk_exe TOTALCMD.exe|TotalCMD64.exe=TC`n, %INI%
	FileAppend,[自定义操作]`n, %INI%
	FileAppend,1=2=s-; |# =1=ahk、py注释切换中文`n, %INI%
	FileAppend,2=2=k-~Enter|~Esc=6=回车、Esc切换英文`n, %INI%
	FileAppend,3=4=k-~F2|~F7|~^s=1=TC切换中文`n, %INI%
	FileAppend,4=4=k-~Enter|~Esc=6=TC回车或ESC重置输入法`n, %INI%

	FileAppend,[中文窗口]`n, %INI%
	FileAppend,win搜索栏=ahk_exe SearchApp.exe`n, %INI%
	FileAppend,OneNote for Windows 10=uwp  OneNote for Windows 10`n, %INI%

	FileAppend,[英文窗口]`n, %INI%
	FileAppend,win桌面=ahk_class WorkerW ahk_exe explorer.exe`n, %INI%
	FileAppend,win桌面=ahk_class Progman ahk_exe explorer.exe`n, %INI%
	FileAppend,文件资源管理器=ahk_class CabinetWClass ahk_exe explorer.exe`n, %INI%
	FileAppend,cmd=ahk_exe cmd.exe`n, %INI%
	FileAppend,任务管理器=ahk_exe taskmgr.exe`n, %INI%

	FileAppend,[英文输入法窗口]`n, %INI%
	FileAppend,死亡细胞=ahk_exe deadcells.exe`n, %INI%
	FileAppend,闹钟和时钟=uwp 闹钟和时钟`n, %INI%
Return

Label_Create_Tray: ; 创建右键托盘菜单
	Menu, Tray, NoStandard
	Menu, Tray, Add, 关闭菜单, Menu_Close
	Menu, Tray, Icon, 关闭菜单, % Ico_path["关闭菜单"], % Ico_num["关闭菜单"]
	Menu, Tray, Add, 帮助文档, gMenu_Help
	Menu, Tray, Icon, 帮助文档, % Ico_path["帮助文档"], % Ico_num["帮助文档"]
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
	If (Tray_Double_Click>0){
		Menu, Tray, Click, 2
		Switch Tray_Double_Click 
		{
			Case 1: Menu, Tray, Default ,语言首选项
			Case 2: Menu, Tray, Default ,设置
			Case 3: Menu, Tray, Default ,停止
		}	
	}
Return

Label_Change_TrayTip: ; 改变托盘图标提示
	自动切换次数 := Format("{:d}", AutoSwitchFrequency/2)
	Transform, TrayTipContent_new, Deref, % TrayTipContent
	TrayTipContent_new := TrayTipContent_new=""?"KBLAutoSwitch":TrayTipContent_new
	Menu, Tray, Tip, %TrayTipContent_new%
Return

FilePathRun(FilePath) { ; 使用内部关联打开文件
	FileGetAttrib, Attributes, %FilePath%
	If InStr(Attributes, "D")
		FileExt := "folder"
	Else{
		SplitPath, FilePath,,, FileExt  ; 获取文件扩展名.
		If (FileExt="")
			FileExt := SubStr(FilePath,InStr(FilePath, ".",,0))
		If (FileExt="lnk"){		
			FileGetShortcut, %FilePath%, FilePath
			SplitPath, FilePath,,, FileExt
			If (FileExt="")
				FileExt := SubStr(FilePath,InStr(FilePath, ".",,0))
		}
	}
	FilePathOpenExe := openExtRunList[FileExt]
	FilePathOpenExe_Parm := openExtRunList_Parm[FileExt]
	try
		Run, %FilePathOpenExe% %FilePathOpenExe_Parm% "%FilePath%"
	Catch{
		Try
			Run, "%FilePath%"
		Catch
			Run, "%A_ScriptDir%"
	}
}

Menu_Close: ; 关闭菜单
	Gosub, Menu_Reload
Return

Menu_Language: ; 打开语言首选项
	If (OSVersion<=7)
		Run,rundll32.exe shell32.dll`,Control_RunDLL input.dll
	Else
		Run,ms-settings:regionlanguage
Return

Menu_Settings_Gui: ; 设置页面Gui
	Critical On
	Gosub, Label_ReadCustomKBLWinGroup
	Gosub, Label_ReadExistEXEIcos
	Gosub, Label_ReadExistIcoStyles
	Gosub, Label_ReadExistCurStyles
	Menu, Tray, Icon, %A_AhkPath%
	global EditSliderobj := Object()
	Edit_Hwnd:="",Slider_Hwnd:=""
	Gui_width_55 := 520
	tab_width_55 := Gui_width_55-20
	group_width_55 := tab_width_55-20
	global group_list_width_55 := tab_width_55-40
	text_width := 110
	left_margin := 12
	Gui, 55:Destroy
	Gui, 55:Default
	Gui, 55:Margin, 30, 20
	Gui, 55:Font, W400, Microsoft YaHei
	Gui, 55:Add, Tab3, x10 y10 w%tab_width_55% h593 vConfigTab +0x8000, 基础设置1|基础设置2|热键配置|中英窗口|高级窗口|高级配置
	
	Gui, 55:Tab, 基础设置1
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_55% h69, 【启动】设置
	Gui, 55:Add, Text, xm+%left_margin% yp+30, 开机自启
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vAuto_Launch, %OnOffState%
	GuiControl, Choose, Auto_Launch, % Auto_Launch+1
	Gui, 55:Add, Text, x+82 yp+2 cred, 启动权限
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vLaunch_Admin, 普通|管理员
	GuiControl, Choose, Launch_Admin, % Launch_Admin+1

	Gui, 55:Add, GroupBox, xm-10 y+26 w%group_width_55% h69, 【输入法切换】设置
	Gui, 55:Add, Text, xm+%left_margin% yp+30 cred, 自动切换
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vAuto_Switch, %OnOffState%
	GuiControl, Choose, Auto_Switch, % Auto_Switch+1
	Gui, 55:Add, Text, x+70 yp+2 cred, 默认输入法
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vDefault_Keyboard, %KBLSwitchState%
	GuiControl, Choose, Default_Keyboard, % Default_Keyboard+1

	Gui, 55:Add, GroupBox, xm-10 y+26 w%group_width_55% h149, 【切换提示】设置
	Gui, 55:Add, Text, cred xm+%left_margin% yp+30, 切换提示
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vTT_OnOff_Style, 关闭|鼠标位置|输入+鼠标位置|固定位置|输入+固定位置
	GuiControl, Choose, TT_OnOff_Style, % TT_OnOff_Style+1
	Gui, 55:Add, Text, x+82 yp+2, 提示时间
	Gui, 55:Add, Edit, x+5 yp-2 w60 h25 vTT_Display_Time, %TT_Display_Time%
	Gui, 55:Add, Text, x+10 yp+2, 毫秒
	Gui, 55:Add, Text, xm+%left_margin% yp+40, 文字大小
	Gui, 55:Add, Edit, x+5 yp-2 w60 h25 vTT_Font_Size, %TT_Font_Size%
	Gui, 55:Add, Text, x+10 yp+2, 榜 (输入,固定)
	Gui, 55:Add, Text, x+59 yp, 透明度
	Gui, 55:Add, Edit, x+5 yp-2 w60 h25 vTT_Transparency, %TT_Transparency%
	Gui, 55:Add, Text, x+10 yp-5, (0-255)`n(输入,固定)
	Gui, 55:Add, Text, xm+%left_margin% yp+47, 提示偏移
	Gui, 55:Add, Edit, x+5 yp-2 w60 h25 vTT_Shift, %TT_Shift%
	Gui, 55:Add, Text, x+10 yp+2, (x,y) 像素 (输入)
	Gui, 55:Add, Text, x+35 yp, 固定位置
	Gui, 55:Add, Edit, x+5 yp-2 w60 h25 vTT_Pos_Coef, %TT_Pos_Coef%
	Gui, 55:Add, Text, x+10 yp+2, (x,y) (0-100)

	Gui, 55:Add, GroupBox, xm-10 y+32 w%group_width_55% h109, 【托盘图标】设置
	Gui, 55:Add, Text, cred xm+%left_margin% yp+30, 托盘图标
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vTray_Display, 关闭|显示
	GuiControl, Choose, Tray_Display, % Tray_Display+1
	Gui, 55:Add, Text, x+82 yp+2, 双击图标
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vTray_Double_Click, %TrayFuncState%
	GuiControl, Choose, Tray_Double_Click, % Tray_Double_Click+1
	Gui, 55:Add, Text, xm+left_margin-12 yp+43, 图标输入法
	Gui, 55:Add, DropDownList, x+5 yp-3 w%text_width% vTray_Display_KBL, %OnOffState%
	GuiControl, Choose, Tray_Display_KBL, % Tray_Display_KBL+1
	Gui, 55:Add, Text, x+82 yp+3, 图标样式
	Gui, 55:Add, DropDownList, x+5 yp-3 w%text_width% vTray_Display_Style ggChange_Tray_Display_Style, %ExistIcoStyles%
	GuiControl, Choose, Tray_Display_Style, % TransformStateReverse(ExistIcoStyles,Tray_Display_Style)+1
	Gui, 55:Add, Picture, x+10 yp w24 h24 HwndTray_Display_Style_Pic_hwnd, % CNico_path
	Gosub, gChange_Tray_Display_Style

	Gui, 55:Add, GroupBox, xm-10 y+25 w%group_width_55% h109, 【鼠标指针】设置
	Gui, 55:Add, Text, cred xm+left_margin-12 yp+30, 鼠标输入法
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vCur_Launch, %OnOffState%
	GuiControl, Choose, Cur_Launch, % Cur_Launch+1
	Gui, 55:Add, Text, x+82 yp+2, 鼠标样式
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vCur_Launch_Style ggChange_Cur_Launch_Style, %ExistCurStyles%
	GuiControl, Choose, Cur_Launch_Style, % TransformStateReverse(ExistCurStyles,Cur_Launch_Style)+1
	Gui, 55:Add, Picture, x+10 yp w24 h24 HwndCur_Launch_Style_Pic_hwnd, % CurPathObj[7]
	Gosub, gChange_Cur_Launch_Style
	Gui, 55:Add, Text, xm+left_margin-12 yp+43, 鼠标分辨率
	Gui, 55:Add, DropDownList, x+5 yp-3 w%text_width% vCur_Size, 自动%ExistCurSize%
	GuiControl, Choose, Cur_Size, % Cur_Size=0?1:getIndexDropDownList(ExistCurSize,Cur_Size)

	Gui, 55:Tab
	Gui, 55:Add, Button, Default w75 x110 y625 GgSet_OK, 确定
	Gui, 55:Add, Button, w75 x+20 yp G55GuiClose, 取消
	Gui, 55:Add, Button, w75 x+20 yp GgSet_ReSet, 恢复默认
	gui, 55:Font, underline
	Gui, 55:Add, Text, Cblue x+20 yp-5  GgMenu_Config, 配置文件
	Gui, 55:Add, Text, Cblue xp+60 yp GgMenu_Icos, 图标文件
	Gui, 55:Add, Text, Cblue xp-60 yp+20 GgMenu_Curs, 鼠标文件
	Gui, 55:Add, Text, Cblue xp+60 yp GgMenu_Help, 帮助文档
	Gui, 55:Font, norm , Microsoft YaHei

	Gui, 55:Tab, 基础设置2
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_55% h310, 【屏蔽】设置（换行分隔）
	Gui, 55:Add, Edit, xm yp+45 w%group_list_width_55% r3 vDisable_HotKey_App_List HwndDisableHotKey_hwnd, %Disable_HotKey_App_List%
	Gui, 55:Add, Text, cred xm yp-24, 【热键】
	Gui, 55:Add, Text, x+5 yp, 屏蔽窗口列表
	Gui, 55:Add, Button, w30 h20 x380 yp vvCurrentWin_Add_Disable_HotKey ggCurrentWin_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vvCurrentWin_Sub_Disable_HotKey ggCurrentWin_Sub, -
	Gui, 55:Add, Button, w30 h20 x+5 yp vvReset_Disable_HotKey ggReset_Value, R
	Gui, 55:Add, Text, cred xm yp+95, 【自动切换】
	Gui, 55:Add, Text, x+5 yp, 屏蔽窗口列表
	Gui, 55:Add, Button, w30 h20 x380 yp vvCurrentWin_Add_Disable_Switch ggCurrentWin_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vvCurrentWin_Sub_Disable_Switch ggCurrentWin_Sub, -
	Gui, 55:Add, Button, w30 h20 x+5 yp vvReset_Disable_Switch ggReset_Value, R
	Gui, 55:Add, Edit, xm yp+24 w%group_list_width_55% r3 vDisable_Switch_App_List HwndDisableSwitch_hwnd, %Disable_Switch_App_List%
	Gui, 55:Add, Text, cred xm yp+71, 【切换提示】
	Gui, 55:Add, Text, x+5 yp, 屏蔽窗口列表
	Gui, 55:Add, Button, w30 h20 x380 yp vvCurrentWin_Add_Disable_TTShow ggCurrentWin_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vvCurrentWin_Sub_Disable_TTShow ggCurrentWin_Sub, -
	Gui, 55:Add, Button, w30 h20 x+5 yp vvReset_Disable_TTShow ggReset_Value, R
	Gui, 55:Add, Edit, xm yp+24 w%group_list_width_55% r3 vDisable_TTShow_App_List HwndDisableTTShow_hwnd, %Disable_TTShow_App_List%

	Gui, 55:Add, GroupBox, xm-10 y+26 w%group_width_55% h223, 【特殊窗口】设置（换行分隔）
	Gui, 55:Add, Text, cred xm yp+21, 【二次切换】
	Gui, 55:Add, Text, x+5 yp, 屏蔽窗口列表（建议手动谨慎添加，一般配合高级窗口使用）
	Gui, 55:Add, Button, w30 h20 x450 yp vvReset_No_TwiceSwitch ggReset_Value, R
	Gui, 55:Add, Edit, xm yp+24 w%group_list_width_55% r3 vNo_TwiceSwitch_App_List HwndNoTwiceSwitch_hwnd, %No_TwiceSwitch_App_List%
	Gui, 55:Add, Text, cred xm yp+71, 【焦点控件切换】
	Gui, 55:Add, Text, x+5 yp, 窗口列表（建议谨慎添加，切换无效时使用）
	Gui, 55:Add, Button, w30 h20 x380 yp vvCurrentWin_Add_FocusControl ggCurrentWin_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vvCurrentWin_Sub_FocusControl ggCurrentWin_Sub, -
	Gui, 55:Add, Button, w30 h20 x+5 yp vvReset_FocusControl ggReset_Value, R
	Gui, 55:Add, Edit, xm yp+24 w%group_list_width_55% r3 vFocusControl_App_List HwndFocusControl_hwnd, %FocusControl_App_List%
	
	Gui, 55:Tab, 热键配置
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_55% h110, 【窗口】添加移除快捷键
	Gui, 55:Add, Text, xm+%left_margin% yp+22, %A_Space%添加至`n中文窗口
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Add_To_Cn, %Hotkey_Add_To_Cn%
	Gui, 55:Add, Text, x+70 yp-6,  添加至英文`n(中文)窗口
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Add_To_CnEn, %Hotkey_Add_To_CnEn%
	Gui, 55:Add, Text, xm+left_margin-12 yp+35, 添加至英文`n输入法窗口
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Add_To_En, %Hotkey_Add_To_En%
	Gui, 55:Add, Text, x+70 yp-6,  %A_Space%%A_Space%移除从`n中英文窗口
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Remove_From_All, %Hotkey_Remove_From_All%

	Gui, 55:Add, GroupBox, xm-10 y+22 w%group_width_55% h192, 【输入法】快捷键
	Gui, 55:Add, Text, xm+left_margin-12 yp+30, 显示输入法
	Gui, 55:Add, Hotkey, x+5 yp-2 w%text_width% vHotkey_Display_KBL, %Hotkey_Display_KBL%
	Gui, 55:Add, Text, x+70 yp+2, 切换至中文
	Gui, 55:Add, Hotkey, x+5 yp-2 w%text_width% vHotkey_Set_Chinese, %Hotkey_Set_Chinese%
	Gui, 55:Add, Text, xm+left_margin-12 yp+35, 切换至英文`n%A_Space%%A_Space%(中文)
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Set_ChineseEnglish, %Hotkey_Set_ChineseEnglish%
	Gui, 55:Add, Text, x+70 yp-6, 切换至英文`n%A_Space%输入法
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Set_English, %Hotkey_Set_English%
	Gui, 55:Add, Text, xm+left_margin-12 yp+35, 切换中英文`n%A_Space%%A_Space%(中文)
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Toggle_CN_CNEN, %Hotkey_Toggle_CN_CNEN%
	Gui, 55:Add, Text, x+70 yp-6, 切换中英文`n%A_Space%输入法
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Toggle_CN_EN, %Hotkey_Toggle_CN_EN%
	Gui, 55:Add, Text, xm+left_margin-12 yp+43, 重置输入法
	Gui, 55:Add, Hotkey, x+5 yp-2 w%text_width% vHotkey_Reset_KBL, %Hotkey_Reset_KBL%


	Gui, 55:Add, GroupBox, xm-10 y+21 w%group_width_55% h69, 【自动切换】程序快捷键
	Gui, 55:Add, Text, xm+%left_margin% yp+22, %A_Space%%A_Space%停止`n自动切换
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Stop_KBLAS, %Hotkey_Stop_KBLAS%
	Gui, 55:Add, Text, x+70 yp-6, 获取输入法`n%A_Space%%A_Space%IME代码
	Gui, 55:Add, Hotkey, x+5 yp+6 w%text_width% vHotkey_Get_KeyBoard, %Hotkey_Get_KeyBoard%

	Gui, 55:Add, GroupBox, xm-10 y+24 w%group_width_55% h158, 【特殊】热键（请关闭输入法内的中英切换快捷键，例如shift）
	temp := left_margin + 7
	Gui, 55:Add, Text, xm+%temp% yp+30 cred, 左Shift%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Left_Shift, %OperationState%
	GuiControl, Choose, Hotkey_Left_Shift, % Hotkey_Left_Shift+1
	Gui, 55:Add, Text, x+89 yp+2 cred, 右Shift%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Right_Shift, %OperationState%
	GuiControl, Choose, Hotkey_Right_Shift, % Hotkey_Right_Shift+1
	temp := left_margin + 12
	Gui, 55:Add, Text, xm+%temp% yp+43, 左Ctrl%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Left_Ctrl, %OperationState%
	GuiControl, Choose, Hotkey_Left_Ctrl, % Hotkey_Left_Ctrl+1
	Gui, 55:Add, Text, x+94 yp+2, 右Ctrl%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Right_Ctrl, %OperationState%
	GuiControl, Choose, Hotkey_Right_Ctrl, % Hotkey_Right_Ctrl+1
	temp := left_margin + 17
	Gui, 55:Add, Text, xm+%temp% yp+43, 左Alt%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Left_Alt, %OperationState%
	GuiControl, Choose, Hotkey_Left_Alt, % Hotkey_Left_Alt+1
	Gui, 55:Add, Text, x+99 yp+2, 右Alt%A_Space%
	Gui, 55:Add, DropDownList, x+5 yp-2 w%text_width% vHotkey_Right_Alt, %OperationState%
	GuiControl, Choose, Hotkey_Right_Alt, % Hotkey_Right_Alt+1

	Gui, 55:Tab, 中英窗口
	group_list_width_55_KBLwin := group_list_width_55*0.75
	group_list_width_55_KBLwinGroup := group_list_width_55-group_list_width_55_KBLwin-10
	wingroupXpos := group_list_width_55_KBLwin+50
	wingroupAddButtonXpos := group_list_width_55_KBLwin-50-30
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_55% h548, 【中英文窗口】设置（手动添加请按照示例格式）
	Gui, 55:Add, Edit, xm yp+45 w%group_list_width_55_KBLwin% r5 vINI_CN HwndKBLWinsCN_hwnd, %INI_CN%
	Gui, 55:Add, Edit, +ReadOnly cgreen x+10 yp w%group_list_width_55_KBLwinGroup% r5 , %Custom_Win_Group_Cn%
	Gui, 55:Add, Text, cred xm yp-24, 【中文】
	Gui, 55:Add, Text, x+5 yp, 窗口
	Gui, 55:Add, Button, w30 h20 x%wingroupAddButtonXpos% yp vvCurrentWin_Add_Cn ggCurrentWin_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vvCurrentWin_Sub_Cn ggCurrentWin_Sub, -
	Gui, 55:Add, Button, w30 h20 x+5 yp vvReset_Cn ggReset_Value, R
	Gui, 55:Add, Text, x%wingroupXpos% yp cred, 【窗口组】
	Gui, 55:Add, Text, cred xm yp+137, 【英文】
	Gui, 55:Add, Text, x+5 yp, 窗口（中文输入法）
	Gui, 55:Add, Button, w30 h20 x%wingroupAddButtonXpos% yp vvCurrentWin_Add_CnEn ggCurrentWin_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vvCurrentWin_Sub_CnEn ggCurrentWin_Sub, -
	Gui, 55:Add, Button, w30 h20 x+5 yp vvReset_CnEn ggReset_Value, R
	Gui, 55:Add, Edit, xm yp+22 w%group_list_width_55_KBLwin% r11 vINI_CNEN HwndKBLWinsCNEN_hwnd, %INI_CNEN%
	Gui, 55:Add, Edit, +ReadOnly cgreen x+10 yp w%group_list_width_55_KBLwinGroup% r11 , %Custom_Win_Group_CnEn%
	Gui, 55:Add, Text, cred xm yp+209, 【英文】
	Gui, 55:Add, Text, x+5 yp, 窗口（英文输入法）
	Gui, 55:Add, Button, w30 h20 x%wingroupAddButtonXpos% yp vvCurrentWin_Add_En ggCurrentWin_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vvCurrentWin_Sub_En ggCurrentWin_Sub, -
	Gui, 55:Add, Button, w30 h20 x+5 yp vvReset_En ggReset_Value, R
	Gui, 55:Add, Edit, xm yp+22 w%group_list_width_55_KBLwin% r7 vINI_EN HwndKBLWinsEN_hwnd, %INI_EN%
	Gui, 55:Add, Edit, +ReadOnly cgreen x+10 yp w%group_list_width_55_KBLwinGroup% r7 , %Custom_Win_Group_En%

	Gui, 55:Tab, 高级窗口
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_55% h275, 【自定义】窗口组（双击编辑查看，|分隔多个窗口内容）
	Gui, 55:Add, ListView, Count1 vahkGroupWin ggAdvanced_Config xm yp+22 r10 w%group_list_width_55%, 序号|窗口组|状态|内容|说明
	Gui, 55:Add, Button, w30 h20 xm+380 yp-25 vButton1 ggAdvanced_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vButton2 ggAdvanced_Remove, -
		ListViewUpdate_Custom_Win_Group(Custom_Win_Group)

	Gui, 55:Add, GroupBox, xm-10 y+277 w%group_width_55% h254, 自定义操作（双击编辑查看，|分割多个热字串和热键）
	Gui, 55:Add, ListView, Count1 vCustomOperation ggAdvanced_Config xm yp+22 r9 w%group_list_width_55%, 序号|窗口组|热字串(s-)或热键(k-)|操作|说明
	Gui, 55:Add, Button, w30 h20 xm+380 yp-25 vButton3 ggAdvanced_Add, +
	Gui, 55:Add, Button, w30 h20 x+5 yp vButton4 ggAdvanced_Remove, -
		ListViewUpdate_Custom_Hotstring(Custom_Hotstring)

	Gui, 55:Tab, 高级配置
	Gui, 55:Add, GroupBox, xm-10 y+10 w%group_width_55% h548, 【高级】配置（双击编辑查看）
	Gui, 55:Add, ListView, Count3 vAdvancedConfig ggAdvanced_Config xm yp+22 r23 w%group_list_width_55%, 序号|配置名称|状态|值|说明
		LV_Add(, 1, "内部关联", openExtRunList_num, Open_Ext,"-内部关联文件路径，用于打开配置文件和路径等`n-支持相对路径，兼容RA[RunAnyConfig.ini]（可以在中英窗口-移除窗口中利用RA无路径显示图标）")
		LV_Add(, 2, "快捷键兼容", Outer_InputKey_Compatible, Outer_InputKey_Compatible,"-软件内快捷键兼容：`n0：适用于左右shift分别对应中英文场景；`n1：适用于单shift切换中英文场景，兼容输入法，不影响中英文符号输入")
		LV_Add(, 3, "左键点击输入位置显示输入法状态", Left_Mouse_ShowKBL_State, Left_Mouse_ShowKBL,"-在指定窗口组左键点击提示输入法：`n1.参数1为开关，参数2为生效窗口组`n2.参数使用|分隔")
		LV_Add(, 4, "左键弹起后提示输入法状态生效窗口", Left_Mouse_ShowKBL_State, Left_Mouse_ShowKBL_Up,"-在指定窗口组左键点击提示输入法时，使用左键弹起响应：`n参数为窗口或窗口组")
		LV_Add(, 5, "定时重置输入法", "秒", SetTimer_Reset_KBL,"-无操作固定时间重置输入法（秒）：`n1.参数1为时间，参数2为窗口组`n2.参数使用|分隔")
		LV_Add(, 6, "切换重置大小写", TransformState(DefaultCapsLockState,Reset_CapsLock_State), Reset_CapsLock,"-切换输入法后自动重置大小写：`n1.参数1为大小写状态（0为不重置，1为小写，2为大写），参数2为屏蔽窗口组，该窗口组将不生效`n2.参数使用|分隔")
		LV_Add(, 7, "上屏字符内容", Enter_Inputing_ContentObj.Count(), Enter_Inputing_Content,"-中文输入法状态下输入待上屏的字符处理`n-需关闭输入法shift，开启软件内快捷键切换：`n1.参数1表示处理方式，其中0表示使用输入法处理，1表示丢弃字符，2表示上屏字符，3表示上屏第一个候选内容`n2.参数2表示中文切换快捷键是否上屏`n目前已支持输入法：搜狗输入法、QQ五笔输入法、QQ拼音输入法、手心输入法、冰凌五笔")
		LV_Add(, 8, "提示颜色", GuiTTColorObj.Count(), GuiTTColor,"-切换提示颜色设置：`n包含四个参数（|隔开）：中文背景色|英文背景色|中文字体颜色|英文字体颜色")
		LV_Add(, 9, "托盘提示内容", StrSplit(TrayTipContent, "``n").Count(), StrReplace(TrayTipContent, "``n", "`n"),"-托盘提示内容：`n1.变量可以使用内部变量、ahk变量、win系统变量`n2.变量使用百分号包裹（%变量名%），变量详情请查看帮助文档")
		LV_ModifyCol(1,group_list_width_55*0.08 " Integer Center")
		LV_ModifyCol(2,group_list_width_55*0.22)
		LV_ModifyCol(3,group_list_width_55*0.08 " Integer Center")
		LV_ModifyCol(4,group_list_width_55*0.38)
		LV_ModifyCol(5,group_list_width_55*0.235)

	GuiTitleContent := A_IsAdmin=1?"（管理员）":"（非管理员）"
	Gui, 55:Show,w%Gui_width_55%, 设置：%APPName% v%APPVersion%%GuiTitleContent%
	Critical off
Return

ListViewUpdate_Custom_Win_Group(Custom_Win_Group) { ; 更新Custom_Win_Group数据
	Gui, ListView, ahkGroupWin
	LV_Delete()
	Loop, parse, Custom_Win_Group, `n, `r
	{
		MyVar := StrSplit(Trim(A_LoopField), "=")
		LV_Add(, MyVar[1], MyVar[2], TransformState(ListViewKBLState,MyVar[3]), MyVar[4],MyVar[5])
	}
	LV_ModifyCol(1,group_list_width_55*0.08 " Integer Center")
	LV_ModifyCol(2,group_list_width_55*0.17)
	LV_ModifyCol(3,group_list_width_55*0.10 " Integer Center")
	LV_ModifyCol(4,group_list_width_55*0.4)
	LV_ModifyCol(5,group_list_width_55*0.24)
}

ListViewUpdate_Custom_Hotstring(Custom_Hotstring) { ; 更新Custom_Hotstring数据
	Gui, ListView, CustomOperation
	LV_Delete()
	Loop, parse, Custom_Hotstring, `n, `r
	{
		MyVar := StrSplit(Trim(A_LoopField), "=")
		LV_Add(, MyVar[1], groupNumObj[MyVar[2]], MyVar[3], TransformState(OperationState,MyVar[4]),MyVar[5])
	}
	LV_ModifyCol(1,group_list_width_55*0.08 " Integer Center")
	LV_ModifyCol(2,group_list_width_55*0.17)
	LV_ModifyCol(3,group_list_width_55*0.28)
	LV_ModifyCol(4,group_list_width_55*0.22)
	LV_ModifyCol(5,group_list_width_55*0.24)
}

ListViewUpdate_Custom_Advanced_Config() { ; 更新高级配置数据
	Gui, ListView, AdvancedConfig
	LV_GetText(OutputVar, 6, 4)
	LV_Modify(6, "Col3", TransformState(DefaultCapsLockState,SubStr(OutputVar, 1, 1)))
}	

TransformState(String,State) { ; 将状态转换为文字
	Loop, parse, String, |
	    If (State+1=A_Index)
			Return A_LoopField
	Return State
}

TransformStateReverse(String,State) { ; 将文字转换为状态
	Loop, parse, String, |
	    If (State=A_LoopField)
			Return A_Index-1
	Return State	
}

getIndexDropDownList(Str,objStr) { ; 根据字符串查找DropDownList中位置
	Loop, parse, Str, |
	{
	    If (A_LoopField=objStr)
	    	pos := A_Index
	}
	Return pos
}

Menu_About: ; 关于页面Gui
	Critical On
	Menu, Tray, Icon, %A_AhkPath%
	Gui, 99:Destroy
	Gui, 99:Color, FFFFFF
	Gui, 99:Add, ActiveX, x0 y0 w700 h570 voWB, shell explorer
	oWB.Navigate("about:blank")
	vHtml = 
	(
		<html>
			<meta http-equiv="X-UA-Compatible" content="IE=edge">
			<title>APPName</title>
			<body style="font-family:Microsoft YaHei">
				<h2 align="center">【%APPName%】</h2>
				<h3 align="center">自动切换输入法 v%APPVersion%</h3>
				<b>最新版本：</b><img alt="GitHub release" style="vertical-align:middle" src="https://img.shields.io/github/v/release/flyinclouds/KBLAutoSwitch?label=KBLAutoSwitch"/>
				<b>AHK版本：</b><img alt="Autohotkey" style="vertical-align:middle" src="https://raster.shields.io/badge/autohotkey-1.1.33.10-blue.svg"/>
				<h4>软件特色</h4>
				<ol>
				  <li>根据程序窗口切换中英文输入法</li>
				  <li>包括切换提示、托盘图标、鼠标指针三种显示输入法状态功能</li>
				  <li>设置快捷键快速添加指定窗口</li>
				</ol>
				<h4>使用建议</h4>
				<ol>
				  <li>建议使用win10及以上系统</li>
				  <li>【中文】使用【搜狗输入法】输入法（非广告）</li>
				  <li>【中文】输入法取消【<kbd>Shift</kbd>】切换中英文，并在软件-热键配置-【特殊】热键中设置<kbd>Shift</kbd>切换输入法功能</li>
				</ol>
				<h4>特殊说明</h4>
				<ol>
				  <li style="color:red">如出现中英文状态识别错误情况或者需要左右<kbd>Shift</kbd>分别设置切换功能，建议将输入法中<kbd>Shift</kbd>切换关闭，在软件-热键配置-【特殊】热键中设置<kbd>Shift</kbd>切换输入法功能</li>
				  <li>不支持非中英文输入法切换</li>
				  <li>有任何问题可以加入【交流群】一起交流讨论，或者查看下方腾讯文档</li>
				</ol>
			</body>
		</html>
	)
	oWB.document.write(vHtml)
	oWB.Refresh()
	Gui, 99:Font, s11 Bold, Microsoft YaHei
	Gui, 99:Add, Link, xm+18 y+10, 交流群：<a href="https://jq.qq.com/?_wv=1027&k=A3F0yfcy">548517941【KBLAutoSwitch交流群】</a>
	Gui, 99:Add, Link, xm+18 y+10, 软件使用文档：<a href="https://docs.qq.com/doc/DWHFxVXBNbWNxcWpa">腾讯文档：https://docs.qq.com/doc/DWHFxVXBNbWNxcWpa</a>
	Gui, 99:Add, Link, xm+18 y+10, 软件github地址：<a href="https://github.com/flyinclouds/KBLAutoSwitch">https://github.com/flyinclouds/KBLAutoSwitch</a>
	Gui, 99:Add, Link, xm+18 y+10, 软件下载地址：<a href="https://wwr.lanzoui.com/b02i9dmsd">蓝奏云下载：https://wwr.lanzoui.com/b02i9dmsd 密码：fd5v</a>
	Gui, 99:Add, Link, xm+18 y+10, RunAny官网：<a href="https://hui-zz.gitee.io/runany/#/">https://hui-zz.gitee.io/runany/#/</a>
	Gui, 99:Add, Link, xm+18 y+10, RunAny交流群：<a href="https://jq.qq.com/?_wv=1027&k=445Ug7u">246308937【RunAny快速启动一劳永逸】</a>
	Gui, 99:Add, Link, xm+18 y+10, AHK中文论坛：<a href="https://www.autoahk.com/">https://www.autoahk.com/</a>
	Gui, 99:Font
	Critical Off
	GuiTitleContent := A_IsAdmin=1?"（管理员）":"（非管理员）"
	Gui, 99:Show, AutoSize Center, 关于：%APPName% v%APPVersion%%GuiTitleContent%
return

Label_Hide_All: ; 隐藏所有Gui和TT
	Gui, SwitchTT:Hide
	Gui, SwitchTT1:Hide
Return

SuspendedApp: ; 挂起脚本
	try Menu, Tray, Rename, 停止, 恢复
	try Menu, Tray, Check, 恢复
	try Gosub, Label_Hide_All
	Suspend, On
Return

UnSuspendedApp: ; 恢复挂起脚本
	try Menu, Tray, Rename, 恢复, 停止
	try Menu, Tray, UnCheck, 停止
	gosub, Reset_KBL
	Suspend, Off
Return

Menu_Stop: ; 停止脚本
	If (A_IsSuspended){
		OnMessage(shell_msg_num, "shellMessage")
		Gosub, UnSuspendedApp
	}Else{
		OnMessage(shell_msg_num, "")
		Gosub, SuspendedApp
	}
Return

Menu_Reload: ; 重新加载脚本
	try Reload
	Sleep, 1000
	Run, %A_AhkPath%%A_Space%"%A_ScriptFullPath%"
	ExitApp
Return

Menu_Exit: ; 退出脚本
	ExitApp
Return

99GuiClose: ; 关闭GUI事件
	gosub,Menu_Reload
Return

55GuiClose: ; 关闭GUI事件
	gosub,Menu_Reload
return

gSet_OK: ; 设置确认按钮功能
	Critical On
	Thread, NoTimers,True
	Gui, Submit
	FileDelete, %INI%
	Auto_Launch := TransformStateReverse(OnOffState,Auto_Launch)
	Launch_Admin := Launch_Admin="普通"?0:1
	Auto_Switch := TransformStateReverse(OnOffState,Auto_Switch)
	Default_Keyboard := TransformStateReverse(KBLSwitchState,Default_Keyboard)

	TT_OnOff_Style := TT_OnOff_Style="关闭"?0:TT_OnOff_Style="鼠标位置"?1:TT_OnOff_Style="输入+鼠标位置"?2:TT_OnOff_Style="固定位置"?3:4

	Tray_Display := Tray_Display="关闭"?0:1
	Tray_Display_KBL := TransformStateReverse(OnOffState,Tray_Display_KBL)
	Tray_Double_Click := TransformStateReverse(TrayFuncState,Tray_Double_Click)

	Cur_Launch := TransformStateReverse(OnOffState,Cur_Launch)
	Cur_Size := Cur_Size="自动"?0:Cur_Size

	Hotkey_Left_Shift := TransformStateReverse(OperationState,Hotkey_Left_Shift)
	Hotkey_Right_Shift := TransformStateReverse(OperationState,Hotkey_Right_Shift)
	Hotkey_Left_Ctrl := TransformStateReverse(OperationState,Hotkey_Left_Ctrl)
	Hotkey_Right_Ctrl := TransformStateReverse(OperationState,Hotkey_Right_Ctrl)
	Hotkey_Left_Alt := TransformStateReverse(OperationState,Hotkey_Left_Alt)
	Hotkey_Right_Alt := TransformStateReverse(OperationState,Hotkey_Right_Alt)

	IniWrite, %Auto_Launch%, %INI%, 基本设置, 开机自启
	IniWrite, %Launch_Admin%, %INI%, 基本设置, 管理员启动
	IniWrite, %Auto_Switch%, %INI%, 基本设置, 自动切换
	IniWrite, %Default_Keyboard%, %INI%, 基本设置, 默认输入法

	IniWrite, %TT_OnOff_Style%, %INI%, 基本设置, 切换提示
	IniWrite, %TT_Display_Time%, %INI%, 基本设置, 切换提示时间
	IniWrite, %TT_Font_Size%, %INI%, 基本设置, 切换提示文字大小
	IniWrite, %TT_Transparency%, %INI%, 基本设置, 切换提示透明度
	IniWrite, %TT_Shift%, %INI%, 基本设置, 切换提示偏移
	IniWrite, %TT_Pos_Coef%, %INI%, 基本设置, 切换提示固定位置
	
	If (Tray_Display=0){
		MsgBox, 305, 自动切换输入法 KBLAutoSwitch, 图标隐藏后将无法打开设置页面，可以通过修改配置文件【KBLAutoSwitch.ini】-【托盘图标显示=1】恢复！`n确定要隐藏图标吗？
		IfMsgBox, OK
			IniWrite, %Tray_Display%, %INI%, 基本设置, 托盘图标显示
	}Else{
		IniWrite, %Tray_Display%, %INI%, 基本设置, 托盘图标显示
	}
	IniWrite, %Tray_Double_Click%, %INI%, 基本设置, 托盘图标双击
	IniWrite, %Tray_Display_KBL%, %INI%, 基本设置, 托盘图标显示输入法
	IniWrite, %Tray_Display_Style%, %INI%, 基本设置, 托盘图标样式
	IniWrite, %Cur_Launch%, %INI%, 基本设置, 鼠标指针显示输入法
	IniWrite, %Cur_Launch_Style%, %INI%, 基本设置, 鼠标指针样式
	IniWrite, %Cur_Size%, %INI%, 基本设置, 鼠标指针对应分辨率

	IniWrite, % Trim(Disable_HotKey_App_List, " `t`n"), %INI%, 热键屏蔽窗口列表
	IniWrite, % Trim(Disable_Switch_App_List, " `t`n"), %INI%, 切换屏蔽窗口列表
	IniWrite, % Trim(Disable_TTShow_App_List, " `t`n"), %INI%, 切换提示屏蔽窗口列表
	IniWrite, % Trim(No_TwiceSwitch_App_List, " `t`n"), %INI%, 二次切换屏蔽窗口列表
	IniWrite, % Trim(FocusControl_App_List, " `t`n"), %INI%, 焦点控件切换窗口列表

	IniWrite, %Hotkey_Add_To_Cn%, %INI%, 热键设置, 添加至中文窗口
	IniWrite, %Hotkey_Add_To_CnEn%, %INI%, 热键设置, 添加至英文(中文)窗口
	IniWrite, %Hotkey_Add_To_En%, %INI%, 热键设置, 添加至英文输入法窗口
	IniWrite, %Hotkey_Remove_From_All%, %INI%, 热键设置, 移除从中英文窗口

	IniWrite, %Hotkey_Set_Chinese%, %INI%, 热键设置, 切换中文
	IniWrite, %Hotkey_Set_ChineseEnglish%, %INI%, 热键设置, 切换英文(中文)
	IniWrite, %Hotkey_Set_English%, %INI%, 热键设置, 切换英文输入法
	IniWrite, %Hotkey_Toggle_CN_CNEN%, %INI%, 热键设置, 切换中英文(中文)
	IniWrite, %Hotkey_Toggle_CN_EN%, %INI%, 热键设置, 切换中英文输入法
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

	Gui, ListView, AdvancedConfig
	LV_ModifyCol(1,"Sort")
	Loop, % LV_GetCount()
	{
		LV_GetText(OutputVar, A_Index , 4)
		OutputVar := StrReplace(Trim(OutputVar, "|"), "`n", "``n")
		Switch A_Index
		{
			Case 1: IniWrite, %OutputVar%, %INI%, 高级设置, 内部关联
			Case 2: IniWrite, %OutputVar%, %INI%, 高级设置, 快捷键兼容
			Case 3: IniWrite, %OutputVar%, %INI%, 高级设置, 左键点击输入位置显示输入法状态
			Case 4: IniWrite, %OutputVar%, %INI%, 高级设置, 左键弹起后提示输入法状态生效窗口
			Case 5: IniWrite, %OutputVar%, %INI%, 高级设置, 定时重置输入法
			Case 6: IniWrite, %OutputVar%, %INI%, 高级设置, 切换重置大小写
			Case 7: IniWrite, %OutputVar%, %INI%, 高级设置, 上屏字符内容
			Case 8: IniWrite, %OutputVar%, %INI%, 高级设置, 提示颜色
			Case 9: IniWrite, %OutputVar%, %INI%, 高级设置, 托盘提示内容
		}
	}

	Gui, ListView, ahkGroupWin
	SetListViewData("自定义窗口组")

	Gui, ListView, CustomOperation
	SetListViewData("自定义操作")

	IniWrite, % Trim(INI_CN, " `t`n"), %INI%, 中文窗口
	IniWrite, % Trim(INI_CNEN, " `t`n"), %INI%, 英文窗口
	IniWrite, % Trim(INI_EN, " `t`n"), %INI%, 英文输入法窗口

	gosub, Menu_Reload
return

getListViewData(Section) { ; 获取Listview数据
	Loop, % LV_GetCount()
	{
		LV_GetText(OutputVar, A_Index, 1)
		LV_GetText(OutputVar0, A_Index, 2)
		LV_GetText(OutputVar1, A_Index, 3)
		LV_GetText(OutputVar2, A_Index, 4)
		LV_GetText(OutputVar3, A_Index, 5)
		If (Section="自定义窗口组")
			IniWrite_Str .= OutputVar "=" OutputVar0 "=" TransformStateReverse(ListViewKBLState,OutputVar1) "=" Trim(OutputVar2,"|") "=" OutputVar3 "`n"
		Else If (Section="自定义操作")
			IniWrite_Str .= OutputVar "=" groupNameObj[OutputVar0] "=" Trim(OutputVar1,"|") "=" TransformStateReverse(OperationState,OutputVar2) "=" OutputVar3 "`n"
		Else
			IniWrite_Str .= OutputVar "=" OutputVar0 "=" OutputVar1 "=" OutputVar2 "=" OutputVar3 "`n"
	}
	Return Trim(IniWrite_Str,"`n")
}

SetListViewData(Section) { ; 保存Listview数据
	LV_ModifyCol(1,"Sort")
	IniDelete, %INI%, %Section%
	IniWrite_Str := getListViewData(Section)
	IniWrite, %IniWrite_Str%, %INI%, %Section%
}

getLVNewOrder() { ; 获取缺失序号
	Loop % LV_GetCount()
	{
	    LV_GetText(Order, A_Index)
	    If (Order!=A_Index)
	    	Return A_Index
	}
	Return Order+1
}

gSet_ReSet: ; 重置按钮的功能
	MsgBox, 49, 重置已有配置,此操作会删除所有KBLAutoSwitch本地配置，确认删除重置吗？
	IfMsgBox Ok
	{
		RegDelete, HKEY_CURRENT_USER, Software\KBLAutoSwitch
		FileDelete, %INI%
		gosub, Menu_Reload
	}
return

gMenu_Config: ; 打开配置文件功能
	FilePathRun(INI)
Return

gMenu_Icos: ; 打开图标文件路径
	FilePathRun(A_ScriptDir "\Icos\" Tray_Display_Style)
Return

gMenu_Curs: ; 打开鼠标指针文件路径
	FilePathRun(A_ScriptDir "\Curs\" Cur_Launch_Style "\" WindowsHeight)
Return

gMenu_Help: ; 打开帮助文档
	run, https://docs.qq.com/doc/DWHFxVXBNbWNxcWpa
Return

gChange_Tray_Display_Style: ; 变更托盘图标
	GuiControlGet, OutputVar,, Tray_Display_Style
	GuiControl,, %Tray_Display_Style_Pic_hwnd%, %A_ScriptDir%\Icos\%OutputVar%\%SystemUsesLightTheme_Str%_Cn.ico
Return

gChange_Cur_Launch_Style: ; 变更鼠标指针
	GuiControlGet, OutputVar,, Cur_Launch_Style
	ExistCurSize_Show := ""
	Loop Files, %A_ScriptDir%\Curs\%OutputVar%\*, D
		ExistCurSize_Show := ExistCurSize_Show "|" A_LoopFileName
	GuiControl,, Cur_Size, |自动%ExistCurSize_Show%
	GuiControl, Choose, Cur_Size, % Cur_Size=0?1:getIndexDropDownList(ExistCurSize_Show,Cur_Size)
	GuiControl,, %Cur_Launch_Style_Pic_hwnd%, % getCurPath(OutputVar,1080,"NORMAL_Cn")
Return

gReset_Value: ; 重置默认值
	Switch A_GuiControl
	{
		Case "vReset_Disable_HotKey":tempVar:="",Hwnd:=DisableHotKey_hwnd
		Case "vReset_Disable_Switch":tempVar:="",Hwnd:=DisableSwitch_hwnd
		Case "vReset_Disable_TTShow":tempVar:="窗口切换=ahk_class MultitaskingViewFrame",Hwnd:=DisableTTShow_hwnd
		Case "vReset_No_TwiceSwitch":tempVar:="TC新建文件夹=ahk_class TCOMBOINPUT`nTC搜索=ahk_class TFindFile`nTC快搜=ahk_class TQUICKSEARCH",Hwnd:=NoTwiceSwitch_hwnd
		Case "vReset_FocusControl":tempVar:="Xshell=ahk_exe Xshell.exe`nSteam=ahk_exe Steam.exe`nYoudaoDict=ahk_exe YoudaoDict.exe",Hwnd:=FocusControl_hwnd
		
		Case "vReset_Cn":tempVar:="win搜索栏=ahk_exe SearchApp.exe`nOneNote for Windows 10=uwp  OneNote for Windows 10",Hwnd:=KBLWinsCN_hwnd
		Case "vReset_CnEn":tempVar:="win桌面=ahk_class WorkerW ahk_exe explorer.exe`nwin桌面=ahk_class Progman ahk_exe explorer.exe`n文件资源管理器=ahk_class CabinetWClass ahk_exe explorer.exe`ncmd=ahk_exe cmd.exe`n任务管理器=ahk_exe taskmgr.exe",Hwnd:=KBLWinsCNEN_hwnd
		Case "vReset_En":tempVar:="死亡细胞=ahk_exe deadcells.exe`n闹钟和时钟=uwp 闹钟和时钟",Hwnd:=KBLWinsEN_hwnd
	}
	GuiControl,, %Hwnd%, %tempVar%
Return

gCurrentWin_Add: ; 添加当前已有窗口至KBL
	global CurrentWin_AddFlag := A_GuiControl
	Switch CurrentWin_AddFlag
	{
		Case "vCurrentWin_Add_Cn":GuiControlGet, KBLWins,, %KBLWinsCN_hwnd%
		Case "vCurrentWin_Add_CnEn":GuiControlGet, KBLWins,, %KBLWinsCNEN_hwnd%
		Case "vCurrentWin_Add_En":GuiControlGet, KBLWins,, %KBLWinsEN_hwnd%
		Case "vCurrentWin_Add_Disable_HotKey":GuiControlGet, KBLWins,, %DisableHotKey_hwnd%
		Case "vCurrentWin_Add_Disable_Switch":GuiControlGet, KBLWins,, %DisableSwitch_hwnd%
		Case "vCurrentWin_Add_Disable_TTShow":GuiControlGet, KBLWins,, %DisableTTShow_hwnd%
		Case "vCurrentWin_Add_FocusControl":GuiControlGet, KBLWins,, %FocusControl_hwnd%
	}
	Menu, Menu_KBLWin, Add, Item1,Label_Return
	Menu, Menu_KBLWin, DeleteAll
	Menu, Menu_KBLWin, Add, --取消--（添加）, Label_Return
	Try Menu, Menu_KBLWin, Icon, --取消--（添加）,shell32.dll,132,24
	Prev_DetectHiddenWindows := A_DetectHiddenWindows
	DetectHiddenWindows off
	NoRepeatObj := Object()
	WinGet windows, List
	Loop %windows%
	{
		id := windows%A_Index%
		item_key_val := getINIItem("ahk_id " id)
		item_key := item_key_val[0]
		item_val := item_key_val[1]
		item_regex := item_key_val[2]
		If NoRepeatObj.HasKey(item_val)
			Continue
		If IsHasSameRegExStr(KBLWins,item_regex)
			Continue
		if AddMenu_KBLWin(id,item_key)
			NoRepeatObj[item_val] := 1
	}
	GuiControlGet, ControlHwnd, Hwnd, %A_GuiControl%
    ControlGetPos, x, y, w, h, ,ahk_id %ControlHwnd%
	Menu, Menu_KBLWin, Show,% x,% y+h+2
	DetectHiddenWindows %Prev_DetectHiddenWindows%
Return

gCurrentWin_Sub: ; 删除已有窗口
	global CurrentWin_SubFlag := A_GuiControl
	Switch CurrentWin_SubFlag
	{
		Case "vCurrentWin_Sub_Cn":GuiControlGet, KBLWins,, %KBLWinsCN_hwnd%
		Case "vCurrentWin_Sub_CnEn":GuiControlGet, KBLWins,, %KBLWinsCNEN_hwnd%
		Case "vCurrentWin_Sub_En":GuiControlGet, KBLWins,, %KBLWinsEN_hwnd%
		Case "vCurrentWin_Sub_Disable_HotKey":GuiControlGet, KBLWins,, %DisableHotKey_hwnd%
		Case "vCurrentWin_Sub_Disable_Switch":GuiControlGet, KBLWins,, %DisableSwitch_hwnd%
		Case "vCurrentWin_Sub_Disable_TTShow":GuiControlGet, KBLWins,, %DisableTTShow_hwnd%
		Case "vCurrentWin_Sub_FocusControl":GuiControlGet, KBLWins,, %FocusControl_hwnd%
	}
	Menu, Menu_KBLWin, Add, Item1,Label_Return
	Menu, Menu_KBLWin, DeleteAll
	Menu, Menu_KBLWin, Add, --取消--（移除）, Label_Return
	Try Menu, Menu_KBLWin, Icon, --取消--（移除）,shell32.dll,132,24
	Loop, parse, KBLWins, `n, `r
	{
		If (A_LoopField="")
			Continue
		If (euqalPos := InStr(A_LoopField, "=")){
			ReadyKey := SubStr(A_LoopField,1,euqalPos-1)
			ReadyValue := SubStr(A_LoopField,euqalPos+1)
		}Else{
			ReadyKey := ""
			ReadyValue := A_LoopField
		}
		If (SubStr(ReadyValue, -3)=".exe" and !InStr(ReadyValue, "ahk_exe"))
			ReadyValue := "ahk_exe " ReadyValue
		WinGet, IcoPath, ProcessPath, %ReadyValue%
		If (IcoPath=""){
			RegExMatch(ReadyValue, "ahk_exe (.*\.exe)", SubPat)
			IcoPath := getExePath(SubPat1)
		}
		Menu, Menu_KBLWin, Add, %A_LoopField%, Label_Sub_KBLWin
		If (IcoPath) {
			Try Menu, Menu_KBLWin, Icon, %A_LoopField%, %IcoPath%,,32
			Catch
				Menu, Menu_KBLWin, Icon, %A_LoopField%,shell32.dll,3,32
		}Else
				Menu, Menu_KBLWin, Icon, %A_LoopField%,shell32.dll,3,32
	}
	GuiControlGet, ControlHwnd, Hwnd, %A_GuiControl%
    ControlGetPos, x, y, w, h, ,ahk_id %ControlHwnd%
	Menu, Menu_KBLWin, Show,% x,% y+h+2
Return

getExePath(SubPat1){ ; 获取exe路径
	If (SubPat1!="" && RunAnyEvFullPath!="")
		try IniRead, ExePath, %RunAnyEvFullPath%, FullPath, %SubPat1%, %A_Space%
	If (ExePath="")
		Switch SubPat1
		{
			Case "Taskmgr.exe":ExePath:="C:\Windows\System32\Taskmgr.exe"
			Case "cmd.exe":ExePath:="C:\Windows\System32\cmd.exe"
			Case "explorer.exe":ExePath:="C:\Windows\explorer.exe"
		}
	Return ExePath
}

AddMenu_KBLWin(id,MenuItem) { ; 添加窗口Menu
	WinGetTitle title, ahk_id %id%
	WinGet, ExStyle, ExStyle, ahk_id %id%
	if (ExStyle & 0x20 || title = "" || title = "Program Manager")
		Return 0
	WinGetClass class, ahk_id %id%
	If (class = "ApplicationFrameWindow"){
		WinGetText, text, ahk_id %id%
		If (text = "")
		{
			WinGet, style, style, ahk_id %id%
			If !(style = "0xB4CF0000")	 ; the window isn't minimized
				Return 0
		}
	}
	WinGet, IcoPath, ProcessPath, ahk_id %id%
	If StrLen(MenuItem)>56 {
		endPos := InStr(MenuItem, "-",,0,1)
		endPos := endPos=0?-10:endPos
		leastLen := endPos=0?(StrLen(MenuItem)-10):endPos
		If (leastLen<46)
			MenuItem := SubStr(MenuItem,1,leastLen) "..." SubStr(MenuItem,endPos)
		Else
			MenuItem := SubStr(MenuItem,1,20) "..." SubStr(MenuItem,endPos-26)
	}
	Menu, Menu_KBLWin, Add,%MenuItem%, Label_Add_KBLWin
	Try Menu, Menu_KBLWin, Icon,%MenuItem%, %IcoPath%,,32
	Catch
		Menu, Menu_KBLWin, Icon,%MenuItem%,shell32.dll,3,32
	WinMenuObj[MenuItem] := id
	Return 1
}

Label_Add_KBLWin: ; 添加KBL窗口
	WinId := WinMenuObj[A_ThisMenuItem]
	item_key_val := getINIItem("ahk_id " WinId)
	item := item_key_val[0] "=" item_key_val[1]
	item := KBLWins=""?item:"`n" item
	item_regex := item_key_val[2]
	KBLWinsNew := KBLWins item
	Switch CurrentWin_AddFlag
	{
		Case "vCurrentWin_Add_Cn":KBLWins_hwnd:=KBLWinsCN_hwnd,RemoveFlag:=1
		Case "vCurrentWin_Add_CnEn":KBLWins_hwnd:=KBLWinsCNEN_hwnd,RemoveFlag:=1
		Case "vCurrentWin_Add_En":KBLWins_hwnd:=KBLWinsEN_hwnd,RemoveFlag:=1
		Case "vCurrentWin_Add_Disable_HotKey":KBLWins_hwnd:=DisableHotKey_hwnd,RemoveFlag:=0
		Case "vCurrentWin_Add_Disable_Switch":KBLWins_hwnd:=DisableSwitch_hwnd,RemoveFlag:=0
		Case "vCurrentWin_Add_Disable_TTShow":KBLWins_hwnd:=DisableTTShow_hwnd,RemoveFlag:=0
		Case "vCurrentWin_Add_FocusControl":KBLWins_hwnd:=FocusControl_hwnd,RemoveFlag:=0
	}
	GuiControl,, %KBLWins_hwnd% , %KBLWinsNew%
	WinMenuObj := Object()
	If (RemoveFlag!=1)
		Return
	KBLList := KBLWinsCN_hwnd "," KBLWinsCNEN_hwnd "," KBLWinsEN_hwnd
	Loop, parse, KBLList, `,
	{
	    If (A_LoopField=KBLWins_hwnd)
	    	Continue
	    Else {
	    	GuiControlGet, KBLWins,, %A_LoopField%
	    	RegExStr := IsHasSameRegExStr(KBLWins,item_regex)
	    	KBLWinsNew := RegExReplace(KBLWins, RegExStr)
	    	GuiControl,, %A_LoopField% , %KBLWinsNew%
	    }
	}
Return

Label_Sub_KBLWin: ; 移除KBL窗口
	KBLWinsNew := StrReplace(KBLWins, "`n" A_ThisMenuItem)
	KBLWinsNew := StrReplace(KBLWinsNew, A_ThisMenuItem "`n")
	KBLWinsNew := StrReplace(KBLWinsNew, A_ThisMenuItem)
	Switch CurrentWin_SubFlag
	{
		Case "vCurrentWin_Sub_Cn":GuiControl,, %KBLWinsCN_hwnd% , %KBLWinsNew%
		Case "vCurrentWin_Sub_CnEn":GuiControl,, %KBLWinsCNEN_hwnd% , %KBLWinsNew%
		Case "vCurrentWin_Sub_En":GuiControl,, %KBLWinsEN_hwnd% , %KBLWinsNew%
		Case "vCurrentWin_Sub_Disable_HotKey":GuiControl,, %DisableHotKey_hwnd% , %KBLWinsNew%
		Case "vCurrentWin_Sub_Disable_Switch":GuiControl,, %DisableSwitch_hwnd% , %KBLWinsNew%
		Case "vCurrentWin_Sub_Disable_TTShow":GuiControl,, %DisableTTShow_hwnd% , %KBLWinsNew%
		Case "vCurrentWin_Sub_FocusControl":GuiControl,, %FocusControl_hwnd% , %KBLWinsNew%
	}
Return

gAdvanced_Add: ; 自定义窗口添加
	ButtonNum := SubStr(A_GuiControl,7)
	If (ButtonNum=1)
		Gui, ListView, ahkGroupWin
	Else If (ButtonNum=3)
		Gui, ListView, CustomOperation
	RunRowNumber := LV_GetCount()+1
	ACvar1 := RunRowNumber,ACvar2 := ACvar3 := ACvar4 := ACvar5 := ""
	If (ButtonNum=1){
		gosub, Label_ahkGroupWin_Var
		Showvar := "添加窗口"
		NewOrder := getLVNewOrder()
	}
	Else If (ButtonNum=3){
		gosub, Label_CustomOperation_Var
		Showvar := "添加操作"
		NewOrder := getLVNewOrder()
	}
	gosub, Menu_AdvancedConfigEdit_Gui
Return

gAdvanced_Remove: ; 自定义窗口删除
	ButtonNum := SubStr(A_GuiControl,7)
	If (ButtonNum=2)
		Gui, ListView, ahkGroupWin
	Else If (ButtonNum=4)
		Gui, ListView, CustomOperation
	Loop
	{
	    RowNumber := LV_GetNext(RowNumber)  ; 在前一次找到的位置后继续搜索.
	    if not RowNumber  ; 上面返回零, 所以选择的行已经都找到了.
	        break
	    LV_Delete(RowNumber)
	}
	gosub, Label_Update_ListView
Return

gAdvanced_Config: ; 编辑高级配置
	if (A_GuiEvent="DoubleClick" && A_EventInfo>0){
		RunRowNumber := A_EventInfo
		Gui, ListView, %A_GuiControl%
		LV_GetText(ACvar1,RunRowNumber,1)
		LV_GetText(ACvar2,RunRowNumber,2)
		LV_GetText(ACvar3,RunRowNumber,3)
		LV_GetText(ACvar4,RunRowNumber,4)
		LV_GetText(ACvar5,RunRowNumber,5)
		If (A_GuiControl="AdvancedConfig")
			gosub,Label_AdvancedConfig_Var
		Else If (A_GuiControl="ahkGroupWin")
			gosub,Label_ahkGroupWin_Var
		Else If (A_GuiControl="CustomOperation")
			gosub,Label_CustomOperation_Var
		gosub, Menu_AdvancedConfigEdit_Gui
	}
Return

gAdvanced_Default: ; 高级配置恢复默认
	Switch RunRowNumber
	{
		Case 1:tempVar:="..\RunAny\RunAnyConfig.ini"
		Case 2:tempVar:=1
		Case 3:tempVar:="1|全局窗口"
		Case 4:tempVar:="Code.exe"
		Case 5:tempVar:="60|编辑器"
		Case 6:tempVar:="1"
		Case 7:tempVar:="2"
		Case 8:tempVar:="333434|dfe3e3|02ecfb|ff0000"
		Case 9:tempVar:="KBLAutoSwitch（%权限%）`n%启动时间%`n版本：%版本%`n自动切换统计：%自动切换次数%"
	}
	GuiControl,, %Advanced_Config_Edit_Hwnd1%, %tempVar%
Return

Label_ahkGroupWin_Var: ; 窗口组对应变量
	ConfigEdit_Flag := 1
	ConfigEdit_h := 247
	Text_w := 50
	Showvar := "窗口状态"
	Showvar1 := "窗口组"
	Showvar2 := "状态"
	Showvar3 := "内容"
	Showvar4 := ACvar3 . "：" StrSplit(Trim(ACvar4,"|"), "|").Length() . "： | 分隔"
	title := "高级窗口"
Return

Label_CustomOperation_Var: ; 自定义操作对应变量
	ConfigEdit_Flag := 2
	ConfigEdit_h := 232
	Text_w := 60
	Showvar := "高级操作"
	Showvar1 := "窗口组"
	Showvar2 := SubStr(ACvar3, 1, 2)="s-"?"热字串(s-)":"热键(k-)"
	Showvar3 := "操作"
	Showvar4 := (SubStr(ACvar3, 1, 2)="s-"?"热字串":"热键") . "：" StrSplit(Trim(ACvar3,"|"), "|").Length() . "： | 分隔"
	ACvar3 := SubStr(ACvar3, 3)
	title := "高级窗口"
Return

Label_AdvancedConfig_Var: ; 高级配置对应变量
	ConfigEdit_Flag := 3
	ConfigEdit_h := 202
	Text_w := 50
	Showvar := ACvar2
	Showvar1 := ""
	Showvar2 := ""
	Showvar3 := A_Space "值"
	Showvar4 := ACvar3
	title := "高级配置"
Return

Menu_AdvancedConfigEdit_Gui: ; 编辑配置Gui
	global Advanced_Config_Edit_Hwnd,Advanced_Config_Edit_Hwnd0,Advanced_Config_Edit_Hwnd1,Advanced_Config_Edit_Hwnd2
	global Advanced_Config_Group_Hwnd
	global Advanced_Config_Edit_Text0
	Gui,ConfigEdit:Destroy
	Gui,ConfigEdit:Default
	Gui,ConfigEdit:+Owner55
	Gui,ConfigEdit:Margin,20,20
	Gui,ConfigEdit:Font,,Microsoft YaHei
	Gui,ConfigEdit:Add, GroupBox,xm-10 y+10 w450 h%ConfigEdit_h% HwndAdvanced_Config_Group_Hwnd, %ACvar1%.%A_Space%%Showvar%：%Showvar4%
	If (ConfigEdit_Flag=1){
		Gui,ConfigEdit:Add, Text, Center xm yp+30 w%Text_w%,%Showvar1%
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd x+5 yp-2 w350 r2, %ACvar2%
		Gui,ConfigEdit:Add, Text, Center xm yp+50 w%Text_w%, %Showvar2%
		Gui,ConfigEdit:Add, DropDownList, HwndAdvanced_Config_Edit_Hwnd0 x+5 yp-2 w120, %ListViewKBLState%
		GuiControl, Choose, %Advanced_Config_Edit_Hwnd0%, % TransformStateReverse(ListViewKBLState,ACvar3)+1
		Gui,ConfigEdit:Add, Text, Center xm yp+35 w%Text_w%,%Showvar3%
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd1 x+5 yp-2 w350 r2, %ACvar4%
		Gui,ConfigEdit:Add, Text, Center xm yp+50 w%Text_w%,说明
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd2 x+5 yp-2 w350 r4 -WantReturn, %ACvar5%
	}Else If (ConfigEdit_Flag=2){
		Gui,ConfigEdit:Add, Text, Center xm yp+30 w%Text_w%, %Showvar1%
		Gui,ConfigEdit:Add, DropDownList, HwndAdvanced_Config_Edit_Hwnd x+5 yp-2 w120, %groupNameList%
		GuiControl, Choose, %Advanced_Config_Edit_Hwnd%, % groupNameObj[ACvar2]+1
		tempVar := SubStr(Showvar2, -2,2)
		If (tempVar="s-")
			tempVar1 := "+default",tempVar2 := ""
		Else
			tempVar2 := "+default",tempVar1 := ""
		Gui, ConfigEdit:Add, Button, %tempVar1% w50 h25 xm+300 yp ggOperation_Flag_HotString, 热字串
		Gui, ConfigEdit:Add, Button, %tempVar2% w50 h25 xm+360 yp ggOperation_Flag_HotKey, 热键
		Gui,ConfigEdit:Add, Text, HwndAdvanced_Config_Edit_Text0 Center xm yp+35 w%Text_w%,%Showvar2%
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd0 x+5 yp-2 w350 r2, %ACvar3%
		Gui,ConfigEdit:Add, Text, Center xm yp+50 w%Text_w%,%Showvar3%
		Gui,ConfigEdit:Add, DropDownList, HwndAdvanced_Config_Edit_Hwnd1 x+5 yp-2 w120, %OperationState%
		GuiControl, Choose, %Advanced_Config_Edit_Hwnd1%, % TransformStateReverse(OperationState,ACvar4)+1
		Gui,ConfigEdit:Add, Text, Center xm yp+35 w%Text_w%,说明
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd2 x+5 yp-2 w350 r4 -WantReturn, %ACvar5%
	}Else If (ConfigEdit_Flag=3){
		Gui,ConfigEdit:Add, Button, xm+350 yp-5 vButton11 ggAdvanced_Default, 恢复默认
		Gui,ConfigEdit:Add, Text, Center xm yp+35 w%Text_w%,%Showvar1%
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd x+5 yp-2 w350 r2, %ACvar2%
		Gui,ConfigEdit:Add, Text, Center xm yp+50 w%Text_w%, %Showvar2%
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd0 x+5 yp-2 w350 r2, %ACvar3%
		GuiControl, Hide, %Advanced_Config_Edit_Hwnd%
		GuiControl, Hide, %Advanced_Config_Edit_Hwnd0%
		Gui,ConfigEdit:Add, Text, Center xm yp-46 w%Text_w%,%Showvar3%
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd1 x+5 yp-2 w350 r4, %ACvar4%
		Gui,ConfigEdit:Add, Text, Center xm yp+90 w%Text_w%,说明
		Gui,ConfigEdit:Add, Edit, HwndAdvanced_Config_Edit_Hwnd2 x+5 yp-2 w350 r4 -WantReturn +ReadOnly, %ACvar5%
	}
	Gui,ConfigEdit:Font
	Gui,ConfigEdit:Add,Button,Default xm+140 y+25 w75 ggSetAdvancedConfig,保存(&S)
	Gui,ConfigEdit:Add,Button,x+20 w75 GgSet_Cancel,取消(&C)
	Gui,ConfigEdit:Show,,%title%
Return

gSetAdvancedConfig: ; 保存高级配置
	Gui,55:Default
	GuiControlGet, OutputVar,, %Advanced_Config_Edit_Hwnd%
	GuiControlGet, OutputVar0,, %Advanced_Config_Edit_Hwnd0%
	GuiControlGet, OutputVar1,, %Advanced_Config_Edit_Hwnd1%
	GuiControlGet, OutputVar2,, %Advanced_Config_Edit_Hwnd2%
	If (substr(Showvar,1,2)="添加" && ConfigEdit_Flag=1 && !groupNumObj.HasKey(NewOrder) && groupNameObj.HasKey(OutputVar)){
		FocusNum := LVFocusNum(2,OutputVar)
	}Else If (OutputVar!=""){
		If (!LV_GetText(tempVar, RunRowNumber , 1)){
			LV_Add(,RunRowNumber)
			LV_Modify(RunRowNumber, "Col1",NewOrder)
			FocusNum := NewOrder
		}Else
			FocusNum := RunRowNumber
		LV_Modify(RunRowNumber, "Col2",OutputVar)
		GuiControlGet, tempVar ,, %Advanced_Config_Edit_Text0%
		tempVar := SubStr(tempVar, -2,2)
		If (tempVar="s-" || tempVar="k-")
			LV_Modify(RunRowNumber, "Col3", tempVar . OutputVar0)
		Else
			LV_Modify(RunRowNumber, "Col3",OutputVar0)
		LV_Modify(RunRowNumber, "Col4",OutputVar1)
		LV_Modify(RunRowNumber, "Col5",OutputVar2)		
	}
	Gui,ConfigEdit:Destroy
	gosub, Label_Update_ListView
	If (ConfigEdit_Flag=1){
		Gui, ListView, ahkGroupWin
	}Else If (ConfigEdit_Flag=2){
		Gui, ListView, CustomOperation
	}Else If (ConfigEdit_Flag=3){
		Gui, ListView, AdvancedConfig
	}
	LV_Modify(FocusNum, "+Focus +Select +Vis")
Return

LVFocusNum(col,val) { ; 获取焦点行
	Loop % LV_GetCount()
	{
	    LV_GetText(OutputVar, A_Index, col)
	    if (OutputVar=val)
	        Return A_Index
	}
}

gSet_Cancel: ; 取消操作
	Gui,Destroy
return

gOperation_Flag_HotString: ; 自定义操作更改为热字串类型
	GuiControlGet, OutputVar ,, %Advanced_Config_Group_Hwnd%
	GuiControl,, %Advanced_Config_Group_Hwnd%, % StrReplace(OutputVar, "热键", "热字串")
	GuiControl,, %Advanced_Config_Edit_Text0%, 热字串(s-)
Return

gOperation_Flag_HotKey: ; 自定义操作更改为热键类型
	GuiControlGet, OutputVar ,, %Advanced_Config_Group_Hwnd%
	GuiControl,, %Advanced_Config_Group_Hwnd%, % StrReplace(OutputVar, "热字串", "热键")
	GuiControl,, %Advanced_Config_Edit_Text0%, 热键(k-)
Return

Label_Update_ListView: ; 更新展示数据
	Gui, ListView, ahkGroupWin
	Custom_Win_Group_temp := getListViewData("自定义窗口组")
	Gui, ListView, CustomOperation
	Custom_Hotstring_temp := getListViewData("自定义操作")
	global groupNameList := "无",groupNameObj := Object(),groupNumObj := Object()
	groupNameObj["无"] := 0
	groupNumObj[0] := "无"
	Loop, parse, Custom_Win_Group_temp, `n, `r
	{
		MyVar := StrSplit(Trim(A_LoopField), "=")		
		groupNameList .= "|" MyVar[2]
		groupNameObj[MyVar[2]] := MyVar[1]
		groupNumObj[MyVar[1]] := MyVar[2]
	}
	ListViewUpdate_Custom_Win_Group(Custom_Win_Group_temp)
	ListViewUpdate_Custom_Hotstring(Custom_Hotstring_temp)
	ListViewUpdate_Custom_Advanced_Config()
Return

Label_SetTimer_ResetKBL: ; 定时重置输入法状态
	If (A_TimeIdle>SetTimer_Reset_KBL_Time*1000){
		SendInput, {F22 up}
		gosub, Reset_KBL
	}
Return

;-----------------------------------【自定义功能】-----------------------------------------------
Add_To_Cn: ; 添加到中文窗口
	AddToKBLWin("中文窗口","中文窗口,英文窗口,英文输入法窗口")
Return

Add_To_CnEn: ; 添加到英文窗口（中文）
	AddToKBLWin("英文窗口","中文窗口,英文窗口,英文输入法窗口")
Return

Add_To_En: ; 添加到英文输入法窗口
	AddToKBLWin("英文输入法窗口","中文窗口,英文窗口,英文输入法窗口")
Return

Remove_From_All: ; 从配置窗口中移除，恢复为默认输入法
	AddToKBLWin("","中文窗口,英文窗口,英文输入法窗口")
Return

Set_Chinese: ; 当前窗口设为中文
	If (TarHotFunFlag=0 && Outer_InputKey_Compatible=1 && A_ThisHotkey!="" && A_PriorKey!=RegExReplace(A_ThisHotkey, "iS)(~|\s|up|down)", ""))
		Return
	If (Enter_Inputing_Content_CnTo=1)
		Gosub, Label_ToEnglishInputingOpera
	setKBLlLayout(0)
Return

Set_ChineseEnglish: ; 当前窗口设为英文（中文输入法）
	If (TarHotFunFlag=0 && Outer_InputKey_Compatible=1 && A_ThisHotkey!="" && A_PriorKey!=RegExReplace(A_ThisHotkey, "iS)(~|\s|up|down)", ""))
		Return
	Gosub, Label_ToEnglishInputingOpera
	setKBLlLayout(1)
Return

Set_English: ; 当前窗口设为英文
	If (TarHotFunFlag=0 && Outer_InputKey_Compatible=1 && A_ThisHotkey!="" && A_PriorKey!=RegExReplace(A_ThisHotkey, "iS)(~|\s|up|down)", ""))
		Return
	Gosub, Label_ToEnglishInputingOpera
	setKBLlLayout(2)
Return

Toggle_CN_CNEN: ; 切换中英文(中文)
	If (TarHotFunFlag=0 && Outer_InputKey_Compatible=1 && A_ThisHotkey!="" && A_PriorKey!=RegExReplace(A_ThisHotkey, "iS)(~|\s|up|down)", ""))
		Return
	KBLState := (getIMEKBL(gl_Active_IMEwin_id)!=EN_Code?(getIMECode(gl_Active_IMEwin_id)!=0?0:1):2)
	If (KBLState=0){
		Gosub, Label_ToEnglishInputingOpera
		setKBLlLayout(1)
	}Else If (KBLState=1 || KBLState=2)
		setKBLlLayout(0)
Return

Toggle_CN_EN: ; 切换中英文输入法
	If (TarHotFunFlag=0 && Outer_InputKey_Compatible=1 && A_ThisHotkey!="" && A_PriorKey!=RegExReplace(A_ThisHotkey, "iS)(~|\s|up|down)", ""))
		Return
	KBLState := (getIMEKBL(gl_Active_IMEwin_id)!=EN_Code?(getIMECode(gl_Active_IMEwin_id)!=0?0:1):2)
	If (KBLState=0){
		Gosub, Label_ToEnglishInputingOpera
		If (KBLEnglish_Exist=1)
			setKBLlLayout(2)
		Else
			setKBLlLayout(1)
	}Else If (KBLState=1 || KBLState=2)
		setKBLlLayout(0)
Return

Display_KBL: ; 显示当前的输入法状态
	showSwitch(,,1)
Return

Reset_KBL: ; 重置当前输入法键盘布局
	If (TarHotFunFlag=0 && Outer_InputKey_Compatible=1 && A_ThisHotkey!="" && A_PriorKey!=RegExReplace(A_ThisHotkey, "iS)(~|\s|up|down)", ""))
		Return
	gosub, Label_Shell_KBLSwitch
Return

Stop_KBLAS: ; 停止输入法自动切换
	gosub, Menu_Stop
Return

Get_KeyBoard: ; 手动检测键盘布局号码
	InputLocaleID := Format("{1:#x}", getIMEKBL(gl_Active_IMEwin_id))
	Clipboard := InputLocaleID
	MsgBox, 键盘布局号码：%InputLocaleID%`n`n已复制到剪贴板
Return

getINIItem(TarWin:="") { ; 获取设置INI文件的key-val
	Prev_DetectHiddenWindows := A_DetectHiddenWindows
	DetectHiddenWindows off
	item_key_val := Object()
	TarWin := TarWin=""?"A":TarWin
	WinGet, ahk_value, ProcessName, %TarWin%
	If (ahk_value = "taskmgr.exe"){
		item_key := "任务管理器"
		item_val = ahk_exe taskmgr.exe
		item_regex := item_val
	}Else If (ahk_value = "explorer.exe"){ ; 针对explorer的优化
		WinGetClass, ahk_value, %TarWin%
		If (ahk_value="CabinetWClass")
			item_key := "文件资源管理器"
		Else
			item_key := SubStr(ahk_value, 1, StrLen(ahk_value))
		item_val = ahk_class %ahk_value% ahk_exe explorer.exe
		item_regex := item_val
	}Else If (ahk_value = "ApplicationFrameHost.exe"){ ; 针对uwp应用的优化
		WinGetTitle uwp_title, %TarWin%
		startPos := InStr(uwp_title,"-",,0)+1
		item_key := SubStr(uwp_title, startPos)
		item_val = uwp %item_key%
		item_regex := item_val
	}Else{
		item_key := SubStr(ahk_value, 1, StrLen(ahk_value)-4)
		item_val = ahk_exe %ahk_value%
		item_regex := item_val "-|-" ahk_value
	}
	item_key_val[0] := item_key
	item_key_val[1] := item_val
	item_key_val[2] := item_regex
	DetectHiddenWindows %Prev_DetectHiddenWindows%
	Return item_key_val
}

IsHasSameRegExStr(Content,Value) { ; Content返回匹配对象
	RegExStr:=""
	Loop, parse, Content, `n, `r
	{
		If (euqalPos := InStr(A_LoopField, "=")){
			ReadyKey := SubStr(A_LoopField,1,euqalPos-1)
			ReadyValue := SubStr(A_LoopField,euqalPos+1)
		}Else{
			ReadyKey := ""
			ReadyValue := A_LoopField
		}
		word_array := StrSplit(Value, "-|-")
		For K, V in word_array {	
			If (ReadyValue=V)
				RegExStr .= "|\n" A_LoopField "|" A_LoopField "\n|" A_LoopField
		}
	}
	RegExStr := Trim(RegExStr,"|")
	return RegExStr=""?RegExStr:"(" RegExStr ")"
}

GetRealItem_key(Section,item_key) { ; 获取合适的Item_key
	original_item_key := item_key
	Loop
	{
		IniRead, res, %INI%, %Section%, %item_key%
		If (res!="ERROR"){
			item_key := original_item_key "_重名" A_Index
		}Else{
			Return item_key
		}
	}
}

AddToKBLWin(KBLName,KBLList,TarWin:="") { ; 将当前窗口添加至指定KBL窗口，KBL窗口为空则去除
	Thread, NoTimers , True
	item_key_val := getINIItem(TarWin)
	item_key := item_key_val[0]
	item_val := item_key_val[1]
	item_regex := item_key_val[2]
	If (item_key = "")
		Return
	If (KBLName!=""){	
		IniRead, res, %INI%, %KBLName%
		TarItem_keys := IsHasSameRegExStr(res,item_regex)
		If (TarItem_keys!="") {
			msg := "【" TarItem_keys[1] "】 已存在于【" KBLName "】！"
		}Else{
			item_key := GetRealItem_key(KBLName,item_key)
			IniWrite, %item_val%, %INI%, %KBLName%, %item_key%
			msg := "【" item_key "】 添加到【" KBLName "】 【成功】！"
		}
	}Else
		msg := "【" item_key "】 移除 【成功】！"
	Loop, parse, KBLList, `,
	{
	    If (A_LoopField=KBLName)
	    	Continue
	    Else {
	    	IniRead, res, %INI%, %A_LoopField%
	    	RegExStr := IsHasSameRegExStr(res,item_regex)
	    	resNew := RegExReplace(res, RegExStr)
	    	IniDelete, %INI%, %A_LoopField%
	    	IniWrite, %resNew%, %INI%, %A_LoopField%
	    }
	}
	showToolTip(msg, State_ShowTime)
	Thread, NoTimers , False
}
;--------------------------------------------------------------------------------------------

TarHotFun: ; 热字串功能触发
	TarHotFunFlag := 2 ; 1表示热字符串，2表示热键
	TarHotVal := A_ThisHotkey
	If (SubStr(TarHotVal, 1, 6)=":*XB0:"){
		TarHotVal := SubStr(TarHotVal, 7)
		TarHotFunFlag := 1
	}
	Switch % TarFunList[TarHotVal]
	{
		Case 1: Gosub, Set_Chinese
		Case 2: Gosub, Set_ChineseEnglish
		Case 3: Gosub, Set_English
		Case 4: Gosub, Toggle_CN_CNEN
		Case 5: Gosub, Toggle_CN_EN
		Case 6: Gosub, Reset_KBL
	}
	TarHotFunFlag := 0
Return

BoundHotkey(BoundHotkey,Hotkey_Fun) { ; 绑定特殊热键
	Switch Hotkey_Fun
	{
		Case 1: Hotkey, %BoundHotkey%, Set_Chinese
		Case 2: Hotkey, %BoundHotkey%, Set_ChineseEnglish
		Case 3: Hotkey, %BoundHotkey%, Set_English
		Case 4: Hotkey, %BoundHotkey%, Toggle_CN_CNEN
		Case 5: Hotkey, %BoundHotkey%, Toggle_CN_EN
		Case 6: Hotkey, %BoundHotkey%, Reset_KBL
	}
}

getCurPath(Cur_Style:="",k:=1080,CurName:="") { ; 获取鼠标指针路径
	if FileExist(A_ScriptDir "\Curs\" Cur_Style "\" k "\" CurName ".ani")
    	CurPath := A_ScriptDir "\Curs\" Cur_Style "\" k "\" CurName ".ani"
    Else
    	CurPath := A_ScriptDir "\Curs\" Cur_Style "\" k "\" CurName ".cur"
    Return CurPath
}

Label_Click_showSwitch: ; 左键点击提示
	If (A_Cursor!="IBeam"){
		If (shellMessageFlag=0)
			SetTimer, Label_Hide_All, -100
		Return
	}
	If WinActive("ahk_group Left_Mouse_ShowKBL_Up_WinGroup"){
		KeyWait, LButton, L
	}
	If OSVersion<=7
		SetTimer,SetTimer_Label_Click_showSwitch,-100
	Else
		SetTimer,SetTimer_Label_Click_showSwitch,-20
	Return

	SetTimer_Label_Click_showSwitch:
		showSwitch(LastKBLState,LastCapsState,1)
Return

Label_ToEnglishInputingOpera: ; 切换到英文时处理已输入的字符
	Thread, NoTimers, True
	DetectHiddenWindows off
	SetTitleMatchMode, RegEx
	WinGet, binglingCount, Count, ahk_class i)^ATL:
	If (Enter_Inputing_Content_Core!=0 && WinExist("ahk_group IMEInput_ahk_group") && binglingCount!=1){
		Switch Enter_Inputing_Content_Core
		{
			Case 1:SendInput, {Esc}
			Case 2:SendInput, {Enter}
			Case 3:SendInput, {Space}
		}
	}
	SetTitleMatchMode, 2
	DetectHiddenWindows on
	Thread, NoTimers, False
Return

Label_ReadCustomKBLWinGroup: ; 读取自定义KBL窗口组
	Loop, parse, Custom_Win_Group, `n, `r
	{
		MyVar := StrSplit(Trim(A_LoopField), "=")
		groupName := MyVar[2]
		groupState := MyVar[3]
		Switch groupState
		{
			Case 1:Custom_Win_Group_Cn .= "`n-" groupName
			Case 2:Custom_Win_Group_CnEn .= "`n-" groupName
			Case 3:Custom_Win_Group_En .= "`n-" groupName
		}
		Custom_Win_Group_Cn := Trim(Custom_Win_Group_Cn," `t`n")
		Custom_Win_Group_CnEn := Trim(Custom_Win_Group_CnEn," `t`n")
		Custom_Win_Group_En := Trim(Custom_Win_Group_En," `t`n")
	}
Return

Label_ReadExistIcoStyles: ; 读取Icos文件夹图标
	global ExistIcoStyles := "" ;鼠标指针分辨率字符串
	Loop Files, %A_ScriptDir%\Icos\*, D
		ExistIcoStyles := ExistIcoStyles "|" A_LoopFileName
	if (Tray_Display_Style="" or !InStr(ExistIcoStyles, "|" Tray_Display_Style))
		Tray_Display_Style := TransformState(ExistIcoStyles,1)
	ExistIcoStyles := Trim(ExistIcoStyles,"|")
Return

Label_ReadExistCurStyles: ; 读取Curs文件夹鼠标指针
	global ExistCurStyles := "" ;鼠标指针分辨率字符串
	Loop Files, %A_ScriptDir%\Curs\*, D
		ExistCurStyles := ExistCurStyles "|" A_LoopFileName
	if (Cur_Launch_Style="" or !InStr(ExistCurStyles, "|" Cur_Launch_Style))
		Cur_Launch_Style := TransformState(ExistCurStyles,1)
	ExistCurStyles := Trim(ExistCurStyles,"|")
Return

Label_ReadExistEXEIcos: ; 读取exe图标
	global RunAnyEvFullPath := ""
	If (InStr(Open_Ext, "RunAnyConfig.ini"))
		IniRead, RunAEvFullPathIniDir, % GetAbsPath(Open_Ext), Config, RunAEvFullPathIniDir, %A_Space%
		If (RunAEvFullPathIniDir="")
			RunAnyEvFullPath := A_AppData "\RunAny\RunAnyEvFullPath.ini"
		Else
			RunAnyEvFullPath := GetAbsPath(RunAEvFullPathIniDir) "\RunAnyEvFullPath.ini"
		If (!FileExist(RunAnyEvFullPath))
			RunAnyEvFullPath := ""
Return

ExitFunc() { ; 退出执行-还原鼠标指针
	DllCall( "SystemParametersInfo", "UInt",0x57, "UInt",0, "UInt",0, "UInt",0 ) ;还原鼠标指针
}

;-----------------------------------【接收消息功能】-----------------------------------------------
Receive_WM_COPYDATA(ByRef wParam,ByRef lParam) {
    StringAddress := NumGet(lParam + 2*A_PtrSize)  ; 获取 CopyDataStruct 的 lpData 成员.
    CopyOfData := StrGet(StringAddress)  ; 从结构中复制字符串.
    Remote_Dyna_Run(CopyOfData)
    return 1  ; 返回 1(true) 是回复此消息的传统方式.
}

;~;[外部动态运行函数和插件]
Remote_Dyna_Run(remoteRun) {
	if(IsLabel(remoteRun)){
		Gosub,%remoteRun%
		return
	}
}

Label_ClearMEM: ; 清理内存
    pid:=() ? DllCall("GetCurrentProcessId") : pid
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
Return

Send_WM_COPYDATA(ByRef StringToSend, ByRef TargetScriptTitle, wParam:=0) { ; 发送消息
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

;获取输入光标位置，源代码来源：https://www.autoahk.com/archives/16443
GetCaret(Byref CaretX="", Byref CaretY="") {
	static init
	CoordMode, Caret, Screen
	Loop 2
	{
		CaretX:=A_CaretX, CaretY:=A_CaretY
		If (CaretX or CaretY)
			Break
		Else
			Sleep 10
	}
	If WinActive("ahk_group GetCaretSleep_ahk_group") {
		LoopCount := 10
	}Else
		LoopCount := 1
	if (!CaretX or !CaretY){
		Loop %LoopCount%
		{
			Try {
				if (!init)
					init:=DllCall("GetProcAddress", "Ptr", DllCall("LoadLibrary", "Str", "oleacc", "Ptr"), "AStr", "AccessibleObjectFromWindow", "Ptr")
				VarSetCapacity(IID,16), idObject:=OBJID_CARET:=0xFFFFFFF8
				, NumPut(idObject==0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0, IID, "Int64")
				, NumPut(idObject==0xFFFFFFF0?0x46000000000000C0:0x719B3800AA000C81, IID, 8, "Int64")
				if DllCall(init, "Ptr",WinExist("A"), "UInt",idObject, "Ptr",&IID, "Ptr*",pacc)=0 {
					Acc:=ComObject(9,pacc,1), ObjAddRef(pacc)
					, Acc.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0)
					, ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), ChildId:=0)
					, CaretX:=NumGet(x,0,"int"), CaretY:=NumGet(y,0,"int"),ObjRelease(pacc)
				}
			}
			If (CaretX or CaretY)
				Break
			Else
				Sleep 20
		}
	}
	return {x:CaretX, y:CaretY}
}

;-----------------------------------【内部关联功能】-----------------------------------------------
ReadExtRunList(Open_Ext,openExtList:="") { ; 读取内部关联
	openExtListObj := Object()
	Loop, parse, openExtList, |
	    openExtListObj[A_LoopField]:=1
	if (openExtListObj.Count()=0)
        openExtListObj := 0
    Open_Ext_Abs := GetAbsPath(Open_Ext)
    SplitPath, Open_Ext_Abs, OutFileName
    If (OutFileName="RunAnyConfig.ini")
        ReadExtRunList_RA(Open_Ext_Abs,openExtListObj)
    Return openExtRunList.Count()
}

ReadExtRunList_RA(openExtConfig,openExtListObj) { ; 读取内部关联-RA
    IniRead, openExtVar, %openExtConfig%, OpenExt
    openExtVar := StrReplace(openExtVar, "`%A_ScriptDir`%", "`%A_WorkingDir`%")
    SplitPath, openExtConfig, OutFileName, OutDir
    WorkingDirOld := A_WorkingDir
    SetWorkingDir, %OutDir%
    Loop, parse, openExtVar, `n, `r
    {
        File_Open_Exe_Parm := ""
        itemList := StrSplit(A_LoopField,"=",,2)
        File_Open_Exe := itemList[1]
        File_Open_Exe_Parm_Pos := InStr(File_Open_Exe, ".exe ")
        If (File_Open_Exe_Parm_Pos!=0){
            File_Open_Exe_Parm := SubStr(File_Open_Exe, File_Open_Exe_Parm_Pos+5)
            File_Open_Exe := SubStr(File_Open_Exe, 1, File_Open_Exe_Parm_Pos+3)
        }
        File_Open_Exe := GetOpenExe(File_Open_Exe,openExtConfig)
        If (File_Open_Exe!=""){
            Loop, parse,% itemList[2], %A_Space%
            {
            	if (openExtListObj!=0 && openExtListObj.Count()=0)
            		Break
                extLoopField:=RegExReplace(A_LoopField,"^\.","")
                If(extLoopField="http" or extLoopField="https" or extLoopField="www" or extLoopField="ftp")
                    extLoopField := "html"
                if (openExtListObj=0 || openExtListObj.HasKey(extLoopField)){
                	openExtRunList[extLoopField] := File_Open_Exe
                	openExtRunList_Parm[extLoopField] := File_Open_Exe_Parm
                	openExtListObj.Delete(extLoopField)
                }
            }
        }
    }
    SetWorkingDir %WorkingDirOld%
    WorkingDirOld := A_WorkingDir
}

GetOpenExe(Open_Exe,RunAnyConfigPath) { ; 获取打开后缀的应用（RA无路径）
    IniRead, RunAEvFullPathIniDir, %RunAnyConfigPath%, Config, RunAEvFullPathIniDir, %A_Space%
    If (RunAEvFullPathIniDir="")
        RunAnyEvFullPath := A_AppData "\RunAny\RunAnyEvFullPath.ini"
    Else{
        Transform, RunAnyEvFullPath, Deref, % RunAEvFullPathIniDir
        RunAnyEvFullPath := RunAnyEvFullPath "\RunAnyEvFullPath.ini"
    }
    If (Open_Exe="")
        Return Open_Exe
    Open_Exe_Abs := GetAbsPath(Open_Exe)
    If !FileExist(Open_Exe_Abs)
        IniRead, Open_Exe, %RunAnyEvFullPath%, FullPath, %Open_Exe%, %Open_Exe%
    Else
        Open_Exe := Open_Exe_Abs
    Return Open_Exe
}

GetAbsPath(filePath) { ; 获取文件绝对路径
    Transform, filePath, Deref, %filePath%
    SplitPath, filePath, OutFileName, OutDir
    WorkingDirOld := A_WorkingDir
    SetWorkingDir, %OutDir%
    filePath := A_WorkingDir "\" OutFileName
    SetWorkingDir %WorkingDirOld%
    WorkingDirOld := A_WorkingDir
    Return filePath
}
;----------------------------------------------------------------------------------------------
