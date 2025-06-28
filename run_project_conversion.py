#!/usr/bin/env python3
"""
プロジェクト全体の変換実行（Python版）
ConvertV1ToV2.ahkの変換ロジックをPythonで実行
"""

import os
import re
import shutil
import time
from datetime import datetime
from pathlib import Path

# 統計情報
conversion_stats = {
    'catchErrors': 0,
    'forLoops': 0,
    'objectProps': 0,
    'conditionals': 0,
    'rangeConversions': 0,
    'pythonLike': 0
}

converted_files = 0
errors = 0
warnings = 0
conversion_log = []

# 除外ファイル・ディレクトリ
excluded_files = [
    "ConvertV1ToV2.ahk",
    "test_conversion_manually.py",
    "run_test_conversion.ahk",
    "test_conversion_expected.ahk",
    "test_conversion_result.ahk",
    "test_conversion.ahk",
    "test_conversion_original.ahk",
    "CONVERSION_SUMMARY.md",
    "run_project_conversion.ahk",
    "run_project_conversion.py"
]

excluded_dirs = ["backups", "logs", ".git", "__pycache__"]

def log_message(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] INFO: {message}"
    conversion_log.append(log_entry)
    print(log_entry)

def log_error(message):
    global errors
    errors += 1
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] ERROR: {message}"
    conversion_log.append(log_entry)
    print(log_entry)

def log_warning(message):
    global warnings
    warnings += 1
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] WARNING: {message}"
    conversion_log.append(log_entry)
    print(log_entry)

def is_file_excluded(file_path):
    file_name = os.path.basename(file_path)
    
    # ファイル名チェック
    if file_name in excluded_files:
        return True
    
    # ディレクトリチェック
    for excluded_dir in excluded_dirs:
        if f"/{excluded_dir}/" in file_path or f"\\{excluded_dir}\\" in file_path:
            return True
    
    return False

def apply_conversions(content, file_path):
    global conversion_stats
    
    # 変換ルール定義
    conversion_rules = [
        {
            'name': 'catch Error as e',
            'pattern': r'catch\s+Error\s+as\s+(\w+)',
            'replacement': r'catch as \1',
            'type': 'v1tov2'
        },
        {
            'name': 'for i := start to end',
            'pattern': r'for\s+(\w+)\s*:=\s*(\d+)\s+to\s+(\d+)\s*\{',
            'replacement': r'Loop (\3 - \2 + 1) {\n    \1 := A_Index + \2 - 1',
            'type': 'v1tov2'
        },
        {
            'name': 'object.%key%',
            'pattern': r'(\w+)\.%(\w+)%',
            'replacement': r'\1[\2]',
            'type': 'v1tov2'
        },
        {
            'name': '%variable% removal',
            'pattern': r'%(\w+)%',
            'replacement': r'\1',
            'type': 'v1tov2'
        },
        {
            'name': 'If IsObject() without parentheses',
            'pattern': r'If\s+IsObject\(',
            'replacement': r'If (IsObject(',
            'type': 'v1tov2'
        },
        {
            'name': 'If without closing parenthesis',
            'pattern': r'If\s+\(([^)]+)$',
            'replacement': r'If (\1)',
            'type': 'v1tov2'
        },
        {
            'name': 'for i in Range(n)',
            'pattern': r'for\s+(\w+)\s+in\s+Range\((\d+)\)\s*\{',
            'replacement': r'Loop \2 {\n    \1 := A_Index',
            'type': 'python'
        },
        {
            'name': 'for i in Range(var)',
            'pattern': r'for\s+(\w+)\s+in\s+Range\((\w+)\)\s*\{',
            'replacement': r'Loop \2 {\n    \1 := A_Index',
            'type': 'python'
        },
        {
            'name': 'for i in Range(start, end)',
            'pattern': r'for\s+(\w+)\s+in\s+Range\((\d+),\s*(\d+)\)\s*\{',
            'replacement': r'Loop (\3 - \2 + 1) {\n    \1 := \2 + A_Index - 1',
            'type': 'python'
        },
        {
            'name': 'for i in Range(var1, var2)',
            'pattern': r'for\s+(\w+)\s+in\s+Range\((\w+),\s*(\w+)\)\s*\{',
            'replacement': r'Loop (\3 - \2 + 1) {\n    \1 := \2 + A_Index - 1',
            'type': 'python'
        },
        {
            'name': 'for i in Range(start, end, step)',
            'pattern': r'for\s+(\w+)\s+in\s+Range\((\d+),\s*(\d+),\s*(\d+)\)\s*\{',
            'replacement': r'Loop {\n    \1 := \2 + (A_Index - 1) * \4\n    if (\1 >= \3)\n        break',
            'type': 'python'
        }
    ]
    
    converted_content = content
    changes_applied = 0
    
    # 各変換ルールを適用
    for rule in conversion_rules:
        matches = re.findall(rule['pattern'], converted_content)
        if matches:
            new_content = re.sub(rule['pattern'], rule['replacement'], converted_content)
            if new_content != converted_content:
                changes_applied += len(matches)
                converted_content = new_content
                log_message(f"Applied rule '{rule['name']}': {len(matches)} changes in {file_path}")
                
                # 統計更新
                if rule['name'] == 'catch Error as e':
                    conversion_stats['catchErrors'] += len(matches)
                elif 'for' in rule['name'] and 'to' in rule['name']:
                    conversion_stats['forLoops'] += len(matches)
                elif 'object.%key%' in rule['name']:
                    conversion_stats['objectProps'] += len(matches)
                elif 'If' in rule['name']:
                    conversion_stats['conditionals'] += len(matches)
                elif rule['type'] == 'python':
                    conversion_stats['pythonLike'] += len(matches)
                    if 'Range' in rule['name']:
                        conversion_stats['rangeConversions'] += len(matches)
    
    # マルチラインパターンの修正
    converted_content = fix_multiline_patterns(converted_content, file_path)
    
    return converted_content

