import re

with open('main.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the corrupted subresource definition
content = re.sub(
    r'\[sub_resource type="AudioStreamMP3" id="AudioStreamMP3_ig7tw"\]\ndata = PackedByteArray\(\)\n',
    '',
    content,
    flags=re.DOTALL
)

with open('main.tscn', 'w', encoding='utf-8') as f:
    f.write(content)

print("Subresource removed successfully")
