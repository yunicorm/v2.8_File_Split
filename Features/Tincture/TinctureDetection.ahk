; Tincture Detection Module
; Visual detection for tincture status (orange frame detection)
; v2.9.6 - Created for future implementation

; Tincture detection constants
global TINCTURE_ORANGE_COLOR := Map(
    "r", 255,
    "g", 165,
    "b", 0,
    "tolerance", 30
)

; Tincture detection globals
global g_tincture_detection_state := Map(
    "enabled", false,
    "last_detection_time", 0,
    "detection_interval", 150,  ; Slightly slower than flask detection
    "orange_frame_threshold", 0.7,  ; 70% orange pixels required
    "sampling_rate", 2,
    "results", Map()
)

; Tincture status constants
global TINCTURE_READY := 1
global TINCTURE_COOLDOWN := 0
global TINCTURE_DETECTION_FAILED := -1

; Initialize tincture detection system
InitializeTinctureDetection() {
    try {
        LogInfo("TinctureDetection", "Initializing tincture detection system")
        
        ; Load configuration
        enabled := ConfigManager.Get("TinctureDetection", "EnableTinctureDetection", "false")
        g_tincture_detection_state["enabled"] := (enabled = "true")
        
        interval := ConfigManager.Get("TinctureDetection", "DetectionInterval", 150)
        g_tincture_detection_state["detection_interval"] := interval
        
        threshold := ConfigManager.Get("TinctureDetection", "OrangeFrameThreshold", 0.7)
        g_tincture_detection_state["orange_frame_threshold"] := threshold
        
        sampling := ConfigManager.Get("TinctureDetection", "SamplingRate", 2)
        g_tincture_detection_state["sampling_rate"] := sampling
        
        LogInfo("TinctureDetection", Format("Tincture detection initialized: enabled={}, interval={}ms", 
            g_tincture_detection_state["enabled"], interval))
        
        return true
        
    } catch as e {
        LogError("TinctureDetection", "Failed to initialize tincture detection: " . e.Message)
        return false
    }
}

; Check if tincture detection is enabled
IsTinctureDetectionEnabled() {
    return g_tincture_detection_state["enabled"]
}

; Enable tincture detection
EnableTinctureDetection() {
    try {
        g_tincture_detection_state["enabled"] := true
        ConfigManager.Set("TinctureDetection", "EnableTinctureDetection", "true")
        
        LogInfo("TinctureDetection", "Tincture detection enabled")
        return true
        
    } catch as e {
        LogError("TinctureDetection", "Failed to enable tincture detection: " . e.Message)
        return false
    }
}

; Disable tincture detection
DisableTinctureDetection() {
    try {
        g_tincture_detection_state["enabled"] := false
        ConfigManager.Set("TinctureDetection", "EnableTinctureDetection", "false")
        
        LogInfo("TinctureDetection", "Tincture detection disabled")
        return true
        
    } catch as e {
        LogError("TinctureDetection", "Failed to disable tincture detection: " . e.Message)
        return false
    }
}

; Detect tincture ready status (orange frame detection)
DetectTinctureStatus(tinctureNumber) {
    try {
        if (!IsTinctureDetectionEnabled()) {
            LogDebug("TinctureDetection", "Tincture detection not enabled")
            return TINCTURE_DETECTION_FAILED
        }
        
        ; Check detection interval
        currentTime := A_TickCount
        lastTime := g_tincture_detection_state["last_detection_time"]
        interval := g_tincture_detection_state["detection_interval"]
        
        if ((currentTime - lastTime) < interval) {
            LogDebug("TinctureDetection", "Detection interval not met, skipping")
            return TINCTURE_DETECTION_FAILED
        }
        
        ; Update last detection time
        g_tincture_detection_state["last_detection_time"] := currentTime
        
        ; Get tincture position from config
        centerX := ConfigManager.Get("TinctureDetection", Format("Tincture{}X", tinctureNumber), 0)
        centerY := ConfigManager.Get("TinctureDetection", Format("Tincture{}Y", tinctureNumber), 0)
        width := ConfigManager.Get("TinctureDetection", Format("Tincture{}Width", tinctureNumber), 100)
        height := ConfigManager.Get("TinctureDetection", Format("Tincture{}Height", tinctureNumber), 100)
        
        if (centerX == 0 || centerY == 0) {
            LogError("TinctureDetection", Format("Tincture{} position not configured", tinctureNumber))
            return TINCTURE_DETECTION_FAILED
        }
        
        ; Perform orange frame detection
        result := DetectOrangeFrame(centerX, centerY, width, height)
        
        ; Store result
        g_tincture_detection_state["results"][tinctureNumber] := Map(
            "result", result,
            "timestamp", currentTime,
            "position", Map("x", centerX, "y", centerY),
            "dimensions", Map("width", width, "height", height)
        )
        
        LogDebug("TinctureDetection", Format("Tincture{} detection result: {}", tinctureNumber, result))
        return result
        
    } catch as e {
        LogError("TinctureDetection", Format("Tincture{} detection failed: {}", tinctureNumber, e.Message))
        return TINCTURE_DETECTION_FAILED
    }
}

