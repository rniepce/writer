from PIL import Image

def replace_pure_white_with_transparent(input_path, output_path):
    """
    Replace ONLY pure white pixels (#FFFFFF) with transparent.
    This preserves the light gray background of the icon.
    """
    img = Image.open(input_path).convert("RGBA")
    print(f"Loaded image: {img.size}")
    
    # Get pixel data
    data = img.getdata()
    
    new_data = []
    white_count = 0
    for item in data:
        r, g, b, a = item
        # Only remove PURE white (255, 255, 255)
        # This preserves light gray (#F5F5F7 = 245, 245, 247) and other near-whites
        if r == 255 and g == 255 and b == 255:
            new_data.append((r, g, b, 0))  # Fully transparent
            white_count += 1
        else:
            new_data.append(item)
    
    print(f"Replaced {white_count} pure white pixels with transparent")
    
    img.putdata(new_data)
    img.save(output_path)
    print(f"Saved to: {output_path}")

# Run it
input_path = "/Users/rafaelpimentel/.gemini/antigravity/brain/1b56d198-fe84-46b6-a2c3-e30b8888aa85/zenwriter_icon_v3_1770334184872.png"
output_path = "/Users/rafaelpimentel/Downloads/writer/frontend/src-tauri/icons/icon_source_final.png"

replace_pure_white_with_transparent(input_path, output_path)
