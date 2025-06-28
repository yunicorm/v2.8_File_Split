; ===================================================================
; フラスコ条件判定 - 条件チェック・ヘルパー関数
; フラスコ使用条件の判定とヘルパー関数を担当
; ===================================================================

; --- 体力割合の取得 ---
GetHealthPercentage() {
    ; TODO: 実際のヘルス％を取得する実装
    ; 現在はダミー実装
    return 100
}

; --- 移動中かどうかの判定 ---
IsMoving() {
    ; TODO: 移動中かどうかを判定する実装
    ; 現在はダミー実装
    return false
}

; --- 体力チェックのラッパー関数 ---
CheckHealthPercentage() {
    return GetHealthPercentage()
}

; --- マナ割合の取得 ---
GetManaPercentage() {
    ; TODO: 実際のマナ％を取得する実装
    ; 現在はダミー実装
    return 100
}

; --- エネルギーシールド割合の取得 ---
GetEnergyShieldPercentage() {
    ; TODO: 実際のエネルギーシールド％を取得する実装
    ; 現在はダミー実装
    return 100
}

; --- 戦闘中かどうかの判定 ---
IsInCombat() {
    ; TODO: 戦闘中かどうかを判定する実装
    ; 現在はダミー実装
    return false
}

; --- ボス戦中かどうかの判定 ---
IsBossFight() {
    ; TODO: ボス戦中かどうかを判定する実装
    ; 現在はダミー実装
    return false
}

; --- 呪い状態かどうかの判定 ---
HasCurse() {
    ; TODO: 呪い状態を検出する実装
    ; 現在はダミー実装
    return false
}

; --- 燃焼状態かどうかの判定 ---
IsBurning() {
    ; TODO: 燃焼状態を検出する実装
    ; 現在はダミー実装
    return false
}

; --- 冷却状態かどうかの判定 ---
IsChilled() {
    ; TODO: 冷却状態を検出する実装
    ; 現在はダミー実装
    return false
}

; --- 感電状態かどうかの判定 ---
IsShocked() {
    ; TODO: 感電状態を検出する実装
    ; 現在はダミー実装
    return false
}

; --- 毒状態かどうかの判定 ---
IsPoisoned() {
    ; TODO: 毒状態を検出する実装
    ; 現在はダミー実装
    return false
}

; --- 出血状態かどうかの判定 ---
IsBleeding() {
    ; TODO: 出血状態を検出する実装
    ; 現在はダミー実装
    return false
}

; --- 複合条件チェック関数 ---

; --- 低体力条件（デフォルト70%未満） ---
IsLowHealth(threshold := 70) {
    return GetHealthPercentage() < threshold
}

; --- 低マナ条件（デフォルト50%未満） ---
IsLowMana(threshold := 50) {
    return GetManaPercentage() < threshold
}

; --- 低エネルギーシールド条件（デフォルト30%未満） ---
IsLowEnergyShield(threshold := 30) {
    return GetEnergyShieldPercentage() < threshold
}

; --- 危険状態の判定（複数デバフまたは低体力） ---
IsInDanger() {
    debuffCount := 0
    
    if (HasCurse()) debuffCount++
    if (IsBurning()) debuffCount++
    if (IsChilled()) debuffCount++
    if (IsShocked()) debuffCount++
    if (IsPoisoned()) debuffCount++
    if (IsBleeding()) debuffCount++
    
    return (debuffCount >= 2) || IsLowHealth(50)
}

; --- 移動速度増加が有益な状況 ---
ShouldUseQuicksilver() {
    return IsMoving() && !IsInCombat()
}

; --- 防御フラスコが必要な状況 ---
ShouldUseDefensiveFlask() {
    return IsInCombat() || IsBossFight() || IsInDanger()
}

; --- 攻撃フラスコが有益な状況 ---
ShouldUseOffensiveFlask() {
    return IsInCombat() || IsBossFight()
}

; --- ユーティリティフラスコが有益な状況 ---
ShouldUseUtilityFlask() {
    return HasCurse() || (IsBurning() || IsChilled() || IsShocked())
}

; --- 条件関数の登録システム ---
global g_condition_functions := Map()

