#!/usr/bin/env python3
"""Generate PomodoroTimer app icon as 1024x1024 PNG."""
import math
from PIL import Image, ImageDraw

SIZE = 1024
CENTER = SIZE // 2
img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# === Rounded square background ===
bg_r = 220  # corner radius for macOS icon shape
draw.rounded_rectangle([40, 40, SIZE - 40, SIZE - 40], radius=bg_r, fill="#E8383D")

# === Tomato body (large red circle with subtle gradient effect) ===
tomato_cx, tomato_cy = CENTER, CENTER + 30
tomato_r = 340

# Shadow behind tomato
draw.ellipse(
    [tomato_cx - tomato_r + 10, tomato_cy - tomato_r + 15,
     tomato_cx + tomato_r + 10, tomato_cy + tomato_r + 15],
    fill="#B02025"
)
# Main tomato body
draw.ellipse(
    [tomato_cx - tomato_r, tomato_cy - tomato_r,
     tomato_cx + tomato_r, tomato_cy + tomato_r],
    fill="#FF4C4C"
)
# Highlight on tomato
draw.ellipse(
    [tomato_cx - tomato_r + 60, tomato_cy - tomato_r + 40,
     tomato_cx + tomato_r - 60, tomato_cy - 20],
    fill="#FF7070"
)

# === Stem ===
stem_w = 28
stem_h = 100
draw.rounded_rectangle(
    [tomato_cx - stem_w // 2, tomato_cy - tomato_r - stem_h + 30,
     tomato_cx + stem_w // 2, tomato_cy - tomato_r + 50],
    radius=14, fill="#4CAF50"
)

# === Leaf ===
leaf_pts = [
    (tomato_cx, tomato_cy - tomato_r - 20),
    (tomato_cx + 100, tomato_cy - tomato_r - 90),
    (tomato_cx + 60, tomato_cy - tomato_r - 30),
]
draw.polygon(leaf_pts, fill="#66BB6A")
# Mirror leaf
leaf_pts_l = [
    (tomato_cx, tomato_cy - tomato_r - 20),
    (tomato_cx - 80, tomato_cy - tomato_r - 80),
    (tomato_cx - 45, tomato_cy - tomato_r - 25),
]
draw.polygon(leaf_pts_l, fill="#4CAF50")

# === Clock face ===
clock_r = 200
# White clock circle
draw.ellipse(
    [tomato_cx - clock_r, tomato_cy - clock_r,
     tomato_cx + clock_r, tomato_cy + clock_r],
    fill="#FFFFFF"
)
# Inner circle
inner_r = clock_r - 16
draw.ellipse(
    [tomato_cx - inner_r, tomato_cy - inner_r,
     tomato_cx + inner_r, tomato_cy + inner_r],
    fill="#FFF5F5"
)

# === Hour marks ===
for i in range(12):
    angle = math.radians(i * 30 - 90)
    is_major = i % 3 == 0
    outer = inner_r - 8
    inner = inner_r - (38 if is_major else 26)
    w = 10 if is_major else 6
    x1 = tomato_cx + inner * math.cos(angle)
    y1 = tomato_cy + inner * math.sin(angle)
    x2 = tomato_cx + outer * math.cos(angle)
    y2 = tomato_cy + outer * math.sin(angle)
    draw.line([(x1, y1), (x2, y2)], fill="#E8383D", width=w)

# === Clock hands — showing ~25 min (minute hand at 5, hour hand roughly at 12) ===
# Hour hand (short, pointing at 12)
hour_angle = math.radians(-90)
hour_len = 90
hx = tomato_cx + hour_len * math.cos(hour_angle)
hy = tomato_cy + hour_len * math.sin(hour_angle)
draw.line([(tomato_cx, tomato_cy), (hx, hy)], fill="#C62828", width=14)

# Minute hand (long, pointing at 5 = 150 degrees from 12)
min_angle = math.radians(150 - 90)  # 5 o'clock position = 150°
min_len = 140
mx = tomato_cx + min_len * math.cos(min_angle)
my = tomato_cy + min_len * math.sin(min_angle)
draw.line([(tomato_cx, tomato_cy), (mx, my)], fill="#C62828", width=10)

# Center dot
draw.ellipse(
    [tomato_cx - 14, tomato_cy - 14, tomato_cx + 14, tomato_cy + 14],
    fill="#C62828"
)

out_path = "/Users/siyucheng/projects/pomodoro-timer/AppIcon.png"
img.save(out_path, "PNG")
print(f"Icon saved: {out_path}")
