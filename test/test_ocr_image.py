#!/usr/bin/env python3
"""
生成包含文字的测试图片，用于测试OCR功能
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_test_image():
    # 创建一个白色背景的图片
    width, height = 400, 200
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    # 尝试使用系统字体
    try:
        # macOS 系统字体
        font = ImageFont.truetype('/System/Library/Fonts/Arial.ttf', 36)
    except:
        try:
            # 备用字体
            font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 36)
        except:
            # 使用默认字体
            font = ImageFont.load_default()
    
    # 绘制文字
    text = "Hello OCR Test\n测试文字识别\n123456"
    
    # 计算文字位置（居中）
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    # 绘制黑色文字
    draw.multiline_text((x, y), text, fill='black', font=font, align='center')
    
    # 保存图片
    output_path = 'ocr_test_image.png'
    image.save(output_path)
    print(f"测试图片已保存到: {output_path}")
    
    return output_path

if __name__ == "__main__":
    create_test_image()