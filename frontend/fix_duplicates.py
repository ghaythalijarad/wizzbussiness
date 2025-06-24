#!/usr/bin/env python3
import json
import re
from collections import OrderedDict

def fix_arb_duplicates(file_path):
    """Fix duplicate keys in ARB file by keeping only the first occurrence"""
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split content into lines
    lines = content.split('\n')
    
    # Track seen keys
    seen_keys = set()
    cleaned_lines = []
    skip_next_metadata = False
    duplicates_removed = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this is a key line (starts with quote, contains colon)
        key_match = re.match(r'\s*"([^"@]+)"\s*:', line)
        if key_match:
            key = key_match.group(1)
            if key in seen_keys:
                # Skip this duplicate key
                duplicates_removed.append(key)
                print(f"Removing duplicate key: {key}")
                # Skip this line and the next metadata block if it exists
                skip_next_metadata = True
                i += 1
                continue
            else:
                seen_keys.add(key)
                cleaned_lines.append(line)
                skip_next_metadata = False
        
        # Check if this is a metadata line (starts with @)
        elif re.match(r'\s*"@', line):
            if skip_next_metadata:
                # Skip metadata for duplicate key
                # Find the end of this metadata block
                while i < len(lines) and not lines[i].strip().endswith('},'):
                    i += 1
                # Skip the closing brace line too
                if i < len(lines):
                    i += 1
                skip_next_metadata = False
                continue
            else:
                cleaned_lines.append(line)
        
        else:
            # Regular line, keep it unless we're skipping metadata
            if not skip_next_metadata:
                cleaned_lines.append(line)
        
        i += 1
    
    # Write cleaned content back
    cleaned_content = '\n'.join(cleaned_lines)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(cleaned_content)
    
    print(f"Removed {len(duplicates_removed)} duplicate keys:")
    for key in duplicates_removed[:10]:  # Show first 10
        print(f"  - {key}")
    if len(duplicates_removed) > 10:
        print(f"  ... and {len(duplicates_removed) - 10} more")
    
    return len(duplicates_removed)

# Clean the English ARB file
print("Cleaning English ARB file...")
removed_count = fix_arb_duplicates('/Users/ghaythallaheebi/order-receiver-app 2/lib/l10n/app_en.arb')

if removed_count > 0:
    print(f"\nSuccessfully removed {removed_count} duplicate keys!")
else:
    print("No duplicate keys found or file couldn't be processed.")
