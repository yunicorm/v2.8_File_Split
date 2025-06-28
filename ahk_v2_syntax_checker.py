#!/usr/bin/env python3
"""
AutoHotkey v2 構文チェッカー
Main.ahkとその依存ファイルの構文エラーを検出
"""

import os
import re
from pathlib import Path

def check_ahk_v2_syntax(file_path):
    """AutoHotkey v2の構文エラーをチェック"""
    errors = []
    warnings = []
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except Exception as e:
        return [f"Failed to read file: {e}"], []
    
    for line_num, line in enumerate(lines, 1):
        line = line.strip()
        
        # v1.1構文の残存チェック
        if re.search(r'catch\s+Error\s+as\s+\w+', line):
            errors.append(f"Line {line_num}: v1.1 catch syntax found: {line}")
        
        if re.search(r'for\s+\w+\s*:=\s*\d+\s+to\s+\d+', line):
            errors.append(f"Line {line_num}: v1.1 for loop syntax found: {line}")
        
        if re.search(r'\w+\.%\w+%', line):
            errors.append(f"Line {line_num}: v1.1 object property syntax found: {line}")
        
        # 括弧の不整合チェック
        open_braces = line.count('{')
        close_braces = line.count('}')
        open_parens = line.count('(')
        close_parens = line.count(')')
        
        if line.strip().startswith('If') and '(' in line and ')' not in line:
            warnings.append(f"Line {line_num}: Possible missing closing parenthesis: {line}")
        
        # 未定義変数の可能性チェック（簡易）
        if re.search(r'%\w+%', line) and not re.search(r'FormatTime|RegEx|Format', line):
            warnings.append(f"Line {line_num}: Possible v1.1 variable syntax: {line}")
        
        # インクルードパスチェック
        if line.startswith('#Include'):
            include_match = re.search(r'#Include\s+"?([^"]+)"?', line)
            if include_match:
                include_path = include_match.group(1)
                # 相対パスの解決
                base_dir = os.path.dirname(file_path)
                full_include_path = os.path.join(base_dir, include_path)
                if not os.path.exists(full_include_path):
                    errors.append(f"Line {line_num}: Include file not found: {include_path}")
    
    return errors, warnings

def check_main_ahk_structure():
    """Main.ahkの構造と依存関係をチェック"""
    main_file = "./Main.ahk"
    if not os.path.exists(main_file):
        return ["Main.ahk not found"], []
    
    print("=== Main.ahk 構文チェック開始 ===")
    
    all_errors = []
    all_warnings = []
    checked_files = set()
    
    def check_file_recursive(file_path, level=0):
        indent = "  " * level
        rel_path = os.path.relpath(file_path)
        
        if rel_path in checked_files:
            return
        
        checked_files.add(rel_path)
        print(f"{indent}Checking: {rel_path}")
        
        errors, warnings = check_ahk_v2_syntax(file_path)
        
        if errors:
            print(f"{indent}  ❌ {len(errors)} errors found")
            all_errors.extend([f"{rel_path}: {err}" for err in errors])
        
        if warnings:
            print(f"{indent}  ⚠️  {len(warnings)} warnings found")
            all_warnings.extend([f"{rel_path}: {warn}" for warn in warnings])
        
        if not errors and not warnings:
            print(f"{indent}  ✅ No issues found")
        
        # インクルードファイルを再帰的にチェック
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            include_matches = re.findall(r'#Include\s+"?([^"]+)"?', content)
            for include_path in include_matches:
                base_dir = os.path.dirname(file_path)
                full_include_path = os.path.join(base_dir, include_path)
                if os.path.exists(full_include_path):
                    check_file_recursive(full_include_path, level + 1)
                    
        except Exception as e:
            all_errors.append(f"{rel_path}: Failed to parse includes: {e}")
    
    # Main.ahkから開始
    check_file_recursive(main_file)
    
    return all_errors, all_warnings

