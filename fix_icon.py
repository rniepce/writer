from PIL import Image

def replace_white_with_transparent(input_path, output_path, threshold=250):
    """
    Replace white/near-white pixels with transparent.
    threshold: pixels with R, G, B all above this value are considered white
    """
    img = Image.open(input_path).convert("RGBA")
    print(f"Loaded image: {img.size}")
    
    # Get pixel data
    data = img.getdata()
    
    new_data = []
    white_count = 0
    for item in data:
        r, g, b, a = item
        # If pixel is white or near-white, make it transparent
        if r > threshold and g > threshold and b > threshold:
            new_data.append((r, g, b, 0))  # Fully transparent
            white_count += 1
        else:
            new_data.append(item)
    
    print(f"Replaced {white_count} white pixels with transparent")
    
    img.putdata(new_data)
    img.save(output_path)
    print(f"Saved to: {output_path}")

# Run it
input_path = "/Users/rafaelpimentel/.gemini/antigravity/brain/1b56d198-fe84-46b6-a2c3-e30b8888aa85/zenwriter_icon_v3_1770334184872.png"
output_path = "/Users/rafaelpimentel/Downloads/writer/frontend/src-tauri/icons/icon_source_clean.png"

replace_white_with_transparent(input_path, output_path)
