# Path of Exile マクロ v2.9.3 - 開発者向けドキュメント

## プロジェクト概要

Path of Exileマクロは、「Wine of the Prophet」ビルド向けに特化した自動化ツールです。v2.9.3では大規模なモジュール分割リファクタリングを実施し、保守性と拡張性を大幅に向上させました。

## モジュール構造（v2.9.3リファクタリング）

### 1. 設定GUI分割（SettingsWindow → 5ファイル）

#### 分割前
- `UI/SettingsWindow.ahk` - 1,320行の巨大ファイル

#### 分割後
```
UI/SettingsWindow/
├── SettingsMain.ahk        (320行) - メインウィンドウ・制御
├── FlaskTab.ahk           (280行) - フラスコタブUI  
├── SkillTab.ahk           (290行) - スキルタブUI
├── GeneralTab.ahk         (250行) - 一般タブUI
└── SettingsValidation.ahk (180行) - 設定検証・エラー処理
```

**責任範囲**:
- `SettingsMain`: ウィンドウ作成、タブ制御、保存/キャンセル処理
- `FlaskTab`: フラスコ1-5、Tincture設定UI
- `SkillTab`: 10スキル設定、Wine設定UI
- `GeneralTab`: デバッグ、ログ、マナ検出設定UI
- `SettingsValidation`: 入力検証、エラーダイアログ

### 2. スキル管理分割（SkillAutomation → 5ファイル）

#### 分割前
- `Features/SkillAutomation.ahk` - 1,182行の複雑ファイル

#### 分割後
```
Features/Skills/
├── SkillController.ahk     (255行) - メイン制御・タイマー管理
├── SkillConfigurator.ahk   (181行) - 設定読み込み・初期化
├── WineManager.ahk         (191行) - Wine専用管理
├── SkillStatistics.ahk     (302行) - 統計・監視機能
└── SkillHelpers.ahk        (253行) - ヘルパー・テスト機能
```

**責任範囲**:
- `SkillController`: 自動化開始/停止、タイマーコールバック、実行制御
- `SkillConfigurator`: レガシー/新システム設定、Config.ini読み込み
- `WineManager`: Wine of the Prophet専用ロジック、5段階ステージ管理
- `SkillStatistics`: 使用統計、パフォーマンス監視、デバッグ情報
- `SkillHelpers`: テスト機能、手動実行、ユーティリティ

### 3. フラスコ管理分割（FlaskManager → 5ファイル）

#### 分割前
- `Features/FlaskManager.ahk` - 674行の機能混在ファイル

#### 分割後
```
Features/Flask/
├── FlaskController.ahk     (328行) - 制御・タイマー管理
├── FlaskChargeManager.ahk  (269行) - チャージ管理・計算
├── FlaskConditions.ahk     (266行) - 条件判定・ヘルパー
├── FlaskConfiguration.ahk  (468行) - 設定管理・プリセット
└── FlaskStatistics.ahk     (335行) - 統計・履歴管理
```

**責任範囲**:
- `FlaskController`: 自動化開始/停止、個別フラスコタイマー、使用制御
- `FlaskChargeManager`: チャージ追跡、獲得/消費計算、効率分析
- `FlaskConditions`: 15種類状態検出、条件評価システム
- `FlaskConfiguration`: 設定管理、3つのプリセット、Config.ini連携
- `FlaskStatistics`: 使用統計、効率レポート、履歴機能（100件）

## 詳細技術仕様ドキュメント

`/docs/technical-specs/` に以下の詳細仕様を用意：

- `data-structures.md` - グローバル変数とデータ構造の詳細
- `function-signatures.md` - 全関数の完全な仕様
- `event-flow.md` - 動作フローと状態遷移
- `timer-specifications.md` - タイマーシステムの詳細
- `internal-apis.md` - 内部APIと暗黙的インターフェース
- `error-handling-details.md` - エラー処理パターンと回復戦略
- `config-validation-rules.md` - Config.ini検証ルールの完全仕様

