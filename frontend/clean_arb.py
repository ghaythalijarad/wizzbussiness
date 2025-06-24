#!/usr/bin/env python3
import json, os

def clean_arb_file(file_path):
    # Read the file content
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    try:
        # Parse as JSON
        data = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON in {file_path}: {e}")
        return False
    
    # Create new dict to preserve order but remove duplicates
    cleaned_data = {}
    duplicate_count = 0
    
    for key, value in data.items():
        if key not in cleaned_data:
            cleaned_data[key] = value
        else:
            duplicate_count += 1
            print(f"Removing duplicate key: {key}")
    
    # Write back to file with proper formatting
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(cleaned_data, f, ensure_ascii=False, indent=2)
    
    print(f"Removed {duplicate_count} duplicate keys from {os.path.basename(file_path)}")
    return True

if __name__ == '__main__':
    base_dir = os.path.dirname(__file__)
    l10n_dir = os.path.join(base_dir, 'lib', 'l10n')  # adjust if needed
    arb_files = ['app_en.arb', 'app_ar.arb']
    for arb in arb_files:
        path = os.path.join(l10n_dir, arb)
        print(f"Cleaning {arb}...")
        clean_arb_file(path)
