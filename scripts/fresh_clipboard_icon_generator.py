#!/usr/bin/env python3
"""
全新简洁剪贴板图标生成器（PNG）
不依赖现有脚本，使用 Pillow 直接绘制极简风格。

设计要点：
- 圆角矩形背景，柔和蓝绿渐变，现代感强
- 纯白剪贴板主体，留白清晰、可识别性强
- 顶部夹子极简造型，小半径圆角
- 三条细线表示内容/流动，采用细腻半透明点缀色
- 轻微阴影与内发光提升精致感
"""

import sys
import os
from pathlib import Path


def ensure_pillow():
    try:
        from PIL import Image  # noqa: F401
        return True
    except Exception:
        print("🔧 正在安装 Pillow…")
        import subprocess
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
            return True
        except subprocess.CalledProcessError:
            print("❌ Pillow 安装失败")
            return False


def draw_linear_gradient_rounded(size, radius, start_rgba, end_rgba):
    """绘制带圆角遮罩的线性渐变背景。"""
    from PIL import Image, ImageDraw

    # 渐变底图
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # 从左上到右下的线性渐变（对角线）
    for i in range(size):
        t = i / (size - 1)
        r = int(start_rgba[0] * (1 - t) + end_rgba[0] * t)
        g = int(start_rgba[1] * (1 - t) + end_rgba[1] * t)
        b = int(start_rgba[2] * (1 - t) + end_rgba[2] * t)
        a = int(start_rgba[3] * (1 - t) + end_rgba[3] * t)
        ImageDraw.Draw(bg).line([(i, 0), (0, i)], fill=(r, g, b, a))

    # 圆角遮罩
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=radius, fill=255)
    bg.putalpha(mask)
    return bg


