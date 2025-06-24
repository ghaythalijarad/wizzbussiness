#!/usr/bin/env python3
import json
import re
from collections import OrderedDict

def clean_arb_duplicates(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all key-value pairs and metadata
    pattern = r'^\s*"([^"]+)"\s*:\s*(.+?)(?=,\s*\n\s*"|\s*\n\s*})'
    matches = re.findall(pattern, content, re.MULTILINE | re.DOTALL)
    
    seen_keys = set()
    cleaned_entries = []
    duplicates_removed = []
    
    for key, value in matches:
        if key not in seen_keys:
            seen_keys.add(key)
            cleaned_entries.append(f'  "{key}": {value.rstrip(",")}')
        else:
            duplicates_removed.append(key)
            print(f"Removing duplicate key: {key}")
    
    # Reconstruct the file
    result = "{\n"
    for i, entry in enumerate(cleaned_entries):
        if i < len(cleaned_entries) - 1:
            result += entry + ",\n"
        else:
            result += entry + "\n"
    result += "}"
    
    return result, duplicates_removed

# Clean the English ARB file
print("Cleaning English ARB file...")
cleaned_content, removed_duplicates = clean_arb_duplicates('/Users/ghaythallaheebi/order-receiver-app 2/lib/l10n/app_en.arb')

print(f"Removed {len(removed_duplicates)} duplicate keys:")
for key in removed_duplicates:
    print(f"  - {key}")

# Write the cleaned content back
with open('/Users/ghaythallaheebi/order-receiver-app 2/lib/l10n/app_en.arb', 'w', encoding='utf-8') as f:
    f.write(cleaned_content)

print("English ARB file cleaned successfully!")
