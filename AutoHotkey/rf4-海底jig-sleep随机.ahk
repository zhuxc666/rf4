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

; 1. 随机时间辅助函数
; 算法逻辑：
; - 波动幅度 = 基准时间 * 20% (如果波动小于20ms，则强制为20ms)
; - 最终时间 = 基准时间 ± 波动幅度
; - 强制限制：最终返回的时间绝对不会小于 50ms
GetRandomSleep(baseTime) {
    variance := baseTime * 0.2
    
    if (variance < 20)
        variance := 20
        
    finalTime := baseTime + Random(-variance, variance)
    
    return Max(50, Integer(finalTime))
}

; 2. 可中断的睡眠函数
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
            Sleep(GetRandomSleep(200)) ; [范围: 160 - 240 ms]
            CleanupF2()
        }

        ; 1. 抛竿动作
        Send("{`` down}")
        Sleep(GetRandomSleep(110))     ; [范围: 88 - 132 ms] (原90，已修正)
        Send("{`` up}")
        Sleep(GetRandomSleep(110))     ; [范围: 88 - 132 ms] (原50，已修正)
        
        ; 2. 等待鱼饵下沉 (20秒)
        if !SmartSleep(GetRandomSleep(20000), &Toggle1) ; [范围: 16000 - 24000 ms]
            return

        ; 3. 开启 Jig 循环
        while Toggle1 {
            ; --- 收线动作 ---
            Send("{LButton down}") 
            
            ; 收线持续时间 (约1.1秒)
            if !SmartSleep(GetRandomSleep(1109), &Toggle1) { ; [范围: 887 - 1331 ms]
                Send("{LButton up}") 
                Sleep(GetRandomSleep(110)) ; [范围: 88 - 132 ms] (原50，已修正)
                break
            }
            Send("{LButton up}")   
            Sleep(GetRandomSleep(110))     ; [范围: 88 - 132 ms] (原50，已修正)
            
            ; --- 放线动作 ---
            Send("{Enter down}")   
            Sleep(GetRandomSleep(110))     ; [范围: 88 - 132 ms] (原85，已修正)
            Send("{Enter up}")  
            Sleep(GetRandomSleep(110))     ; [范围: 88 - 132 ms] (原50，已修正)
            
            if !Toggle1 
                break
                
            ; --- 等待放线 (约3秒) ---
            if !SmartSleep(GetRandomSleep(3068), &Toggle1) ; [范围: 2454 - 3682 ms]
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
            Sleep(GetRandomSleep(200)) ; [范围: 160 - 240 ms]
            Send("{LButton up}") 
            Sleep(GetRandomSleep(110)) ; [范围: 88 - 132 ms] (原50，已修正)
        }
        
        ; 准备动作：按住 Shift 和 `
        Send("{Shift down}")
        Sleep(GetRandomSleep(110))     ; [范围: 88 - 132 ms] (原50，已修正)
        Send("{`` down}")
        Sleep(GetRandomSleep(100))     ; [范围: 80 - 120 ms] (100未小于100，保持原样)
        
        while Toggle2 {
            Send("{= down}")  
            
            ; 持续按住收鱼 (约2.5秒)
            if !SmartSleep(GetRandomSleep(2514), &Toggle2) { ; [范围: 2011 - 3017 ms]
                break 
            }
            
            Send("{= up}")    
            
            ; 松开休息 (约2.2秒)
            if !SmartSleep(GetRandomSleep(2237), &Toggle2) { ; [范围: 1790 - 2684 ms]
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

; F2 的清理逻辑 (释放收鱼键)
CleanupF2() {
    Send("{= up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原50，已修正)
    Send("{`` up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原50，已修正)
    Send("{Shift up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原50，已修正)
}

; ===================================================
; F3：关闭结算 + 强制重置
; ===================================================
*$F3::
{
    global Toggle1, Toggle2
    
    Toggle1 := false
    Toggle2 := false
    
    ; 强制弹起所有键
    Send("{Shift up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原30，已修正)
    Send("{`` up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原30，已修正)
    Send("{= up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原30，已修正)
    Send("{LButton up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原30，已修正)
    Send("{Enter up}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原50，已修正)
    
    ; 跳过结算 (空格)
    Send("{Space down}")
    Sleep(GetRandomSleep(110))   ; [范围: 88 - 132 ms] (原75，已修正)
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