新機能開発時は、これらのドキュメントで実装詳細を確認してください。

### 4. ユーティリティ統合（Utils/Validators.ahk追加）

v2.9.3で新規追加されたユーティリティモジュール：

```
Utils/Validators.ahk (70行) - 共通検証関数ライブラリ
```

**主要機能**:
- `IsValidInteger()` - AutoHotkey v2組み込み関数との衝突を回避
- `IsValidRange()` - 数値範囲チェック
- `IsPositiveInteger()` - 正の整数チェック  
- `IsValidPriority()` - 優先度範囲チェック（1-5）
- `IsValidColorValue()` - 色値チェック（0-255）
- `IsValidPercentage()` - パーセンテージチェック（0-100）

**解決した問題**:
- 3ファイルでのIsValidInteger重複定義エラー
- 関数名衝突による実行時エラー
- 検証ロジックの一元管理

## 新機能（v2.9.3で追加）

### 1. 条件判定システム（FlaskConditions.ahk）

**15種類の状態検出関数**:
```ahk
// 基本状態
GetHealthPercentage(), IsMoving(), GetManaPercentage(), GetEnergyShieldPercentage()

// 戦闘状態  
IsInCombat(), IsBossFight()

// デバフ状態
HasCurse(), IsBurning(), IsChilled(), IsShocked(), IsPoisoned(), IsBleeding()

// 複合条件
IsLowHealth(threshold), IsLowMana(threshold), IsInDanger()
```

**動的条件登録システム**:
```ahk
RegisterConditionFunction("customCondition", () => CustomLogic())
EvaluateCondition("customCondition", [param1, param2])
```

### 2. 統計・分析機能強化

**FlaskStatistics.ahk新機能**:
- 使用履歴管理（最新100件）
- 効率レポート生成
- パフォーマンス統計
- リアルタイム成功率計算

**SkillStatistics.ahk新機能**:
- スキル別使用統計
- 平均遅延・エラー率追跡
- パフォーマンス予測

### 3. 設定プリセット（FlaskConfiguration.ahk）

**3つのプリセット**:
```ahk
// 基本構成
"basic": ライフ+マナフラスコ

// 完全自動構成  
"full_auto": 5フラスコ完全自動化

// 戦闘重視構成
"combat": 防御・攻撃フラスコ重点
```

### 4. チャージ管理システム（FlaskChargeManager.ahk）

**高度なチャージ追跡**:
- 時間ベースチャージ計算
- 効率統計・回復時間予測
- チャージ不足時の自動制限

## グローバル変数管理

### 分離設計
各モジュールは専用のグローバル変数を管理：

**SkillSystem**:
- `g_skill_timers`, `g_skill_last_use`, `g_skill_enabled` (SkillController)
- `g_skill_configs` (SkillConfigurator)  
- `g_skill_stats` (SkillStatistics)
- `g_wine_stage_start_time`, `g_wine_current_stage` (WineManager)

**FlaskSystem**:
- `g_flask_timer_handles`, `g_flask_automation_paused` (FlaskController)
- `g_flask_charge_tracker` (FlaskChargeManager)
- `g_flask_configs` (FlaskConfiguration)
- `g_flask_stats`, `g_flask_use_count` (FlaskStatistics)

## 依存関係設計

### レイヤー構造
```
Utils (基盤) → UI → Config → Core → Features → Hotkeys (最上位)
```

### モジュール間依存
- **循環依存なし**の設計
- 適切な委譲パターン
- TimerManager、Loggerへの統一依存

## 開発ガイドライン

### コード規約
```ahk
// 関数名: PascalCase
StartFlaskAutomation()

// 変数名: snake_case with g_prefix  
global g_flask_timer_active

// 定数: UPPER_CASE
TIMING_FLASK_MAX
```

