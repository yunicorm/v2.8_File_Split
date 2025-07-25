; Visual Detection Testing Tools Module
; Debug functions, testing utilities, and diagnostic tools
; v2.9.6 - Extracted from VisualDetection.ahk for better modularity

; Testing globals
global g_test_session := Map()
global g_debug_mode := false
global g_performance_metrics := Map()

; Initialize testing tools
InitializeTestingTools() {
    try {
        LogInfo("TestingTools", "Initializing testing tools")
        
        ; Initialize test session
        g_test_session := Map(
            "started", false,
            "start_time", 0,
            "test_count", 0,
            "success_count", 0,
            "failure_count", 0,
            "results", []
        )
        
        ; Initialize performance metrics
        g_performance_metrics := Map(
            "detection_times", [],
            "average_time", 0,
            "max_time", 0,
            "min_time", 999999
        )
        
        ; Load debug mode setting
        debugEnabled := ConfigManager.Get("VisualDetection", "DebugMode", "false")
        g_debug_mode := (debugEnabled = "true")
        
        LogInfo("TestingTools", Format("Testing tools initialized, debug mode: {}", g_debug_mode))
        return true
        
    } catch as e {
        LogError("TestingTools", "Failed to initialize testing tools: " . e.Message)
        return false
    }
}

; Start test session
StartTestSession() {
    try {
        LogInfo("TestingTools", "Starting test session")
        
        g_test_session["started"] := true
        g_test_session["start_time"] := A_TickCount
        g_test_session["test_count"] := 0
        g_test_session["success_count"] := 0
        g_test_session["failure_count"] := 0
        g_test_session["results"] := []
        
        ; Clear performance metrics
        g_performance_metrics["detection_times"] := []
        g_performance_metrics["average_time"] := 0
        g_performance_metrics["max_time"] := 0
        g_performance_metrics["min_time"] := 999999
        
        LogInfo("TestingTools", "Test session started")
        return true
        
    } catch as e {
        LogError("TestingTools", "Failed to start test session: " . e.Message)
        return false
    }
}

; End test session and show results
EndTestSession() {
    try {
        if (!g_test_session["started"]) {
            LogWarn("TestingTools", "No test session was started")
            return false
        }
        
        duration := A_TickCount - g_test_session["start_time"]
        
        ; Calculate statistics
        totalTests := g_test_session["test_count"]
        successRate := totalTests > 0 ? (g_test_session["success_count"] / totalTests) * 100 : 0
        
        ; Calculate average detection time
        detectionTimes := g_performance_metrics["detection_times"]
        if (detectionTimes.Length > 0) {
            totalTime := 0
            for time in detectionTimes {
                totalTime += time
            }
            g_performance_metrics["average_time"] := totalTime / detectionTimes.Length
        }
        
        ; Create results report
        results := [
            "=== Visual Detection Test Session Results ===",
            "",
            Format("Session Duration: {:.1f} seconds", duration / 1000),
            Format("Total Tests: {}", totalTests),
            Format("Successful: {} ({:.1f}%)", g_test_session["success_count"], successRate),
            Format("Failed: {} ({:.1f}%)", g_test_session["failure_count"], 100 - successRate),
            "",
            "Performance Metrics:",
            Format("  Average Detection Time: {:.1f}ms", g_performance_metrics["average_time"]),
            Format("  Fastest Detection: {:.1f}ms", g_performance_metrics["min_time"]),
            Format("  Slowest Detection: {:.1f}ms", g_performance_metrics["max_time"]),
            ""
        ]
        
        ; Add individual test results
        if (g_test_session["results"].Length > 0) {
            results.Push("Individual Test Results:")
            for testResult in g_test_session["results"] {
                results.Push(Format("  {}: {} ({:.1f}ms)", 
                    testResult["name"], 
                    testResult["success"] ? "PASS" : "FAIL",
                    testResult["duration"]))
            }
        }
        
        ; Display results
        ShowMultiLineOverlay(results, 10000)
        
        ; Reset session
        g_test_session["started"] := false
        
        LogInfo("TestingTools", Format("Test session completed: {}/{} tests passed", 
            g_test_session["success_count"], totalTests))
        
        return true
        
    } catch as e {
        LogError("TestingTools", "Failed to end test session: " . e.Message)
        return false
    }
}