; --- 条件関数の登録 ---
RegisterConditionFunction(name, func) {
    global g_condition_functions
    
    g_condition_functions[name] := func
    LogDebug("FlaskConditions", Format("Registered condition function: {}", name))
}

; --- 条件関数の実行 ---
EvaluateCondition(conditionName, params := []) {
    global g_condition_functions
    
    if (!g_condition_functions.Has(conditionName)) {
        LogWarn("FlaskConditions", Format("Unknown condition function: {}", conditionName))
        return false
    }
    
    try {
        conditionFunc := g_condition_functions[conditionName]
        return conditionFunc(params*)
    } catch Error as e {
        LogError("FlaskConditions", Format("Error evaluating condition '{}': {}", 
            conditionName, e.Message))
        return false
    }
}

; --- フラスコ条件の評価 ---
EvaluateFlaskCondition(flaskName, config) {
    global g_flask_configs
    
    ; 設定に条件が定義されていない場合は常にtrue
    if (!config.HasOwnProp("useCondition")) {
        return true
    }
    
    try {
        return config.useCondition()
    } catch Error as e {
        LogError("FlaskConditions", Format("Error evaluating flask '{}' condition: {}", 
            flaskName, e.Message))
        return false
    }
}

; --- 条件ヘルパー関数の初期化 ---
InitializeConditionHelpers() {
    ; 基本条件関数を登録
    RegisterConditionFunction("lowHealth", IsLowHealth)
    RegisterConditionFunction("lowMana", IsLowMana)
    RegisterConditionFunction("lowEnergyShield", IsLowEnergyShield)
    RegisterConditionFunction("inCombat", () => IsInCombat())
    RegisterConditionFunction("moving", () => IsMoving())
    RegisterConditionFunction("inDanger", () => IsInDanger())
    RegisterConditionFunction("shouldUseQuicksilver", () => ShouldUseQuicksilver())
    RegisterConditionFunction("shouldUseDefensive", () => ShouldUseDefensiveFlask())
    RegisterConditionFunction("shouldUseOffensive", () => ShouldUseOffensiveFlask())
    RegisterConditionFunction("shouldUseUtility", () => ShouldUseUtilityFlask())
    
    LogInfo("FlaskConditions", "Condition helper functions initialized")
}

; --- デバッグ用: 全条件状態の表示 ---
GetAllConditionStates() {
    return {
        healthPercentage: GetHealthPercentage(),
        manaPercentage: GetManaPercentage(),
        energyShieldPercentage: GetEnergyShieldPercentage(),
        isMoving: IsMoving(),
        isInCombat: IsInCombat(),
        isBossFight: IsBossFight(),
        hasCurse: HasCurse(),
        isBurning: IsBurning(),
        isChilled: IsChilled(),
        isShocked: IsShocked(),
        isPoisoned: IsPoisoned(),
        isBleeding: IsBleeding(),
        isLowHealth: IsLowHealth(),
        isLowMana: IsLowMana(),
        isLowEnergyShield: IsLowEnergyShield(),
        isInDanger: IsInDanger()
    }
}

; --- 条件評価のパフォーマンス統計 ---
global g_condition_performance := {
    evaluations: 0,
    failures: 0,
    averageTime: 0,
    totalTime: 0
}

; --- 条件評価の統計更新 ---
UpdateConditionPerformance(evaluationTime, failed := false) {
    global g_condition_performance
    
    g_condition_performance.evaluations++
    g_condition_performance.totalTime += evaluationTime
    g_condition_performance.averageTime := g_condition_performance.totalTime / g_condition_performance.evaluations
    
    if (failed) {
        g_condition_performance.failures++
    }
}

; --- 条件評価統計の取得 ---
GetConditionPerformanceStats() {
    global g_condition_performance
    
    successRate := g_condition_performance.evaluations > 0 ? 
        Round((1 - g_condition_performance.failures / g_condition_performance.evaluations) * 100, 2) : 100
    
    return {
        totalEvaluations: g_condition_performance.evaluations,
        failures: g_condition_performance.failures,
        successRate: successRate,
        averageEvaluationTime: Round(g_condition_performance.averageTime, 2)
    }
}