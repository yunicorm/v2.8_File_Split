# Path of Exile マクロ v2.9.3

## 概要

このマクロは、Path of Exileにおける特定のビルド（Wine of the Prophet使用）向けに最適化された自動化ツールです。マナ管理、スキル自動実行、フラスコ管理などを統合的に制御します。

**v2.9.3の主な改善点**：
- **大規模モジュール分割**: 保守性と拡張性を大幅向上
  - SettingsWindow → 5ファイル分割（タブ別UI管理）
  - SkillAutomation → 5ファイル分割（機能別責任分離）
  - FlaskManager → 5ファイル分割（チャージ管理・条件判定強化）
- **新機能の大幅追加**:
  - 15種類の条件判定関数（健康状態、戦闘状態、デバフ検出）
  - 強化された統計・分析機能（効率レポート、履歴管理）
  - 3つの設定プリセット（basic/full_auto/combat）
- **コードベース最適化**: 1,182行 → 5モジュールによる機能分離

## 主要機能と動作原理

### 1. Wine of the Prophet システム

**概要**：Enkindling Orbによって強化されたMana Flaskの効果を最大限活用するシステム

**動作原理**：
- **Enkindling Orb効果**：効果時間中（6.05秒）チャージ獲得不可、77%効果増加
- **チャージ獲得式**：`1×(1.50+ManaB%)×1.77 チャージ/秒`
- **The Tides of Time**：フラスコチャージ獲得 +50%
- **Mana Burn**：最大340%の追加効果

**タイミング調整**（Config.iniで調整可能）：
```
経過時間     | Wine使用間隔
0-60秒      | 22-22.5秒
60-90秒     | 19.5-20秒
90-120秒    | 17.5-18秒
120-170秒   | 16-16.5秒
170秒以上   | 14.5-15秒
```

**v2.9.2の改善点**：
- ステージ管理の最適化
- ステージ遷移の自動検出とログ記録
- エラー時の保守的な遅延設定

### 2. マナ監視システム（完全枯渇検出式）

**検出方式**：
- 円形マナオーブの下部3つの高さ（85%、90%、95%）で検出
- 各高さで5ポイント、合計15ポイントをチェック
- 全ポイントで青色が検出されない場合、完全枯渇（0/26）と判定
- **最適化モード**：安定時は簡易チェック、変化時のみ詳細検出

**座標設定**（Config.iniで調整可能）：
- マナオーブ中心：X=3294, Y=1300
- 半径：139ピクセル
- 青色閾値：40以上（青が赤・緑より20以上大きい）

**重要な設定**：
- ゲーム内で「Always Show Mana Cost」を**必ずOFF**にする
- リザーブされたマナを非表示にする

### 3. Tincture管理システム（v2.9.2強化版）

**基本動作**：
1. マクロ開始時：即座にTincture（3キー）を使用
2. マナ完全枯渇検出時：Tinctureが切れたと判定
3. 5.41秒のクールダウン後、再使用を試行

**再試行メカニズム**：
- 最大5回まで自動再試行（Config.iniで調整可能）
- 使用後1秒待機してマナ状態を確認
- マナが30%以上または回復傾向なら成功と判定
- 失敗時は0.5秒後に再試行

**v2.9.2の新機能**：
- **使用履歴管理**: 最新50件の使用履歴を保持
- **成功率統計**: リアルタイムの成功率計算
- **タイムアウト保護**: 3秒のタイムアウトによるフェイルセーフ
- **検証方法の選択**: マナベースまたはバフアイコン（将来実装）

### 4. フラスコ自動化（v2.9.2拡張版）

**マナフラスコ（2キー）**：
- 4.5-4.8秒間隔で継続的に使用
- Tincture再使用時にタイミングをリセット
- マクロ実行中は常に動作