; Test single flask detection
TestSingleFlaskDetection(flaskNumber) {
    try {
        testName := Format("Flask{} Detection", flaskNumber)
        LogInfo("TestingTools", Format("Testing: {}", testName))
        
        startTime := A_TickCount
        
        ; Perform detection
        result := DetectFlaskCharge(flaskNumber)
        
        endTime := A_TickCount
        duration := endTime - startTime
        
        ; Record performance
        g_performance_metrics["detection_times"].Push(duration)
        if (duration > g_performance_metrics["max_time"]) {
            g_performance_metrics["max_time"] := duration
        }
        if (duration < g_performance_metrics["min_time"]) {
            g_performance_metrics["min_time"] := duration
        }
        
        ; Determine success
        success := (result != -1)  ; Any result except failure is considered success
        
        ; Record test result
        if (g_test_session["started"]) {
            g_test_session["test_count"]++
            if (success) {
                g_test_session["success_count"]++
            } else {
                g_test_session["failure_count"]++
            }
            
            g_test_session["results"].Push(Map(
                "name", testName,
                "success", success,
                "duration", duration,
                "result", result
            ))
        }
        
        ; Log result
        statusText := ""
        switch result {
            case 1:
                statusText := "HAS CHARGES"
            case 0:
                statusText := "EMPTY"
            case -1:
                statusText := "DETECTION FAILED"
        }
        
        LogInfo("TestingTools", Format("{} result: {} ({:.1f}ms)", testName, statusText, duration))
        
        return success
        
    } catch as e {
        LogError("TestingTools", Format("Test single flask detection failed: {}", e.Message))
        return false
    }
}

; Test all flask detections
TestAllFlaskDetections() {
    try {
        LogInfo("TestingTools", "Testing all flask detections")
        
        results := []
        totalTests := 0
        successfulTests := 0
        
        ; Test each flask
        Loop 5 {
            flaskNumber := A_Index
            
            ; Check if flask is configured
            x := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
            y := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
            
            if (x != 0 || y != 0) {
                totalTests++
                success := TestSingleFlaskDetection(flaskNumber)
                if (success) {
                    successfulTests++
                }
                
                ; Add result to display
                statusText := success ? "PASS" : "FAIL"
                results.Push(Format("Flask{}: {}", flaskNumber, statusText))
            } else {
                results.Push(Format("Flask{}: NOT CONFIGURED", flaskNumber))
            }
        }
        
        ; Add summary
        if (totalTests > 0) {
            successRate := (successfulTests / totalTests) * 100
            results.Push("")
            results.Push(Format("Summary: {}/{} tests passed ({:.1f}%)", 
                successfulTests, totalTests, successRate))
        }
        
        ; Display results
        ShowMultiLineOverlay(results, 5000)
        
        LogInfo("TestingTools", Format("All flask tests completed: {}/{} passed", 
            successfulTests, totalTests))
        
        return successfulTests == totalTests
        
    } catch as e {
        LogError("TestingTools", "Test all flask detections failed: " . e.Message)
        return false
    }
}

; Performance benchmark
RunPerformanceBenchmark(iterations := 10) {
    try {
        LogInfo("TestingTools", Format("Running performance benchmark with {} iterations", iterations))
        
        ; Start benchmark
        benchmarkResults := []
        totalDuration := 0
        
        Loop iterations {
            iterationStart := A_TickCount
            
            ; Test configured flasks
            configuredFlasks := []
            Loop 5 {
                flaskNumber := A_Index
                x := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
                y := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
                
                if (x != 0 || y != 0) {
                    configuredFlasks.Push(flaskNumber)
                }
            }
            
            ; Test each configured flask
            for flaskNumber in configuredFlasks {
                DetectFlaskCharge(flaskNumber)
            }
            
            iterationEnd := A_TickCount
            iterationDuration := iterationEnd - iterationStart
            totalDuration += iterationDuration
            
            benchmarkResults.Push(iterationDuration)
        }
        
        ; Calculate statistics
        avgDuration := totalDuration / iterations
        minDuration := 999999
        maxDuration := 0
        
        for duration in benchmarkResults {
            if (duration < minDuration) {
                minDuration := duration
            }
            if (duration > maxDuration) {
                maxDuration := duration
            }
        }
        
        ; Create benchmark report
        results := [
            "=== Performance Benchmark Results ===",
            "",
            Format("Iterations: {}", iterations),
            Format("Total Duration: {:.1f}s", totalDuration / 1000),
            Format("Average per Iteration: {:.1f}ms", avgDuration),
            Format("Fastest Iteration: {:.1f}ms", minDuration),
            Format("Slowest Iteration: {:.1f}ms", maxDuration),
            Format("Detections per Second: {:.1f}", 1000 / avgDuration)
        ]
        
        ShowMultiLineOverlay(results, 8000)
        
        LogInfo("TestingTools", Format("Performance benchmark completed: avg {:.1f}ms", avgDuration))
        return avgDuration
        
    } catch as e {
        LogError("TestingTools", "Performance benchmark failed: " . e.Message)
        return -1
    }
}

