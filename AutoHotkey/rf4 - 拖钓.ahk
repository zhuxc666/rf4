#Requires AutoHotkey v2.0
#SingleInstance Force

; ===================================================
; RF4 快捷操作
; F1：轻抽循环（不抛竿）
; F2：快速抬杆收鱼
; F3：循环按住 / 松开 A
; F4：循环按住 / 松开 D
; F5：确认入鱼护，并取消正在运行的 F2 / F6
; F6：快速收鱼（不抬杆）
; End：紧急停止并释放所有按键
;
; 运行规则：
; - 按 F2 或 F6 会取消 F1；F2 与 F6 可同时运行。
; - F3 与 F4 互相取消，其他模式不受影响。
; - F5 只取消 F2 / F6；End 取消全部模式。
; ===================================================

; 所有数值单位均为毫秒。
; F3/F4 的按住与间隔时长使用 ±5%，其余正数时长默认使用 ±20% 随机波动。
global Timing := {
    LightJerkDown:          700,    ; F1：抬杆键 = 每次按住的基础时长
    LightJerkUp:            2200,   ; F1：两次抬杆之间松开 = 的基础时长
    RetrieveStart:           110,   ; F2/F6：开启后，等待按下收线键 ` 的基础延迟
    RetrieveRodDelay:        100,   ; F2：按下收线键 ` 后，等待首次按下抬杆键 = 的基础延迟
    RetrieveRodDown:        2514,   ; F2：抬杆键 = 每次按住的基础时长
    RetrieveRodUp:          2237,   ; F2：两次抬杆之间松开 = 的基础时长
    DirectionHoldDefault: 160000,   ; F3/F4：间隔为 0 时的默认基础时长（160 秒，±5%）
    DirectionHoldCustom:  3000,   ; F3/F4：有间隔时的可配置按住时长（默认 160 秒，±5%）
    DirectionInterval:      0,   ; F3/F4：每次松开后的基础间隔；设为 0 时持续按住
    ConfirmKeepnet:           110,  ; F5：确认入鱼护时，空格键按住的基础时长
    Status:                  1000   ; 状态提示框显示的基础时长
}

; 模式状态
global Mode := {
    LightJerk: false,
    FastRetrieve: false,
    FastRetrieveNoRod: false
}
global HoldActive := Map("A", false, "D", false)

; 并行模式对共享按键的需求状态
global Request := {
    LightJerkRod: false,
    FastRetrieveRod: false,
    FastRetrieveReelReady: false,
    FastRetrieveNoRodReelReady: false
}
global KeyState := {
    Rod: false,
    Shift: false,
    Reel: false
}

; 返回带指定波动比例的随机毫秒数，默认上下 20%。
RandomMs(baseMs, varianceRatio := 0.20) {
    if (baseMs <= 0)
        return 0

    variance := Max(20, Round(baseMs * varianceRatio))
    return Max(50, Round(baseMs + Random(-variance, variance)))
}

ShowStatus(message) {
    global Timing
    SetTimer(HideStatus, 0)
    ToolTip(message)
    SetTimer(HideStatus, -RandomMs(Timing.Status))
}

HideStatus() {
    ToolTip()
}

; ===================================================
; 共享按键协调
; ===================================================

SyncRodKey() {
    global Request, KeyState
    shouldBeDown := Request.LightJerkRod || Request.FastRetrieveRod

    if (shouldBeDown = KeyState.Rod)
        return

    KeyState.Rod := shouldBeDown
    Send(shouldBeDown ? "{= down}" : "{= up}")
}

SyncFastRetrieveKeys() {
    global Mode, Request, KeyState
    shiftShouldBeDown := Mode.FastRetrieve || Mode.FastRetrieveNoRod
    reelShouldBeDown := (Mode.FastRetrieve && Request.FastRetrieveReelReady)
        || (Mode.FastRetrieveNoRod && Request.FastRetrieveNoRodReelReady)

    if (shiftShouldBeDown != KeyState.Shift) {
        KeyState.Shift := shiftShouldBeDown
        Send(shiftShouldBeDown ? "{Shift down}" : "{Shift up}")
    }

    if (reelShouldBeDown != KeyState.Reel) {
        KeyState.Reel := reelShouldBeDown
        Send(reelShouldBeDown ? "{`` down}" : "{`` up}")
    }
}

ReleaseAllKeys() {
    global KeyState
    KeyState.Rod := false
    KeyState.Shift := false
    KeyState.Reel := false
    Send("{= up}{`` up}{Shift up}{Space up}{A up}{D up}")
}

