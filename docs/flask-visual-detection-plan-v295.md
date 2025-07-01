# Path of Exile マクロ - フラスコ視覚検出システム実装計画 v2.9.5

## 概要

本ドキュメントは、Path of Exile自動化マクロのフラスコシステムに、デュアルオーバーレイと色検出を用いた高精度な視覚検出システムを実装する計画を記述したものです。

### 目的
- フラスコ本体とプログレスバーを分離して検出精度を向上
- 色ベース検出により高速かつ堅牢な状態判定を実現
- Wine of the Prophet、Tincture、バフアイコンの統合管理

## システム設計

### デュアルオーバーレイシステム

#### 各フラスコスロットの構成
1. **Flask Body Overlay（上部）**
   - 用途：フラスコ内の液体色と量を検出
   - 検出対象：チャージ量（0-100%）
   - 色判定：赤（Life）、青（Mana）、シアン（Utility）、紫（Unique）

2. **Progress Bar Overlay（下部）**
   - 用途：フラスコ効果時間の検出
   - 検出対象：クリーム色のプログレスバー
   - 状態判定：効果中/クールダウン/使用可能

### 状態判定マトリクス

| チャージ | プログレスバー | 状態 | アクション |
|---------|--------------|------|------------|
| あり | なし | 使用可能 | フラスコ使用 |
| あり | あり | 使用中 | 待機 |
| なし | なし | 空 | チャージ待ち |
| なし | あり | 回復中 | 待機 |

### Tincture特殊検出

#### 検出要素
1. **オレンジ枠検出**
   - フラスコスロット枠の発光状態
   - アクティブ/非アクティブの判定

2. **マナバーン追跡**
   - 0.5秒ごとのスタック蓄積
   - マナ枯渇タイミング予測

#### 状態遷移
```
待機 → オレンジ枠検出 → アクティブ
アクティブ → マナ枯渇 → クールダウン
クールダウン → プログレスバー消失 → 待機
```

### Wine of the Prophet連携

#### バフ管理システム
1. **バフエリアオーバーレイ**
   - 画面上部のバフアイコン表示領域を定義
   - 複数のバフパターンを登録

2. **動的制御**
   - 高優先度バフ：20秒間維持
   - 低優先度バフ：即座に更新可能
   - バフなし：チャージがあれば使用

## 実装フェーズ

### Phase 1: 基盤構築（2-3日）

#### 1.1 デュアルオーバーレイUI
```ahk
; Features/VisualDetection.ahk に追加
CreateDualOverlays(flaskNum) {
    ; フラスコ本体用オーバーレイ
    CreateFlaskBodyOverlay(flaskNum)
    ; プログレスバー用オーバーレイ
    CreateProgressBarOverlay(flaskNum)
}

SaveDualOverlayPositions(flaskNum) {
    ; 両オーバーレイの座標を保存
}
```

#### 1.2 色検出基盤
```ahk
; Features/ColorDetection.ahk（新規）
DetectFlaskLiquidLevel(flaskNum) {
    ; 複数ポイントサンプリング
    ; 色の割合計算
    ; 0-100%でチャージレベル返却
}

DetectProgressBarPresence(flaskNum) {
    ; クリーム色検出
    ; true/false返却
}

DetectTinctureOrangeGlow(slotNum) {
    ; オレンジ色の発光検出
}
```

### Phase 2: 状態管理（2-3日）

#### 2.1 統合状態判定
```ahk
; Features/FlaskStateManager.ahk（新規）
GetFlaskState(flaskNum) {
    chargeLevel := DetectFlaskLiquidLevel(flaskNum)
    hasProgress := DetectProgressBarPresence(flaskNum)
    
    ; 状態判定ロジック
    return DetermineFlaskState(chargeLevel, hasProgress)
}
```

#### 2.2 Tincture状態管理
```ahk
GetTinctureState() {
    hasOrangeGlow := DetectTinctureOrangeGlow(3)
    hasProgress := DetectProgressBarPresence(3)
    
    ; 状態判定
    if (hasOrangeGlow)
        return "ACTIVE"
    else if (hasProgress)
        return "COOLDOWN"
    else
        return "READY"
}
```

### Phase 3: バフシステム（3-4日）

