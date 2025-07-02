; Visual Detection System - Main API
; This file serves as the main entry point for the visual detection system
; v2.9.6 - Refactored into modular architecture

; Include all split modules - Order is important for dependencies
#Include "VisualDetection/Core.ahk"
#Include "VisualDetection/Settings.ahk"
#Include "VisualDetection/UIHelpers.ahk"
#Include "VisualDetection/CoordinateManager.ahk"
#Include "VisualDetection/TestingTools.ahk"
#Include "Flask/FlaskDetection.ahk"
#Include "Flask/FlaskOverlay.ahk"
#Include "Wine/WineDetection.ahk"
#Include "Tincture/TinctureDetection.ahk"

; Main API Functions - These serve as the public interface

; Initialize the entire visual detection system
InitializeVisualDetectionSystem() {
    try {
        LogInfo("VisualDetection", "Initializing complete visual detection system")
        
        ; Initialize core modules in dependency order
        if (!InitializeVisualDetection()) {
            throw Error("Core initialization failed")
        }
        
        if (!LoadVisualDetectionConfig()) {
            LogWarn("VisualDetection", "Configuration loading failed, using defaults")
        }
        
        if (!InitializeTestingTools()) {
            LogWarn("VisualDetection", "Testing tools initialization failed")
        }
        
        if (!InitializeTinctureDetection()) {
            LogWarn("VisualDetection", "Tincture detection initialization failed")
        }
        
        LogInfo("VisualDetection", "Visual detection system fully initialized")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to initialize visual detection system: " . e.Message)
        return false
    }
}

; Cleanup the entire visual detection system
CleanupVisualDetectionSystem() {
    try {
        LogInfo("VisualDetection", "Cleaning up visual detection system")
        
        ; Cleanup modules in reverse order
        CleanupTinctureDetection()
        ClearTestData()
        ClearSettingsCache()
        CleanupVisualDetection()
        
        LogInfo("VisualDetection", "Visual detection system cleanup completed")
        return true
        
    } catch as e {
        LogError("VisualDetection", "Failed to cleanup visual detection system: " . e.Message)
        return false
    }
}

; Public API wrapper functions for backward compatibility

; Enable/Disable visual detection
EnableVisualDetectionSystem() {
    return EnableVisualDetection()
}

DisableVisualDetectionSystem() {
    return DisableVisualDetection()
}

; Detection mode management
GetCurrentDetectionMode() {
    return GetDetectionMode()
}

SetCurrentDetectionMode(mode) {
    return SetDetectionMode(mode)
}

; Flask detection API
DetectFlask(flaskNumber) {
    return DetectFlaskCharge(flaskNumber)
}

TestFlask(flaskNumber) {
    return TestSingleFlaskDetection(flaskNumber)
}

TestAllFlasks() {
    return TestAllFlaskDetections()
}

; Configuration API
GetFlaskSetting(key, defaultValue := "") {
    return GetSetting(key, defaultValue)
}

SetFlaskSetting(key, value) {
    return SetSetting(key, value)
}

LoadFlaskConfig() {
    return LoadVisualDetectionConfig()
}

SaveFlaskConfig() {
    return SaveVisualDetectionConfig()
}

; Preset management API
ApplyFlaskPreset(presetName) {
    return ApplyPreset(presetName)
}

SaveCurrentAsCustomPreset() {
    return SaveCustomPreset("CustomPreset", "User-defined custom preset")
}

ExportCurrentSettings() {
    return ExportSettings()
}

ImportSettingsFromConfig() {
    return ImportSettings()
}

; Status and information API
GetSystemStatus() {
    try {
        status := Map(
            "visual_detection", GetVisualDetectionStatus(),
            "tincture_detection", GetTinctureDetectionStatus(),
            "configured_flasks", GetConfiguredFlaskCount(),
            "debug_mode", IsDebugModeEnabled()
        )
        return status
    } catch as e {
        LogError("VisualDetection", "Failed to get system status: " . e.Message)
        return Map()
    }
}

; Debug and testing API
ShowSystemDebugInfo() {
    return ShowDebugOverlay()
}

RunSystemBenchmark(iterations := 10) {
    return RunPerformanceBenchmark(iterations)
}

StartSystemTestSession() {
    return StartTestSession()
}

EndSystemTestSession() {
    return EndTestSession()
}

ToggleSystemDebugMode() {
    return ToggleDebugMode()
}

; Coordinate management API
ConvertToAbsolute(relativeX, relativeY) {
    return ConvertRelativeToAbsolute(relativeX, relativeY)
}

ConvertToRelative(absoluteX, absoluteY) {
    return ConvertAbsoluteToRelative(absoluteX, absoluteY)
}

GetMonitorInformation() {
    return GetCachedMonitorInfo()
}

ValidateFlaskCoordinates(x, y, width, height) {
    return ValidateCoordinates(x, y, width, height)
}

; UI and overlay API
ShowSystemMultiLineOverlay(lines, duration := 5000) {
    return ShowMultiLineOverlay(lines, duration)
}

ShowSystemNotification(title, message, type := "info", duration := 3000) {
    return ShowVisualNotification(title, message, type, duration)
}

ShowSystemProgress(title, current, total, description := "") {
    return ShowProgressOverlay(title, current, total, description)
}

; Wine detection API (delegated to Wine module)
TestWineDetection() {
    return TestWineChargeDetection()
}

DiagnoseWine() {
    return DiagnoseWineDetection()
}

GetMouseColor() {
    return GetMousePositionColor()
}

; Tincture detection API (delegated to Tincture module)
DetectTincture(tinctureNumber) {
    return DetectTinctureStatus(tinctureNumber)
}

TestTincture(tinctureNumber) {
    return TestTinctureDetection(tinctureNumber)
}

SetTinctureThreshold(threshold) {
    return SetOrangeFrameThreshold(threshold)
}

GetTinctureThreshold() {
    return GetOrangeFrameThreshold()
}

; Legacy compatibility functions - maintained for existing code
IsVisualDetectionReady() {
    return IsVisualDetectionEnabled()
}

GetLastDetectionResults() {
    return GetDetectionResults()
}

ClearAllDetectionResults() {
    ClearDetectionResults()
    ClearTinctureDetectionResults()
    return true
}

ResetVisualDetectionSystem() {
    return ResetVisualDetectionState()
}