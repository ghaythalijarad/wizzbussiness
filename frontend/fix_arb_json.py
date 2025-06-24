#!/usr/bin/env python3
import json
import re

def fix_arb_json(filepath):
    """Fix common JSON formatting issues in ARB files."""
    print(f"Fixing JSON formatting in {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove any trailing commas before closing braces/brackets
    content = re.sub(r',\s*}', '}', content)
    content = re.sub(r',\s*]', ']', content)
    
    # Fix incomplete metadata blocks
    content = re.sub(r'(@[^"]+": {\s*)\n\s*"', r'\1\n  },\n  "', content)
    
    # Fix missing closing braces for metadata
    lines = content.split('\n')
    fixed_lines = []
    in_metadata = False
    metadata_indent = 0
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Check if this is a metadata line
        if stripped.startswith('"@') and stripped.endswith(': {'):
            in_metadata = True
            metadata_indent = len(line) - len(line.lstrip())
            fixed_lines.append(line)
            continue
        
        # If we're in metadata and see a new property at the same or lower indent
        if in_metadata:
            current_indent = len(line) - len(line.lstrip()) if line.strip() else 0
            if (stripped.startswith('"') and not stripped.startswith('"@') and 
                current_indent <= metadata_indent and stripped != '}'):
                # Close the metadata block
                fixed_lines.append(' ' * (metadata_indent + 2) + '},')
                in_metadata = False
        
        fixed_lines.append(line)
    
    # Join back and clean up
    content = '\n'.join(fixed_lines)
    
    # Final cleanup
    content = re.sub(r'},\s*}', '}', content)  # Remove trailing comma before final brace
    content = re.sub(r'\n\s*\n\s*}$', '\n}', content)  # Clean up ending
    
    # Write the fixed content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed JSON formatting in {filepath}")

if __name__ == "__main__":
    fix_arb_json("lib/l10n/app_en.arb")
    
    # Validate the JSON
    try:
        with open("lib/l10n/app_en.arb", 'r', encoding='utf-8') as f:
            json.load(f)
        print("✅ JSON is now valid!")
    except json.JSONDecodeError as e:
        print(f"❌ JSON still has errors: {e}")