**v2.9.2の新機能 - カスタムフラスコ設定**：
```autohotkey
; 使用例
flaskConfig := Map(
    "1", {
        key: "1", 
        type: "life", 
        minInterval: 5000, 
        maxInterval: 5500, 
        enabled: true,
        maxCharges: 60,
        chargePerUse: 20,
        chargeGainRate: 6,
        useCondition: () => GetHealthPercentage() < 70
    },
    "5", {
        key: "5", 
        type: "quicksilver", 
        minInterval: 6000, 
        maxInterval: 6500, 
        enabled: true,
        useCondition: () => IsMoving()
    }
)
ConfigureFlasks(flaskConfig)
```

**新機能**：
- **チャージ管理**: フラスコのチャージを自動追跡
- **条件付き使用**: ヘルス％、移動中などの条件で自動使用
- **優先度管理**: フラスコごとの優先度設定
- **詳細統計**: 使用回数、成功率、エラー率の追跡

### 5. スキル自動化（v2.9.2拡張版）

**新しいスキルシステム**：
- **10個の設定可能スキル**: 2つのグループ（各5スキル）
  - Group 1: キーボードスキル（Q,W,E,R,T など）
  - Group 2: マウス/特殊スキル（LButton, RButton, MButton, XButton1/2）
- **優先度システム**: 1-5の優先度で実行順序を制御
- **カスタム名称**: 各スキルに名前を設定可能
- **個別制御**: スキルごとにON/OFF、キー、間隔を設定

**従来のスキル**（Config.ini [Timing]セクション）：
- **E, R キー**：1-1.1秒間隔でランダムに実行
- **T キー**：4.1-4.2秒間隔で実行
- **4 キー**（Wine of the Prophet）：動的間隔（上記参照）

**v2.9.2の改善点**：
- **エラーハンドリング強化**: 各スキル実行でエラーをキャッチ
- **最小間隔チェック**: 連続実行の防止
- **カスタムスキル対応**: 任意のスキルを追加可能
- **統計情報**: 使用回数、平均遅延、エラー率
- **パフォーマンス監視**: 10スキル同時実行時の負荷予測

### 6. エリア検出システム（Client.txtログ監視）

**検出方法**：
- Path of ExileのClient.txtログファイルを監視
- "You have entered [エリア名]" のログエントリーを検出
- ピクセル検出よりも確実で、ゲーム更新の影響を受けない

**動作フロー**：
1. ログファイルで新しいエリアへの移動を検出
2. マクロを自動的に一時停止
3. プレイヤーの入力（移動、スキル使用など）を待機
4. 入力検出後0.5秒でマクロ自動再開

**非戦闘エリアの自動識別**：
- ハイドアウト（Hideout）
- 町エリア（Encampment、Oriath等）
- Aspirants' Plaza（ラビリンス待機エリア）
- これらのエリアでは自動再開をスキップ

### 7. タイマー管理システム（v2.9.2強化版）

**新機能**：
- **優先度管理**: Critical、High、Normal、Lowの4段階
- **実行時間追跡**: 各タイマーの平均/最大/最小実行時間
- **エラー管理**: エラー率が高いタイマーの自動停止
- **一時停止/再開**: 個別タイマーの制御

## 想定される動作フロー

### マップ開始時
1. エリアに入る
2. プレイヤーが移動開始（任意のキー/クリック）
3. マクロが自動的に起動
4. Tincture使用 → マナフラスコ開始 → スキルループ開始

### 戦闘中
1. **通常時**：
   - E, R, Tを自動実行
   - マナフラスコを定期使用
   - Wine of the Prophetを適切な間隔で使用

2. **マナ枯渇時**：
   - Tinctureのバフが切れる
   - マナが0/26まで低下
   - 5.41秒後にTincture再使用
   - マナフラスコのタイミングリセット

### エリア移動時
1. ロード画面を自動検出
2. 全ての自動機能を一時停止
3. 新エリアでプレイヤーの行動を待つ
4. 行動検出後に自動再開

## ファイル構造

