# Divination Card Patterns

## 概要
- 40種類のDivination Cardバフアイコン
- 緑枠＋1～3px程度のマージン（ファイル毎にばらつきあり）でトリミング済み
- FindText用に最適化

## ファイル命名規則
- ファイル名 = カード名（スペースはアンダースコア）,（ファイル名はすべて小文字）
- 例：the_doctor.png

## 重要度別フォルダ
-  highest-priority: 現在のビルドに極めて有効なバフ効果をもつ
-  high-priority: 現在のビルドに有効なバフ効果を持つ
-  medium-priority: 現在のビルドにそれなりの恩恵があるバフ効果を持つ
-  low-priority: 現在のビルドにはあまり恩恵がないバフ効果を持つ
-  lowest-priority: 現在のビルドにはほとんど恩恵のないバフ効果を持つ 

## 使用方法
1. FindTextでパターン生成
2. BuffDetection.ahkで読み込み
3. 優先度に基づく制御