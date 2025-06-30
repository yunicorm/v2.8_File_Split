; ===================================================================
; 検証ユーティリティ
; 共通の入力値検証・データ型チェック関数
; ===================================================================

; --- 整数チェックヘルパー関数 ---
; AutoHotkey v2の組み込みIsInteger()関数との衝突を避けるため、
; カスタム検証ロジックをIsValidInteger()として定義
IsValidInteger(value) {
    try {
        Integer(value)
        return true
    } catch {
        return false
    }
}

; --- 数値範囲チェック ---
IsValidRange(value, min := "", max := "") {
    if (!IsValidInteger(value)) {
        return false
    }
    
    numValue := Integer(value)
    
    if (min != "" && numValue < min) {
        return false
    }
    
    if (max != "" && numValue > max) {
        return false
    }
    
    return true
}

; --- 正の整数チェック ---
IsPositiveInteger(value) {
    return IsValidInteger(value) && Integer(value) > 0
}

; --- 非負整数チェック ---
IsNonNegativeInteger(value) {
    return IsValidInteger(value) && Integer(value) >= 0
}

; --- 文字列の空チェック ---
IsNotEmpty(value) {
    return Trim(value) != ""
}

; --- 優先度チェック（1-5の範囲） ---
IsValidPriority(priority) {
    return IsValidRange(priority, 1, 5)
}

; --- ファイルパスの存在チェック ---
IsValidFilePath(path) {
    return IsNotEmpty(path) && FileExist(path)
}

; --- 色値チェック（0-255の範囲） ---
IsValidColorValue(value) {
    return IsValidRange(value, 0, 255)
}

; --- パーセンテージチェック（0-100の範囲） ---
IsValidPercentage(value) {
    return IsValidRange(value, 0, 100)
}