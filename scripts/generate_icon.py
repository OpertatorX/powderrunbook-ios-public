from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path

S = 2048
img = Image.new('RGB', (S, S), '#111417')
# subtle radial warm glow behind the mark
glow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
for r, a in [(760, 12), (620, 18), (500, 24), (380, 34)]:
    gd.ellipse((S//2-r, S//2-r, S//2+r, S//2+r), fill=(245, 101, 40, a))
glow = glow.filter(ImageFilter.GaussianBlur(90))
img = Image.alpha_composite(img.convert('RGBA'), glow)
d = ImageDraw.Draw(img)
orange = '#F56628'
ivory = '#F8F3EA'
muted = '#596067'
# powder fan: disciplined dot geometry, not a generic lettermark
dots = [
    (600, 530, 34), (740, 575, 31), (880, 620, 28),
    (630, 690, 31), (770, 725, 28), (910, 760, 25),
    (660, 845, 28), (800, 865, 25), (940, 885, 22),
]
for x, y, r in dots:
    d.ellipse((x-r, y-r, x+r, y+r), fill=orange)
# spray nozzle on left
d.rounded_rectangle((315, 430, 560, 650), radius=70, fill=ivory)
d.polygon([(500, 610), (675, 780), (590, 870), (430, 680)], fill=ivory)
d.rounded_rectangle((360, 585, 455, 930), radius=45, fill=ivory)
d.rounded_rectangle((520, 480, 650, 585), radius=35, fill=orange)
# coated panel / run card on right
d.rounded_rectangle((1010, 585, 1695, 1450), radius=120, outline=ivory, width=54)
d.rounded_rectangle((1120, 735, 1585, 850), radius=48, fill=muted)
d.rounded_rectangle((1120, 925, 1470, 1040), radius=48, fill=muted)
# orange QC check as the focal point
d.line((1175, 1230, 1305, 1355, 1545, 1090), fill=orange, width=72, joint='curve')
# bottom track line
d.rounded_rectangle((475, 1570, 1575, 1625), radius=27, fill=ivory)
d.rounded_rectangle((475, 1570, 1010, 1625), radius=27, fill=orange)

out = Path(r'C:\Users\lucbi\Downloads\PowderRunbook-iOS\PowderRunbook\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png')
img = img.convert('RGB').resize((1024, 1024), Image.Resampling.LANCZOS)
img.save(out, quality=95)
print(out)
