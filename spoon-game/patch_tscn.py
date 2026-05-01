import sys

def main():
    file_path = 'main.tscn'
    new_line = '[ext_resource type="AudioStream" uid="uid://c6sdkihlitwvv" path="res://clap.mp3" id="3_clap"]\n'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Insert after line 4 (index 4)
    lines.insert(4, new_line)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)

if __name__ == "__main__":
    main()
