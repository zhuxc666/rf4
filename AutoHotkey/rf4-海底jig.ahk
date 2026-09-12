#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 3
#SingleInstance Force

; ===================================================
; 全局配置与状态
; ===================================================
global Toggle1 := false
global Toggle2 := false

; ===================================================
; 辅助函数
; ===================================================

; 1. 随机时间辅助函数 (已修复负数崩溃 Bug)
GetRandomSleep(baseTime) {
    ; 为了更拟人，波动幅度应该与时长成正比
    ; 如果时间短(比如100ms)，波动就小点；时间长，波动就大点
    variance := baseTime * 0.2  ; 波动幅度为时间的 20%
    
    ; 如果计算出的波动小于 20ms，至少给 20ms 波动
    if (variance < 20)
        variance := 20
        
    finalTime := baseTime + Random(-variance, variance)
    
    ; 【核心修复】使用 Max 函数确保时间永远不小于 50ms
    ; 防止产生负数导致 crash，也防止过快按键游戏不响应
    return Max(50, Integer(finalTime))
}

; 2. 可中断的睡眠函数
SmartSleep(sleepTime, &toggleVar) {
    ; 确保 sleepTime 也是正数
    sleepTime := Max(0, sleepTime)
    
    loopCount := sleepTime // 100
    remaining := Mod(sleepTime, 100)
    
    Loop loopCount {
        if (!toggleVar)
            return false
        Sleep(100)
    }
    
    if (!toggleVar)
        return false
        
    Sleep(remaining)
    return true
}

; ===================================================
; F1：抛竿 & 海底 Jig
; ===================================================
*$F1::
{
    global Toggle1, Toggle2
    Toggle1 := !Toggle1 

    if (Toggle1) {
        ToolTip("F1：抛竿/Jig 模式 ON")
        SetTimer(() => ToolTip(), -1000)

        ; 互斥：关掉 F2
        if (Toggle2) {
            Toggle2 := false
            Sleep(200)
            CleanupF2()
        }

        ; 1. 抛竿动作
        Send("{`` down}")
        Sleep(GetRandomSleep(90))
        Send("{`` up}")
        
        ; 2. 等待鱼饵下沉 (20秒左右)
        if !SmartSleep(GetRandomSleep(20000), &Toggle1)
            return

        ; 3. 开启 Jig 循环
        while Toggle1 {
            ; 模拟鼠标左键 (提竿)
            Send("{LButton down}") 
            
            ; 【修复】这里之前是变量 c，现已修复为具体数值 1109
            if !SmartSleep(GetRandomSleep(1109), &Toggle1) {
                Send("{LButton up}") 
                break
            }
            Send("{LButton up}")   
            
            ; 模拟回车 (收线一小段)
            Send("{Enter down}")   
            Sleep(GetRandomSleep(85))             
            Send("{Enter up}")  
            
            if !Toggle1 
                break
                
            ; 等待下沉 (3秒)
            if !SmartSleep(GetRandomSleep(3068), &Toggle1)
                break
        }
    } else {
        Send("{LButton up}")
        ToolTip("F1：停止")
        SetTimer(() => ToolTip(), -1000)
    }
}

; ===================================================
; F2：快速抬杆收鱼
; ===================================================
*$F2::
{
    global Toggle1, Toggle2
    Toggle2 := !Toggle2 

    if (Toggle2) {
        ToolTip("F2：快速收鱼模式 ON")
        SetTimer(() => ToolTip(), -1000)
        
        ; 互斥：关掉 F1
        if (Toggle1) {
            Toggle1 := false
            Sleep(200)
            Send("{LButton up}") 
        }
        
        Send("{Shift down}{`` down}")
        Sleep(GetRandomSleep(100)) 
        
        while Toggle2 {
            Send("{= down}")  
            
            ; 持续按住
            if !SmartSleep(GetRandomSleep(2514), &Toggle2) {
                break 
            }
            
            Send("{= up}")    
            
            ; 松开
            if !SmartSleep(GetRandomSleep(2237), &Toggle2) {
                break
            }
        }
        
        CleanupF2()
        
    } else {
        CleanupF2()
        ToolTip("F2：停止")
        SetTimer(() => ToolTip(), -1000)
    }
}

CleanupF2() {
    Send("{= up}")
    Sleep(50)
    Send("{`` up}")
    Sleep(50)
    Send("{Shift up}")
}

; ===================================================
; F3：关闭结算 + 强制重置
; ===================================================
*$F3::
{
    global Toggle1, Toggle2
    
    Toggle1 := false
    Toggle2 := false
    
    Send("{Shift up}")
    Send("{`` up}")
    Send("{= up}")
    Send("{LButton up}")
    Send("{Enter up}")
    
    Send("{Space down}")
    Sleep(GetRandomSleep(75)) 
    Send("{Space up}")
    
    ToolTip("F3：全局重置 & 关闭结算")
    SetTimer(() => ToolTip(), -1000)
}

; ===================================================
; 紧急救援键 (End)
; ===================================================
*End::
{
    global Toggle1 := false, Toggle2 := false
    BlockInput(false)
    Send("{Shift up}{`` up}{= up}{LButton up}{Enter up}{F1 up}{F2 up}{Ctrl up}{Alt up}")
    SoundBeep(1000, 200)
    ToolTip("！！！EMERGENCY STOP！！！")
    SetTimer(() => ToolTip(), -2000)
}