# FlaskManager.ahk分割分析レポート

## 1. 現状分析結果

### ファイル概要
- **総行数**: 825行
- **関数数**: 73個
- **グローバル変数**: 6個のMapと1個の統計オブジェクト

### 主要機能グループ分析

#### A. 初期化グループ (2関数)
- `InitializeFlaskConfigs()` - フラスコ設定テンプレート作成
- `InitializeChargeTracker()` - チャージ追跡システム初期化

#### B. 制御グループ (7関数) 
- `StartFlaskAutomation()` - システム開始
- `StopFlaskAutomation()` - システム停止  
- `PauseFlaskAutomation()` / `ResumeFlaskAutomation()` - 一時停止/再開
- `StartFlaskTimer()` / `StopFlaskTimer()` - 個別フラスコ制御
- `RetryFlaskStart()` - 再試行ロジック

#### C. タイミング・実行グループ (4関数)
- `FlaskTimerCallback()` - メインタイマーコールバック
- `UseFlask()` - 中核使用関数（検証付き）
- `UseManaFlask()` - レガシー互換性関数
- `ManualUseFlask()` - 手動トリガー

#### D. チャージ管理グループ (1関数)
- `UpdateFlaskCharges()` - 時間ベースチャージ計算・更新

#### E. 設定管理グループ (2関数)
- `ConfigureFlasks()` - 動的フラスコ設定
- `ToggleFlask()` - 個別有効/無効切替

#### F. 統計・監視グループ (3関数)
- `UpdateFlaskStats()` - 使用統計更新
- `GetFlaskStats()` - 統計情報取得
- `GetFlaskDebugInfo()` - デバッグ情報取得

#### G. 条件判定グループ (3関数)
- `GetHealthPercentage()` - 体力割合チェック（TODO実装）
- `IsMoving()` - 移動検出（TODO実装）
- `CheckHealthPercentage()` - 体力チェックラッパー

## 2. グローバル変数使用状況

### タイマー関連
- `g_flask_timer_handles` - アクティブタイマーハンドル管理
- `g_flask_automation_paused` - 一時停止状態フラグ

### 使用追跡
- `g_flask_use_count` - フラスコ別使用回数
- `g_flask_last_use_time` - 最終使用タイムスタンプ
- `g_flask_active_flasks` - アクティブフラスコ管理

### 設定・データ
- `g_flask_configs` - フラスコ設定Map（中核データ）
- `g_flask_charge_tracker` - チャージ追跡データ
- `g_flask_stats` - グローバル統計オブジェクト

## 3. 他モジュールとの依存関係

### 強依存
- **TimerManager**: `StartManagedTimer()`, `StopManagedTimer()`
- **Logger**: `LogInfo()`, `LogError()`, `LogDebug()`, `LogWarn()`
- **ConfigManager**: `TIMING_FLASK`, `KEY_MANA_FLASK`

### 中依存
- **PerformanceMonitor**: `StartPerfTimer()`, `EndPerfTimer()`
- **MacroController**: グローバル状態 `g_macro_active`

### 軽依存
- **DebugDisplay**: デバッグ情報提供
- **SettingsWindow**: 設定インターフェース

## 4. チャージ管理機能詳細分析

### 実装レベル: **高度に実装済み**

#### チャージ追跡構造
```
g_flask_charge_tracker[flaskName] = {
    currentCharges: number,    // 現在チャージ数
    lastGainTime: tickCount,   // 最終チャージ取得時刻
    lastUseTime: tickCount     // 最終使用時刻
}
```

#### チャージ計算システム
- **更新頻度**: 100ms間隔
- **計算式**: `gain = (経過時間秒 * chargeGainRate)`
- **上限制御**: `Math.min(current + gain, maxCharges)`
- **使用時検証**: 使用前にチャージ十分性確認

#### チャージ設定
各フラスコに以下のチャージパラメータ:
- `maxCharges` - 最大チャージ容量
- `chargePerUse` - 使用時消費チャージ
- `chargeGainRate` - 秒あたりチャージ獲得率

## 5. 条件判定機能詳細分析