; Debug overlay display
ShowDebugOverlay() {
    try {
        ; Get current status
        visualStatus := GetVisualDetectionStatus()
        detectionResults := GetDetectionResults()
        
        debugInfo := [
            "=== Visual Detection Debug Info ===",
            "",
            Format("Status: {}", visualStatus["enabled"] ? "ENABLED" : "DISABLED"),
            Format("Mode: {}", visualStatus["mode"]),
            Format("Interval: {}ms", visualStatus["interval"]),
            Format("FindText Available: {}", visualStatus["findtext_available"] ? "YES" : "NO"),
            "",
            "Recent Detection Results:"
        ]
        
        ; Add recent results
        resultCount := 0
        for flaskNumber, result in detectionResults {
            if (resultCount >= 5) {
                break  ; Limit to 5 most recent
            }
            
            timestamp := result["timestamp"]
            status := ""
            switch result["result"] {
                case 1:
                    status := "CHARGED"
                case 0:
                    status := "EMPTY"
                case -1:
                    status := "FAILED"
            }
            
            debugInfo.Push(Format("  Flask{}: {} ({}ms ago)", 
                flaskNumber, status, A_TickCount - timestamp))
            resultCount++
        }
        
        if (resultCount == 0) {
            debugInfo.Push("  No recent results")
        }
        
        ShowMultiLineOverlay(debugInfo, 6000)
        
        LogInfo("TestingTools", "Debug overlay displayed")
        return true
        
    } catch as e {
        LogError("TestingTools", "Failed to show debug overlay: " . e.Message)
        return false
    }
}

; Enable debug mode
EnableDebugMode() {
    try {
        g_debug_mode := true
        ConfigManager.Set("VisualDetection", "DebugMode", "true")
        
        LogInfo("TestingTools", "Debug mode enabled")
        ShowVisualNotification("Debug Mode", "Debug mode enabled", "info", 2000)
        return true
        
    } catch as e {
        LogError("TestingTools", "Failed to enable debug mode: " . e.Message)
        return false
    }
}

; Disable debug mode
DisableDebugMode() {
    try {
        g_debug_mode := false
        ConfigManager.Set("VisualDetection", "DebugMode", "false")
        
        LogInfo("TestingTools", "Debug mode disabled")
        ShowVisualNotification("Debug Mode", "Debug mode disabled", "info", 2000)
        return true
        
    } catch as e {
        LogError("TestingTools", "Failed to disable debug mode: " . e.Message)
        return false
    }
}

; Toggle debug mode
ToggleDebugMode() {
    if (g_debug_mode) {
        return DisableDebugMode()
    } else {
        return EnableDebugMode()
    }
}

; Is debug mode enabled
IsDebugModeEnabled() {
    return g_debug_mode
}

; Clear all test data
ClearTestData() {
    try {
        ; Clear test session
        g_test_session := Map(
            "started", false,
            "start_time", 0,
            "test_count", 0,
            "success_count", 0,
            "failure_count", 0,
            "results", []
        )
        
        ; Clear performance metrics
        g_performance_metrics := Map(
            "detection_times", [],
            "average_time", 0,
            "max_time", 0,
            "min_time", 999999
        )
        
        ; Clear detection results
        ClearDetectionResults()
        
        LogInfo("TestingTools", "All test data cleared")
        return true
        
    } catch as e {
        LogError("TestingTools", "Failed to clear test data: " . e.Message)
        return false
    }
}

; Global variables for real-time testing
global g_visual_test_timer := ""
global g_test_overlay_gui := ""

