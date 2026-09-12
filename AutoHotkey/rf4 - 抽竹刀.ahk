#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 3
#SingleInstance Force

; ===================================================
; 全局配置与状态
; ===================================================
global Toggle1 := false
global Toggle2 := false
global Toggle3 := false ; F4的状态变量 [cite: 1]

; ===================================================
; 辅助函数
; ===================================================

; 1. 随机时间辅助函数 [cite: 2]
GetRandomSleep(baseTime) {
    variance := baseTime * 0.2
    if (variance < 20)
        variance := 20
    finalTime := baseTime + Random(-variance, variance)
    return Max(50, Integer(finalTime))
}

; 2. 可中断的睡眠函数 [cite: 3, 4]
SmartSleep(sleepTime, &toggleVar) {
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

; 3. 完整的抛竿与轻抽循环 (F1, F5 等共用)
StartFishingCycle() {
    global Toggle1
    
    ; 1. 抛竿动作
    Send("{`` down}")
    Sleep(GetRandomSleep(110))
    Send("{`` up}")
    Sleep(GetRandomSleep(110))
    
    ; 2. 等待鱼饵下沉 (如果中途中断，会直接 return)
    if !SmartSleep(GetRandomSleep(15000), &Toggle1)
        return

    ; 3. 关闭线组，开始轻抽
    Send("{`` down}")
    Sleep(GetRandomSleep(110))
    Send("{`` up}")
    Sleep(GetRandomSleep(110))
    
    while Toggle1 {
        Send("{= down}")  
        
        if !SmartSleep(GetRandomSleep(500), &Toggle1) {
            break 
        }
        
        Send("{= up}")    
        
        if !SmartSleep(GetRandomSleep(1200), &Toggle1) {
            break
        }
    }
    
    ; 退出循环时的清理状态
    Send("{= up}")
}

; ===================================================
; F1：抛竿 & 修改后的循环模式
; ===================================================
*$F1::
{
    global Toggle1, Toggle2, Toggle3
    Toggle1 := !Toggle1 

    Sleep(GetRandomSleep(600))

    if (Toggle1) {
        ToolTip("F1：抛竿/等号循环 ON")
        SetTimer(() => ToolTip(), -1000)

        ; 互斥逻辑
        if (Toggle2 || Toggle3) {
            Toggle2 := false
            Toggle3 := false
            Sleep(GetRandomSleep(200))
            CleanupF2() 
            Send("{LButton up}") 
        }

        ; 执行完整的抛竿与轻抽循环
        StartFishingCycle()

    } else {
        Send("{= up}")
        ToolTip("F1：停止")
        SetTimer(() => ToolTip(), -1000)
    }
}

; ===================================================
; F2：快速抬杆收鱼
; ===================================================
*$F2::
{
    global Toggle1, Toggle2, Toggle3
    Toggle2 := !Toggle2 

    if (Toggle2) {
        ToolTip("F2：快速收鱼模式 ON")
        SetTimer(() => ToolTip(), -1000)
        
        if (Toggle1 || Toggle3) {
            Toggle1 := false
            Toggle3 := false
            Sleep(GetRandomSleep(200))
            Send("{LButton up}")
            Send("{= up}")
            Sleep(GetRandomSleep(110))
        }
        
        Send("{Shift down}")
        Sleep(GetRandomSleep(110))
        Send("{`` down}")
        Sleep(GetRandomSleep(100))
        
        while Toggle2 {
            Send("{= down}")  
            if !SmartSleep(GetRandomSleep(2514), &Toggle2)
                break 
            
            Send("{= up}")    
            if !SmartSleep(GetRandomSleep(2237), &Toggle2)
                break
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
    Sleep(GetRandomSleep(110))
    Send("{`` up}")
    Sleep(GetRandomSleep(110))
    Send("{Shift up}")
    Sleep(GetRandomSleep(110))
}

; ===================================================
; F3：关闭结算 + 强制重置 [cite: 22, 23, 24, 25]
; ===================================================
*$F3::
{
    global Toggle1, Toggle2, Toggle3
    Toggle1 := false
    Toggle2 := false
    Toggle3 := false 
    
    Send("{Shift up}{`` up}{= up}{LButton up}{Enter up}")
    Sleep(GetRandomSleep(110))
    Send("{Space down}")
    Sleep(GetRandomSleep(110))
    Send("{Space up}")
    
    ToolTip("F3：全局重置 & 关闭结算")
    SetTimer(() => ToolTip(), -1000)
}

; ===================================================
; F4：点击循环 [cite: 26, 27, 28, 29, 30, 31, 32, 33, 34, 35]
; ===================================================
*$F4::
{
    global Toggle1, Toggle2, Toggle3
    Toggle3 := !Toggle3

    if (Toggle3) {
        ToolTip("F4：自动点击循环 ON")
        SetTimer(() => ToolTip(), -1000)

        while Toggle3 {
            Send("{LButton down}")
            Sleep(GetRandomSleep(100))
            Send("{LButton up}")
            
            if !SmartSleep(GetRandomSleep(4000), &Toggle3)
                break

            Send("{LButton down}")
            Sleep(GetRandomSleep(100))
            Send("{LButton up}")
            
            if !SmartSleep(GetRandomSleep(300), &Toggle3)
                break

            Send("{LButton down}")
            Sleep(GetRandomSleep(100))
            Send("{LButton up}")

            if !SmartSleep(GetRandomSleep(500), &Toggle3)
                break
        }
        Send("{LButton up}")
    } else {
        Send("{LButton up}")
        ToolTip("F4：停止")
        SetTimer(() => ToolTip(), -1000)
    }
}

; ===================================================
; F5：扔鱼 + 强制重置 + 重新执行抛竿循环
; ===================================================
*$F5::
{
    global Toggle1, Toggle2, Toggle3
    
    ; 先强行中断当前可能正在运行的其他循环
    Toggle1 := false
    Toggle2 := false
    Toggle3 := false 
    
    Send("{Shift up}{`` up}{= up}{LButton up}{Enter up}")
    Sleep(GetRandomSleep(1100))
    
    ; 扔鱼动作
    Send("{Backspace down}")
    Sleep(GetRandomSleep(110))
    Send("{Backspace up}")
    
    ToolTip("F5：扔鱼并重新开始抛竿循环")
    SetTimer(() => ToolTip(), -1000)
    
    ; 扔鱼动画缓冲延时（根据实际游戏手感可微调这个 800）
    Sleep(GetRandomSleep(800)) 
    
    ; 重新激活 F1 的状态变量，并调用完整的抛竿循环
    Toggle1 := true
    StartFishingCycle()
}

; ===================================================
; 紧急救援键 (End) [cite: 40]
; ===================================================
*End::
{
    global Toggle1 := false, Toggle2 := false, Toggle3 := false
    BlockInput(false)
    Send("{Shift up}{`` up}{= up}{LButton up}{Enter up}{F1 up}{F2 up}{F4 up}{Ctrl up}{Alt up}")
    SoundBeep(1000, 200)
    ToolTip("！！！EMERGENCY STOP！！！")
    SetTimer(() => ToolTip(), -2000)
}