### 実装レベル: **フレームワーク完成、ヘルパー関数TODO**

#### 条件システム設計
- **条件関数**: 各フラスコの`useCondition`プロパティ
- **評価タイミング**: タイマー開始時、使用時、再試行時
- **条件例**:
  - ライフフラスコ: `() => CheckHealthPercentage() < 70`
  - クイックシルバー: `() => IsMoving()`

#### 条件失敗処理
- **開始失敗**: 1秒後再試行
- **実行時失敗**: 500ms後再チェック
- **優雅な劣化**: 他フラスコの動作は継続

#### 未実装ヘルパー関数
- `GetHealthPercentage()` - 体力割合取得（TODO）
- `IsMoving()` - 移動状態検出（TODO）

## 6. 最適分割方法提案

### 推奨分割構造

```
Features/Flask/
├── FlaskController.ahk     # 制御・タイミング (140-160行)
├── FlaskChargeManager.ahk  # チャージ管理 (80-100行)  
├── FlaskConditions.ahk     # 条件判定・ヘルパー (60-80行)
├── FlaskConfiguration.ahk  # 設定管理・初期化 (120-140行)
└── FlaskStatistics.ahk     # 統計・デバッグ情報 (100-120行)
```

### 関数分配

#### FlaskController.ahk (制御層)
```
- StartFlaskAutomation()
- StopFlaskAutomation()  
- PauseFlaskAutomation() / ResumeFlaskAutomation()
- StartFlaskTimer() / StopFlaskTimer()
- FlaskTimerCallback()
- UseFlask()
- UseManaFlask() (レガシー)
- ManualUseFlask()
- RetryFlaskStart()
- ResetFlaskTiming()
```

#### FlaskChargeManager.ahk (チャージ層)
```
- InitializeChargeTracker()
- UpdateFlaskCharges() 
- GetFlaskCharges()
- ValidateChargeUsage()
- ResetFlaskCharges()
```

#### FlaskConditions.ahk (条件層)
```
- GetHealthPercentage()
- IsMoving()
- CheckHealthPercentage()
- EvaluateFlaskCondition()
- RegisterConditionHelpers()
```

#### FlaskConfiguration.ahk (設定層)
```
- InitializeFlaskConfigs()
- ConfigureFlasks()
- ToggleFlask()
- LoadFlaskFromConfig()
- ValidateFlaskConfig()
```

#### FlaskStatistics.ahk (統計層)
```
- UpdateFlaskStats()
- GetFlaskStats()
- GetFlaskDebugInfo()
- ResetFlaskStats()
- GetFlaskPerformanceReport()
```

### グローバル変数分配
- **Controller**: `g_flask_timer_handles`, `g_flask_automation_paused`
- **ChargeManager**: `g_flask_charge_tracker`
- **Configuration**: `g_flask_configs`, `g_flask_active_flasks`
- **Statistics**: `g_flask_stats`, `g_flask_use_count`, `g_flask_last_use_time`

## 7. 分割の利点

### 保守性向上
- 各ファイル100-160行で管理しやすいサイズ
- 機能別の明確な責任分離
- チャージシステムの独立性

### 拡張性向上  
- 条件システムの独立により新条件追加が容易
- 統計システムの分離により監視機能拡張が簡単
- 設定システムの分離により新フラスコタイプ追加が容易

### テスト性向上
- 各機能の単体テストが可能
- チャージ計算ロジックの独立テスト
- 条件判定ロジックのモックテスト

## 8. 注意点

### 依存関係管理
- TimerManagerとの密結合（適切な委譲必要）
- グローバル変数の共有（適切なinclude順序必要）

### 既存コード互換性
- `UseManaFlask()`レガシー関数の維持
- 既存設定形式との互換性保持

### パフォーマンス考慮
- チャージ更新の100ms間隔維持
- 条件評価の最適化

**結論**: FlaskManager.ahkは高度に実装された複雑なシステムですが、明確な機能境界により5ファイルへの分割が可能です。特にチャージ管理システムと条件判定フレームワークの分離により、大幅な保守性向上が期待できます。