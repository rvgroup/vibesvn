#!/usr/bin/env python3
import xml.etree.ElementTree as ET

def create_android_icon(size, folder):
    svg_content = f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="{size}dp"
    android:height="{size}dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#667eea"
        android:pathData="M54,6c26.5,0 48,21.5 48,48s-21.5,48 -48,48S6,80.5 6,54S27.5,6 54,6z"/>
    <path
        android:fillColor="#764ba2"
        android:pathData="M54,10c24.3,0 44,19.7 44,44s-19.7,44 -44,44S10,78.3 10,54S29.7,10 54,10z"/>
    <path
        android:fillColor="#ffffff"
        android:fillType="evenOdd"
        android:pathData="M30,65h48v-8h-48V65zM30,45h48v-8h-48V45z"/>
</vector>'''
    
    with open(f'/Users/simplica/Desktop/test/vibesvn/android/app/src/main/res/{folder}/ic_launcher.xml', 'w') as f:
        f.write(svg_content)

# Create Android vector icons
create_android_icon(108, "mipmap-hdpi")
create_android_icon(108, "mipmap-mdpi") 
create_android_icon(108, "mipmap-xhdpi")
create_android_icon(108, "mipmap-xxhdpi")
create_android_icon(108, "mipmap-xxxhdpi")

print("Android icons created!")