def simulate_hotkey_functions():
    """ホットキー機能のシミュレーション"""
    print("\n=== ホットキー機能シミュレーション ===")
    
    # F12: マクロ切り替え機能
    print("🔧 F12 (マクロ切り替え):")
    try:
        # MacroController.ahkの存在確認
        if os.path.exists("./Core/MacroController.ahk"):
            print("  ✅ MacroController.ahk found")
            # ToggleMacro関数の存在確認
            with open("./Core/MacroController.ahk", 'r', encoding='utf-8') as f:
                content = f.read()
                if "ToggleMacro" in content:
                    print("  ✅ ToggleMacro function found")
                else:
                    print("  ⚠️  ToggleMacro function not found")
        else:
            print("  ❌ MacroController.ahk not found")
    except Exception as e:
        print(f"  ❌ Error checking MacroController: {e}")
    
    # Ctrl+Shift+S: 設定ウィンドウ
    print("\n🔧 Ctrl+Shift+S (設定ウィンドウ):")
    try:
        if os.path.exists("./UI/SettingsWindow/SettingsMain.ahk"):
            print("  ✅ SettingsMain.ahk found")
            with open("./UI/SettingsWindow/SettingsMain.ahk", 'r', encoding='utf-8') as f:
                content = f.read()
                if "ShowSettingsWindow" in content or "CreateSettingsWindow" in content:
                    print("  ✅ Settings window function found")
                else:
                    print("  ⚠️  Settings window function not clearly identified")
        else:
            print("  ❌ SettingsMain.ahk not found")
    except Exception as e:
        print(f"  ❌ Error checking SettingsMain: {e}")
    
    # F6: ログビューア
    print("\n🔧 F6 (ログビューア):")
    try:
        if os.path.exists("./Utils/Logger.ahk"):
            print("  ✅ Logger.ahk found")
            with open("./Utils/Logger.ahk", 'r', encoding='utf-8') as f:
                content = f.read()
                if "ShowLogViewer" in content:
                    print("  ✅ ShowLogViewer function found")
                else:
                    print("  ⚠️  ShowLogViewer function not found")
        else:
            print("  ❌ Logger.ahk not found")
    except Exception as e:
        print(f"  ❌ Error checking Logger: {e}")

def check_config_system():
    """設定システムの整合性チェック"""
    print("\n=== 設定システムチェック ===")
    
    try:
        # ConfigManager.ahkの確認
        if os.path.exists("./Utils/ConfigManager.ahk"):
            print("✅ ConfigManager.ahk found")
            
            # Config.iniの確認
            if os.path.exists("./Config.ini"):
                print("✅ Config.ini found")
            else:
                print("⚠️  Config.ini not found (will be auto-generated)")
        else:
            print("❌ ConfigManager.ahk not found")
            
    except Exception as e:
        print(f"❌ Error checking config system: {e}")

def main():
    print("AutoHotkey v2 構文チェッカー")
    print("=" * 50)
    
    # 構文チェック実行
    errors, warnings = check_main_ahk_structure()
    
    print(f"\n=== 構文チェック結果 ===")
    print(f"チェックしたファイル数: {len(set(err.split(':')[0] for err in errors + warnings))}")
    print(f"エラー: {len(errors)}")
    print(f"警告: {len(warnings)}")
    
    if errors:
        print("\n❌ エラー詳細:")
        for error in errors:
            print(f"  {error}")
    
    if warnings:
        print("\n⚠️  警告詳細:")
        for warning in warnings:
            print(f"  {warning}")
    
    if not errors and not warnings:
        print("\n✅ 構文エラーは検出されませんでした")
    
    # 機能シミュレーション
    simulate_hotkey_functions()
    
    # 設定システムチェック
    check_config_system()
    
    # 総合評価
    print(f"\n=== 総合評価 ===")
    if len(errors) == 0:
        print("🎉 Main.ahkは正常に起動可能と推定されます")
        print("   主要機能のファイルが正常に配置されています")
    else:
        print("⚠️  いくつかの問題が検出されました")
        print("   AutoHotkey v2環境での動作前に修正が推奨されます")
    
    return len(errors) == 0

if __name__ == "__main__":
    main()