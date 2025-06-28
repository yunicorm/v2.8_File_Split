; ===================================================================
; AutoHotkey v1.1 → v2 自動変換スクリプト
; Pythonライク記述の修正も含む包括的変換ツール
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; --- グローバル変数 ---
global g_conversion_log := []
global g_backup_dir := A_ScriptDir . "\backups"
global g_converted_files := 0
global g_errors := 0
global g_warnings := 0

; --- 変換統計 ---
global g_conversion_stats := {
    catchErrors: 0,
    forLoops: 0,
    objectProps: 0,
    conditionals: 0,
    rangeConversions: 0,
    pythonLike: 0
}

; --- 変換ルール定義 ---
global g_conversion_rules := [
    ; AutoHotkey v1.1 → v2 変換ルール
    {
        name: "catch Error as e",
        pattern: "catch\s+Error\s+as\s+(\w+)",
        replacement: "catch as $1",
        type: "v1tov2"
    },
    {
        name: "for i := start to end",
        pattern: "for\s+(\w+)\s*:=\s*(\d+)\s+to\s+(\d+)",
        replacement: "Loop ($3 - $2 + 1) {\n    $1 := A_Index + $2 - 1\n}",
        type: "v1tov2"
    },
    {
        name: "object.%key%",
        pattern: "(\w+)\.%(\w+)%",
        replacement: "$1[$2]",
        type: "v1tov2"
    },
    {
        name: "%variable% removal",
        pattern: "%(\w+)%",
        replacement: "$1",
        type: "v1tov2"
    },
    {
        name: "If IsObject() without parentheses",
        pattern: "If\s+IsObject\(",
        replacement: "If (IsObject(",
        type: "v1tov2"
    },
    ; Pythonライク → AutoHotkey v2 変換ルール
    {
        name: "for i in Range(n)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\d+)\)",
        replacement: "Loop $2 {\n    $1 := A_Index\n}",
        type: "python"
    },
    {
        name: "for i in Range(var)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\w+)\)",
        replacement: "Loop $2 {\n    $1 := A_Index\n}",
        type: "python"
    },
    {
        name: "for i in Range(start, end)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\d+),\s*(\d+)\)",
        replacement: "Loop ($3 - $2 + 1) {\n    $1 := $2 + A_Index - 1\n}",
        type: "python"
    },
    {
        name: "for i in Range(var1, var2)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\w+),\s*(\w+)\)",
        replacement: "Loop ($3 - $2 + 1) {\n    $1 := $2 + A_Index - 1\n}",
        type: "python"
    },
    {
        name: "for i in Range(start, end, step)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\d+),\s*(\d+),\s*(\d+)\)",
        replacement: "Loop { $1 := $2 + (A_Index - 1) * $4; if ($1 >= $3) break",
        type: "python"
    }
]

; === メイン機能 ===

; --- 初期化 ---
Initialize() {
    ; バックアップディレクトリを作成
    if (!DirExist(g_backup_dir)) {
        try {
            DirCreate(g_backup_dir)
            LogMessage("Created backup directory: " . g_backup_dir)
        } catch as e {
            MsgBox("Failed to create backup directory: " . e.Message, "Error", "OK Icon!")
            return false
        }
    }
    
    LogMessage("ConvertV1ToV2 initialized successfully")
    return true
}

; --- 単一ファイル変換 ---
ConvertFile(filePath) {
    global g_converted_files, g_errors
    
    if (!FileExist(filePath)) {
        LogError("File not found: " . filePath)
        return false
    }
    
    ; ファイル拡張子チェック
    if (!RegExMatch(filePath, "\.ahk$")) {
        LogWarning("Skipping non-AutoHotkey file: " . filePath)
        return false
    }
    
    LogMessage("Converting file: " . filePath)
    
    ; バックアップ作成
    if (!CreateBackup(filePath)) {
        LogError("Failed to create backup for: " . filePath)
        return false
    }
    
    try {
        ; ファイル読み込み
        content := FileRead(filePath)
        originalContent := content
        
        ; 変換実行
        convertedContent := ApplyConversions(content, filePath)
        
        ; 変更があった場合のみ書き込み
        if (convertedContent != originalContent) {
            FileDelete(filePath)
            FileAppend(convertedContent, filePath)
            g_converted_files++
            LogMessage("Successfully converted: " . filePath)
            return true
        } else {
            LogMessage("No changes needed: " . filePath)
            return true
        }
        
    } catch as e {
        g_errors++
        LogError("Error converting file " . filePath . ": " . e.Message)
        return false
    }
}