; Detect orange frame around tincture icon
DetectOrangeFrame(centerX, centerY, width, height) {
    try {
        ; Calculate frame detection area (outer edge)
        frameThickness := 3  ; Pixel thickness of orange frame
        
        ; Sample the frame area
        samplingRate := g_tincture_detection_state["sampling_rate"]
        orangePixelCount := 0
        totalSampleCount := 0
        
        ; Sample top edge
        startY := centerY - height // 2
        endY := startY + frameThickness
        Loop height // samplingRate {
            x := centerX - width // 2 + (A_Index - 1) * samplingRate
            Loop frameThickness {
                y := startY + A_Index - 1
                if (IsPixelOrange(x, y)) {
                    orangePixelCount++
                }
                totalSampleCount++
            }
        }
        
        ; Sample bottom edge
        startY := centerY + height // 2 - frameThickness
        endY := startY + frameThickness
        Loop width // samplingRate {
            x := centerX - width // 2 + (A_Index - 1) * samplingRate
            Loop frameThickness {
                y := startY + A_Index - 1
                if (IsPixelOrange(x, y)) {
                    orangePixelCount++
                }
                totalSampleCount++
            }
        }
        
        ; Sample left edge
        startX := centerX - width // 2
        endX := startX + frameThickness
        Loop height // samplingRate {
            y := centerY - height // 2 + (A_Index - 1) * samplingRate
            Loop frameThickness {
                x := startX + A_Index - 1
                if (IsPixelOrange(x, y)) {
                    orangePixelCount++
                }
                totalSampleCount++
            }
        }
        
        ; Sample right edge
        startX := centerX + width // 2 - frameThickness
        endX := startX + frameThickness
        Loop height // samplingRate {
            y := centerY - height // 2 + (A_Index - 1) * samplingRate
            Loop frameThickness {
                x := startX + A_Index - 1
                if (IsPixelOrange(x, y)) {
                    orangePixelCount++
                }
                totalSampleCount++
            }
        }
        
        ; Calculate orange percentage
        if (totalSampleCount == 0) {
            return TINCTURE_DETECTION_FAILED
        }
        
        orangePercentage := orangePixelCount / totalSampleCount
        threshold := g_tincture_detection_state["orange_frame_threshold"]
        
        LogDebug("TinctureDetection", Format("Orange frame analysis: {:.2f}% orange ({}/{}), threshold: {:.1f}%", 
            orangePercentage * 100, orangePixelCount, totalSampleCount, threshold * 100))
        
        ; Determine tincture status
        if (orangePercentage >= threshold) {
            return TINCTURE_READY
        } else {
            return TINCTURE_COOLDOWN
        }
        
    } catch as e {
        LogError("TinctureDetection", "Failed to detect orange frame: " . e.Message)
        return TINCTURE_DETECTION_FAILED
    }
}

