; ===================================================================
; ログローテーションテスト
; ForceLogRotation()関数のテスト
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; 最小限の環境をセットアップ
SetupMockEnvironment() {
    global g_log_file, g_log_dir, g_log_file_handle
    global g_log_buffer, g_log_buffer_size, g_log_write_count
    global g_log_rotation_in_progress, g_log_stats
    
    ; ログディレクトリ
    g_log_dir := A_ScriptDir . "\logs"
    g_log_file := g_log_dir . "\macro_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".log"
    
    ; 初期化
    g_log_buffer := []
    g_log_buffer_size := 50
    g_log_write_count := 0
    g_log_rotation_in_progress := false
    g_log_file_handle := ""
    
    g_log_stats := {
        totalLogs: 0,
        droppedLogs: 0,
        rotations: 0,
        writeErrors: 0
    }
    
    ; ディレクトリ作成
    if (!DirExist(g_log_dir)) {
        DirCreate(g_log_dir)
    }
}

; Mock ConfigManager
global ConfigManager := {
    Get: (section, key, default) => {
        if (section == "General" && key == "MaxLogSize") {
            return 5  ; 5MB
        }
        return default
    }
}

; Logger.ahkをインクルード
#Include "Utils\Logger.ahk"

; テスト実行
TestLogRotation() {
    OutputDebug("=== Log Rotation Test Start ===")
    
    ; 環境セットアップ
    SetupMockEnvironment()
    
    ; ログディレクトリの現在の状況
    files := ""
    Loop Files, g_log_dir . "\*.log" {
        files .= A_LoopFileName . " (" . Round(A_LoopFileSize/1024/1024, 2) . "MB)`n"
    }
    
    OutputDebug("Current log files:")
    OutputDebug(files)
    
    ; 最大のログファイルを見つける
    largestFile := ""
    largestSize := 0
    Loop Files, g_log_dir . "\*.log" {
        if (A_LoopFileSize > largestSize) {
            largestSize := A_LoopFileSize
            largestFile := A_LoopFilePath
        }
    }
    
    if (largestFile != "") {
        g_log_file := largestFile
        OutputDebug("Testing with largest log file: " . largestFile)
        OutputDebug("File size: " . Round(largestSize/1024/1024, 2) . "MB")
        
        ; CheckLogRotation()をテスト
        OutputDebug("Running CheckLogRotation()...")
        CheckLogRotation()
        
        ; ForceLogRotation()をテスト
        OutputDebug("Running ForceLogRotation()...")
        result := ForceLogRotation()
        OutputDebug("ForceLogRotation() result: " . (result ? "SUCCESS" : "FAILED"))
        
        ; 結果確認
        Sleep(1000)
        newFiles := ""
        Loop Files, g_log_dir . "\*.*" {
            newFiles .= A_LoopFileName . " (" . Round(A_LoopFileSize/1024/1024, 2) . "MB)`n"
        }
        
        OutputDebug("Files after rotation:")
        OutputDebug(newFiles)
    } else {
        OutputDebug("No log files found for testing")
    }
    
    OutputDebug("=== Log Rotation Test End ===")
}

; F9キーでテスト実行
F9::TestLogRotation()

; 自動実行
TestLogRotation()

; ESCで終了
Esc::ExitApp()