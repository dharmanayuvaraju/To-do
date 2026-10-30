import os
from PIL import Image, ImageDraw

src_img_path = r"assets/images/hero_star.jpg"
if not os.path.exists(src_img_path):
    src_img_path = r"assets/images/me.jpg"

base_img = Image.open(src_img_path).convert("RGBA")

# Crop to square
w, h = base_img.size
min_dim = min(w, h)
left = (w - min_dim) // 2
top = (h - min_dim) // 2
square_img = base_img.crop((left, top, left + min_dim, top + min_dim))

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
    
    # Standard square icon
    icon = square_img.resize((size, size), Image.Resampling.LANCZOS)
    icon_path = os.path.join(out_dir, "ic_launcher.png")
    icon.save(icon_path, "PNG")
    
    # Round icon with circular mask
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size, size), fill=255)
    
    round_icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    round_icon.paste(icon, (0, 0), mask=mask)
    round_path = os.path.join(out_dir, "ic_launcher_round.png")
    round_icon.save(round_path, "PNG")
    
    print(f"Generated {folder}/ic_launcher.png ({size}x{size})")

print("ALL MIPMAP ICONS GENERATED SUCCESSFULLY!")