```
PoE-Macro/
├── Config.ini                  # 設定ファイル（初回実行時に自動生成）
├── Main.ahk                    # メインエントリーポイント
├── Config.ahk                  # 設定とグローバル変数
├── Core/                       # コア機能
│   ├── MacroController.ahk    # マクロの開始/停止制御
│   ├── TimerManager.ahk       # タイマー管理（優先度対応）
│   └── WindowManager.ahk      # ウィンドウ検出と管理
├── Features/                   # 機能別モジュール
│   ├── ManaMonitor.ahk        # マナ監視システム
│   ├── TinctureManager.ahk    # Tincture管理（統計機能付き）
│   ├── FlaskManager.ahk       # フラスコ管理統合（→5ファイル分割）
│   │   └── Flask/             # フラスコ管理モジュール（v2.9.3新規）
│   │       ├── FlaskController.ahk     # 制御・タイマー管理（328行）
│   │       ├── FlaskChargeManager.ahk  # チャージ管理・計算（269行）
│   │       ├── FlaskConditions.ahk     # 条件判定・ヘルパー（266行）
│   │       ├── FlaskConfiguration.ahk  # 設定管理・プリセット（468行）
│   │       └── FlaskStatistics.ahk     # 統計・履歴管理（335行）
│   ├── SkillAutomation.ahk    # スキル管理統合（→5ファイル分割）
│   │   └── Skills/            # スキル管理モジュール（v2.9.3新規）
│   │       ├── SkillController.ahk     # メイン制御・タイマー管理（255行）
│   │       ├── SkillConfigurator.ahk   # 設定読み込み・初期化（181行）
│   │       ├── WineManager.ahk         # Wine専用管理（191行）
│   │       ├── SkillStatistics.ahk     # 統計・監視機能（302行）
│   │       └── SkillHelpers.ahk        # ヘルパー・テスト機能（253行）
│   ├── LoadingScreen.ahk      # ロード画面検出
│   └── ClientLogMonitor.ahk   # ログベースエリア検出
├── UI/                         # UI関連
│   ├── Overlay.ahk            # オーバーレイ表示
│   ├── StatusDisplay.ahk      # ステータス表示
│   ├── DebugDisplay.ahk       # デバッグ表示
│   └── SettingsWindow.ahk     # 設定GUI統合（→5ファイル分割）
│       └── SettingsWindow/    # 設定GUI モジュール（v2.9.3新規）
│           ├── SettingsMain.ahk        # メインウィンドウ・制御（320行）
│           ├── FlaskTab.ahk            # フラスコタブUI（280行）
│           ├── SkillTab.ahk            # スキルタブUI（290行）
│           ├── GeneralTab.ahk          # 一般タブUI（250行）
│           └── SettingsValidation.ahk  # 設定検証・エラー処理（180行）
├── Utils/                      # ユーティリティ
│   ├── ConfigManager.ahk      # 設定ファイル管理
│   ├── HotkeyValidator.ahk    # ホットキー検証
│   ├── ColorDetection.ahk     # 色検出関数
│   ├── Coordinates.ahk        # 座標計算
│   ├── Logger.ahk             # ログ機能
│   └── PerformanceMonitor.ahk # パフォーマンス監視
├── Hotkeys/                    # ホットキー定義
│   ├── MainHotkeys.ahk        # メインホットキー
│   └── DebugHotkeys.ahk       # デバッグ用ホットキー
└── logs/                       # ログファイル保存ディレクトリ（自動生成）
```

## 必要な環境

- **AutoHotkey**: v2.0以降
- **解像度**: 3440x1440（ウルトラワイド）推奨
- **対応ウィンドウ**: 
  - Path of Exile (PathOfExileSteam.exe)
  - Steam Remote Play (streaming_client.exe)

## インストールと使用方法

1. **AutoHotkey v2.0**以降をインストール
2. すべてのファイルを`PoE-Macro`フォルダに配置
3. `Main.ahk`を実行（初回実行時にConfig.iniが自動生成される）
4. Path of ExileまたはSteam Remote Playウィンドウをアクティブに
5. **F12**キーでマクロのオン/オフ

### 設定GUI（新機能）

**Ctrl+Shift+S**を押して設定GUIを開く：

