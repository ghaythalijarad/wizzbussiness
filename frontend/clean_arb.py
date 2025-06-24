#!/usr/bin/env python3
import json

def clean_arb_file(file_path):
    # Read the file content
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    try:
        # Parse as JSON
        data = json.loads(content)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
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
    
    print(f"Removed {duplicate_count} duplicate keys")
    print(f"File saved with {len(cleaned_data)} unique keys")
    return True

# Clean the English ARB file
print("Cleaning English ARB file...")
success = clean_arb_file('/Users/ghaythallaheebi/order-receiver-app 2/lib/l10n/app_en.arb')

if success:
    print("English ARB file cleaned successfully!")
else:
    print("Failed to clean the file. Please check for JSON syntax errors.")
