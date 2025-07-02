# Path of Exile マクロ v2.9.5 - 開発者向けドキュメント

## プロジェクト概要

Path of Exileマクロは、「Wine of the Prophet」ビルド向けに特化した自動化ツールです。v2.9.5では楕円形フラスコ検出システムを実装し、従来の矩形検出から精度を大幅に向上させました。

### v2.9.5 (2025-01-02)
- フラスコ検出エリアを楕円形に変更
- 楕円の縦横比を個別調整可能に
- Wine of the Prophet の色検出を複数範囲対応に改善
- F9キー操作を拡張（楕円形状の調整機能追加）

## プロジェクトの制約事項
- AutoHotkey v2.0+ 準拠のコードのみ
- 既存のモジュール構造を尊重
- エラーハンドリングとログ記録を必須とする

## 優先順位
1. 既存機能の動作を保証
2. 段階的な実装で検証可能にする
3. パフォーマンスへの影響を最小限に

## 成功基準
- 既存のタイマーベースシステムとの共存
- CPU使用率の増加が5%以内
- 設定UIでの切り替えが可能

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

## 外部ライブラリ統合ガイド

### FindText (v10.0) - 実装済み
画像認識ベースのフラスコチャージ検出に使用

**統合状況**: ✅ v2.9.4で実装完了
- VisualDetection.ahk でラップ
- FlaskController.ahk で使用
- 3つの検出モード対応

**使用例**:
```ahk
; フラスコチャージ検出
chargeStatus := DetectFlaskCharge(flaskNumber)
// 1: チャージあり, 0: 空, -1: 検出失敗
```

**配置場所**: `Utils/FindText.ahk`

**基本的な使い方**:
```autohotkey
; インスタンス取得
ft := FindText()

; 画像検索（基本形）
ok := FindText().FindText(&X, &Y, x1, y1, x2, y2, err1, err0, Text)

; 戻り値
; ok: 見つかった場合は配列、見つからない場合は0
; X, Y: 見つかった座標（絶対座標）
; ok[1].x, ok[1].y: 中心座標
; ok[1].id: コメント文字列

; テキスト形式
Text := "|<comment>*similarity$width.base64data"
```

### 画像キャプチャ方法
```autohotkey
; GUIツールを使用したキャプチャ
FindText().Gui("Show")

; コードからの直接キャプチャ
Text := FindText().GetTextFromScreen(x1, y1, x2, y2)
```

## Visual Detection System (v2.9.4実装)

### 概要
FindTextを使用したフラスコチャージの視覚的検出システム

### 検出モード
- **Timer**: 従来のタイマーベース（デフォルト）
- **Visual**: 視覚的検出のみ
- **Hybrid**: 視覚的検出→失敗時タイマー

### 統合ポイント
- **UseFlask()**: 視覚的検出を最初に試行
- **PerformInitialActions()**: 起動時初期化

### アーキテクチャ
```ahk
// 初期化フロー
InitializeVisualDetection()
├── CheckFindTextFile()           // ファイル存在確認
├── InitializeDefaultVisualDetectionConfig()  // デフォルト設定
└── FindText() インスタンス作成

// 検出フロー  
UseFlask(flaskName, config)
├── GetDetectionMode() != "Timer"
├── DetectFlaskCharge(flaskNumber)
│   ├── CanPerformDetection()     // 100ms間隔制限
│   └── DetectFlaskChargeInternal() // FindText実行
└── フォールバック処理
```

### 設定項目
```ini
[VisualDetection]
Enabled=false                    // 機能有効/無効
DetectionMode=Timer             // Timer/Visual/Hybrid
Flask1X=0                       // フラスコ1のX座標
Flask1Y=0                       // フラスコ1のY座標
Flask1ChargedPattern=           // チャージパターン（base64）
DetectionInterval=100           // 検出間隔制限（ms）
SearchAreaSize=25               // 検索エリアサイズ
```

### エラーハンドリング
- **FindText.ahk不在**: 自動的にTimerモードで動作
- **検出失敗**: -1を返してフォールバック
- **設定不備**: エラーログ出力後、無効化