; ===================================================
; 停止逻辑
; ===================================================

StopLightJerk() {
    global Mode, Request
    Mode.LightJerk := false
    Request.LightJerkRod := false
    SetTimer(LightJerkDown, 0)
    SetTimer(LightJerkUp, 0)
    SyncRodKey()
}

StopFastRetrieve() {
    global Mode, Request
    Mode.FastRetrieve := false
    Request.FastRetrieveReelReady := false
    Request.FastRetrieveRod := false
    SetTimer(FastRetrieveReelDown, 0)
    SetTimer(FastRetrieveRodDown, 0)
    SetTimer(FastRetrieveRodUp, 0)
    SyncFastRetrieveKeys()
    SyncRodKey()
}

StopFastRetrieveNoRod() {
    global Mode, Request
    Mode.FastRetrieveNoRod := false
    Request.FastRetrieveNoRodReelReady := false
    SetTimer(FastRetrieveNoRodReelDown, 0)
    SyncFastRetrieveKeys()
}

StopHold(keyName) {
    global HoldActive
    HoldActive[keyName] := false

    if (keyName = "A") {
        SetTimer(DirectionDownA, 0)
        SetTimer(DirectionUpA, 0)
    } else {
        SetTimer(DirectionDownD, 0)
        SetTimer(DirectionUpD, 0)
    }

    Send("{" keyName " up}")
}

StopAll() {
    StopLightJerk()
    StopFastRetrieve()
    StopFastRetrieveNoRod()
    StopHold("A")
    StopHold("D")
    SetTimer(ReleaseConfirmKey, 0)
    ReleaseAllKeys()
}

; ===================================================
; F1：轻抽循环
; ===================================================

ToggleLightJerk() {
    global Mode
    Critical()

    if Mode.LightJerk {
        StopLightJerk()
        ShowStatus("F1 轻抽：停止")
        return
    }

    Mode.LightJerk := true
    ShowStatus("F1 轻抽：开启")
    LightJerkDown()
}

LightJerkDown() {
    global Mode, Request, Timing
    Critical()
    if !Mode.LightJerk
        return

    Request.LightJerkRod := true
    SyncRodKey()
    SetTimer(LightJerkUp, -RandomMs(Timing.LightJerkDown))
}

LightJerkUp() {
    global Mode, Request, Timing
    Critical()
    if !Mode.LightJerk
        return

    Request.LightJerkRod := false
    SyncRodKey()
    SetTimer(LightJerkDown, -RandomMs(Timing.LightJerkUp))
}

; ===================================================
; F2：快速抬杆收鱼
; 按住 Shift 和 ` 收线，并循环按 = 抬杆。
; ===================================================

ToggleFastRetrieve() {
    ToggleRetrieve(true)
}

FastRetrieveReelDown() {
    global Mode, Request, Timing
    Critical()
    if !Mode.FastRetrieve
        return

    Request.FastRetrieveReelReady := true
    SyncFastRetrieveKeys()
    SetTimer(FastRetrieveRodDown, -RandomMs(Timing.RetrieveRodDelay))
}

FastRetrieveRodDown() {
    global Mode, Request, Timing
    Critical()
    if !Mode.FastRetrieve
        return

    Request.FastRetrieveRod := true
    SyncRodKey()
    SetTimer(FastRetrieveRodUp, -RandomMs(Timing.RetrieveRodDown))
}

FastRetrieveRodUp() {
    global Mode, Request, Timing
    Critical()
    if !Mode.FastRetrieve
        return

    Request.FastRetrieveRod := false
    SyncRodKey()
    SetTimer(FastRetrieveRodDown, -RandomMs(Timing.RetrieveRodUp))
}

; ===================================================
; F6：快速收鱼（不抬杆）
; 按住 Shift 和 ` 收线，但不按 =。
; ===================================================

ToggleFastRetrieveNoRod() {
    ToggleRetrieve(false)
}

