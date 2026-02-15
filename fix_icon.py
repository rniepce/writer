from PIL import Image, ImageDraw, ImageOps
import os

def add_rounded_corners(im, radius_ratio=0.22):
    """
    Adds rounded corners to an image with high-quality anti-aliasing (supersampling).
    """
    w, h = im.size
    
    # Supersample: create mask at 4x resolution
    scale = 4
    w_big, h_big = w * scale, h * scale
    radius_big = int(min(w_big, h_big) * radius_ratio)
    
    # Create mask on black background
    mask = Image.new('L', (w_big, h_big), 0)
    draw = ImageDraw.Draw(mask)
    
    # Draw white rounded rect (inclusive coords)
    # Using w_big-1, h_big-1 to be precise
    draw.rounded_rectangle([(0, 0), (w_big-1, h_big-1)], radius=radius_big, fill=255)
    
    # Downsample mask with high quality filter
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)
    
    # Apply mask
    output = im.copy().convert("RGBA")
    
    # If the image already has transparency, we want to combine masks?
    # Usually standard composition is: output alpha = min(original alpha, new mask)
    # But putalpha replaces it. Let's composite.
    
    # Get existing alpha if any
    if "A" in im.getbands():
        alpha = output.split()[3]
        # Combine: new_alpha = old_alpha * (mask/255)
        # We can use ImageChops.multiply but handling L vs 1 is tricky
        # Simplest: use paste with mask? No.
        # Let's verify pixel data:
        # We want the intersection of the rounded rect and the original alpha.
        from PIL import ImageChops
        mask = ImageChops.multiply(alpha, mask)
        
    output.putalpha(mask)
    return output

def regenerate_icons(source_path, output_dir):
    """
    Regenerates all required icon sizes from source.
    """
    if not os.path.exists(source_path):
        print(f"Error: Source not found at {source_path}")
        return

    print(f"Processing source: {source_path}")
    img = Image.open(source_path).convert("RGBA")
    
    # Add internal padding to match macOS icon sizing (~12% on each side)
    # Apple's icons have internal margins so they don't appear oversized in the dock
    padding_ratio = 0.22
    w, h = img.size
    pad = int(min(w, h) * padding_ratio)
    padded = Image.new("RGBA", (w + pad * 2, h + pad * 2), (255, 255, 255, 255))
    padded.paste(img, (pad, pad), img if "A" in img.getbands() else None)
    # Resize back to original dimensions
    padded = padded.resize((w, h), Image.Resampling.LANCZOS)
    print(f"Added {padding_ratio*100:.0f}% internal padding for macOS sizing")
    
    # Apply rounded corners to master image
    fixed_img = add_rounded_corners(padded)
    
    # Shrink the squircle within the canvas to match macOS icon grid
    # macOS icons have the squircle at ~80% of the full canvas, with transparent margins
    squircle_ratio = 0.80
    canvas_w, canvas_h = fixed_img.size
    new_size = int(min(canvas_w, canvas_h) * squircle_ratio)
    shrunken = fixed_img.resize((new_size, new_size), Image.Resampling.LANCZOS)
    final_img = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    offset = ((canvas_w - new_size) // 2, (canvas_h - new_size) // 2)
    final_img.paste(shrunken, offset, shrunken)
    fixed_img = final_img
    print(f"Shrunk squircle to {squircle_ratio*100:.0f}% of canvas for macOS grid alignment")
    
    # Definition of required sizes
    sizes = [
        ("32x32.png", 32),
        ("128x128.png", 128),
        ("128x128@2x.png", 256),
        ("icon.png", 512), # Max size usually
    ]
    
    for filename, size in sizes:
        out_path = os.path.join(output_dir, filename)
        resized = fixed_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(out_path)
        print(f"Generated: {filename} ({size}x{size})")

    # Generate ICO (windows)
    ico_path = os.path.join(output_dir, "icon.ico")
    fixed_img.save(ico_path, format='ICO', sizes=[(32,32), (64,64), (128,128), (256,256)])
    print(f"Generated: icon.ico")

    # Attempt ICNS (macOS) if possible, otherwise use PNG
    # PIL can't write ICNS directly easily without external tools or complex logic.
    # But Tauri `icon.png` is often enough for dev, or `iconutil` if on mac.
    try:
        # Create iconset folder structure for iconutil
        iconset_dir = os.path.join(output_dir, "icon.iconset")
        os.makedirs(iconset_dir, exist_ok=True)
        
        iconset_map = [
            ("icon_16x16.png", 16),
            ("icon_16x16@2x.png", 32),
            ("icon_32x32.png", 32),
            ("icon_32x32@2x.png", 64),
            ("icon_128x128.png", 128),
            ("icon_128x128@2x.png", 256),
            ("icon_256x256.png", 256),
            ("icon_256x256@2x.png", 512),
            ("icon_512x512.png", 512),
            ("icon_512x512@2x.png", 1024),
        ]
        
        # We need high res source for 1024. If source < 1024, upscaling will occur.
        for fname, size in iconset_map:
            p = os.path.join(iconset_dir, fname)
            fixed_img.resize((size, size), Image.Resampling.LANCZOS).save(p)
            
        # Run iconutil
        os.system(f"iconutil -c icns {iconset_dir} -o {os.path.join(output_dir, 'icon.icns')}")
        print("Generated: icon.icns via iconutil")
        
        # Cleanup
        import shutil
        shutil.rmtree(iconset_dir)
        
    except Exception as e:
        print(f"Warning: Could not help with ICNS: {e}")

# Configuration
input_path = "/Users/rafaelpimentel/Downloads/writer/frontend/src-tauri/icons/macos_feather_clean_diagonal.png"
output_dir = "/Users/rafaelpimentel/Downloads/writer/frontend/src-tauri/icons"

regenerate_icons(input_path, output_dir)