### パフォーマンス最適化
- **間隔制限**: 100ms以内の再検出を防止
- **エリア限定**: ±25px範囲での検索
- **失敗時フォールバック**: 既存システムへの自動切り替え

## フラスコ検出システムアーキテクチャ (v2.9.5)

### 楕円形検出の実装詳細

#### 座標系
- **中心座標系**: F9で設定した座標は楕円の中心点
- **検出範囲**: 設定した楕円全体（上部60%制限を撤廃）
- **サンプリング**: 3ピクセルごとのグリッドスキャン

#### 色検出の最適化
Wine of the Prophet用の複数色範囲：
```ahk
; 明るいオレンジ: RGB(200-255, 150-200, 50-100)
; 中間オレンジ: RGB(180-240, 120-190, 40-90)
; 暗い茶色: RGB(30-70, 20-50, 15-35)
```

#### パフォーマンス考慮
- 楕円内判定により、スキャンピクセル数を約21%削減
- DllCallのオーバーヘッドは CreateEllipticRgn の初回作成時のみ
- リアルタイム調整時は座標変更のみで再描画

#### 将来の拡張案
- フラスコタイプ別プリセット: Life/Mana/Unique用の楕円比率
- 自動形状検出: エッジ検出による最適楕円の自動計算
- Tincture専用形状: 矩形のまま、またはカスタム形状

### チャージ検出の仕組み（v2.9.5）

#### 検出フロー
1. **楕円形エリア定義**: F9で設定した楕円がそのまま検出範囲
2. **色検出**: 楕円内の全ピクセルをスキャン（3pxごとのサンプリング）
3. **割合計算**: Wine液体色のピクセル数 ÷ 総スキャンピクセル数
4. **チャージ推定**: 液体割合 × 最大チャージ（140）
5. **使用可否判定**: 推定チャージ >= 72（1回使用分）

#### 例
- 楕円内の60%がWine色 → 84チャージ（使用可能）
- 楕円内の40%がWine色 → 56チャージ（使用不可）

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

### 1. 設定ウィンドウGUIエラー（修正済み）
**ファイル**: `UI/SettingsWindow/SkillTab.ahk`  
**行**: 24, 67  
**エラー**: `Too many parameters passed to function`  
**問題**: `gui.Add("Text", "x50 y110", "Group 1", "Bold")` - 4パラメータ使用

**修正内容**: 
- ❌ 修正前: `gui.Add("Text", "x50 y110", "Group 1", "Bold")`
- ✅ 修正後: `gui.Add("Text", "x50 y110", "Group 1")`
- **教訓**: AutoHotkey v2のGui.Add()は3パラメータのみ (Type, Options, Text)

### 2. 無効なオプション指定エラー（修正済み）
**問題**: `gui.Add("Text", "x50 y110 Bold", "Group 1")` - "Bold"が無効オプション
**修正方法**: フォントスタイルはSetFont()で設定
```ahk
gui.SetFont("Bold")
gui.Add("Text", "x50 y110", "Group 1")
gui.SetFont()  ; デフォルトに戻す
```

### 3. catch文構文エラー（未修正）
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

## GUI開発の学習項目（今回の修正から）

### AutoHotkey v2 GUIの重要な制約
1. **パラメータ数制限**: `gui.Add(Type, Options, Text)` - 必ず3パラメータ以内
2. **オプション文字列形式**: 座標・サイズ・スタイルは全てOptions文字列に記述
3. **フォントスタイル**: SetFont()メソッドで事前設定が必要
4. **デバッグ重要性**: エラー後は完全再起動推奨（キャッシュ問題）

### 実践的対処パターン
```ahk
// ❌ 避けるべきパターン
gui.Add("Text", "x10 y10", "テキスト", "Bold")  // 4パラメータ
gui.Add("Text", "x10 y10 Bold", "テキスト")     // 無効オプション

// ✅ 推奨パターン
gui.SetFont("Bold")                              // フォント設定
gui.Add("Text", "x10 y10", "テキスト")          // 正しい3パラメータ
gui.SetFont()                                    // デフォルトに戻す
```

## トラブルシューティングガイド

### 設定ウィンドウが開かない場合のデバッグ手順

