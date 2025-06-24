#!/usr/bin/env python3
import json
import re

def clean_duplicates(file_path):
    """Clean duplicate keys from ARB file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Parse JSON manually to track duplicates
    lines = content.strip().split('\n')
    seen_keys = set()
    cleaned_lines = []
    removed_count = 0
    
    for line in lines:
        # Match lines with JSON key-value pairs
        match = re.match(r'\s*"([^"]+)"\s*:\s*', line)
        if match:
            key = match.group(1)
            if key in seen_keys:
                print(f"Removing duplicate key: {key}")
                removed_count += 1
                continue
            seen_keys.add(key)
        cleaned_lines.append(line)
    
    # Write cleaned content
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(cleaned_lines))
    
    print(f"Removed {removed_count} duplicate keys from {file_path}")

if __name__ == "__main__":
    ar_file = "/Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/l10n/app_ar.arb"
    en_file = "/Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/l10n/app_en.arb"
    
    print("Cleaning Arabic ARB file...")
    clean_duplicates(ar_file)
    
    print("Cleaning English ARB file...")
    clean_duplicates(en_file)
    
    print("Duplicate cleanup complete!")