def fix_multiline_patterns(content, file_path):
    """複数行パターンの修正"""
    lines = content.split('\n')
    fixed_lines = []
    changes_applied = 0
    
    for line_num, line in enumerate(lines):
        trimmed_line = line.strip()
        current_line = line
        
        # If文の未閉じ括弧を検出・修正
        if re.match(r'^If\s*\([^)]*$', trimmed_line) and ')' not in trimmed_line:
            current_line = re.sub(r'(\s*)$', r')\1', current_line)
            log_message(f"Added missing closing parenthesis at line {line_num + 1} in {file_path}")
            changes_applied += 1
        
        # インデント修正: Loop文内の変数代入
        if re.match(r'^(\w+\s*:=.*)', trimmed_line) and line_num > 0:
            prev_line = lines[line_num - 1].strip()
            if re.match(r'^Loop.*\{', prev_line):
                current_line = re.sub(r'^(\s*)', r'    ', current_line)
                log_message(f"Fixed indentation at line {line_num + 1} in {file_path}")
                changes_applied += 1
        
        fixed_lines.append(current_line)
    
    if changes_applied > 0:
        log_message(f"Applied {changes_applied} multi-line pattern fixes in {file_path}")
    
    return '\n'.join(fixed_lines)

def create_backup(file_path):
    backup_dir = "./backups"
    if not os.path.exists(backup_dir):
        os.makedirs(backup_dir)
    
    file_name = os.path.basename(file_path)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(backup_dir, f"{file_name}_{timestamp}.bak")
    
    try:
        shutil.copy2(file_path, backup_path)
        log_message(f"Created backup: {backup_path}")
        return True
    except Exception as e:
        log_error(f"Failed to create backup for {file_path}: {e}")
        return False

