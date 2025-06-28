; テスト用構文（変換後の期待結果）
TestFunction() {
    ; v1構文テスト
    try {
        result := SomeFunction()
    } catch as e {
        MsgBox("Error: " . e.Message)
    }
    
    Loop (10 - 1 + 1) {
        i := A_Index + 1 - 1
        value := i * 2
    }
    
    obj[key] := value
    result := myVar
    
    If (IsObject(obj))
        return true
    
    ; Python構文テスト  
    Loop 5 {
        i := A_Index
        value := i
    }
    
    Loop (end - start + 1) {
        j := start + A_Index - 1
        value := j
    }
    
    Loop { k := 0 + (A_Index - 1) * 3; if (k >= 20) break
        value := k
    }
    
    ; 追加パターン
    options[setting] := "test"
    config[key] := value
    If (!IsFunc(fn))
        return
    Loop count {
        n := A_Index
        Process(n)
    }
}