#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

# 创建一个包含多行文本的图片
width, height = 400, 200
image = Image.new('RGB', (width, height), color='white')
draw = ImageDraw.Draw(image)

# 尝试使用系统字体
try:
    font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 20)
except:
    font = ImageFont.load_default()

# 添加多行文本
texts = [
    "Hello World",
    "This is a test image",
    "OCR Recognition Test",
    "Search functionality",
    "ClipFlow Pro"
]

y_position = 20
for text in texts:
    draw.text((20, y_position), text, fill='black', font=font)
    y_position += 30

# 保存图片
image.save('test_text_image.png')
print("Created test_text_image.png with multiple text lines")