; --- ディレクトリ一括変換 ---
ConvertDirectory(dirPath, recursive := true) {
    global g_converted_files, g_errors
    
    if (!DirExist(dirPath)) {
        LogError("Directory not found: " . dirPath)
        return false
    }
    
    LogMessage("Converting directory: " . dirPath)
    
    ; ファイル検索パターン
    pattern := recursive ? (dirPath . "\*.ahk") : (dirPath . "\*.ahk")
    
    try {
        ; .ahkファイルを検索
        Loop Files, dirPath . "\*.ahk", recursive ? "R" : "" {
            ; バックアップファイルはスキップ
            if (InStr(A_LoopFileFullPath, g_backup_dir)) {
                continue
            }
            
            ConvertFile(A_LoopFileFullPath)
        }
        
        LogMessage(Format("Directory conversion completed. Files: {}, Errors: {}", g_converted_files, g_errors))
        return true
        
    } catch as e {
        LogError("Error scanning directory " . dirPath . ": " . e.Message)
        return false
    }
}

; --- バックアップ作成 ---
CreateBackup(filePath) {
    global g_backup_dir
    
    try {
        ; バックアップファイル名生成
        fileName := RegExReplace(filePath, ".*\\", "")  ; ファイル名のみ抽出
        timestamp := FormatTime(, "yyyyMMdd_HHmmss")
        backupPath := g_backup_dir . "\" . fileName . "_" . timestamp . ".bak"
        
        ; ファイルコピー
        FileCopy(filePath, backupPath, true)
        LogMessage("Created backup: " . backupPath)
        return true
        
    } catch as e {
        LogError("Failed to create backup for " . filePath . ": " . e.Message)
        return false
    }
}

; --- 変換ルール適用 ---
ApplyConversions(content, filePath) {
    global g_conversion_rules, g_conversion_stats
    
    convertedContent := content
    changesApplied := 0
    
    ; 各変換ルールを適用
    for rule in g_conversion_rules {
        if (RegExMatch(convertedContent, rule.pattern)) {
            originalContent := convertedContent
            convertedContent := RegExReplace(convertedContent, rule.pattern, rule.replacement, &count)
            
            if (count > 0) {
                changesApplied += count
                LogMessage(Format("Applied rule '{}': {} changes in {}", rule.name, count, filePath))
                
                ; 統計更新
                switch rule.name {
                    case "catch Error as e":
                        g_conversion_stats.catchErrors += count
                    case "for i := start to end":
                        g_conversion_stats.forLoops += count
                    case "object.%key%":
                        g_conversion_stats.objectProps += count
                    case "If IsObject() without parentheses":
                        g_conversion_stats.conditionals += count
                    default:
                        if (rule.type = "python") {
                            g_conversion_stats.pythonLike += count
                            if (InStr(rule.name, "Range")) {
                                g_conversion_stats.rangeConversions += count
                            }
                        }
                }
            }
        }
    }
    
    ; 特殊ケース: 複数行にわたる変換
    convertedContent := FixMultiLinePatterns(convertedContent, filePath)
    
    if (changesApplied > 0) {
        LogMessage(Format("Total changes applied to {}: {}", filePath, changesApplied))
    }
    
    return convertedContent
}

; --- 複数行パターンの修正 ---
FixMultiLinePatterns(content, filePath) {
    ; 未閉じの括弧を検出・修正
    lines := StrSplit(content, "`n")
    fixedLines := []
    
    for lineNum, line in lines {
        trimmedLine := Trim(line)
        
        ; Loop文で開始されているが閉じ括弧がない行を検出
        if (RegExMatch(trimmedLine, "^Loop.*\{\s*\w+\s*:=.*$") && !InStr(trimmedLine, "}")) {
            ; 次の行に閉じ括弧がない場合は追加
            nextLineIndex := lineNum + 1
            if (nextLineIndex <= lines.Length) {
                nextLine := Trim(lines[nextLineIndex])
                if (!RegExMatch(nextLine, "^\s*\}")) {
                    line .= " }"
                    LogMessage(Format("Added missing closing brace at line {} in {}", lineNum, filePath))
                }
            } else {
                line .= " }"
                LogMessage(Format("Added missing closing brace at end of file in {}", filePath))
            }
        }
        
        fixedLines.Push(line)
    }
    
    return JoinArray(fixedLines, "`n")
}

; === ユーティリティ関数 ===

; --- 配列結合 ---
JoinArray(arr, separator) {
    result := ""
    for index, value in arr {
        if (index > 1) {
            result .= separator
        }
        result .= value
    }
    return result
}

