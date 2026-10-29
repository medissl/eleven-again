"""Local visual-reference helper. Photos stay ignored and never enter the composer/game."""
import argparse
import concurrent.futures
import io
import hashlib
import json
import urllib.request
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source")
    parser.add_argument("board")
    parser.add_argument("picks", nargs="+")
    args = parser.parse_args()
    refs = json.loads((ROOT / args.source).read_text(encoding="utf-8-sig"))
    cache = ROOT / "reference-studies"
    cache.mkdir(exist_ok=True)
    (cache / ".gitignore").write_text("*\n!.gitignore\n", encoding="utf-8")

    def fetch(pick):
        card, index = pick.rsplit(":", 1)
        reference = refs[card][int(index)]
        source_key = hashlib.sha256(reference["image"].encode("utf-8")).hexdigest()[:10]
        path = cache / (pick.replace(":", "_") + "_" + source_key + ".png")
        try:
            if not path.exists():
                with urllib.request.urlopen(reference["image"], timeout=8) as response:
                    data = response.read(12_000_000)
                Image.open(io.BytesIO(data)).convert("RGB").save(path)
            return card, path
        except Exception as error:
            print(card, type(error).__name__, str(error)[:100])
            return card, None

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(fetch, args.picks))
    columns = min(4, len(results))
    board = Image.new("RGB", (columns * 400, ((len(results) + columns - 1) // columns) * 470), "#17251e")
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype(str(ROOT.parents[1] / "assets/ui/matchday/fonts/SourceSans3-Regular.ttf"), 16)
    for i, (card, path) in enumerate(results):
        x, y = i % columns * 400, i // columns * 470
        draw.text((x + 6, y + 7), card, fill="white", font=font)
        if path:
            photo = ImageOps.contain(Image.open(path), (390, 430))
            board.paste(photo, (x + 5, y + 32))
            print(card, "loaded", path.name)
    board.save(cache / args.board)


if __name__ == "__main__":
    main()