#### フラスコタブ
- **フラスコ1-5**: 各フラスコの有効化、キー、間隔、タイプを設定
- **Tincture設定**: リトライ回数、間隔、検証遅延、クールダウンを調整
- **全体有効化**: フラスコとTinctureの機能を個別にON/OFF

#### スキルタブ
- **Group 1 (スキル1-5)**: キーボードスキルの設定
- **Group 2 (スキル6-10)**: マウス/特殊スキルの設定
- 各スキル設定項目：
  - **有効化チェック**: スキルのON/OFF
  - **スキル名**: 識別しやすい名前を設定
  - **キー**: 使用するキーを指定
  - **間隔Min/Max**: ランダム実行間隔（ミリ秒）
  - **優先度**: 1-5（数字が小さいほど高優先）
- **Wine設定**: Wine of the Prophet間隔と動的タイミング

#### 一般タブ
- **デバッグ設定**: デバッグモード、ログ記録のON/OFF
- **ログ管理**: 最大サイズ、保持日数
- **自動開始**: マクロの自動開始と遅延時間
- **マナ検出**: 中心座標、半径、青色閾値、最適化モード

#### 操作ボタン
- **保存**: 設定を保存してConfig.iniに反映
- **キャンセル**: 変更を破棄して閉じる  
- **リセット**: デフォルト設定に戻す（確認あり）

## ホットキー一覧

### メイン操作
| キー | 機能 |
|------|------|
| **F12** | マクロのオン/オフ切り替え |
| **Ctrl+F12** | 緊急停止（全機能を即座に停止） |
| **Shift+F12** | マクロの手動停止/開始 |
| **Alt+F12** | 設定リロード（Config.ini再読み込み） |
| **Pause** | 一時停止/再開 |
| **ScrollLock** | ステータス表示の切り替え |
| **Ctrl+Shift+S** | 設定GUIを開く |
| **Ctrl+H** | 登録済みホットキー一覧表示 |
| **F1** | クイックヘルプ |

### デバッグ機能
| キー | 機能 |
|------|------|
| **F11** | マナ状態デバッグ表示 |
| **F10** | エリア検出方式の切り替え |
| **F9** | エリア検出デバッグ |
| **F8** | タイマーデバッグ（優先度、実行時間表示） |
| **F7** | 全体デバッグ情報表示 |
| **F6** | ログビューアを開く |

### 開発用
| キー | 機能 |
|------|------|
| **Ctrl+D** | デバッグモード切り替え |
| **Ctrl+L** | ログ記録切り替え |
| **Ctrl+S** | マウス座標と色情報表示 |
| **Ctrl+M** | マナ状態手動チェック |
| **Ctrl+T** | テストオーバーレイ表示 |
| **Ctrl+R** | マクロ状態リセット |
| **Ctrl+P** | パフォーマンステスト |

## 設定のカスタマイズ

設定は`Config.ini`ファイルで管理されます。初回実行時に自動生成され、メモ帳などで編集できます。

### 主な設定項目

#### [General] - 一般設定
```ini
DebugMode=false         # デバッグモード
LogEnabled=true         # ログ記録
MaxLogSize=10          # ログファイル最大サイズ (MB)
LogRetentionDays=7     # ログ保持日数
AutoStart=false        # マクロ自動開始
AutoStartDelay=2000    # 自動開始遅延 (ms)
```

#### [Keys] - キー設定
```ini
Tincture=3            # Tinctureキー
ManaFlask=2           # マナフラスコキー
SkillE=E              # スキルEキー
SkillR=R              # スキルRキー
SkillT=T              # スキルTキー
WineProphet=4         # Wine of the Prophetキー
```

#### [Timing] - タイミング設定（ミリ秒）
```ini
SkillER_Min=1000      # E,Rキーの最小間隔
SkillER_Max=1100      # E,Rキーの最大間隔
SkillT_Min=4100       # Tキーの最小間隔
SkillT_Max=4200       # Tキーの最大間隔
Flask_Min=4500        # フラスコの最小間隔
Flask_Max=4800        # フラスコの最大間隔
```

