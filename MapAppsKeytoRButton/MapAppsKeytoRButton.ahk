;
; Entry
;
Menu, Tray, Tip, Map [Apps Key]`nTo [Mouse Right Button]

; register hotkey `AppsKey`
$AppsKey::On_AppsKey()
return
;

On_AppsKey() {
    Send {RButton}
}
return

; EOF
