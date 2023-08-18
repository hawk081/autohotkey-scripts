#SingleInstance Prompt
;
; Entry
;
Menu, Tray, NoStandard
Menu, Tray, Tip, Beyond Compare Helper

DEFAULT_HOTKEY := "Ctrl+B"
PREDEFINED_KEYS := {}
PREDEFINED_KEYS["Ctrl+B"] := {"hotkey": "$^b", "key_combination": "{Ctrl down}b{Ctrl up}"}
PREDEFINED_KEYS["Ctrl+Alt+B"] := {"hotkey": "$^!b", "key_combination": "{Ctrl down}{Alt down}b{Alt up}{Ctrl up}"}
PREDEFINED_KEYS["Ctrl+Alt+C"] := {"hotkey": "$^!c", "key_combination": "{Ctrl down}{Alt down}c{Alt up}{Ctrl up}"}

global BCOMPARE_PATH
global CURRENT_HOTKEY
global REGISTERED_HOTKEYS := []

; read BCOMPARE_PATH from ini file
IniRead, BCOMPARE_PATH, BCompareHelper.ini, bcompare, path

; read saved hotkey from REG, default to `DEFAULT_HOTKEY`
CURRENT_HOTKEY := Reg_Read("CurrentHotkey")
if(StrLen(CURRENT_HOTKEY) == 0) {
    CURRENT_HOTKEY := DEFAULT_HOTKEY
}

; build menu
Build_Menu(PREDEFINED_KEYS, CURRENT_HOTKEY, REGISTERED_HOTKEYS)

; setup hotkey
Setup_Hotkey(PREDEFINED_KEYS, CURRENT_HOTKEY)

return
;;;

Setup_Hotkey(ByRef predefined_keys, curr) {
    For key, value in predefined_keys {
        hotkey := value["hotkey"]
        func := Func("On_Hotkey_Triggered").Bind(key, value)

        Hotkey, % hotkey, % func, Off
        if(curr == key) {
            Hotkey, % hotkey, On
        }
    }
}
return

On_Hotkey_Triggered(ByRef hotkey_name, ByRef hotkey_obj) {
    key_combination := hotkey_obj["key_combination"]

    ; MsgBox %hotkey_name% ~ %A_ThisHotkey% ~ %key_combination%.

    ; only active `BCompare_Helper_Proc` when select file(s) in Windows explorer
    ; else, pass the key combination to original window
    if (WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass")) and WinActive("ahk_exe explorer.exe") {
        BCompare_Helper_Proc()
    } else {
        ; pass key combination to original window
        Send % key_combination
    }
}
return

Build_Menu(ByRef predefined_keys, curr, ByRef registered_hotkeys) {
    checked_item := ""
    ; Menu, HotkeySelectMenu, Add, item_name2, On_Hotkey_Menu_Selected
    For key, value in predefined_keys {
        OnMenuProc := Func("On_Hotkey_Menu_Selected").Bind(predefined_keys, registered_hotkeys, key, value)

        Menu, HotkeySelectMenu, Add, % key, % OnMenuProc, +Radio
        if(curr == key) {
            checked_item := curr
        }
        registered_hotkeys.Push(key)
    }

    Menu, Tray, Add, HotKeys, :HotkeySelectMenu
    Menu, Tray, Icon, HotKeys, BCompareHelper.ico
    Menu, Tray, Add ; separator
    if(StrLen(checked_item) > 0) {
        Menu, HotkeySelectMenu, ToggleCheck, % checked_item
    }
    Menu, Tray, Standard
}
return

On_Hotkey_Menu_Selected(ByRef predefined_keys, ByRef registered_hotkeys, ByRef hotkey_name, ByRef item_obj) {
    ; MsgBox You selected %A_ThisMenuItem% from the menu %A_ThisMenu%.
    For index, value in registered_hotkeys {
        if(value == hotkey_name) {
            Menu, HotkeySelectMenu, Check, % value
        }
        else {
            Menu, HotkeySelectMenu, Uncheck, % value
        }
    }
    For key, value in predefined_keys {
        hotkey := value["hotkey"]
        Hotkey, % hotkey, Off
    }

    hotkey := item_obj["hotkey"]
    Hotkey, % hotkey, On
    Reg_Write("CurrentHotkey", hotkey_name)
    MsgBox %hotkey_name% activated!
}
return

Reg_Read(Key) {
    RegRead, Value, HKEY_CURRENT_USER\SOFTWARE\Best\BCompareHelper, % Key
    return Value
}
return

Reg_Write(Key, Value) {
    RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\Best\BCompareHelper, % Key, % Value
}
return

Compare_Items(LeftItem, RightItem) {
    Run %BCOMPARE_PATH% %LeftItem% %RightItem%
}
return

Save_Left_Item(LeftItem) {
    Reg_Write(LastSelected, LeftItem)
}
return

Get_Saved_Left_Item() {
    return Reg_Read(LastSelected)
}
return

Clear_Saved_Left_Item() {
    Save_Left_Item("")
}
return

; https://www.autohotkey.com/boards/viewtopic.php?style=7&t=82516
Explorer_GetSelectednames(hwnd="") {
    SelectedItems := []
	WinGet, process, processName, % "ahk_id" hwnd := hwnd? hwnd:WinExist("A")
	WinGetClass class, ahk_id %hwnd%
	if (process = "explorer.exe") {
		if (class ~= "Progman|WorkerW") {
			ControlGet, files, List, Selected Col1, SysListView321, ahk_class %class%
			Loop, Parse, files, `n, `r
				Content .= A_LoopField "`n"
		} else if (class ~= "(Cabinet|Explore)WClass") {
            for window in ComObjCreate("Shell.Application").Windows
                if (window.hwnd==hwnd)
                        sel := window.Document.SelectedItems
            for item in sel
            {
                SelectedItems.Push(item.path)
            }
        }
    }
    return SelectedItems
}
return

BCompare_Helper_Proc() {
    SelectedItems := Explorer_GetSelectednames()
    SelectedItemsCount := SelectedItems.Length()

    ;Content := ""
    ;For index, value in SelectedItems
    ;    Content .= index ":" value "`n"
    ;MsgBox, Selected files: [%SelectedItemsCount%]`n%Content%

    if (SelectedItems.Length() == 1) {
        SelectedItem := SelectedItems[1]
        LastSelectedItem := Get_Saved_Left_Item()
        ;MsgBox, - SelectedItem: %SelectedItem%
        if(StrLen(LastSelectedItem) == 0) {
            Save_Left_Item(SelectedItem)
        } else {
            ;MsgBox, - LastSelectedItem: %LastSelectedItem%
            Compare_Items(LastSelectedItem, SelectedItem)
            Clear_Saved_Left_Item()
        }
    } else if (SelectedItems.Length() == 2) {
        LeftItem := SelectedItems[1]
        RightItem := SelectedItems[2]
        Compare_Items(LeftItem, RightItem)
        Clear_Saved_Left_Item()
    } else {
        Clear_Saved_Left_Item()
    }
}
return

; EOF
