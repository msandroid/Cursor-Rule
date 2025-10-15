#!/usr/bin/env python3
import re

def fix_json_syntax(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to find lines that end with "    }" followed by a new line and then "    "key" : {"
    # This indicates missing comma after closing brace
    pattern = r'(\s+})\n(\s+"[^"]+"\s*:\s*{)'
    
    def add_comma(match):
        indent = match.group(1)
        key_line = match.group(2)
        return f'{indent},\n{key_line}'
    
    # Apply the fix
    fixed_content = re.sub(pattern, add_comma, content)
    
    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print("JSON syntax fixes applied")

if __name__ == "__main__":
    fix_json_syntax("/Users/am/Desktop/Cription/Cription/Resources/Localizable.xcstrings")
