#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size, filename):
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw gradient circle
    center = size // 2
    radius = int(size * 0.44)  # 44% of size for circle
    
    # Create gradient effect manually
    for i in range(radius):
        color_ratio = i / radius
        r = int(102 + (118 - 102) * color_ratio)
        g = int(126 + (75 - 126) * color_ratio) 
        b = int(234 + (162 - 234) * color_ratio)
        draw.ellipse([center - radius + i, center - radius + i, 
                      center + radius - i, center + radius - i], 
                     fill=(r, g, b, 255))
    
    # Draw SVN text
    try:
        # Try to use a bold font
        font_size = int(size * 0.3)
        font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
        except:
            font = ImageFont.load_default()
    
    # Draw text with shadow
    text = "SVN"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = center - text_width // 2
    text_y = center - text_height // 2 + int(size * 0.05)
    
    # Draw shadow
    draw.text((text_x + 2, text_y + 2), text, font=font, fill=(0, 0, 0, 100))
    # Draw main text
    draw.text((text_x, text_y), text, font=font, fill=(255, 255, 255, 255))
    
    img.save(f'/Users/simplica/Desktop/test/vibesvn/macos/Runner/Assets.xcassets/AppIcon.iconset/{filename}')

# Create macOS icons in different sizes
macos_sizes = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), 
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for size, filename in macos_sizes:
    create_icon(size, filename)

print("macOS PNG icons created!")