#### エラーログの確認
`Logs/` フォルダの最新ログファイルで以下を確認：
- "Too many parameters passed to function"
- "Invalid option"  
- ShowSettingsWindow関連のエラー

#### 段階的デバッグアプローチ

1. **ステップ1**: エラーメッセージの詳細確認（ファイル名、行番号）
2. **ステップ2**: 問題のあるGUI作成コードを特定
3. **ステップ3**: AutoHotkey v2のGUI構文に準拠しているか確認
4. **ステップ4**: 最小限のテストスクリプトで問題を再現

#### よくある原因と解決策

| エラーメッセージ | 原因 | 解決策 |
|---|---|---|
| Too many parameters | イベントハンドラーの引数不一致 | Variadic関数 `(*)` を使用 |
| Invalid option | 無効なGUIオプション（Bold等） | `SetFont()` を使用 |
| Multiple parameters to Add() | v1構文の混在 | 3パラメータに修正 |

## 開発のベストプラクティス

### AutoHotkey v2 GUI開発チェックリスト

- [ ] `Gui.Add()` は3パラメータのみ使用
- [ ] フォントスタイルは `SetFont()` で設定  
- [ ] イベントハンドラーは `(*)` パラメータを使用
- [ ] `Tab3.OnEvent("Change", Tab_Change)` のような登録
- [ ] エラー時は必ずログファイルを確認
- [ ] 複雑なGUIは分割モジュールで管理

## 開発優先度

1. **緊急**: catch文構文エラーの修正
2. **高**: 分割モジュールの実行テスト完了
3. **中**: レガシーコードのクリーンアップ
4. **低**: ドキュメント同期とリファクタリング

このリファクタリングにより、Path of Exileマクロは大幅な保守性と拡張性を獲得し、今後の機能追加と改善が容易になりました。

## v2.9.4 フラスコ座標設定機能改善（2025/06/30実装）

### 実装内容
- 一括フラスコ座標設定機能を実装
- 5つのオーバーレイを同時に表示・調整可能に
- 従来の個別設定から大幅な効率化を実現

### 技術的ポイント
1. AutoHotkey v2のラムダ関数制限への対処
   - 複数行実行にはヘルパー関数を使用
   - Hotkey設定では`(*) =>`形式を使用

2. 変数スコープの管理
   - Loop内でのGui変数名の衝突を回避
   - `gui`→`newGui`、`existingGui`など明示的な命名

### 操作方法
- F9: 座標取得モード（5つ同時表示）
- 矢印: 全体移動
- +/_: 間隔調整（±2px）
- =/- ]/[ '/;: サイズ変更
- Space: 一括保存

## トラブルシューティング

### ConfigManager Mapアクセスエラー
**問題**: "This value of type "Map" has no property named "type""
**原因**: AutoHotkey v2ではMapオブジェクトのプロパティアクセス方法が異なる
**解決**: 
- `map.property` → `map["property"]`
- Objectタイプは`.property`のまま、Mapタイプのみ`["key"]`形式を使用

### フラスコ設定が反映されない
**問題**: 設定ウィンドウの変更が実際の動作に反映されない
**原因**: `InitializeFlaskConfigs()`がハードコード値を使用
**解決**:
1. `StartFlaskAutomation()`で`LoadFlaskConfigFromINI()`を呼び出す
2. INI読み込み失敗時のみデフォルト値を使用
3. `UpdateFlaskManagerConfig()`で実行時の設定更新を実装

### フラスコとシステムキーの競合
**問題**: Flask3/4がTincture/Wineシステムと同じキーを使用
**解決**:
1. `CheckFlaskKeyConflict()`関数で競合を検出
2. 競合するフラスコを自動的に無効化
3. ログに詳細な競合情報を出力

## 開発のベストプラクティス

### Map vs Object の使い分け
- **Map使用時**: `map["key"]`または`map.Get("key")`
- **Object使用時**: `object.property`
- **型チェック**: `Type(variable) == "Map"`で判定してアクセス方法を切り替え

### 設定の動的読み込み
- 起動時: INIファイルから設定を読み込む
- 実行時: ConfigManager経由で設定を更新
- フォールバック: 読み込み失敗時のデフォルト値を用意