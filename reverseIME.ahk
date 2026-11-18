#Requires AutoHotkey v2.0
#SingleInstance Force

enable := true
global statusGui
global guiValid := false

IsPunct(c) {
    static punct := ["?","!",".",",",";","：","，","。","？","！","；"]
    return punct.Has(c)
}

IsEnglish(c) {
    code := Ord(c)
    return (code >= Ord("a") && code <= Ord("z")) || (code >= Ord("A") && code <= Ord("Z")) || (c = "'")
}

IsChinese(c) {
    code := Ord(c)
    return (code >= 0x4E00 && code <= 0x9FFF)
}

ReverseSmart(s) {
    units := []
    pos := 1
    len := StrLen(s)
    while pos <= len {
        char := SubStr(s, pos, 1)
        if IsEnglish(char) {
            word := ""
            while pos <= len && IsEnglish(SubStr(s, pos, 1)) {
                word .= SubStr(s, pos, 1)
                pos += 1
            }
            p := ""
            if pos <= len && IsPunct(SubStr(s, pos, 1)) {
                p := SubStr(s, pos, 1)
                pos += 1
            }
            units.Push({txt: word, p: p})
        }
        else if IsChinese(char) {
            p := ""
            if pos+1 <= len && IsPunct(SubStr(s, pos+1, 1)) {
                p := SubStr(s, pos+1, 1)
                pos += 2
            } else {
                pos += 1
            }
            units.Push({txt: char, p: p})
        }
        else if char = " " {
            units.Push({txt: " ", p: ""})
            pos += 1
        }
        else {
            units.Push({txt: char, p: ""})
            pos += 1
        }
    }

    revUnits := []
    idx := units.Length
    Loop {
        if idx < 1
            break
        revUnits.Push(units[idx])
        idx -= 1
    }

    out := ""
    for u in revUnits {
        if u.txt = " "
            out .= u.txt
        else
            out .= u.p u.txt
    }
    return Trim(out)
}

F8:: {
    global enable
    if !enable
        return
    A_Clipboard := ""
    Send "^c"
    Sleep 50
    if A_Clipboard = ""
        return
    rev := ReverseSmart(A_Clipboard)
    A_Clipboard := rev
    Sleep 50
    Send "^v"
}

F9:: {
    global enable, statusGui, guiValid
    if guiValid {
        statusGui.Destroy()
        guiValid := false
    }

    enable := !enable
    text := enable ? "✅ 反转功能【已开启】" : "❌ 反转功能【已关闭】"

    statusGui := Gui()
    statusGui.Opt("+AlwaysOnTop +ToolWindow -Caption")
    statusGui.BackColor := "1F1F1F"
    statusGui.SetFont("s11 cWhite")
    statusGui.Add("Text", "xm ym", text)
    statusGui.Show("x0 y0 AutoSize NoActivate")
    Sleep 20
    guiValid := true

    statusGui.GetPos(&gx, &gy, &winW, &winH)
    MonitorGetWorkArea(, &Left, &Top, &Right, &Bottom)

    offsetX := 30
    baseX := Right - winW - offsetX
    baseY := Bottom - winH

    statusGui.Show("x" baseX " y" baseY " w0 h0 NoActivate")
    sleep 10
    step := 6
    currW := 0
    currH := 0
    while (currW < winW || currH < winH) {
        currW := Min(currW + step, winW)
        currH := Min(currH + step, winH)
        statusGui.Show("x" (baseX + winW - currW) " y" (baseY + winH - currH) " w" currW " h" currH " NoActivate")
        Sleep 6
    }
    statusGui.Show("x" baseX " y" baseY " w" winW " h" winH " NoActivate")

    Sleep 2000

    while (currW > 0 || currH > 0) {
        currW := Max(currW - step, 0)
        currH := Max(currH - step, 0)
        statusGui.Show("x" (baseX + winW - currW) " y" (baseY + winH - currH) " w" currW " h" currH " NoActivate")
        Sleep 6
    }
    statusGui.Destroy()
    guiValid := false
}