### エラーハンドリング
```ahk
try {
    // メイン処理
    UseFlask(flaskName, config)
} catch Error as e {
    LogError("ModuleName", "Error description: " . e.Message)
    // 適切な回復処理
}
```

### ログ記録
```ahk
LogInfo("ModuleName", "Operation completed successfully")
LogError("ModuleName", "Error with context information")  
LogDebug("ModuleName", "Detailed diagnostic information")
```

## テスト戦略

### 単体テスト
各モジュールは独立してテスト可能：
```ahk
// FlaskChargeManager単体テスト
TestChargeCalculation()
TestChargeConsumption()
TestEfficiencyAnalysis()
```

### 統合テスト
モジュール間の連携テスト：
```ahk
// Flask統合テスト
TestFlaskAutomationFlow()
TestConditionBasedUsage()
TestStatisticsIntegration()
```

## 今後の拡張ポイント

### 1. 条件判定システム拡張
- PixelSearch/ImageSearchによる実装
- バフアイコン検出
- 敵検出・識別

### 2. AI/機械学習統合
- 使用パターン学習
- 最適タイミング予測
- 異常検出

### 3. 外部API連携
- Path of Exile公式API
- 価格情報取得
- ビルド情報同期

### 4. 設定システム拡張
- プロファイル管理
- クラウド同期
- 設定共有機能

## パフォーマンス考慮事項

### タイマー管理
- 優先度システム（Critical > High > Normal > Low）
- 100ms間隔でのチャージ更新
- エラー率監視による自動停止

### メモリ効率
- Map使用による高速アクセス
- 循環バッファによる履歴管理
- ガベージコレクション配慮

## 移行ガイド（v2.9.2 → v2.9.3）

### 互換性
- **完全な後方互換性**維持
- Config.ini形式変更なし
- 既存ホットキー・API保持

### 新機能利用
```ahk
// 新しい条件判定システム
InitializeConditionHelpers()
result := EvaluateCondition("lowHealth", [75])

// 強化された統計機能
stats := GetDetailedFlaskStats("life")
report := GenerateFlaskEfficiencyReport()

// プリセット機能
ApplyFlaskPreset("combat")
```

## 貢献ガイド

### コード貢献
1. 適切なモジュールへの配置
2. エラーハンドリング必須
3. ログ記録の徹底
4. テストケース作成

### 新機能追加
1. 責任範囲の明確化
2. 既存モジュールとの整合性
3. 設定システムとの統合
4. ドキュメント更新

## 既知の問題（v2.9.3時点）

### 1. catch文構文エラー
**ファイル**: `UI/SettingsWindow/SettingsMain.ahk`  
**行**: 145-147  
**エラー**: `Invalid class`  
**問題**: `catch Error as e` 構文

**対処予定**: AutoHotkey v2のcatch構文に修正

### 2. 分割モジュールの最終テスト未完了
**状況**: 分割されたモジュールの一部でWindows環境での実行テストが未完了

**残件**:
- SettingsWindow分割ファイルの結合テスト
- Skills分割ファイルの統合テスト  
- Flask分割ファイルの動作確認

### 3. レガシーコードの残存
**残存箇所**:
- バックアップファイル（*_backup.ahk）
- テストファイル（test_*.ahk）
- 一部の古い構文

**対処予定**: クリーンアップとコード統合

### 4. ドキュメント同期
**課題**: 分割後の関数シグネチャとドキュメントの不整合

**対処必要**:
- `/docs/technical-specs/function-signatures.md` の更新
- API仕様書の同期

## 開発優先度

1. **緊急**: catch文構文エラーの修正
2. **高**: 分割モジュールの実行テスト完了
3. **中**: レガシーコードのクリーンアップ
4. **低**: ドキュメント同期とリファクタリング

このリファクタリングにより、Path of Exileマクロは大幅な保守性と拡張性を獲得し、今後の機能追加と改善が容易になりました。