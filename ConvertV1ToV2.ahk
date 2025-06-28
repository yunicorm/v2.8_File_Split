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
global g_dry_run := false

; --- 除外ファイルリスト ---
global g_excluded_files := [
    "ConvertV1ToV2.ahk",
    "test_conversion_manually.py",
    "run_test_conversion.ahk",
    "test_conversion_expected.ahk",
    "test_conversion_result.ahk",
    "test_conversion.ahk",
    "test_conversion_original.ahk",
    "CONVERSION_SUMMARY.md"
]

; --- 除外ディレクトリリスト ---
global g_excluded_dirs := [
    "backups",
    "logs",
    ".git"
]

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
        pattern: "for\s+(\w+)\s*:=\s*(\d+)\s+to\s+(\d+)\s*\{",
        replacement: "Loop ($3 - $2 + 1) {\n    $1 := A_Index + $2 - 1",
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
    {
        name: "If without closing parenthesis",
        pattern: "If\s+\(([^)]+)$",
        replacement: "If ($1)",
        type: "v1tov2"
    },
    {
        name: "If (condition without closing parenthesis",
        pattern: "If\s+\\(([^)]+)(?:\\s*$|\\s*\\n)",
        replacement: "If ($1)",
        type: "v1tov2"
    },
    ; Pythonライク → AutoHotkey v2 変換ルール
    {
        name: "for i in Range(n)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\d+)\)\s*\{",
        replacement: "Loop $2 {\n    $1 := A_Index",
        type: "python"
    },
    {
        name: "for i in Range(var)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\w+)\)\s*\{",
        replacement: "Loop $2 {\n    $1 := A_Index",
        type: "python"
    },
    {
        name: "for i in Range(start, end)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\d+),\s*(\d+)\)\s*\{",
        replacement: "Loop ($3 - $2 + 1) {\n    $1 := $2 + A_Index - 1",
        type: "python"
    },
    {
        name: "for i in Range(var1, var2)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\w+),\s*(\w+)\)\s*\{",
        replacement: "Loop ($3 - $2 + 1) {\n    $1 := $2 + A_Index - 1",
        type: "python"
    },
    {
        name: "for i in Range(start, end, step)",
        pattern: "for\s+(\w+)\s+in\s+Range\((\d+),\s*(\d+),\s*(\d+)\)\s*\{",
        replacement: "Loop {\n    $1 := $2 + (A_Index - 1) * $4\n    if ($1 >= $3)\n        break",
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

; --- ファイル除外チェック ---
IsFileExcluded(filePath) {
    global g_excluded_files, g_excluded_dirs
    
    fileName := RegExReplace(filePath, ".*\\", "")  ; ファイル名のみ抽出
    
    ; ファイル名チェック
    for excludedFile in g_excluded_files {
        if (fileName = excludedFile) {
            return true
        }
    }
    
    ; ディレクトリチェック
    for excludedDir in g_excluded_dirs {
        if (InStr(filePath, "\" . excludedDir . "\") || InStr(filePath, "/" . excludedDir . "/")) {
            return true
        }
    }
    
    return false
}

; --- 統計リセット ---
ResetStatistics() {
    global g_converted_files, g_errors, g_warnings, g_conversion_stats
    
    g_converted_files := 0
    g_errors := 0
    g_warnings := 0
    
    g_conversion_stats.catchErrors := 0
    g_conversion_stats.forLoops := 0
    g_conversion_stats.objectProps := 0
    g_conversion_stats.conditionals := 0
    g_conversion_stats.rangeConversions := 0
    g_conversion_stats.pythonLike := 0
    
    LogMessage("Statistics reset successfully")
}

; --- 単一ファイル変換 ---
ConvertFile(filePath, dryRun := false) {
    global g_converted_files, g_errors, g_dry_run
    
    if (!FileExist(filePath)) {
        LogError("File not found: " . filePath)
        return false
    }
    
    ; ファイル拡張子チェック
    if (!RegExMatch(filePath, "\.ahk$")) {
        LogWarning("Skipping non-AutoHotkey file: " . filePath)
        return false
    }
    
    ; 除外ファイルチェック
    if (IsFileExcluded(filePath)) {
        LogMessage("Skipping excluded file: " . filePath)
        return true
    }
    
    if (dryRun) {
        LogMessage("[DRY RUN] Would convert file: " . filePath)
    } else {
        LogMessage("Converting file: " . filePath)
    }
    
    ; バックアップ作成（ドライランでない場合のみ）
    if (!dryRun && !CreateBackup(filePath)) {
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
            if (dryRun) {
                LogMessage("[DRY RUN] Would modify file: " . filePath)
                LogMessage("[DRY RUN] Changes detected but not applied")
            } else {
                FileDelete(filePath)
                FileAppend(convertedContent, filePath)
                LogMessage("Successfully converted: " . filePath)
            }
            g_converted_files++
            return true
        } else {
            if (dryRun) {
                LogMessage("[DRY RUN] No changes needed: " . filePath)
            } else {
                LogMessage("No changes needed: " . filePath)
            }
            return true
        }
        
    } catch as e {
        g_errors++
        LogError("Error converting file " . filePath . ": " . e.Message)
        return false
    }
}

; --- ディレクトリ一括変換 ---
ConvertDirectory(dirPath, recursive := true, dryRun := false) {
    global g_converted_files, g_errors, g_backup_dir
    
    if (!DirExist(dirPath)) {
        LogError("Directory not found: " . dirPath)
        return false
    }
    
    if (dryRun) {
        LogMessage("[DRY RUN] Would convert directory: " . dirPath)
    } else {
        LogMessage("Converting directory: " . dirPath)
    }
    
    try {
        ; .ahkファイルを検索
        Loop Files, dirPath . "\*.ahk", recursive ? "R" : "" {
            ; バックアップファイルはスキップ
            if (InStr(A_LoopFileFullPath, g_backup_dir)) {
                continue
            }
            
            ConvertFile(A_LoopFileFullPath, dryRun)
        }
        
        if (dryRun) {
            LogMessage(Format("[DRY RUN] Directory scan completed. Would process {} files, {} errors detected", g_converted_files, g_errors))
        } else {
            LogMessage(Format("Directory conversion completed. Files: {}, Errors: {}", g_converted_files, g_errors))
        }
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

; --- 括弧バランスチェック関数 ---
CountBraces(line) {
    open := 0
    close := 0
    Loop Parse, line {
        if (A_LoopField == "{")
            open++
        else if (A_LoopField == "}")
            close++
    }
    return {open: open, close: close}
}

; --- 次の行が閉じ括弧かチェック ---
IsNextLineClosingBrace(lines, currentIndex) {
    nextIndex := currentIndex + 1
    while (nextIndex <= lines.Length) {
        nextLine := Trim(lines[nextIndex])
        ; 空行はスキップ
        if (nextLine == "") {
            nextIndex++
            continue
        }
        ; 閉じ括弧で始まる行かチェック
        if (RegExMatch(nextLine, "^\s*\}")) {
            return true
        }
        ; その他の行が見つかったら終了
        return false
    }
    return false
}

; --- ブロック終了を探す ---
FindBlockEnd(lines, startIndex) {
    braceCount := 0
    foundOpening := false
    
    for i := startIndex to lines.Length {
        line := lines[i]
        braces := CountBraces(line)
        
        ; 開始括弧を見つけた
        if (braces.open > 0) {
            foundOpening := true
            braceCount += braces.open
        }
        
        ; 閉じ括弧を処理
        braceCount -= braces.close
        
        ; バランスが取れたらブロック終了
        if (foundOpening && braceCount <= 0) {
            return i
        }
    }
    
    return -1  ; 見つからない
}

; --- 複数行パターンの修正（改善版） ---
FixMultiLinePatterns(content, filePath) {
    lines := StrSplit(content, "`n")
    fixedLines := []
    changesApplied := 0
    
    for lineNum, line in lines {
        trimmedLine := Trim(line)
        currentLine := line
        
        ; Loop文の後に変数代入があるパターンを検出
        if (RegExMatch(trimmedLine, "^Loop.*\{\s*$")) {
            ; 現在の行の括弧バランスをチェック
            braces := CountBraces(line)
            
            ; 開始括弧があるが閉じ括弧がない場合
            if (braces.open > braces.close) {
                ; 次の行をチェック
                if (lineNum < lines.Length) {
                    nextLine := lines[lineNum + 1]
                    nextTrimmed := Trim(nextLine)
                    
                    ; 次の行が変数代入で始まる場合
                    if (RegExMatch(nextTrimmed, "^\s*\w+\s*:=")) {
                        ; その後のブロック終了を探す
                        blockEnd := FindBlockEnd(lines, lineNum + 1)
                        
                        if (blockEnd == -1 || blockEnd == lineNum + 1) {
                            ; ブロック終了が見つからない、または変数代入行で終わっている場合
                            if (!IsNextLineClosingBrace(lines, lineNum + 1)) {
                                ; 次の行に閉じ括弧を追加する必要がある
                                LogMessage(Format("Missing closing brace detected after line {} in {}", lineNum + 1, filePath))
                                changesApplied++
                            }
                        }
                    }
                }
            }
        }
        
        ; If文の未閉じ括弧を検出・修正
        if (RegExMatch(trimmedLine, "^If\s*\([^)]*$") && !InStr(trimmedLine, ")")) {
            ; 行末に閉じ括弧を追加
            currentLine := RegExReplace(currentLine, "(\s*)$", ")$1")
            LogMessage(Format("Added missing closing parenthesis at line {} in {}", lineNum, filePath))
            changesApplied++
        }
        
        ; インデント修正: Loop文内の変数代入
        if (RegExMatch(trimmedLine, "^(\w+\s*:=.*)$") && lineNum > 1) {
            prevLine := Trim(lines[lineNum - 1])
            ; 前の行がLoop文で始まる場合、インデントを追加
            if (RegExMatch(prevLine, "^Loop.*\{")) {
                currentLine := RegExReplace(currentLine, "^(\s*)", "    ")
                LogMessage(Format("Fixed indentation at line {} in {}", lineNum, filePath))
                changesApplied++
            }
        }
        
        fixedLines.Push(currentLine)
    }
    
    if (changesApplied > 0) {
        LogMessage(Format("Applied {} multi-line pattern fixes in {}", changesApplied, filePath))
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

; --- ドライラン実行 ---
DryRunTest() {
    if (!Initialize()) {
        return
    }
    
    MsgBox("Starting DRY RUN test on current directory...", "Dry Run", "OK")
    ConvertDirectory(A_ScriptDir, true, true)  ; dryRun = true
    ShowStatistics()
    SaveLogToFile()
}

; --- ホットキー定義 ---
F12::Main()
^F12::ConvertDirectory(A_ScriptDir, true)
^+F12::ShowStatistics()
^!F12::DryRunTest()  ; Ctrl+Alt+F12 でドライランテスト

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