#### [Mana] - マナ検出設定
```ini
CenterX=3294          # マナオーブ中心X座標
CenterY=1300          # マナオーブ中心Y座標
Radius=139            # マナオーブ半径
BlueThreshold=40      # 青色検出閾値
OptimizedDetection=true  # 最適化モード（高速検出）
```

#### [Tincture] - Tincture設定
```ini
RetryMax=5            # 最大再試行回数
RetryInterval=500     # 再試行間隔 (ms)
VerifyDelay=1000     # 効果確認待機時間 (ms)
DepletedCooldown=5410 # マナ枯渇時クールダウン (ms)
```

#### [Skill] - 新しいスキル設定（v2.9.2）
```ini
; Group 1 - キーボードスキル
Skill_1_1_Enabled=true
Skill_1_1_Name=Molten Strike
Skill_1_1_Key=q
Skill_1_1_Min=1000
Skill_1_1_Max=1500
Skill_1_1_Priority=3

; Group 2 - マウス/特殊スキル
Skill_2_1_Enabled=true
Skill_2_1_Name=Basic Attack
Skill_2_1_Key=LButton
Skill_2_1_Min=500
Skill_2_1_Max=800
Skill_2_1_Priority=1
```

#### [Flask] - フラスコ個別設定（v2.9.2）
```ini
Flask1_Enabled=true
Flask1_Key=1
Flask1_Min=2800
Flask1_Max=3200
Flask1_Type=Life
```

### 設定の適用方法
1. **設定GUI使用（推奨）**: `Ctrl+Shift+S`で設定GUIを開いて編集
2. **手動編集**: `Config.ini`をテキストエディタで編集
3. 保存後、ゲーム内で`Alt+F12`を押して設定をリロード
4. マクロの再起動は不要

## 高度な機能（v2.9.2新機能）

### カスタムフラスコ設定（プログラム的）

```autohotkey
; スクリプト内でカスタムフラスコを設定
flaskConfig := Map(
    "1", {
        key: "1",                  ; 使用するキー
        type: "life",              ; フラスコタイプ
        minInterval: 5000,         ; 最小使用間隔
        maxInterval: 5500,         ; 最大使用間隔
        enabled: true,             ; 有効/無効
        maxCharges: 60,            ; 最大チャージ数
        chargePerUse: 20,          ; 使用時消費チャージ
        chargeGainRate: 6,         ; チャージ回復速度/秒
        useCondition: () => GetHealthPercentage() < 70  ; 使用条件
    }
)
ConfigureFlasks(flaskConfig)
```

### カスタムスキル追加（プログラム的）

```autohotkey
; 新しいスキルを追加
skillConfig := Map(
    "Skill_1_1", {
        name: "Molten Strike",
        key: "Q",
        minInterval: 2000,
        maxInterval: 2500,
        priority: 1,
        enabled: true
    },
    "Skill_2_1", {
        name: "Movement Skill",
        key: "RButton",
        minInterval: 5000,
        maxInterval: 5500,
        priority: 2,
        enabled: false
    }
)
ConfigureSkills(skillConfig)
```

### 統計情報の取得

```autohotkey
; Tincture統計
tinctureStats := GetTinctureStatus()
; stats.successRate - 成功率
; stats.totalAttempts - 総試行回数
; stats.cooldownRemaining - 残りクールダウン

; フラスコ統計
flaskStats := GetFlaskStats()
; stats.totalUses - 総使用回数
; stats.errorRate - エラー率
; stats.activeFlasks - アクティブフラスコ数

; スキル統計
skillStats := GetSkillStats()
; 各スキルの使用回数、平均遅延、エラー数
```

## 重要な注意事項

### ゲーム内設定
1. **Always Show Mana Cost**を必ず**OFF**にする
2. リザーブされたマナの表示を**OFF**にする
3. UI設定は変更しない（マナオーブの位置が変わるため）

### 解像度について
- デフォルトは**3440x1440**解像度用に最適化
- 他の解像度では`Config.ini`の`[Resolution]`セクションで設定
- 座標は自動的にスケーリングされます