; --- ログ機能 ---
LogMessage(message) {
    global g_conversion_log
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    logEntry := Format("[{}] INFO: {}", timestamp, message)
    g_conversion_log.Push(logEntry)
    OutputDebug(logEntry)
}

LogError(message) {
    global g_conversion_log, g_errors
    g_errors++
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    logEntry := Format("[{}] ERROR: {}", timestamp, message)
    g_conversion_log.Push(logEntry)
    OutputDebug(logEntry)
}

LogWarning(message) {
    global g_conversion_log, g_warnings
    g_warnings++
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    logEntry := Format("[{}] WARNING: {}", timestamp, message)
    g_conversion_log.Push(logEntry)
    OutputDebug(logEntry)
}

; --- ログファイル出力 ---
SaveLogToFile() {
    global g_conversion_log
    
    try {
        logFilePath := A_ScriptDir . "\conversion_log_" . FormatTime(, "yyyyMMdd_HHmmss") . ".txt"
        
        for entry in g_conversion_log {
            FileAppend(entry . "`n", logFilePath)
        }
        
        ; 統計情報を追加
        FileAppend("`n=== Conversion Statistics ===`n", logFilePath)
        FileAppend(Format("Files converted: {}`n", g_converted_files), logFilePath)
        FileAppend(Format("Errors: {}`n", g_errors), logFilePath)
        FileAppend(Format("Warnings: {}`n", g_warnings), logFilePath)
        FileAppend(Format("catch Error corrections: {}`n", g_conversion_stats.catchErrors), logFilePath)
        FileAppend(Format("for loop conversions: {}`n", g_conversion_stats.forLoops), logFilePath)
        FileAppend(Format("Object property fixes: {}`n", g_conversion_stats.objectProps), logFilePath)
        FileAppend(Format("Conditional fixes: {}`n", g_conversion_stats.conditionals), logFilePath)
        FileAppend(Format("Range conversions: {}`n", g_conversion_stats.rangeConversions), logFilePath)
        FileAppend(Format("Python-like conversions: {}`n", g_conversion_stats.pythonLike), logFilePath)
        
        LogMessage("Log saved to: " . logFilePath)
        return logFilePath
        
    } catch as e {
        LogError("Failed to save log file: " . e.Message)
        return ""
    }
}

; --- 統計表示 ---
ShowStatistics() {
    global g_converted_files, g_errors, g_warnings, g_conversion_stats
    
    stats := Format("
(
Conversion Statistics:
===================
Files converted: {}
Errors: {}
Warnings: {}

Rule Applications:
- catch Error fixes: {}
- for loop conversions: {}
- Object property fixes: {}
- Conditional fixes: {}
- Range conversions: {}
- Python-like conversions: {}
)", 
    g_converted_files, g_errors, g_warnings,
    g_conversion_stats.catchErrors,
    g_conversion_stats.forLoops, 
    g_conversion_stats.objectProps,
    g_conversion_stats.conditionals,
    g_conversion_stats.rangeConversions,
    g_conversion_stats.pythonLike)
    
    MsgBox(stats, "Conversion Statistics", "OK")
}

; === エントリーポイント ===

; --- メイン実行 ---
Main() {
    if (!Initialize()) {
        return
    }
    
    ; 使用方法を表示
    usage := "
(
AutoHotkey v1.1 → v2 Converter

Usage:
1. Single file: ConvertFile("path\to\file.ahk")
2. Directory: ConvertDirectory("path\to\directory", true)
3. Show stats: ShowStatistics()
4. Save log: SaveLogToFile()

Example:
ConvertDirectory(A_ScriptDir, true)
)"
    
    result := MsgBox(usage . "`n`nConvert current directory?", "ConvertV1ToV2", "YesNo")
    
    if (result = "Yes") {
        ConvertDirectory(A_ScriptDir, true)
        ShowStatistics()
        SaveLogToFile()
    }
}

; --- ホットキー定義 ---
F12::Main()
^F12::ConvertDirectory(A_ScriptDir, true)
^+F12::ShowStatistics()

; --- スクリプト開始時の自動実行 ---
if (A_IsCompiled || !A_LineFile) {
    Main()
}

; テスト実行関数
TestConversion() {
    if (!Initialize()) {
        return
    }
    
    testFile := A_ScriptDir . "\test_conversion.ahk"
    if (FileExist(testFile)) {
        LogMessage("Testing conversion on: " . testFile)
        if (ConvertFile(testFile)) {
            LogMessage("Test conversion completed successfully")
            ShowStatistics()
            SaveLogToFile()
        } else {
            LogError("Test conversion failed")
        }
    } else {
        LogError("Test file not found: " . testFile)
    }
}