ToggleRetrieve(withRod) {
    global Mode, Request, Timing
    Critical()

    ; F2 / F6 均会取消 F1。
    StopLightJerk()

    if withRod {
        if Mode.FastRetrieve {
            StopFastRetrieve()
            ShowStatus("F2 快速收鱼：停止")
            return
        }

        Mode.FastRetrieve := true
        Request.FastRetrieveReelReady := false
        Request.FastRetrieveRod := false
        ShowStatus("F2 快速收鱼：开启")
        SyncFastRetrieveKeys()
        SetTimer(FastRetrieveReelDown, -RandomMs(Timing.RetrieveStart))
        return
    }

    if Mode.FastRetrieveNoRod {
        StopFastRetrieveNoRod()
        ShowStatus("F6 快速收鱼（不抬杆）：停止")
        return
    }

    Mode.FastRetrieveNoRod := true
    Request.FastRetrieveNoRodReelReady := false
    ShowStatus("F6 快速收鱼（不抬杆）：开启")
    SyncFastRetrieveKeys()
    SetTimer(FastRetrieveNoRodReelDown, -RandomMs(Timing.RetrieveStart))
}

FastRetrieveNoRodReelDown() {
    global Mode, Request
    Critical()
    if !Mode.FastRetrieveNoRod
        return

    Request.FastRetrieveNoRodReelReady := true
    SyncFastRetrieveKeys()
}

; ===================================================
; F3 / F4：随机按住 / 松开 A / D
; 两者互相取消；间隔设为 0 时等效于持续按住。
; ===================================================

ToggleHoldA() {
    ToggleHold("A")
}

ToggleHoldD() {
    ToggleHold("D")
}

ToggleHold(keyName) {
    global HoldActive, Timing
    Critical()

    otherKey := keyName = "A" ? "D" : "A"
    if HoldActive[otherKey]
        StopHold(otherKey)

    if HoldActive[keyName] {
        StopHold(keyName)
        ShowStatus(HoldHotkey(keyName) " 按住 " keyName "：停止")
        return
    }

    HoldActive[keyName] := true
    ShowStatus(HoldHotkey(keyName) " 按住 " keyName "：开启")
    DirectionDown(keyName)
}

HoldHotkey(keyName) {
    return keyName = "A" ? "F3" : "F4"
}

DirectionDownA() {
    DirectionDown("A")
}

DirectionDownD() {
    DirectionDown("D")
}

DirectionDown(keyName) {
    global HoldActive, Timing
    Critical()
    if !HoldActive[keyName]
        return

    Send("{" keyName " down}")
    holdBase := DirectionHoldMs()

    ; 间隔为 0 时不安排松开，保持与原来一直按住等效。
    if (Timing.DirectionInterval <= 0)
        return

    if (keyName = "A")
        SetTimer(DirectionUpA, -RandomMs(holdBase, 0.05))
    else
        SetTimer(DirectionUpD, -RandomMs(holdBase, 0.05))
}

DirectionHoldMs() {
    global Timing
    return Timing.DirectionInterval <= 0
        ? Timing.DirectionHoldDefault
        : Timing.DirectionHoldCustom
}

DirectionUpA() {
    DirectionUp("A")
}

DirectionUpD() {
    DirectionUp("D")
}

DirectionUp(keyName) {
    global HoldActive, Timing
    Critical()
    if !HoldActive[keyName]
        return

    Send("{" keyName " up}")

    if (keyName = "A")
        SetTimer(DirectionDownA, -RandomMs(Timing.DirectionInterval, 0.05))
    else
        SetTimer(DirectionDownD, -RandomMs(Timing.DirectionInterval, 0.05))
}

; ===================================================
; F5：确认入鱼护
; 随机短按空格；只取消 F2 / F6。
; ===================================================

ConfirmKeepnet() {
    global Timing
    Critical()
    StopFastRetrieve()
    StopFastRetrieveNoRod()

    SetTimer(ReleaseConfirmKey, 0)
    Send("{Space up}{Space down}")
    SetTimer(ReleaseConfirmKey, -RandomMs(Timing.ConfirmKeepnet))
    ShowStatus("F5 确认入鱼护")
}

ReleaseConfirmKey() {
    Critical()
    Send("{Space up}")
}

; 屏蔽原始按下事件，仅在松开时切换，避免长按自动连发。
*F1::return
*F1 Up::ToggleLightJerk()

*F2::return
*F2 Up::ToggleFastRetrieve()

*F3::return
*F3 Up::ToggleHoldA()

*F4::return
*F4 Up::ToggleHoldD()

*F5::return
*F5 Up::ConfirmKeepnet()

*F6::return
*F6 Up::ToggleFastRetrieveNoRod()

*End::return
*End Up::
{
    Critical()
    StopAll()
    SoundBeep(1000, RandomMs(200))
    ShowStatus("！！！紧急停止！！！")
}
