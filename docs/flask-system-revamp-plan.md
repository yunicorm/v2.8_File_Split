# Path of Exile マクロ - フラスコシステム刷新計画 v2.9.4

## 概要

本ドキュメントは、Path of Exile自動化マクロ（Wine of the Prophetビルド向け）のフラスコシステムを、タイマーベースから画像認識ベースへ移行する計画を記述したものです。

### 変更の背景
- 現在のタイマーベースシステムは、ゲーム内の実際の状態と同期が取れない場合がある
- フラスコの視覚的状態（チャージ量、プログレスバー）を直接検出することで、より正確な制御が可能
- Wine of the ProphetやTinctureなど、特殊な挙動を持つアイテムへの対応が必要

## システムアーキテクチャ

### 検出対象と要素

#### 1. 通常フラスコ（Life/Mana/Utility）
- **チャージ量**: 瓶内の液体の色と量
  - ライフ: 赤
  - マナ: 青
  - ユーティリティ: シアン
  - ユニーク: 紫（Cinderswallow）等
- **プログレスバー**: フラスコ下部の効果時間表示
- **使用可能状態**: チャージ有り＆効果なし

#### 2. Wine of the Prophet（ユニークフラスコ）
- **基本機能**: 通常フラスコと同様
- **特殊機能**: ランダムDivinationバフ（20秒間）
  - バフアイコンは画面上部に表示
  - バフごとに重要度を設定可能
  - 低重要度バフ時は早期更新

#### 3. Tincture（Sap of the Seasons）
- **アクティブ状態**: フラスコ枠がオレンジ色に発光
- **Mana Burn**: 0.5秒ごとに1スタック（最大マナの1%減少）
- **クールダウン**: マナ枯渇後のプログレスバー表示
- **マナオーブ連携**: マナ量の視覚的変化を追跡

### マナオーブの状態遷移
1. **満タン（26/26）**: 青で完全に満たされた状態
2. **減少中（12/26）**: 上から下へ青が減少、空き部分は半透明グレー
3. **枯渇（0/26）**: 全体が黒半透明、フィールドが透けて見える

## 実装計画

### フェーズ1: 基盤システム構築（優先度: 最高）

#### 1.1 FindText統合
```ahk
; Utils/FindText.ahk
; FindTextライブラリの統合と基本設定
```

#### 1.2 ビジュアル検出基盤
```ahk
; Features/VisualDetection.ahk
; - DetectFlaskCharge(slot)
; - DetectProgressBar(slot)
; - DetectBuffIcon(position)
; - DetectManaOrb()
```

#### 1.3 座標管理システム
```ini
[VisualDetection]
FlaskSlot1_X=100
FlaskSlot1_Y=800
BuffArea_X=640
BuffArea_Y=50
ManaOrb_X=100
ManaOrb_Y=700
```

### フェーズ2: フラスコシステム拡張（優先度: 高）

#### 2.1 検出モード切り替え
- Timer Mode: 従来のタイマーベース制御
- Visual Mode: 新しい画像認識ベース制御

#### 2.2 フラスコパターン定義
```ahk
; FlaskPatterns.ahk
; 各フラスコタイプの視覚的パターン定義
```

#### 2.3 Wine of the Prophet移行
- SkillAutomationから削除
- FlaskManagerに統合
- ユニークフラスコタイプとして実装

### フェーズ3: Wine of the Prophet高度機能（優先度: 中）

#### 3.1 バフ管理システム
- バフアイコン検出（画面上部）
- 残り時間OCR読み取り
- バフ種類識別

#### 3.2 動的制御
```ini
[WineBuffPriority]
Buff_Type_1=High
Buff_Type_2=Low
Buff_Type_3=Medium
```

#### 3.3 統計収集
- wine_statistics.csv への記録
- バフ出現頻度分析
- 最適化提案

### フェーズ4: Tincture専用システム（優先度: 中）

#### 4.1 状態検出
- オレンジ枠の発光検出
- クールダウンプログレスバー
- マナオーブ状態追跡

#### 4.2 Mana Burn予測
- スタック蓄積速度: 0.5秒/スタック
- マナ枯渇タイミング計算
- 最適な再使用タイミング

### フェーズ5: 統合と最適化（優先度: 低）

#### 5.1 設定GUI拡張
- 検出モード選択
- バフ重要度設定
- キャリブレーション機能

#### 5.2 デバッグ機能
- リアルタイム検出状態表示
- 画像認識成功率
- パフォーマンスメトリクス

## 技術仕様

### 必要なファイル構造
```
PoE-Macro/
├── Features/
│   ├── FlaskManager.ahk (改修)
│   ├── VisualDetection.ahk (新規)
│   ├── WineOfProphetManager.ahk (新規)
│   └── TinctureVisualManager.ahk (新規)
├── Utils/
│   ├── FindText.ahk (新規)
│   └── BuffDetection.ahk (新規)
├── Patterns/
│   ├── FlaskPatterns.ahk (新規)
│   └── BuffPatterns.ahk (新規)
└── UI/
    └── SettingsWindow/ (改修)
        └── FlaskTab.ahk
```

### Config.ini 新規セクション
```ini
[VisualDetection]
Enabled=true
Mode=Hybrid ; Timer, Visual, Hybrid

[Flask1-5]
DetectionMode=Visual

[WineOfProphet]
Enabled=true
Key=4
DetectionMode=Visual
DynamicTiming=true

[Tincture]
VisualDetection=true
ManaBurnTracking=true
```

## 実装上の注意点

### パフォーマンス考慮事項
1. 画像認識は計算コストが高いため、適切な間隔で実行
2. 必要最小限の領域のみを検出対象とする
3. キャッシュシステムの実装を検討

### 互換性維持
1. 既存のタイマーベースシステムは完全に残す
2. ユーザーが選択可能なハイブリッドモード
3. 段階的な移行を可能にする

### エラーハンドリング
1. 画像認識失敗時のフォールバック
2. 座標ずれの自動補正
3. ログによる問題追跡

## テスト計画

### 単体テスト
- 各検出関数の精度検証
- パターンマッチング成功率
- OCR読み取り精度

### 統合テスト
- フラスコループの安定性
- Wine of the Prophetバフ管理
- Tincture状態遷移

### パフォーマンステスト
- CPU使用率
- メモリ使用量
- 応答速度

## リリース計画

### v2.9.4-alpha
- 基盤システム実装
- 基本的な画像認識

### v2.9.4-beta
- Wine of the Prophet統合
- Tinctureビジュアル検出

### v2.9.4-release
- 全機能実装完了
- 最適化完了

## 参考資料

### フラスコ画像サンプル
- Cinder_Full_NOT_USE.png
- Cinder_Empty_USING1.png
- Wine_of_The_Prophet_Full_NOT_USE.png
- Mana1.png, Mana2.png
- Gold.png, Granite.png, Quicksilver.png

### Tincture画像サンプル
- Tincture_available.png
- Tincture_Active.png
- Tincture_Cooldown_1.png
- Tincture_Cooldown_2.png

### マナオーブ画像サンプル
- Mana_Orb_Full.png
- Mana_Orb_Middle.png
- Mana_no_mana.png

### バフアイコンサンプル
- Wine_Buff_1.png
- Wine_Buff_2.png
- Wine_Buff_3.png

---

最終更新日: 2025-06-29
バージョン: 2.9.4計画案
作成者: Claude AI Assistant