#!/usr/bin/env python3
"""
创建包含文字的测试图片用于OCR测试
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_test_image():
    # 创建一个白色背景的图片
    width, height = 200, 100
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    # 尝试使用系统字体，如果没有则使用默认字体
    try:
        # macOS系统字体
        font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 36)
    except:
        try:
            # 备用字体
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 36)
        except:
            # 使用默认字体
            font = ImageFont.load_default()
    
    # 在图片上绘制文字
    text = "123"
    
    # 计算文字位置（居中）
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    # 绘制黑色文字
    draw.text((x, y), text, fill='black', font=font)
    
    # 保存图片
    output_path = 'test_ocr_image.png'
    image.save(output_path)
    print(f"测试图片已保存到: {output_path}")
    
    return output_path

if __name__ == "__main__":
    create_test_image()