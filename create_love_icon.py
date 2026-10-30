import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_heart_icon(size, is_round=False):
    # Create high-res canvas (4x supersampling for ultra crispness)
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Gradient background
    # Top-left to bottom-right gradient: Coral Rose (#FF4D6D) to Sweet Lavender (#CDB4F6)
    c1 = (255, 77, 109)
    c2 = (178, 112, 230)
    
    # Background shape
    bg_mask = Image.new("L", (s, s), 0)
    bg_draw = ImageDraw.Draw(bg_mask)
    if is_round:
        bg_draw.ellipse((0, 0, s, s), fill=255)
    else:
        radius = int(s * 0.22)
        bg_draw.rounded_rectangle((0, 0, s, s), radius=radius, fill=255)

    # Draw gradient
    for y in range(s):
        ratio = y / s
        r = int(c1[0] * (1 - ratio) + c2[0] * ratio)
        g = int(c1[1] * (1 - ratio) + c2[1] * ratio)
        b = int(c1[2] * (1 - ratio) + c2[2] * ratio)
        draw.line([(0, y), (s, y)], fill=(r, g, b, 255))
    
    # Apply background mask
    bg_img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    bg_img.paste(img, (0, 0), mask=bg_mask)
    img = bg_img

    # Draw 3D-styled stylized heart love symbol in center
    heart_layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    h_draw = ImageDraw.Draw(heart_layer)

    # Parametric heart shape
    center_x = s / 2
    center_y = s * 0.48
    heart_scale = s * 0.021

    points = []
    # 360 points along mathematical heart curve
    for deg in range(0, 360):
        t = math.radians(deg)
        x = 16 * (math.sin(t) ** 3)
        y = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
        px = center_x + x * heart_scale
        py = center_y + y * heart_scale
        points.append((px, py))

    # Shadow
    shadow_layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_layer)
    shadow_points = [(p[0], p[1] + s * 0.04) for p in points]
    s_draw.polygon(shadow_points, fill=(50, 10, 40, 90))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=scale * 3))
    img.paste(shadow_layer, (0, 0), mask=shadow_layer)

    # Main white glowing heart
    h_draw.polygon(points, fill=(255, 255, 255, 255))

    # Soft inner mini heart sparkle
    inner_points = []
    inner_scale = heart_scale * 0.72
    for deg in range(0, 360):
        t = math.radians(deg)
        x = 16 * (math.sin(t) ** 3)
        y = -(13 * math.cos(t) - 5 * math.cos(2*t) - 2 * math.cos(3*t) - math.cos(4*t))
        px = center_x + x * inner_scale
        py = center_y + y * inner_scale
        inner_points.append((px, py))
    h_draw.polygon(inner_points, fill=(255, 245, 250, 255))

    img.paste(heart_layer, (0, 0), mask=heart_layer)

    # Downscale to target size with high quality lanczos antialiasing
    final_img = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_img

densities = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

res_dir = r"android/app/src/main/res"

for folder, size in densities.items():
    out_dir = os.path.join(res_dir, folder)
    os.makedirs(out_dir, exist_ok=True)
    
    # Square icon
    sq = create_heart_icon(size, is_round=False)
    sq.save(os.path.join(out_dir, "ic_launcher.png"), "PNG")
    
    # Round icon
    rd = create_heart_icon(size, is_round=True)
    rd.save(os.path.join(out_dir, "ic_launcher_round.png"), "PNG")
    
    print(f"Generated {folder}: {size}x{size} heart love symbol icon")

print("SUCCESSFULLY GENERATED ALL LOVE SYMBOL LAUNCHER ICONS!")
