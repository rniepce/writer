from PIL import Image, ImageDraw
import math

def create_squircle_mask(size, corner_radius_factor=0.225):
    """
    Create a macOS-style squircle (superellipse) mask.
    corner_radius_factor controls the roundness (0.225 is close to macOS Big Sur style)
    """
    width, height = size
    mask = Image.new('L', size, 0)  # Start with fully transparent
    draw = ImageDraw.Draw(mask)
    
    # Draw a rounded rectangle that matches macOS icon style
    # macOS uses approximately 22.5% corner radius
    corner_radius = int(min(width, height) * corner_radius_factor)
    
    # Draw the rounded rectangle
    draw.rounded_rectangle(
        [(0, 0), (width - 1, height - 1)],
        radius=corner_radius,
        fill=255  # Fully opaque inside
    )
    
    return mask

def apply_transparency_to_icon(input_path, output_path):
    """
    Apply squircle transparency mask to an icon image.
    """
    # Load the image
    img = Image.open(input_path).convert("RGBA")
    print(f"Loaded image: {img.size}")
    
    # Create the squircle mask
    mask = create_squircle_mask(img.size)
    
    # Apply the mask as the alpha channel
    # First, get the existing alpha or create one
    r, g, b, a = img.split()
    
    # Combine original alpha with our mask (minimum of both)
    # This preserves any existing transparency while adding our shape
    new_alpha = Image.composite(mask, Image.new('L', img.size, 0), mask)
    
    # Merge back with the new alpha
    result = Image.merge('RGBA', (r, g, b, new_alpha))
    
    # Save the result
    result.save(output_path)
    print(f"Saved transparent icon to: {output_path}")

# Run it
input_path = "/Users/rafaelpimentel/.gemini/antigravity/brain/1b56d198-fe84-46b6-a2c3-e30b8888aa85/zenwriter_icon_v3_1770334184872.png"
output_path = "/Users/rafaelpimentel/Downloads/writer/frontend/src-tauri/icons/icon_source_transparent.png"

apply_transparency_to_icon(input_path, output_path)