; Toggle visual detection test mode with real-time detection
ToggleVisualDetectionTestMode() {
    global g_test_session, g_visual_test_timer, g_test_overlay_gui
    static testMode := false
    
    try {
        testMode := !testMode
        ConfigManager.Set("VisualDetection", "TestMode", testMode ? "true" : "false")
        
        if (testMode) {
            ; Start test mode with real-time detection
            ShowOverlay("テストモード: ON - リアルタイム検出開始", 2000)
            LogInfo("TestingTools", "Real-time visual detection test mode enabled")
            
            ; Start real-time detection timer
            g_visual_test_timer := SetTimer(PerformTestDetection, 250)
            
            ; Initialize test session if needed
            if (!g_test_session.Has("started")) {
                StartTestSession()
            }
        } else {
            ; Stop test mode
            ShowOverlay("テストモード: OFF", 2000)
            LogInfo("TestingTools", "Real-time visual detection test mode disabled")
            
            ; Stop timer
            if (g_visual_test_timer) {
                SetTimer(g_visual_test_timer, 0)
                g_visual_test_timer := ""
            }
            
            ; Cleanup overlay
            if (g_test_overlay_gui) {
                try g_test_overlay_gui.Destroy()
                g_test_overlay_gui := ""
            }
            
            ; End test session
            if (g_test_session.Has("started") && g_test_session["started"]) {
                EndTestSession()
            }
        }
        
        return testMode
        
    } catch as e {
        LogError("TestingTools", "Failed to toggle test mode: " . e.Message)
        ShowOverlay("テストモード切り替えエラー: " . e.Message, 3000)
        return false
    }
}

; Perform real-time test detection
PerformTestDetection() {
    global g_test_overlay_gui
    
    try {
        results := []
        
        ; Test each flask's detection status
        Loop 5 {
            flaskNumber := A_Index
            
            ; Get flask coordinates
            x := ConfigManager.Get("VisualDetection", Format("Flask{}X", flaskNumber), 0)
            y := ConfigManager.Get("VisualDetection", Format("Flask{}Y", flaskNumber), 0)
            
            if (x == 0 || y == 0) {
                results.Push(Format("Flask{}: 未設定", flaskNumber))
                continue
            }
            
            ; Check if flask has saved pattern
            pattern := ConfigManager.Get("VisualDetection", Format("Flask{}ChargedPattern", flaskNumber), "")
            if (pattern == "") {
                results.Push(Format("Flask{}: パターン無", flaskNumber))
                continue
            }
            
            ; Perform detection (simplified for testing)
            try {
                ; Use existing detection function if available
                if (IsSet(DetectFlaskCharge)) {
                    result := DetectFlaskCharge(flaskNumber)
                    switch result {
                        case 1: results.Push(Format("Flask{}: 充填", flaskNumber))
                        case 0: results.Push(Format("Flask{}: 空", flaskNumber))
                        case -1: results.Push(Format("Flask{}: エラー", flaskNumber))
                        default: results.Push(Format("Flask{}: 不明", flaskNumber))
                    }
                } else {
                    results.Push(Format("Flask{}: 検出不可", flaskNumber))
                }
            } catch {
                results.Push(Format("Flask{}: 検出エラー", flaskNumber))
            }
        }
        
        ; Update test overlay with results
        UpdateTestOverlay(results)
        
    } catch as e {
        LogError("TestingTools", "Real-time detection error: " . e.Message)
    }
}

; Update or create test overlay with detection results
UpdateTestOverlay(results) {
    global g_test_overlay_gui
    
    try {
        ; Create overlay if it doesn't exist
        if (!g_test_overlay_gui) {
            g_test_overlay_gui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
            g_test_overlay_gui.BackColor := "0x1E1E1E"
            g_test_overlay_gui.SetFont("s12", "Consolas")
            
            ; Add text control for results
            g_test_overlay_gui.Add("Text", "cLime vResultText w250 h120", "")
            
            ; Position at top-right corner
            g_test_overlay_gui.Show("x3190 y10 w250 h120 NoActivate")
            WinSetTransparent(220, g_test_overlay_gui)
        }
        
        ; Build result text
        text := "=== リアルタイム検出 ===`n"
        for result in results {
            text .= result . "`n"
        }
        text .= Format("更新: {}", FormatTime(, "HH:mm:ss"))
        
        ; Update text
        g_test_overlay_gui["ResultText"].Text := text
        
    } catch as e {
        LogError("TestingTools", "Failed to update test overlay: " . e.Message)
    }
}

; Check if visual detection test mode is currently active
IsVisualDetectionTestModeActive() {
    global g_test_session
    
    try {
        return g_test_session.Has("started") && g_test_session["started"]
    } catch {
        return false
    }
}