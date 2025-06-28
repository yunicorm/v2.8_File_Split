; ===================================================================
; プロジェクト全体の変換実行スクリプト
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ConvertV1ToV2.ahkをインクルード
#Include "ConvertV1ToV2.ahk"

; プロジェクト全体変換実行
RunProjectConversion() {
    ; 初期化
    if (!Initialize()) {
        MsgBox("Initialization failed!", "Error", "OK Icon!")
        return
    }
    
    ; 統計リセット
    ResetStatistics()
    
    ; 変換実行前の確認
    result := MsgBox("Start converting the entire project?`n`nThis will:`n- Create backups in .\backups\`n- Convert all .ahk files except excluded ones`n- Log all changes", "Project Conversion", "YesNo Icon?")
    
    if (result != "Yes") {
        LogMessage("Conversion cancelled by user")
        return
    }
    
    ; 変換開始
    LogMessage("=== PROJECT CONVERSION STARTED ===")
    startTime := A_TickCount
    
    ; ディレクトリ一括変換実行
    success := ConvertDirectory(A_ScriptDir, true, false)  ; recursive=true, dryRun=false
    
    endTime := A_TickCount
    duration := (endTime - startTime) / 1000
    
    ; 結果表示
    if (success) {
        LogMessage(Format("=== PROJECT CONVERSION COMPLETED in {:.2f} seconds ===", duration))
        ShowStatistics()
        logFile := SaveLogToFile()
        
        resultMsg := Format("
(
Project Conversion Completed Successfully!

Duration: {:.2f} seconds
Files processed: {}
Errors: {}
Warnings: {}

Log saved to: {}

Would you like to view the detailed statistics?
)", duration, g_converted_files, g_errors, g_warnings, logFile)
        
        result := MsgBox(resultMsg, "Conversion Complete", "YesNo Icon!")
        if (result = "Yes") {
            ShowDetailedReport()
        }
    } else {
        LogError("=== PROJECT CONVERSION FAILED ===")
        MsgBox("Project conversion failed! Check the error log for details.", "Conversion Failed", "OK Icon!")
        SaveLogToFile()
    }
}

; 詳細レポート表示
ShowDetailedReport() {
    global g_conversion_stats, g_converted_files, g_errors, g_warnings
    
    report := Format("
(
=== DETAILED CONVERSION REPORT ===

File Statistics:
• Files processed: {}
• Errors: {}
• Warnings: {}

Conversion Rules Applied:
• catch Error fixes: {}
• for loop conversions: {}
• Object property fixes: {}
• Conditional fixes: {}
• Range conversions: {}
• Python-like conversions: {}

Total rule applications: {}
)", 
    g_converted_files, g_errors, g_warnings,
    g_conversion_stats.catchErrors,
    g_conversion_stats.forLoops, 
    g_conversion_stats.objectProps,
    g_conversion_stats.conditionals,
    g_conversion_stats.rangeConversions,
    g_conversion_stats.pythonLike,
    g_conversion_stats.catchErrors + g_conversion_stats.forLoops + g_conversion_stats.objectProps + 
    g_conversion_stats.conditionals + g_conversion_stats.rangeConversions + g_conversion_stats.pythonLike)
    
    MsgBox(report, "Detailed Report", "OK")
}

; 実行
RunProjectConversion()