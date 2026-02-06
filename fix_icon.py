from PIL import Image
import sys

try:
    # Load image
    img_path = "/Users/rafaelpimentel/.gemini/antigravity/brain/1b56d198-fe84-46b6-a2c3-e30b8888aa85/zenwriter_icon_v3_1770334184872.png"
    img = Image.open(img_path).convert("RGBA")
    
    print(f"Original size: {img.size}")

    # Aggressive crop to remove rounded corners (assuming they are in the outer ~4-5%)
    # 1024 * 0.05 = ~50 pixels. Let's do 60 to be safe.
    crop_margin = 60
    width, height = img.size
    
    cropped = img.crop((crop_margin, crop_margin, width - crop_margin, height - crop_margin))
    print(f"Cropped size: {cropped.size}")

    # Resize back to full size
    final_img = cropped.resize((1024, 1024), Image.LANCZOS)
    
    output_path = "/Users/rafaelpimentel/Downloads/writer/frontend/src-tauri/icons/icon_source_fixed.png"
    final_img.save(output_path)
    print(f"Saved fixed icon to {output_path}")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
