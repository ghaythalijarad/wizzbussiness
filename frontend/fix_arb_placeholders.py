#!/usr/bin/env python3
"""
Fix malformed placeholders in ARB localization files
"""
import json
import re

def fix_arb_file(file_path):
    """Fix malformed placeholders in an ARB file"""
    print(f"Fixing {file_path}...")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to find malformed placeholders like:
    # "@key": {
    #     "param": {
    #     }
    #   }
    
    # Fix pattern: replace malformed placeholders with proper structure
    pattern = r'("@[^"]+": \{)\s*("[^"]+": \{\s*\}\s*)+(\s*\})'
    
    def fix_placeholder(match):
        # Extract the key and parameter names
        full_match = match.group(0)
        lines = full_match.split('\n')
        
        # Find parameter names
        params = []
        for line in lines:
            if '": {' in line and not line.strip().startswith('"@'):
                param_name = line.split('": {')[0].strip().strip('"')
                params.append(param_name)
        
        # Build proper placeholder structure
        if params:
            placeholders_content = []
            for param in params:
                placeholders_content.append(f'      "{param}": {{\n        "type": "String"\n      }}')
            
            key_line = lines[0]
            result = f"""{key_line}
    "placeholders": {{
{',\\n'.join(placeholders_content)}
    }}
  }}"""
            return result
        else:
            return match.group(0)
    
    # Apply the fix
    fixed_content = re.sub(pattern, fix_placeholder, content, flags=re.MULTILINE | re.DOTALL)
    
    # Additional cleanup for specific malformed patterns
    # Fix patterns like: "@key": {\n      "param": {\n      }\n    }\n  },
    pattern2 = r'("@[^"]+": \{[^}]*?"[^"]+": \{[^}]*?\}[^}]*?\})'
    
    def fix_simple_placeholder(match):
        placeholder_block = match.group(0)
        
        # Extract key name
        key_match = re.search(r'"(@[^"]+)":', placeholder_block)
        if not key_match:
            return placeholder_block
            
        # Extract parameter names
        param_matches = re.findall(r'"([^@"][^"]*)":\s*\{', placeholder_block)
        
        if param_matches:
            placeholders_content = []
            for param in param_matches:
                placeholders_content.append(f'      "{param}": {{\n        "type": "String"\n      }}')
            
            result = f"""  "{key_match.group(1)}": {{
    "placeholders": {{
{',\\n'.join(placeholders_content)}
    }}
  }}"""
            return result
        
        return placeholder_block
    
    # Try to parse as JSON to validate
    try:
        json.loads(fixed_content)
        print(f"✅ {file_path} is valid JSON after fixes")
    except json.JSONDecodeError as e:
        print(f"❌ {file_path} still has JSON errors: {e}")
        
        # Try alternative fix approach
        lines = fixed_content.split('\n')
        fixed_lines = []
        i = 0
        
        while i < len(lines):
            line = lines[i]
            
            # Look for malformed placeholder patterns
            if '"@' in line and '": {' in line:
                # Start of a placeholder definition
                placeholder_lines = [line]
                i += 1
                
                # Collect all lines until the closing brace
                brace_count = line.count('{') - line.count('}')
                while i < len(lines) and brace_count > 0:
                    next_line = lines[i]
                    placeholder_lines.append(next_line)
                    brace_count += next_line.count('{') - next_line.count('}')
                    i += 1
                
                # Try to fix this placeholder block
                placeholder_block = '\n'.join(placeholder_lines)
                
                # Extract key and parameters
                key_match = re.search(r'"(@[^"]+)":', placeholder_block)
                if key_match:
                    # Find parameter names in the block
                    param_matches = re.findall(r'"([^@"][^"]*)":\s*\{[^}]*\}', placeholder_block)
                    
                    if param_matches:
                        # Rebuild with proper structure
                        placeholders_content = []
                        for param in param_matches:
                            placeholders_content.append(f'      "{param}": {{\n        "type": "String"\n      }}')
                        
                        fixed_placeholder = f"""  "{key_match.group(1)}": {{
    "placeholders": {{
{',\\n'.join(placeholders_content)}
    }}
  }}"""
                        fixed_lines.append(fixed_placeholder)
                    else:
                        fixed_lines.extend(placeholder_lines)
                else:
                    fixed_lines.extend(placeholder_lines)
            else:
                fixed_lines.append(line)
                i += 1
        
        fixed_content = '\n'.join(fixed_lines)
    
    # Write the fixed content back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print(f"Fixed {file_path}")

if __name__ == "__main__":
    import sys
    
    files_to_fix = [
        "/Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/l10n/app_en.arb",
        "/Users/ghaythallaheebi/order-receiver-app-2/frontend/lib/l10n/app_ar.arb"
    ]
    
    for file_path in files_to_fix:
        try:
            fix_arb_file(file_path)
        except Exception as e:
            print(f"Error fixing {file_path}: {e}")
