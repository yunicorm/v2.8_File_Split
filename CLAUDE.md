以下が修正版のCLAUDE.mdです：
markdown# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a sophisticated **Path of Exile automation macro** written in **AutoHotkey v2** (v2.9.6), specifically designed for the "Wine of the Prophet" build. The codebase features robust error handling, **highly modular architecture**, and comprehensive game automation capabilities.

### v2.9.6 Major Refactoring (2025-01-02)
**VisualDetection.ahk** underwent complete modular refactoring for better maintainability and Claude Code compatibility:
- **Original**: 3,587 lines → **Refactored**: 249 lines (-93% reduction)
- **Split into 9 specialized modules** for different functionality areas
- **All files now under 25,000 tokens** - fully compatible with Claude Code
- **Backward compatibility maintained** through comprehensive API wrapper layer

## Development Commands

### Execution
```bash
# Run the macro (requires AutoHotkey v2.0+)
# Double-click Main.ahk or run via AutoHotkey
Main.ahk
Configuration Management

Settings GUI: Ctrl+Shift+S (opens graphical settings window)
Hot reload config: Alt+F12 (reloads Config.ini without restart)
Settings file: Config.ini (auto-generated on first run)
Reset macro state: Ctrl+R

Debugging Commands

Debug mana detection: F11
Timer debug info: F8 (shows priority, execution times)
Full debug display: F7 (comprehensive system status)
View logs: F6 (opens log viewer)
Test performance: Ctrl+P

No Build/Test System

This is a direct-execution AutoHotkey script
No compilation or build process required
Testing done through built-in debug modes and live monitoring

Architecture Overview
Module Structure
Utils (foundational) → UI → Config → Core → Features → Hotkeys (final)
Critical Dependency Order: The include sequence in Main.ahk must be preserved - each layer depends on the previous ones.
Claude Code連携時の注意事項
AutoHotkey実行環境

Claude CodeはLinux環境で動作（AutoHotkey実行不可）
.claude_code_instructions.mdに従い自動的に代替検証を実施
Windows環境での動作確認は別途必要

代替検証方法

静的構文解析による検証
括弧の対応確認
AutoHotkey v2構文準拠チェック
インクルードパスの妥当性検証
関数定義の重複確認

Technical Specifications
詳細な技術仕様は /docs/technical-specs/ ディレクトリを参照：

data-structures.md - グローバル変数とデータ構造の詳細
function-signatures.md - 全関数の完全な仕様
event-flow.md - 動作フローと状態遷移
timer-specifications.md - タイマーシステムの詳細
internal-apis.md - 内部APIと暗黙的インターフェース
error-handling-details.md - エラー処理パターンと回復戦略
config-validation-rules.md - Config.ini検証ルールの完全仕様

これらのドキュメントは、コードベースの深い理解が必要な場合に参照。
Key Directories (v2.9.6 Updated)
Core/ - Central control systems

MacroController.ahk: State management and initial actions
TimerManager.ahk: Priority-based timer system with performance monitoring
WindowManager.ahk: Window detection and target application management

Features/ - Domain-specific automation modules

ManaMonitor.ahk: Circular mana orb sampling with optimization modes
TinctureManager.ahk: Complex cooldown/retry logic with usage statistics

Flask/ (v2.9.6 Expanded with Visual Detection)
FlaskController.ahk: 制御・タイマー管理
FlaskChargeManager.ahk: チャージ管理・計算
FlaskConditions.ahk: 条件判定・ヘルパー
FlaskConfiguration.ahk: 設定管理・プリセット
FlaskStatistics.ahk: 統計・履歴管理
FlaskDetection.ahk: ビジュアル検出ロジック (v2.9.6新規)
FlaskOverlay.ahk: オーバーレイUI管理 (v2.9.6新規, 1,199行)

Skills/ (v2.9.4で5ファイルに分割)
SkillController.ahk: メイン制御・タイマー管理
SkillConfigurator.ahk: 設定読み込み・初期化
WineManager.ahk: Wine専用管理
SkillStatistics.ahk: 統計・監視機能
SkillHelpers.ahk: ヘルパー・テスト機能

VisualDetection/ (v2.9.6 NEW: 完全モジュール化)
VisualDetection.ahk: メインAPI・エントリーポイント (249行)
Core.ahk: グローバル変数・初期化 (390行)
Settings.ahk: 設定管理・プリセット (532行)
UIHelpers.ahk: 拡張UIヘルパー (317行)
CoordinateManager.ahk: 座標変換・モニター管理 (448行)
TestingTools.ahk: デバッグ・テストツール (462行)

Wine/ (v2.9.6 NEW: Wine of the Prophet専用)
WineDetection.ahk: Wine専用検出・診断 (523行)

Tincture/ (v2.9.6 NEW: 将来実装用)
TinctureDetection.ahk: オレンジ枠検出準備 (366行)

ClientLogMonitor.ahk: Log file parsing for area transitions

### 楕円形検出エリア実装 (v2.9.5)
フラスコの自然な形状に合わせて、検出エリアを矩形から楕円形に変更しました。

#### 主な改善点
- **精度向上**: フラスコの実際の形状（楕円形）に合致
- **誤検出削減**: 矩形の角部分の背景色を除外
- **柔軟な調整**: 各フラスコごとに楕円の縦横比を調整可能

#### 操作方法
```
F9: 座標設定モード開始
矢印キー: 位置調整
]/[: 楕円の幅調整
'/;: 楕円の高さ調整
=/—: 全体サイズ調整
Shift+キー: 微調整（2px単位）
Space: 保存
```

#### 技術詳細
- `IsPointInEllipse()`: 楕円内判定関数
- `CreateEllipticRgn`: Windows APIによる楕円形GUI作成
- Wine of the Prophet対応: オレンジ〜茶色の複数色範囲検出

Utils/ - Foundational services

ConfigManager.ahk: INI management with validation and hot-reloading
Logger.ahk: Comprehensive logging with rotation and buffering (改善済み: 自動ローテーション機能追加)
ColorDetection.ahk: Optimized pixel color detection
HotkeyValidator.ahk: Conflict detection and registration
Validators.ahk: Common input validation functions (v2.9.4で追加)

UI/ - User interface components

Overlay.ahk: Temporary message displays
StatusDisplay.ahk: Persistent status information
DebugDisplay.ahk: Development interfaces
SettingsWindow/ (v2.9.4で5ファイルに分割)

SettingsMain.ahk: メインウィンドウ・制御
FlaskTab.ahk: フラスコタブUI
SkillTab.ahk: スキルタブUI
GeneralTab.ahk: 一般タブUI
SettingsValidation.ahk: 設定検証・エラー処理



External Libraries

FindText.ahk (v10.0): Image pattern matching library
- Location: Utils/FindText.ahk
- Purpose: Visual flask charge detection
- Integration: VisualDetection.ahk wrapper

Configuration System
Primary Config File: Config.ini

Auto-generated on first run with sensible defaults
Validation rules enforce valid ranges and types
Resolution scaling automatically adjusts coordinates for different screen sizes
Profile support with backup/restore capabilities

Key Configuration Sections
ini[General]    - Debug, logging, auto-start settings (MaxLogSize=5MB推奨)
[Mana]       - Mana orb detection parameters (coordinates, thresholds)
[Timing]     - Skill and flask intervals (legacy)
[Keys]       - Key mappings for all game actions
[Wine]       - Dynamic timing stages for Wine of the Prophet
[ClientLog]  - Log monitoring for area detection
[Flask]      - Individual flask configuration (1-5)
[Skill]      - New skill system (10 configurable skills)
[Tincture]   - Tincture retry and cooldown settings
Resolution Independence

Base resolution: 3440x1440 (ultrawide)
Auto-scaling: Coordinates automatically scale for other resolutions
Manual override: Adjust coordinates in [Mana] section if needed

Settings GUI Interface (Enhanced in v2.9.3)

Access: Press Ctrl+Shift+S to open the graphical settings window
Window size: 800x600 pixels with resizable interface
Tab organization: Three main tabs for different setting categories

フラスコ (Flask): Flask timing, keys, and Tincture configuration

5 configurable flasks with individual enable/disable
Min/Max interval settings for randomization
Flask type selection (Life/Mana/Utility/Quicksilver/Unique)
Tincture retry and cooldown configuration


スキル (Skill): Advanced skill automation system

10 configurable skills (2 groups of 5)
Individual enable/disable per skill
Custom skill names for easy identification
Key binding, min/max intervals, and priority (1-5)
Group 1: Keyboard skills (Q,W,E,R,T)
Group 2: Mouse/special skills (LButton, RButton, MButton, XButton1/2)
Wine of the Prophet dynamic timing configuration


一般 (General): Debug, logging, auto-start, and mana detection settings


Input validation: Comprehensive validation system

Empty key detection
Numeric range validation
Min/Max interval consistency checks
Priority range enforcement (1-5)
Error dialog with detailed validation messages


Save/Cancel/Reset: Standard dialog buttons with confirmation for destructive operations
Real-time validation: Settings are validated before saving
Hot-reload integration: Changes are immediately available after saving
Performance monitoring: Built-in performance prediction for skill configurations

## Flask System Architecture

### Flask System Key Conflict Resolution
フラスコシステムは他のシステムとのキー競合を自動的に検出し解決します：

- **競合検出**: `CheckFlaskKeyConflict()`関数がTincture（3キー）とWine of the Prophet（4キー）との競合を検出
- **自動無効化**: 競合するフラスコは自動的に無効化され、ログに警告が記録されます
- **動的設定**: ConfigManagerから動的にキー設定を読み込むため、柔軟な設定変更が可能

### Configuration Loading Priority
1. **INIファイル優先**: `LoadFlaskConfigFromINI()`が最初に実行
2. **フォールバック**: INI読み込み失敗時のみ`InitializeFlaskConfigs()`のデフォルト値を使用
3. **実行時更新**: `UpdateFlaskManagerConfig()`により再起動不要で設定変更可能

Development Patterns
Error Handling

Comprehensive try-catch blocks throughout all modules
Global error handler with graceful degradation
Automatic recovery mechanisms for non-critical failures
Error statistics tracking per component

Timer Management

Priority system: Critical > High > Normal > Low
Performance monitoring: Execution time tracking and warnings
Concurrent execution prevention: Timers cannot overlap
Graceful shutdown: Dependency-aware cleanup order

Configuration-Driven Design

Minimize hard-coded values - use ConfigManager.Get() instead
Validation at load time prevents runtime errors
Hot-reloading support for rapid development iteration

Logging Best Practices
ahkLogInfo("ModuleName", "Operation completed successfully")
LogError("ModuleName", "Error message with context")
LogDebug("ModuleName", "Detailed diagnostic information")
Working with This Codebase
新機能開発を始める前に、/docs/technical-specs/ の関連ドキュメントを確認することを推奨。特に：

新しいタイマー追加時は timer-specifications.md
エラー処理実装時は error-handling-details.md
設定項目追加時は config-validation-rules.md

Adding New Features

Create module in appropriate directory (usually Features/)
Add include to Main.ahk in dependency order
Use ConfigManager for all settings rather than hard-coding
Implement error handling following existing patterns
Add configuration section to Config.ini if needed
Register hotkeys through HotkeyValidator if required

Common Operations

Get config value: ConfigManager.Get("Section", "Key", defaultValue)
Create timer: Use TimerManager with appropriate priority
Add logging: Use appropriate log level (Debug/Info/Warn/Error)
Display message: ShowOverlay("message", duration)
Check game window: IsTargetWindowActive()

Target Game Setup Requirements

Game: Path of Exile (PathOfExileSteam.exe) or Steam Remote Play
Resolution: Optimized for 3440x1440, configurable for others
Game settings: "Always Show Mana Cost" must be OFF
UI scaling: Designed for 100% UI scale

Performance Considerations

Mana monitoring: 100ms intervals with optimization modes
Log monitoring: 250ms intervals for file changes
Color detection: 50ms timeout (configurable)
Timer priorities: Use appropriately to avoid performance issues

### v2.9.6 Performance Optimization Target
**Flask Overlay Performance Issue** (Flask/FlaskOverlay.ahk:661-708):
- `MoveSingleOverlay()` function recreates GUI elements on every movement
- Causes stuttering when moving 5+ overlays simultaneously
- **Fix needed**: Use existing GUI `.Move()` method instead of recreation
- **Location**: Features/Flask/FlaskOverlay.ahk, line 697 `CreateGuidelineOverlays()`

Important Notes
Target Application

Designed specifically for Path of Exile automation
Game-specific coordinates and timing optimized for "Wine of the Prophet" build
Client.txt log parsing for reliable area detection

AutoHotkey Version

Requires AutoHotkey v2.0+ (not compatible with v1.x)
Modern syntax and error handling patterns
Single instance enforcement prevents multiple runs

Debugging Workflow

Enable debug mode: Set DebugMode=true in Config.ini
Monitor logs: Use F6 to view real-time log output
Check system status: F7 for comprehensive debug info
Performance analysis: F8 for timer statistics, Ctrl+P for performance tests
Configuration issues: Alt+F12 to reload settings after changes

よくあるエラーと対処法
インクルードパスエラー
エラー: #Include file "..." cannot be opened
原因: AutoHotkey v2では相対パスの解決方法が変更されました
対処法:

✅ 正しい: #Include "SettingsWindow/SettingsMain.ahk"
❌ 間違い: #Include "UI/SettingsWindow/SettingsMain.ahk"
分割ファイルからは親ディレクトリプレフィックスを除去

関数名衝突エラー
エラー: This function declaration conflicts with an existing Func
原因: AutoHotkey v2組み込み関数と同名の関数を定義
対処法:

IsInteger() → IsValidInteger() に変更
Send() → MockSend() や TestSend() に変更
Utils/Validators.ahkで共通検証関数を一元管理

AutoHotkey v2構文エラー
エラー: Syntax error, Invalid property name, Unexpected reserved word
原因: v1.x構文の残存
対処法:

C言語スタイルfor文: for i := 1; i <= 5; i++ → Loop 5 { i := A_Index }
引用符付きプロパティ: "propertyName": value → propertyName: value
関数定義の競合: 組み込み関数名を避ける
catch文: catch Error as e → catch as e または正しいクラス名を使用

AutoHotkey v2 GUI開発の注意点
GUI作成時のよくあるエラーと対処法

1. Gui.Add()メソッドのパラメータ数
   - ❌ 間違い: gui.Add("Text", "x10 y10", "テキスト", "Bold")
   - ✅ 正解: gui.Add("Text", "x10 y10", "テキスト")
   - v2では3つのパラメータのみ: Type, Options, Text/Content

2. 無効なオプションの使用
   - ❌ 間違い: gui.Add("Text", "x10 y10 Bold", "テキスト")
   - ✅ 正解: フォントスタイルはSetFont()で設定
   ```ahk
   gui.SetFont("Bold")
   gui.Add("Text", "x10 y10", "テキスト")
   gui.SetFont()  ; デフォルトに戻す
   ```

3. デバッグのベストプラクティス
   - エラー発生時は必ずログを確認 (F6)
   - AutoHotkeyプロセスの完全再起動が必要な場合がある
   - 修正後はキャッシュクリアのため完全再起動推奨

実行時エラーの対処
一般的な手順:

F6でログを確認
F7でシステム状態を確認
Alt+F12で設定をリロード
Ctrl+Rでマクロ状態をリセット
Main.ahkを再起動

ログファイル肥大化の防止
問題: ログファイルが100MBを超える
対処法:

Config.iniで MaxLogSize=5 (5MB) に設定
LogRetentionDays=3 で古いログを自動削除
DebugMode=false でデバッグログを無効化
.gitignoreに logs/ を追加済み


### v2.9.6 (2025-01-02) - VisualDetection.ahk完全モジュール化
**重要な機能追加**: フラスコ位置設定の操作性とユーザビリティを大幅に向上
**アーキテクチャ変更**: VisualDetection.ahkを9つの専門モジュールに分割

#### ファイル分割による改善
- **メインファイル大幅削減**: 3,587行 → 249行 (-93%削減)
- **Claude Code完全対応**: 全ファイルが25,000トークン未満
- **モジュール化**: 機能別に独立したファイル構成で保守性向上
- **API設計**: 後方互換性を保った包括的なパブリックAPI

#### 新しいモジュール構成
```
Features/VisualDetection.ahk (249行) - メインAPI
├── VisualDetection/Core.ahk (390行) - 初期化・グローバル変数
├── VisualDetection/Settings.ahk (532行) - 設定管理・プリセット
├── VisualDetection/UIHelpers.ahk (317行) - UI拡張機能
├── VisualDetection/CoordinateManager.ahk (448行) - 座標変換
├── VisualDetection/TestingTools.ahk (462行) - デバッグツール
├── Flask/FlaskDetection.ahk (288行) - フラスコ検出ロジック
├── Flask/FlaskOverlay.ahk (1,199行) - オーバーレイ管理
├── Wine/WineDetection.ahk (523行) - Wine専用機能
└── Tincture/TinctureDetection.ahk (366行) - 将来実装用
```

#### 1. 順次設定システムの実装
- **精密な座標計算**: Utils/Coordinates.ahkのGetDetailedMonitorInfo()を使用
- **3440x1440モニター自動検出**: マルチモニター環境での中央モニター特定
- **推定位置への自動配置**: PoEの実際のフラスコ配置に基づく座標計算
  - Flask1: 中央モニター左端+100px、Y座標1350px
  - 間隔: 80px、解像度スケーリング対応

#### 2. 視覚的ガイドシステム
- **フラスコ番号表示**: 楕円中央に24pt白文字で番号表示
- **設定完了の視覚化**: 薄い緑色楕円で完了フラスコを表示
- **ガイドライン**: 隣接フラスコとの距離を黄色点線で表示
- **境界警告**: 画面端50px以内で赤い警告枠を表示
- **移行アニメーション**: 300msのスムーズなease-outアニメーション

#### 3. 操作性向上機能群
##### プリセット機能（Pキー）
```
1. 標準左下配置  : PoE標準的な配置
2. 中央下配置   : 画面中央下部配置  
3. 右下配置     : 画面右下配置
4. 現在設定読込 : Config.iniから読込
5. カスタム保存 : 現在設定を保存
```

##### 一括調整機能
```
Shift+矢印    : 全フラスコ同時移動
Ctrl+]/[     : 全フラスコ間隔調整
Ctrl+=/−     : 全フラスコサイズ調整
```

##### その他便利機能
```
G : グリッドスナップ ON/OFF (10px単位)
I : 設定インポート (Config.iniから読込)
E : 設定エクスポート (クリップボードへ)
H : ヘルプ表示 (包括的操作ガイド)
```

#### 4. 座標管理システムの改善
- **相対座標保存**: 中央モニター相対座標での保存
- **解像度独立**: 異なる解像度環境での自動スケーリング
- **設定継承**: モニター構成変更時の座標保持

#### 5. 更新されたホットキー一覧
```
### 基本操作
矢印キー      : 位置調整 (10px)
]/[          : 幅調整 (10px)  
'/;          : 高さ調整 (10px)
=/−          : 全体サイズ調整 (5px)
Shift+キー   : 微調整 (2px)
Enter        : 位置確定・次へ
Escape       : 設定終了

### 一括操作（新規）
Shift+矢印   : 全フラスコ移動
Ctrl+]/[     : 全フラスコ間隔調整  
Ctrl+=/−     : 全フラスコサイズ調整

### 便利機能（新規）
G            : グリッドスナップ切替
P            : プリセットメニュー
I            : 設定インポート
E            : 設定エクスポート
H            : ヘルプ表示
```

#### 6. 設定ファイル形式の拡張
```ini
[VisualDetection]
# 中央モニター相対座標での保存
Flask1X=100
Flask1Y=1350  
Flask1Width=60
Flask1Height=80

# モニター情報も保存
CentralMonitorWidth=3440
CentralMonitorHeight=1440

# カスタムプリセット対応
CustomFlask1X=100
CustomFlask1Y=1350
```

### v2.9.5 (2025-01-02)
- フラスコ検出エリアを楕円形に変更
- 楕円の縦横比を個別調整可能に
- Wine of the Prophet の色検出を複数範囲対応に改善
- F9キー操作を拡張（楕円形状の調整機能追加）

主な変更点：
1. バージョンを v2.9.6 に更新
2. **VisualDetection.ahk完全モジュール化**: 9ファイルに分割
3. **Claude Code完全対応**: 全ファイル25,000トークン未満
4. **パフォーマンス最適化対象特定**: FlaskOverlay.ahk MoveSingleOverlay()
5. **将来拡張準備**: Tincture検出モジュール追加
6. **API設計**: 後方互換性を保った包括的インターフェース
7. **開発効率向上**: 機能別ファイル分割で保守性大幅改善