### パフォーマンスへの影響
- マナ監視：100ms間隔（最適化モードで高速化）
- Client.txt監視：250ms間隔
- 色検出タイムアウト：50ms（Config.iniで調整可能）
- タイマー優先度管理により重要な処理を優先実行

## トラブルシューティング

### マクロが動作しない
1. AutoHotkey v2.0以降がインストールされているか確認
2. ゲームウィンドウがアクティブか確認
3. `F6`でログを確認
4. `Ctrl+H`でホットキー競合がないか確認
5. 管理者権限で実行してみる

### マナ検出が正しくない
1. ゲーム内設定を確認（上記参照）
2. `F11`でマナデバッグ表示を確認
3. `Config.ini`の`[Mana]`セクションで座標を調整
4. `OptimizedDetection=false`で詳細検出モードを試す

### Tinctureが再使用されない
1. マナが完全に枯渇（0/26）しているか確認
2. `F7`でTincture状態を確認（成功率、履歴を確認）
3. `Config.ini`で`RetryMax`を増やす
4. `VerifyDelay`を調整（デフォルト1000ms）

### エリア検出が機能しない
1. `F10`で検出方式を確認（ログ監視推奨）
2. `F9`でエリア検出デバッグを表示
3. Client.txtのパスが正しいか確認
4. `Config.ini`で`[ClientLog]`の設定を確認

### フラスコが期待通りに動作しない
1. `F8`でタイマーデバッグを確認
2. フラスコのチャージ設定を確認
3. 使用条件（useCondition）が適切か確認
4. 優先度設定を調整

### 設定が反映されない
1. `Config.ini`を保存したか確認
2. `Alt+F12`で設定をリロード
3. 値の形式が正しいか確認（数値、true/false）

### ログファイルが大きくなりすぎる
1. `Config.ini`で`MaxLogSize`を調整（デフォルト10MB）
2. `LogRetentionDays`で古いログの自動削除期間を設定
3. `LogEnabled=false`でログを無効化

## 既知の制限事項

1. **解像度依存**：デフォルトは3440x1440、他の解像度はConfig.iniで調整
2. **言語依存**：英語版でのみテスト済み
3. **UIスケール**：100%以外のUIスケールには非対応
4. **ウィンドウモード**：フルスクリーンまたはウィンドウフルスクリーン推奨

## 開発者向け情報

### 新機能の追加方法
1. `Features/`ディレクトリに新しいファイルを作成
2. `Main.ahk`でインクルード（依存関係に注意）
3. 必要な設定を`Config.ini`に追加
4. `ConfigManager.Get()`で設定値を取得
5. ホットキーが必要な場合は`HotkeyValidator.Register()`で登録

### デバッグ方法
1. `Config.ini`で`DebugMode=true`に設定
2. `Ctrl+L`でログ記録を有効化
3. `logs/`ディレクトリのログファイルを確認
4. `F8`でタイマー状態を確認（優先度、実行時間表示）
5. `F7`で全体の状態を確認（統計情報含む）
6. `Ctrl+P`でパフォーマンステストを実行

### コード規約
- 関数名：PascalCase（例：`CheckManaRadial`）
- 変数名：snake_case with g_prefix（例：`g_macro_active`）
- 定数：UPPER_CASE（例：`TIMING_MANA_DEPLETED_CD`）
- コメント：日本語可（`;`を使用、`//`は避ける）
- エラーハンドリング：すべての主要関数でtry-catchを使用

### パフォーマンス計測

```autohotkey
; パフォーマンス計測の例
StartPerfTimer("MyFunction")
; ... 処理 ...
duration := EndPerfTimer("MyFunction", "ModuleName")
; durationには実行時間（ミリ秒）が返される
```

### 詳細技術仕様

より詳細な技術情報については、`/docs/technical-specs/` ディレクトリを参照してください：
- 内部実装の詳細
- データ構造の完全な仕様
- エラーハンドリングパターン
- その他の技術的詳細

これらのドキュメントは、マクロの拡張や大規模な改修を行う開発者向けです。

## 更新履歴

