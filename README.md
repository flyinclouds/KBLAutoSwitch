# AHK输入法键盘布局自动切换

#### 介绍
基于AutoHotkey的自动切换输入法键盘布局
1. 可针对不同的应用自动切换中英文键盘布局
2. 可设置切换输入法在屏幕右下角文字提示
3. 可设置切换输入法在鼠标位置文字提示
4. 可设置中英文键盘布局、提示方式、文字提示样式及内容、应用默认输入法等

#### 下载地址
1. KBLAutoSwitch下载
    1. Gitee下载：
    2. GitHub下载：
    3. 蓝奏云下载：
    4. 百度云下载：
    5. 阿里云下载
2. Runany官网：https://hui-zz.gitee.io/runany/#/
3. AutoHotkey官网：https://www.autohotkey.com/

#### 安装教程
1. 作为RunAny插件使用
    1. 下载安装Runany https://hui-zz.gitee.io/runany/#/ 
    2. 下载KBLAutoSwitch源代码压缩包并解压
    3. 将Kawvin_AutoIME_tong_vx.xx.ahk和Kawvin_AutoIME.ini文件移动至Runany的RunPlugins文件夹
    4. 打开Runany的插件管理找到对应脚本文件设置为启动、自启，屏幕右下角显示当前输入法表示安装成功
2. exe方式运行
    1. 下载直接KBLAutoSwitch运行文件压缩包并解压
    2. 运行KBLAutoSwitch_x.xx.exe，屏幕右下角显示当前输入法表示安装成功
3. 以AHK脚本运行
    1. 安装AutoHotkey V1版本 https://www.autohotkey.com/ 并安装
    2. 下载KBLAutoSwitch源代码文件
    3. 运行Kawvin_AutoIME_tong_vx.xx.ahk文件，屏幕右下角显示当前输入法表示安装成功

#### 使用说明
1. 文件说明
    1. 源代码文件
        1. Kawvin_AutoIME_tong_vx.xx.ahk    输入法键盘布局自动切换脚本文件        【必要文件】
        2. Kawvin_AutoIME.ini               脚本配置文件                        【必要文件】，与主文件同路径，更改文件后需重新启动脚本
        3. get_keyboard_x.xx.ahk            键盘布局代码获取脚本文件             【非必要文件】，需要时打开使用
        4. AU3_Spy.exe                      窗口信息查看程序                    【非必要文件】，需要时打开使用
    2. 可执行文件
        1. KBLAutoSwitch_x.xx.exe           输入法键盘布局自动切换程序            【必要文件】
        2. Kawvin_AutoIME.ini               脚本配置文件                         【必要文件】，与主文件同路径，更改文件后需重新启动脚本
        3. GetKeyBoard_x.xx.exe             键盘布局代码获取程序文件，F10获取当前键盘布局代码    【非必要文件】，需要时打开使用
        4. AU3_Spy.exe                      窗口信息查看程序    【非必要文件】，需要时打开使用
2. 使用步骤
    1. 打开需要切换输入法的程序，运行AU3_Spy.exe，鼠标移至目标程序后获取目标程序ahk_exe sample.exe
    2. 打开Kawvin_AutoIME.ini配置文件，按照备注配置
    3. 作为RunAny插件运行，,或者以exe方式运行，或者以AHK脚本运行
3. 特殊说明
    1. 输入习惯问题：因为切换到窗口自动设置输入法，所以需要在系统里面设置切换快捷键，默认为win+空格，且不可设置为其他快捷键，否者使用快捷键切换不显示切换提示，可以修改源码，自行映射切换快捷键。
    2. 如果不显示切换提示，一般为分辨率问题，默认是1080P，可以先设置成ToolTip显示，查看是否生效，若生效，再调整水平系数、垂直系数等调整屏幕位置。

#### 参与贡献
1. 基于原作者【lspcieee】自动切换输入法脚本，后由【心如止水】改编。

#### 特技
1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