#### 3.1 バフエリア検出
```ahk
; Features/BuffDetection.ahk（新規）
CreateBuffAreaOverlay() {
    ; 画面上部のバフエリア定義
}

DetectBuffIcon(buffPattern) {
    ; バフアイコンの存在確認
}
```

#### 3.2 Wine of the Prophet統合
```ahk
ManageWineOfProphet() {
    if (HasDivinationBuff()) {
        buffPriority := GetBuffPriority(currentBuff)
        if (buffPriority == "LOW" && HasCharges())
            UseWineOfProphet()
    } else if (HasCharges()) {
        UseWineOfProphet()
    }
}
```

### Phase 4: 最適化とテスト（2-3日）

#### 4.1 パフォーマンス最適化
- 検出頻度の動的調整
- キャッシュシステム
- 変化検出による効率化

#### 4.2 設定GUI更新
- デュアルオーバーレイ設定
- 色閾値調整
- バフ優先度設定

## 技術仕様

### ファイル構造
```
PoE-Macro/
├── Features/
│   ├── VisualDetection.ahk（既存・拡張）
│   ├── ColorDetection.ahk（新規）
│   ├── FlaskStateManager.ahk（新規）
│   └── BuffDetection.ahk（新規）
├── docs/
│   └── flask-visual-detection-plan.md（本文書）
└── Config.ini（拡張）
```

### Config.ini 追加設定
```ini
[ColorDetection]
Enabled=true
ColorThreshold=40
SamplingPoints=5
UpdateInterval=50

[DualOverlay]
FlaskBodyHeight=80
ProgressBarHeight=20
Spacing=5

[BuffDetection]
BuffAreaX=640
BuffAreaY=50
BuffAreaWidth=300
BuffAreaHeight=80
```

### 色定義
```ahk
; 色閾値定義
FLASK_COLORS := Map(
    "Life", {r: 200, g: 50, b: 50, threshold: 40},
    "Mana", {r: 50, g: 50, b: 200, threshold: 40},
    "Utility", {r: 50, g: 200, b: 200, threshold: 40},
    "Unique", {r: 150, g: 50, b: 200, threshold: 40}
)

PROGRESS_BAR_COLOR := {r: 255, g: 248, b: 220}  ; クリーム色
TINCTURE_GLOW_COLOR := {r: 255, g: 165, b: 0}   ; オレンジ色
```

## 実装上の注意事項

### パフォーマンス
1. **色検出の高速性**
   - PixelGetColor: 5-10ms
   - 画像パターン: 50-100ms
   - 必要最小限の領域のみ検出

2. **更新頻度の最適化**
   - 通常時: 100ms間隔
   - 変化検出時: 50ms間隔
   - アイドル時: 200ms間隔

### エラーハンドリング
1. **フォールバック戦略**
   - 色検出失敗 → パターン認識
   - パターン認識失敗 → タイマーベース
   - 全失敗 → 手動制御

2. **自動補正**
   - 解像度変更検出
   - 座標ドリフト補正
   - 明るさ変化対応

### 互換性
1. **既存システムとの共存**
   - タイマーベースモード維持
   - ハイブリッドモード実装
   - 段階的移行サポート

2. **解像度対応**
   - 相対座標使用
   - スケーリング対応
   - プリセット提供

## テスト計画

### 単体テスト
- 各色検出関数の精度
- 状態判定の正確性
- エッジケースの処理

### 統合テスト
- フラスコループの安定性
- Tincture/Wine連携
- バフ管理の動作

### ストレステスト
- 長時間実行の安定性
- CPU/メモリ使用率
- エラー回復能力

## 成功指標

1. **検出精度**: 95%以上
2. **応答速度**: 50ms以内
3. **CPU使用率**: 5%以下
4. **メモリ使用**: 50MB以下
5. **エラー率**: 0.1%以下

## リスク管理

### 技術的リスク
- ゲームアップデートによる色変更
- 解像度/設定の多様性
- パフォーマンス問題

### 対策
- 色範囲の柔軟な設定
- プリセットシステム
- 段階的ロールアウト

## まとめ

本実装により、現在のタイマーベースシステムから、より正確で柔軟な視覚ベースシステムへの移行が実現します。デュアルオーバーレイと色検出の組み合わせにより、高精度かつ高速な状態判定が可能となります。

---

最終更新: 2025-01-30
バージョン: 2.9.5計画案
次期リリース予定: v2.9.5-alpha（Phase 1完了後）