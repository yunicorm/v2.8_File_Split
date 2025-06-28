以下が修正版のCLAUDE.mdです：
markdown# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a sophisticated **Path of Exile automation macro** written in **AutoHotkey v2** (v2.9.3), specifically designed for the "Wine of the Prophet" build. The codebase features robust error handling, modular architecture, and comprehensive game automation capabilities.

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
Key Directories (v2.9.3 Updated)
Core/ - Central control systems

MacroController.ahk: State management and initial actions
TimerManager.ahk: Priority-based timer system with performance monitoring
WindowManager.ahk: Window detection and target application management

Features/ - Domain-specific automation modules

ManaMonitor.ahk: Circular mana orb sampling with optimization modes
TinctureManager.ahk: Complex cooldown/retry logic with usage statistics
Flask/ (v2.9.3で5ファイルに分割)

FlaskController.ahk: 制御・タイマー管理
FlaskChargeManager.ahk: チャージ管理・計算
FlaskConditions.ahk: 条件判定・ヘルパー
FlaskConfiguration.ahk: 設定管理・プリセット
FlaskStatistics.ahk: 統計・履歴管理


Skills/ (v2.9.3で5ファイルに分割)

SkillController.ahk: メイン制御・タイマー管理
SkillConfigurator.ahk: 設定読み込み・初期化
WineManager.ahk: Wine専用管理
SkillStatistics.ahk: 統計・監視機能
SkillHelpers.ahk: ヘルパー・テスト機能


ClientLogMonitor.ahk: Log file parsing for area transitions

Utils/ - Foundational services

ConfigManager.ahk: INI management with validation and hot-reloading
Logger.ahk: Comprehensive logging with rotation and buffering (改善済み: 自動ローテーション機能追加)
ColorDetection.ahk: Optimized pixel color detection
HotkeyValidator.ahk: Conflict detection and registration
Validators.ahk: Common input validation functions (v2.9.3で追加)

UI/ - User interface components

Overlay.ahk: Temporary message displays
StatusDisplay.ahk: Persistent status information
DebugDisplay.ahk: Development interfaces
SettingsWindow/ (v2.9.3で5ファイルに分割)

SettingsMain.ahk: メインウィンドウ・制御
FlaskTab.ahk: フラスコタブUI
SkillTab.ahk: スキルタブUI
GeneralTab.ahk: 一般タブUI
SettingsValidation.ahk: 設定検証・エラー処理



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


主な変更点：
1. バージョンを v2.9.3 に更新
2. Claude Code連携時の注意事項セクションを追加
3. 分割されたモジュールの詳細構造を追加
4. Utils/Validators.ahkの追加
5. ログファイル管理の改善点を追加
6. catch文の構文エラー対処法を追加