; テスト用構文
TestFunction() {
    ; v1構文テスト
    try {
        result := SomeFunction()
    } catch Error as e {
        MsgBox("Error: " . e.Message)
    }
    
    for i := 1 to 10 {
        value := i * 2
    }
    
    obj.%key% := value
    result := %myVar%
    
    If IsObject(obj)
        return true
    
    ; Python構文テスト  
    for i in Range(5) {
        value := i
    }
    
    for j in Range(start, end) {
        value := j
    }
    
    for k in Range(0, 20, 3) {
        value := k
    }
    
    ; 追加パターン
    options.%setting% := "test"
    config.%key% := value
    If !IsFunc(fn)
        return
    for n in Range(count) {
        Process(n)
    }
}