def draw_clipboard(canvas, size):
    """在画布上绘制极简剪贴板图形。"""
    from PIL import Image, ImageDraw, ImageFilter

    draw = ImageDraw.Draw(canvas)

    # 主体尺寸与位置（相对比）
    body_w = max(4, int(size * 0.56))
    body_h = max(4, int(size * 0.62))
    body_x = (size - body_w) // 2
    body_y = int(size * 0.21)
    body_r = max(2, int(size * 0.04))

    # 阴影层
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([(body_x, body_y), (body_x + body_w, body_y + body_h)],
                         radius=body_r, fill=(0, 0, 0, 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(1, size // 80)))
    canvas.alpha_composite(shadow)

    # 剪贴板主体（纯白）
    draw.rounded_rectangle([(body_x, body_y), (body_x + body_w, body_y + body_h)],
                           radius=body_r, fill=(255, 255, 255, 255))

    # 顶部夹子
    clip_w = int(size * 0.28)
    clip_h = int(size * 0.065)
    clip_x = (size - clip_w) // 2
    clip_y = body_y - int(size * 0.035)
    clip_r = max(2, int(clip_h * 0.45))
    draw.rounded_rectangle([(clip_x, clip_y), (clip_x + clip_w, clip_y + clip_h)],
                           radius=clip_r, fill=(240, 244, 248, 255))

    # 夹子内层点缀
    inner_w = int(clip_w * 0.68)
    inner_h = max(2, int(clip_h * 0.44))
    inner_x = clip_x + (clip_w - inner_w) // 2
    inner_y = clip_y + (clip_h - inner_h) // 2
    draw.rounded_rectangle([(inner_x, inner_y), (inner_x + inner_w, inner_y + inner_h)],
                           radius=max(1, int(inner_h / 2)), fill=(218, 226, 234, 255))

    # 轻微内发光描边增强质感
    # 仅在尺寸足够时绘制内发光，避免负半径与无效矩形
    if body_w > 6 and body_h > 6 and size >= 24:
        inner_radius = max(0, body_r - 2)
        draw.rounded_rectangle(
            [(body_x + 2, body_y + 2), (body_x + body_w - 2, body_y + body_h - 2)],
            radius=inner_radius,
            outline=(255, 255, 255, 100),
            width=2,
        )

    # 剪贴板内容（三条细线，象征文本/数据流）
    line_w = max(2, int(size * 0.008))
    margin_x = int(body_w * 0.10)
    usable_w = body_w - margin_x * 2
    line_x1 = body_x + margin_x
    line_x2 = line_x1 + usable_w

    # 三种点缀色（半透明）
    ink1 = (54, 197, 234, 200)   # 清透蓝
    ink2 = (54, 211, 153, 190)   # 清透绿
    ink3 = (245, 158, 11, 190)   # 清透橙

    y1 = body_y + int(body_h * 0.28)
    y2 = body_y + int(body_h * 0.52)
    y3 = body_y + int(body_h * 0.76)

    draw.rounded_rectangle([(line_x1, y1 - line_w // 2), (line_x2, y1 + line_w // 2)],
                           radius=line_w // 2, fill=ink1)
    draw.rounded_rectangle([(line_x1, y2 - line_w // 2), (line_x2, y2 + line_w // 2)],
                           radius=line_w // 2, fill=ink2)
    draw.rounded_rectangle([(line_x1, y3 - line_w // 2), (line_x2, y3 + line_w // 2)],
                           radius=line_w // 2, fill=ink3)


def generate_icon(size, output_path):
    from PIL import Image

    # 渐变背景（蓝绿清爽渐变）
    radius = int(size * 0.18)
    start = (28, 99, 234, 255)   # 明亮蓝
    end = (20, 184, 166, 255)    # 清爽青绿
    bg = draw_linear_gradient_rounded(size, radius, start, end)

    # 绘制剪贴板
    draw_clipboard(bg, size)

    # 保存
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bg.save(output_path, "PNG")
    return True


def write_macos_contents_json(appiconset_dir: Path):
    import json
    content = {
        "images": [
            {"size": "16x16", "idiom": "mac", "filename": "fresh_icon_16.png", "scale": "1x"},
            {"size": "16x16", "idiom": "mac", "filename": "fresh_icon_32.png", "scale": "2x"},
            {"size": "32x32", "idiom": "mac", "filename": "fresh_icon_32.png", "scale": "1x"},
            {"size": "32x32", "idiom": "mac", "filename": "fresh_icon_64.png", "scale": "2x"},
            {"size": "128x128", "idiom": "mac", "filename": "fresh_icon_128.png", "scale": "1x"},
            {"size": "128x128", "idiom": "mac", "filename": "fresh_icon_256.png", "scale": "2x"},
            {"size": "256x256", "idiom": "mac", "filename": "fresh_icon_256.png", "scale": "1x"},
            {"size": "256x256", "idiom": "mac", "filename": "fresh_icon_512.png", "scale": "2x"},
            {"size": "512x512", "idiom": "mac", "filename": "fresh_icon_512.png", "scale": "1x"},
            {"size": "512x512", "idiom": "mac", "filename": "fresh_icon_1024.png", "scale": "2x"}
        ],
        "info": {"version": 1, "author": "xcode"}
    }
    with open(appiconset_dir / "Contents.json", "w", encoding="utf-8") as f:
        json.dump(content, f, indent=2)


def main():
    print("🎨 全新极简剪贴板图标生成器 (PNG)")
    print("=" * 40)

    if not ensure_pillow():
        return 1

    # 目录
    project_root = Path(__file__).parent.parent
    assets_dir = project_root / "assets" / "icons"
    web_icons_dir = project_root / "web" / "icons"
    appiconset_dir = project_root / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

    # 生成 Web/预览尺寸
    web_sizes = [192, 512, 1024]
    web_success = 0
    for s in web_sizes:
        out_asset = assets_dir / f"clipboard_brand_fresh_{s}.png"
        out_web = web_icons_dir / f"clipboard_brand_fresh_{s}.png"
        print(f"生成 {s}x{s} -> {out_asset.name}")
        if generate_icon(s, out_asset):
            web_success += 1
            try:
                out_web.parent.mkdir(parents=True, exist_ok=True)
                generate_icon(s, out_web)
            except Exception:
                pass
        else:
            print("❌ 失败")

    # 生成 macOS 全尺寸
    mac_sizes = [16, 32, 64, 128, 256, 512, 1024]
    mac_success = 0
    appiconset_dir.mkdir(parents=True, exist_ok=True)
    for s in mac_sizes:
        out_macos = appiconset_dir / f"fresh_icon_{s}.png"
        print(f"生成 macOS {s}x{s} -> {out_macos.name}")
        if generate_icon(s, out_macos):
            mac_success += 1
        else:
            print("❌ 失败")

    # 更新 Contents.json 指向新文件
    write_macos_contents_json(appiconset_dir)

    total = len(web_sizes) + len(mac_sizes)
    done = web_success + mac_success
    print(f"\n📊 总结: 生成成功 {done}/{total}")
    if done == total:
        print("✅ 已更新 AppIcon.appiconset/Contents.json 指向 fresh_icon_* 文件")
        print("👉 下一步：flutter clean && flutter build macos --release")
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())