#!/usr/bin/env python3
import json
import re

def fix_json_comprehensive(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split into lines for easier processing
    lines = content.split('\n')
    fixed_lines = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this line ends with "}" and next line starts with a key
        if (line.strip().endswith('}') and 
            i + 1 < len(lines) and 
            re.match(r'\s*"[^"]+"\s*:\s*{', lines[i + 1])):
            
            # Add comma to current line
            fixed_lines.append(line + ',')
        else:
            fixed_lines.append(line)
        
        i += 1
    
    # Join lines back
    fixed_content = '\n'.join(fixed_lines)
    
    # Additional fixes for common patterns
    # Remove extra commas before closing braces
    fixed_content = re.sub(r',(\s*})', r'\1', fixed_content)
    
    # Fix missing commas between objects
    fixed_content = re.sub(r'(\s+})\n(\s+"[^"]+"\s*:\s*{)', r'\1,\n\2', fixed_content)
    
    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(fixed_content)
    
    print("Comprehensive JSON syntax fixes applied")

if __name__ == "__main__":
    fix_json_comprehensive("/Users/am/Desktop/Cription/Cription/Resources/Localizable.xcstrings")