### v2.9.3（2024年最新）
- **大規模モジュール分割によるリファクタリング**：
  - SettingsWindow.ahk → 5ファイル分割（1,320行→タブ別UI管理）
  - SkillAutomation.ahk → 5ファイル分割（1,182行→機能別責任分離）
  - FlaskManager.ahk → 5ファイル分割（674行→チャージ管理・条件判定強化）
- **新しいユーティリティモジュール**:
  - Utils/Validators.ahk追加（共通検証関数を一元管理）
  - 重複関数定義の解決（IsValidIntegerの統合）
- **AutoHotkey v2構文への完全準拠**:
  - C言語スタイルfor文の修正（Loop構文への変換）
  - 関数名衝突の解決（IsInteger → IsValidInteger）
  - オブジェクトリテラル構文の修正（引用符付きプロパティ名）
  - インクルードパスの相対パス問題解決
- **保守性・拡張性の大幅向上**：
  - 各モジュール180-468行の管理しやすいサイズ
  - 明確な責任分離による単体テスト可能
  - 新機能追加が容易な構造

### v2.9.2
- **エラーハンドリング全面強化**：
  - 全主要関数にtry-catch実装
  - エラー時の自動リカバリー機能
  - タイマーエラーの自動停止機能
- **フラスコ管理システムの大幅拡張**：
  - カスタムフラスコ設定機能
  - チャージ管理システム
  - 条件付き自動使用（ヘルス％、移動中など）
  - 詳細な統計情報（成功率、エラー率）
- **Tincture管理の強化**：
  - 使用履歴の記録（最新50件）
  - リアルタイム成功率統計
  - タイムアウト保護機能
  - 検証方法の拡張（将来のバフアイコン検証対応）
- **スキル自動化の改善**：
  - 最小間隔チェックによる連続実行防止
  - Wine of the Prophetのステージ管理改善
  - カスタムスキル追加機能
  - 詳細なエラー追跡
- **タイマー管理システムの最適化**：
  - 優先度管理（Critical/High/Normal/Low）
  - 実行時間の追跡と統計
  - パフォーマンス警告機能
  - 個別タイマーの一時停止/再開
- **その他の改善**：
  - コメント形式の統一（`//`から`;`へ）
  - メモリ効率の最適化
  - デバッグ情報の拡充

### v2.9.1
- Client.txtログ監視によるエリア検出
- マルチモニター対応の改善
- ログローテーション機能

### v2.9
- エリア検出システムの実装
- 自動停止/再開機能
- 非戦闘エリアの自動識別

### v2.8.2
- 外部設定ファイル対応（Config.ini）
- エラーハンドリング強化（初期版）
- ホットキー検証システム
- マナ検出最適化
- ログローテーション
- 設定リロード機能
- 座標自動スケーリング

### v2.8.1
- Tincture連打バグ修正
- マクロOFF時の再試行継続問題を修正

### v2.8
- Tincture再試行メカニズム実装
- マナ状態によるTincture効果確認機能

### v2.7.3
- 初回起動時のマナ誤検出修正
- マナモニタリング開始遅延実装

### v2.7.2
- ステータスオーバーレイサイズ修正
- テキスト表示の見切れ防止

### v2.7.1
- F12キー連打防止強化
- キーリリース検出改善

### v2.7
- Mana Burnスタック管理を削除
- Tincture + マナフラスコの新フロー実装
- 5キーループを削除

## ライセンス

個人使用のみ。再配布禁止。

## サポート

問題が発生した場合：
1. まずこのREADMEのトラブルシューティングを確認
2. `F6`でログを確認（詳細なエラー情報）
3. `F7`で全体デバッグ情報を確認（統計情報含む）
4. `Config.ini`の設定を確認
5. デバッグ機能を使用して詳細を調査
6. 必要に応じて設定を調整

## 貢献者への感謝

このマクロの開発にあたり、Path of Exileコミュニティの皆様からの貴重なフィードバックとテストに感謝いたします。

特にv2.9.2の大規模改善にあたっては、エラーハンドリングの重要性とユーザビリティの向上に焦点を当てて開発を行いました。