def convert_file(file_path):
    global converted_files
    
    if not os.path.exists(file_path):
        log_error(f"File not found: {file_path}")
        return False
    
    if not file_path.endswith('.ahk'):
        log_warning(f"Skipping non-AutoHotkey file: {file_path}")
        return False
    
    if is_file_excluded(file_path):
        log_message(f"Skipping excluded file: {file_path}")
        return True
    
    log_message(f"Converting file: {file_path}")
    
    # バックアップ作成
    if not create_backup(file_path):
        log_error(f"Failed to create backup for: {file_path}")
        return False
    
    try:
        # ファイル読み込み
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # 変換実行
        converted_content = apply_conversions(content, file_path)
        
        # 変更があった場合のみ書き込み
        if converted_content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(converted_content)
            converted_files += 1
            log_message(f"Successfully converted: {file_path}")
            return True
        else:
            log_message(f"No changes needed: {file_path}")
            return True
            
    except Exception as e:
        log_error(f"Error converting file {file_path}: {e}")
        return False

def convert_directory(dir_path):
    log_message(f"Converting directory: {dir_path}")
    
    # .ahkファイルを再帰的に検索
    for root, dirs, files in os.walk(dir_path):
        # 除外ディレクトリをスキップ
        dirs[:] = [d for d in dirs if d not in excluded_dirs]
        
        for file in files:
            if file.endswith('.ahk'):
                file_path = os.path.join(root, file)
                convert_file(file_path)

def save_log_to_file():
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file_path = f"conversion_log_{timestamp}.txt"
    
    try:
        with open(log_file_path, 'w', encoding='utf-8') as f:
            for entry in conversion_log:
                f.write(entry + '\n')
            
            # 統計情報を追加
            f.write('\n=== Conversion Statistics ===\n')
            f.write(f'Files converted: {converted_files}\n')
            f.write(f'Errors: {errors}\n')
            f.write(f'Warnings: {warnings}\n')
            f.write(f'catch Error corrections: {conversion_stats["catchErrors"]}\n')
            f.write(f'for loop conversions: {conversion_stats["forLoops"]}\n')
            f.write(f'Object property fixes: {conversion_stats["objectProps"]}\n')
            f.write(f'Conditional fixes: {conversion_stats["conditionals"]}\n')
            f.write(f'Range conversions: {conversion_stats["rangeConversions"]}\n')
            f.write(f'Python-like conversions: {conversion_stats["pythonLike"]}\n')
        
        log_message(f"Log saved to: {log_file_path}")
        return log_file_path
        
    except Exception as e:
        log_error(f"Failed to save log file: {e}")
        return ""

def show_statistics():
    total_rule_applications = (conversion_stats['catchErrors'] + conversion_stats['forLoops'] + 
                              conversion_stats['objectProps'] + conversion_stats['conditionals'] + 
                              conversion_stats['rangeConversions'] + conversion_stats['pythonLike'])
    
    stats = f"""
=== PROJECT CONVERSION COMPLETED ===

File Statistics:
• Files processed: {converted_files}
• Errors: {errors}
• Warnings: {warnings}

Conversion Rules Applied:
• catch Error fixes: {conversion_stats['catchErrors']}
• for loop conversions: {conversion_stats['forLoops']}
• Object property fixes: {conversion_stats['objectProps']}
• Conditional fixes: {conversion_stats['conditionals']}
• Range conversions: {conversion_stats['rangeConversions']}
• Python-like conversions: {conversion_stats['pythonLike']}

Total rule applications: {total_rule_applications}
"""
    
    print(stats)
    return stats

def main():
    print("=== PROJECT CONVERSION STARTED ===")
    start_time = time.time()
    
    # 統計リセット
    global converted_files, errors, warnings, conversion_stats
    converted_files = 0
    errors = 0
    warnings = 0
    for key in conversion_stats:
        conversion_stats[key] = 0
    
    log_message("Statistics reset successfully")
    
    # 変換実行
    try:
        convert_directory(".")
        
        end_time = time.time()
        duration = end_time - start_time
        
        log_message(f"=== PROJECT CONVERSION COMPLETED in {duration:.2f} seconds ===")
        
        # 結果表示
        show_statistics()
        log_file = save_log_to_file()
        
        print(f"\nLog saved to: {log_file}")
        
        return True
        
    except Exception as e:
        log_error(f"Project conversion failed: {e}")
        save_log_to_file()
        return False

if __name__ == "__main__":
    main()