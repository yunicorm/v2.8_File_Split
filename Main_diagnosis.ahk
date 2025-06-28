; ===================================================================
; AutoHotkey v2 段階的診断スクリプト
; main.ahk実行問題の詳細診断
; ===================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; === 段階1: 基本起動テスト ===
try {
    FileAppend(A_Now . " - Stage 1: Basic startup test`n", "diagnosis.log")
    MsgBox("Stage 1: AutoHotkey v2 basic test successful", "Diagnosis - Stage 1")
} catch as e {
    FileAppend(A_Now . " - Stage 1 ERROR: " . e.Message . "`n", "diagnosis.log")
    ExitApp()
}

; === 段階2: ファイルシステムアクセステスト ===
try {
    FileAppend(A_Now . " - Stage 2: File system access test`n", "diagnosis.log")
    
    ; 作業ディレクトリ確認
    workingDir := A_WorkingDir
    scriptDir := A_ScriptDir
    
    FileAppend("Working Dir: " . workingDir . "`n", "diagnosis.log")
    FileAppend("Script Dir: " . scriptDir . "`n", "diagnosis.log")
    
    MsgBox("Stage 2: File system access successful`nWorking Dir: " . workingDir, "Diagnosis - Stage 2")
} catch as e {
    FileAppend(A_Now . " - Stage 2 ERROR: " . e.Message . "`n", "diagnosis.log")
    ExitApp()
}

; === 段階3: 基本インクルードテスト ===
try {
    FileAppend(A_Now . " - Stage 3: Testing basic includes`n", "diagnosis.log")
    
    ; Utils/ConfigManagerの存在確認
    configPath := A_ScriptDir . "\Utils\ConfigManager.ahk"
    if (FileExist(configPath)) {
        FileAppend("ConfigManager.ahk found`n", "diagnosis.log")
    } else {
        FileAppend("ConfigManager.ahk NOT found at: " . configPath . "`n", "diagnosis.log")
    }
    
    ; Utils/Loggerの存在確認
    loggerPath := A_ScriptDir . "\Utils\Logger.ahk"
    if (FileExist(loggerPath)) {
        FileAppend("Logger.ahk found`n", "diagnosis.log")
    } else {
        FileAppend("Logger.ahk NOT found at: " . loggerPath . "`n", "diagnosis.log")
    }
    
    MsgBox("Stage 3: Include path check completed", "Diagnosis - Stage 3")
} catch as e {
    FileAppend(A_Now . " - Stage 3 ERROR: " . e.Message . "`n", "diagnosis.log")
    ExitApp()
}

; === 段階4: 実際のインクルードテスト ===
try {
    FileAppend(A_Now . " - Stage 4: Testing actual include`n", "diagnosis.log")
    
    ; Logger.ahkを実際にインクルード
    #Include "Utils/Logger.ahk"
    
    FileAppend("Logger.ahk included successfully`n", "diagnosis.log")
    MsgBox("Stage 4: Logger include successful", "Diagnosis - Stage 4")
} catch as e {
    FileAppend(A_Now . " - Stage 4 ERROR: " . e.Message . "`n", "diagnosis.log")
    MsgBox("Stage 4 FAILED: " . e.Message, "Diagnosis - Stage 4 ERROR")
    ExitApp()
}

; === 段階5: ConfigManagerインクルードテスト ===
try {
    FileAppend(A_Now . " - Stage 5: Testing ConfigManager include`n", "diagnosis.log")
    
    #Include "Utils/ConfigManager.ahk"
    
    FileAppend("ConfigManager.ahk included successfully`n", "diagnosis.log")
    MsgBox("Stage 5: ConfigManager include successful", "Diagnosis - Stage 5")
} catch as e {
    FileAppend(A_Now . " - Stage 5 ERROR: " . e.Message . "`n", "diagnosis.log")
    MsgBox("Stage 5 FAILED: " . e.Message, "Diagnosis - Stage 5 ERROR")
    ExitApp()
}

; === 最終段階: 診断完了 ===
FileAppend(A_Now . " - DIAGNOSIS COMPLETED SUCCESSFULLY`n", "diagnosis.log")
MsgBox("All diagnosis stages passed!`nCheck diagnosis.log for details.", "Diagnosis Complete - SUCCESS")

ExitApp()