# AutoHotkey v2起動問題診断手順

## 問題の状況
- main.ahk実行後、プロセスが起動しない
- 原因特定のための段階的診断が必要

## 診断手順

### 手順1: 基本起動テスト
```bash
# Windows環境で実行
AutoHotkey.exe Main_debug.ahk
```

**期待される結果:**
- `debug.log`ファイルが作成される
- "Test"というメッセージボックスが表示される
- プロセスが正常終了する

### 手順2: 詳細診断テスト
```bash
# Windows環境で実行
AutoHotkey.exe Main_diagnosis.ahk
```

**期待される結果:**
- 5段階の診断メッセージが順次表示される
- `diagnosis.log`ファイルに詳細ログが記録される
- 各段階でのエラー発生箇所を特定

### 手順3: 診断結果の確認

#### 成功パターン
- 全ての段階が完了
- "All diagnosis stages passed!"メッセージ表示
- `diagnosis.log`に完了ログ

#### 失敗パターンと対処

**Stage 1失敗**: AutoHotkey v2.0がインストールされていない
- AutoHotkey v2.0.11以降をインストール
- PATH環境変数の確認

**Stage 2失敗**: ファイルシステムアクセス権限問題
- 管理者権限で実行
- ウイルス対策ソフトの除外設定

**Stage 3失敗**: インクルードファイルが見つからない
- ファイルパス構造の確認
- 相対パス解決の問題

**Stage 4-5失敗**: インクルードファイルの構文エラー
- Utils/Logger.ahkまたはUtils/ConfigManager.ahkに構文エラー
- AutoHotkey v1.1構文の残存

## ログファイル分析

### debug.log の内容確認
```
[期待される内容]
20241228120000 - Starting
```

### diagnosis.log の内容確認
```
[期待される内容]
20241228120000 - Stage 1: Basic startup test
20241228120001 - Stage 2: File system access test
Working Dir: C:\path\to\project
Script Dir: C:\path\to\project
20241228120002 - Stage 3: Testing basic includes
ConfigManager.ahk found
Logger.ahk found
20241228120003 - Stage 4: Testing actual include
Logger.ahk included successfully
20241228120004 - Stage 5: Testing ConfigManager include
ConfigManager.ahk included successfully
20241228120005 - DIAGNOSIS COMPLETED SUCCESSFULLY
```

## トラブルシューティング

### よくある問題と解決策

1. **ログファイルが作成されない**
   - AutoHotkey v2.0がインストールされていない
   - 実行権限の問題

2. **Stage 1で停止**
   - AutoHotkey v2.0のバージョン確認
   - システム互換性の問題

3. **Stage 3でファイルが見つからない**
   - プロジェクトディレクトリ構造の確認
   - 相対パスの問題

4. **Stage 4-5でインクルードエラー**
   - Utils/ファイルの構文エラー
   - 循環参照の問題

## 報告テンプレート

診断実行後、以下の情報を報告してください：

```
診断結果報告:
- 最後に成功した段階: Stage X
- エラーメッセージ: [表示されたメッセージ]
- ログファイル内容: [debug.log/diagnosis.logの内容]
- AutoHotkeyバージョン: [バージョン情報]
- OS環境: [Windows version]
```

この診断により、main.ahk起動問題の根本原因を特定できます。