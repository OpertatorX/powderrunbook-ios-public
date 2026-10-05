from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "screenshots-final-raw"
OUT = ROOT / "store" / "apple" / "screenshot"
FONT_REG = Path(r"C:\Windows\Fonts\segoeui.ttf")
FONT_BOLD = Path(r"C:\Windows\Fonts\segoeuib.ttf")

ACCENT = (245, 102, 40)
INK = (22, 24, 26)
MUTED = (100, 102, 103)
BG_TOP = (249, 247, 241)
BG_BOTTOM = (232, 226, 216)

COPY = {
    "en-US": [
        ("jobs", "SHOP FLOOR FLOW", "Every job.\nOne clean flow.", "Move work from intake to handoff without turning the shop into an ERP project."),
        ("detail", "PROCESS RECORD", "Cure & QC records,\nwhere they belong.", "Keep powder, thickness, cure values and operator notes together on the job."),
        ("inventory", "POWDER TRACEABILITY", "Powder lots,\nalways traceable.", "Track lot number, location and recorded usage beside the work that consumed it."),
        ("overview", "AT A GLANCE", "See the shop\nat a glance.", "Know what is active, what finished and where recorded powder usage is going."),
        ("settings", "PRIVATE BY DESIGN", "Private. Offline.\nBuilt for the floor.", "No account, ads, analytics or cloud upload. Your workshop records stay on device."),
    ],
    "fr-FR": [
        ("jobs", "FLUX ATELIER", "Chaque job.\nUn flux clair.", "Suivez le travail de la réception à la remise client sans déployer un ERP complet."),
        ("detail", "RELEVÉ PROCESS", "Cuisson & contrôle,\nau bon endroit.", "Gardez poudre, épaisseur, valeurs de cuisson et notes opérateur avec le job."),
        ("inventory", "TRAÇABILITÉ POUDRE", "Lots de poudre,\ntoujours traçables.", "Suivez lot, emplacement et consommation relevée avec les jobs qui l'utilisent."),
        ("overview", "EN UN COUP D’ŒIL", "L’atelier,\nen un coup d’œil.", "Voyez les jobs actifs, les derniers terminés et la consommation de poudre relevée."),
        ("settings", "PRIVÉ PAR CONCEPTION", "Privé. Hors ligne.\nPensé atelier.", "Aucun compte, pub, analyse ni cloud. Les données atelier restent sur l’appareil."),
    ],
}

def font(size: int, bold: bool = False):
    path = FONT_BOLD if bold else FONT_REG
    return ImageFont.truetype(str(path), size=size) if path.exists() else ImageFont.load_default()

def gradient(size):
    w, h = size
    strip = Image.new("RGB", (1, h))
    rows = []
    for y in range(h):
        t = y / max(h - 1, 1)
        rows.append(tuple(round(BG_TOP[i] * (1 - t) + BG_BOTTOM[i] * t) for i in range(3)))
    strip.putdata(rows)
    return strip.resize((w, h))

def place_screenshot(canvas, source, box, radius):
    x, y, w, h = box
    shot = Image.open(source).convert("RGB")
    scale = min(w / shot.width, h / shot.height)
    nw, nh = int(shot.width * scale), int(shot.height * scale)
    shot = shot.resize((nw, nh), Image.Resampling.LANCZOS)
    sx, sy = x + (w - nw) // 2, y + (h - nh) // 2

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((sx - 18, sy - 12, sx + nw + 18, sy + nh + 28), radius=radius + 14, fill=(0, 0, 0, 48))
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    canvas.paste(shadow, (0, 0), shadow)

    mask = Image.new("L", (nw, nh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, nw, nh), radius=radius, fill=255)
    canvas.paste(shot, (sx, sy), mask)
    ImageDraw.Draw(canvas).rounded_rectangle((sx, sy, sx + nw, sy + nh), radius=radius, outline=(255, 255, 255), width=3)

def draw_copy(canvas, eyebrow, headline, subtitle, x, y, scale=1.0):
    draw = ImageDraw.Draw(canvas)
    f_eye = font(round(31 * scale), True)
    f_head = font(round(76 * scale), True)
    f_sub = font(round(33 * scale), False)
    draw.text((x, y), eyebrow, font=f_eye, fill=ACCENT)
    y += round(58 * scale)
    draw.multiline_text((x, y), headline, font=f_head, fill=INK, spacing=round(4 * scale))
    hb = draw.multiline_textbbox((x, y), headline, font=f_head, spacing=round(4 * scale))
    y = hb[3] + round(22 * scale)
    draw.multiline_text((x, y), subtitle, font=f_sub, fill=MUTED, spacing=round(7 * scale))

def make_phone(locale, item, index):
    feature, eyebrow, headline, subtitle = item
    canvas = gradient((1290, 2796))
    draw_copy(canvas, eyebrow, headline, subtitle, 86, 92, 1.0)
    place_screenshot(canvas, RAW / locale / "iphone" / f"{feature}.png", (175, 665, 940, 2050), 66)
    out = OUT / locale / "APP_IPHONE_67"
    out.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out / f"{index:02d}.png", optimize=True)

def make_ipad(locale, item, index):
    feature, eyebrow, headline, subtitle = item
    canvas = gradient((2048, 2732))
    draw_copy(canvas, eyebrow, headline, subtitle, 150, 88, 1.22)
    place_screenshot(canvas, RAW / locale / "ipad" / f"{feature}.png", (210, 620, 1628, 2030), 56)
    out = OUT / locale / "APP_IPAD_PRO_3GEN_129"
    out.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out / f"{index:02d}.png", optimize=True)

def main():
    if not RAW.exists():
        raise SystemExit(f"Missing raw screenshots: {RAW}")
    for locale, items in COPY.items():
        for index, item in enumerate(items, 1):
            make_phone(locale, item, index)
            make_ipad(locale, item, index)
            print(locale, index, item[0])

if __name__ == "__main__":
    main()