; Check if a pixel is orange
IsPixelOrange(x, y) {
    try {
        pixelColor := PixelGetColor(x, y, "RGB")
        
        ; Extract RGB components
        r := (pixelColor >> 16) & 0xFF
        g := (pixelColor >> 8) & 0xFF
        b := pixelColor & 0xFF
        
        ; Check against orange color with tolerance
        targetR := TINCTURE_ORANGE_COLOR["r"]
        targetG := TINCTURE_ORANGE_COLOR["g"]
        targetB := TINCTURE_ORANGE_COLOR["b"]
        tolerance := TINCTURE_ORANGE_COLOR["tolerance"]
        
        if (Abs(r - targetR) <= tolerance && 
            Abs(g - targetG) <= tolerance && 
            Abs(b - targetB) <= tolerance) {
            return true
        }
        
        return false
        
    } catch as e {
        LogError("TinctureDetection", Format("Failed to check pixel at {},{}: {}", x, y, e.Message))
        return false
    }
}

; Test tincture detection for a specific tincture
TestTinctureDetection(tinctureNumber) {
    try {
        LogInfo("TinctureDetection", Format("Testing tincture detection for Tincture{}", tinctureNumber))
        
        result := DetectTinctureStatus(tinctureNumber)
        
        switch result {
            case TINCTURE_READY:
                status := "READY (Orange frame detected)"
            case TINCTURE_COOLDOWN:
                status := "COOLDOWN (No orange frame)"
            case TINCTURE_DETECTION_FAILED:
                status := "DETECTION FAILED"
            default:
                status := "UNKNOWN"
        }
        
        LogInfo("TinctureDetection", Format("Tincture{} test result: {}", tinctureNumber, status))
        return result != TINCTURE_DETECTION_FAILED
        
    } catch as e {
        LogError("TinctureDetection", Format("Test tincture detection failed: {}", e.Message))
        return false
    }
}

; Get tincture detection results
GetTinctureDetectionResults() {
    return g_tincture_detection_state["results"]
}

; Clear tincture detection results
ClearTinctureDetectionResults() {
    g_tincture_detection_state["results"].Clear()
    LogDebug("TinctureDetection", "Tincture detection results cleared")
}

; Set orange frame threshold
SetOrangeFrameThreshold(threshold) {
    try {
        if (threshold < 0.1 || threshold > 1.0) {
            LogError("TinctureDetection", Format("Invalid threshold: {} (must be 0.1-1.0)", threshold))
            return false
        }
        
        g_tincture_detection_state["orange_frame_threshold"] := threshold
        ConfigManager.Set("TinctureDetection", "OrangeFrameThreshold", threshold)
        
        LogInfo("TinctureDetection", Format("Orange frame threshold set to: {:.1f}%", threshold * 100))
        return true
        
    } catch as e {
        LogError("TinctureDetection", "Failed to set orange frame threshold: " . e.Message)
        return false
    }
}

; Get current orange frame threshold
GetOrangeFrameThreshold() {
    return g_tincture_detection_state["orange_frame_threshold"]
}

; Cleanup tincture detection resources
CleanupTinctureDetection() {
    try {
        LogInfo("TinctureDetection", "Cleaning up tincture detection resources")
        
        ; Clear results
        ClearTinctureDetectionResults()
        
        ; Reset state
        g_tincture_detection_state["enabled"] := false
        g_tincture_detection_state["last_detection_time"] := 0
        
        LogInfo("TinctureDetection", "Tincture detection cleanup completed")
        return true
        
    } catch as e {
        LogError("TinctureDetection", "Tincture cleanup failed: " . e.Message)
        return false
    }
}

; Get tincture detection status
GetTinctureDetectionStatus() {
    try {
        status := Map(
            "enabled", g_tincture_detection_state["enabled"],
            "interval", g_tincture_detection_state["detection_interval"],
            "threshold", g_tincture_detection_state["orange_frame_threshold"],
            "sampling_rate", g_tincture_detection_state["sampling_rate"],
            "last_detection", g_tincture_detection_state["last_detection_time"],
            "results_count", g_tincture_detection_state["results"].Count
        )
        
        return status
        
    } catch as e {
        LogError("TinctureDetection", "Failed to get tincture status: " . e.Message)
        return Map()
    }
}