import os
import shutil
from PIL import Image, ImageDraw

src_path = r'C:\Users\yuvar\.gemini\antigravity\brain\25f814ba-003c-4103-a85c-cc703dd2c331\.user_uploaded\media_1793346415680_4ad024c9.png'
dest_asset = 'assets/images/todo_icon.png'
shutil.copyfile(src_path, dest_asset)
print(f"Copied source icon to {dest_asset}")

src = Image.open(src_path).convert('RGBA')

densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

base_res = 'android/app/src/main/res'

for folder, size in densities.items():
    folder_path = os.path.join(base_res, folder)
    os.makedirs(folder_path, exist_ok=True)

    # 1. Square Icon (ic_launcher.png)
    # Using clean white rounded card background with the sticker centered
    corner_radius = int(size * 0.22)
    sq_canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    sq_mask = Image.new('L', (size, size), 0)
    sq_draw = ImageDraw.Draw(sq_mask)
    sq_draw.rounded_rectangle([0, 0, size, size], radius=corner_radius, fill=255)

    white_sq = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    sticker_size = int(size * 0.84)
    sticker_resized = src.resize((sticker_size, sticker_size), Image.Resampling.LANCZOS)
    offset_sq = ((size - sticker_size) // 2, (size - sticker_size) // 2)
    white_sq.paste(sticker_resized, offset_sq, sticker_resized)

    sq_canvas.paste(white_sq, (0, 0), sq_mask)
    sq_path = os.path.join(folder_path, 'ic_launcher.png')
    sq_canvas.save(sq_path, 'PNG')

    # 2. Round Icon (ic_launcher_round.png)
    round_canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    round_mask = Image.new('L', (size, size), 0)
    round_draw = ImageDraw.Draw(round_mask)
    round_draw.ellipse([0, 0, size, size], fill=255)

    white_round = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    round_sticker_size = int(size * 0.78)
    round_sticker_resized = src.resize((round_sticker_size, round_sticker_size), Image.Resampling.LANCZOS)
    offset_round = ((size - round_sticker_size) // 2, (size - round_sticker_size) // 2)
    white_round.paste(round_sticker_resized, offset_round, round_sticker_resized)

    round_canvas.paste(white_round, (0, 0), round_mask)
    round_path = os.path.join(folder_path, 'ic_launcher_round.png')
    round_canvas.save(round_path, 'PNG')

    print(f"Generated {folder}: {size}x{size} (ic_launcher.png & ic_launcher_round.png)")

print("All TO DO launcher icons generated successfully!")
