#!/usr/bin/env python3

def create_macos_icon(size, filename):
    svg_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="{size}" height="{size}" viewBox="0 0 108 108" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="textGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#ffffff;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#f0f0f0;stop-opacity:1" />
    </linearGradient>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="0" dy="2" stdDeviation="2" flood-opacity="0.3"/>
    </filter>
  </defs>
  
  <!-- Background circle with gradient -->
  <circle cx="54" cy="54" r="48" fill="url(#bgGradient)" filter="url(#shadow)"/>
  
  <!-- Inner circle for depth effect -->
  <circle cx="54" cy="54" r="44" fill="none" stroke="rgba(255,255,255,0.2)" stroke-width="1"/>
  
  <!-- SVN Text -->
  <text x="54" y="65" font-family="Arial, sans-serif" font-size="32" font-weight="900" 
        text-anchor="middle" fill="url(#textGradient)" filter="url(#shadow)">
    SVN
  </text>
</svg>'''
    
    with open(f'/Users/simplica/Desktop/test/vibesvn/macos/Runner/Assets.xcassets/AppIcon.iconset/{filename}', 'w') as f:
        f.write(svg_content)

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
    create_macos_icon(size, filename)

print("macOS iconset created!")
