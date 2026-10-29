"""Build-time continuation of card-system-v2's modular pixel composer.

Python + Pillow are authoring tools only. Game code consumes the existing PNGs.
Geometry/palette/recipe JSON remain editable; no photographs or RNG are inputs.
"""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
CATEGORIES = ("head", "hair", "eyes", "brows", "nose", "mouth", "facial", "shirt")
ORDER = ("head", "shirt", "eyes", "brows", "nose", "mouth", "facial", "hair")


def read(name):
    return json.loads((ROOT / name).read_text(encoding="utf-8-sig"))


class Kit:
    def __init__(self):
        source = read("parts.json")
        self.size = tuple(source["canvas"])
        assert self.size == (96, 96)
        self.parts = {part["id"]: part for part in source["parts"]}
        assert len(self.parts) == len(source["parts"]), "Duplicate part ID"
        self.palettes = read("palettes.json")
        self.recipes = read("recipes.json")["recipes"]

    def colours(self, recipe):
        result = dict(self.palettes["fixed"])
        assert set(recipe["palettes"]) == {"skin", "hair", "shirt"}
        for category, palette in recipe["palettes"].items():
            result.update(self.palettes[category][palette])
        return result

    def layer(self, part_id, colours, layer="front"):
        image = Image.new("RGBA", self.size)
        draw = ImageDraw.Draw(image)
        for command in self.parts[part_id].get(layer, []):
            colour = colours[command["colour"]]
            if command["op"] == "rectangle":
                draw.rectangle(command["box"], fill=colour)
            elif command["op"] == "polygon":
                draw.polygon([tuple(p) for p in command["points"]], fill=colour)
            elif command["op"] == "line":
                draw.line([tuple(p) for p in command["points"]], fill=colour,
                          width=command.get("width", 1))
            else:
                raise ValueError(f"Unknown operation: {command['op']}")
        return image

    def portrait(self, recipe):
        assert set(recipe["parts"]) == set(CATEGORIES), recipe["id"]
        for category, part_id in recipe["parts"].items():
            assert self.parts[part_id]["category"] == category, part_id
        colours, parts = self.colours(recipe), recipe["parts"]
        image = self.layer(parts["hair"], colours, "back")
        for category in ORDER:
            image.alpha_composite(self.layer(parts[category], colours))
        return image

    def check(self):
        assert len({r["id"] for r in self.recipes}) == len(self.recipes)
        for part_id, part in self.parts.items():
            assert part_id and all(c in "abcdefghijklmnopqrstuvwxyz0123456789_" for c in part_id)
            assert part["category"] in CATEGORIES
            for layer in ("front", "back"):
                for command in part.get(layer, []):
                    if command["op"] == "rectangle":
                        box = command["box"]
                        assert len(box) == 4 and box[0] <= box[2] and box[1] <= box[3]
                        points = [box[:2], box[2:]]
                    else:
                        assert command["op"] in ("line", "polygon")
                        points = command["points"]
                    assert all(len(p) == 2 and all(type(v) is int and 0 <= v < 96 for v in p)
                               for p in points), part_id
                    assert type(command.get("width", 1)) is int and 1 <= command.get("width", 1) <= 4
        for recipe in self.recipes:
            image = self.portrait(recipe)
            assert {value for _, value in image.getchannel("A").getcolors()} <= {0, 255}, recipe["id"]
            assert image.getbbox(), recipe["id"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--export", type=Path, help="Explicit output directory for baked portraits")
    parser.add_argument("--parts", type=Path, help="Export reusable transparent front/back piece PNGs")
    parser.add_argument("--only", nargs="*", help="Selected stable card IDs; otherwise all recipes")
    args = parser.parse_args()
    kit = Kit()
    kit.check()
    selected = set(args.only or (r["id"].removeprefix("portrait_") for r in kit.recipes))
    recipes = [r for r in kit.recipes if r["id"].removeprefix("portrait_") in selected]
    assert len(recipes) == len(selected), "Unknown or duplicate selection"
    if args.export:
        args.export.mkdir(parents=True, exist_ok=True)
        for recipe in recipes:
            kit.portrait(recipe).save(args.export / (recipe["id"] + ".png"))
    if args.parts:
        args.parts.mkdir(parents=True, exist_ok=True)
        colours = kit.colours({"palettes": {"skin": "fair", "hair": "brown", "shirt": "white"}})
        for part_id, part in kit.parts.items():
            for layer in ("front", "back"):
                if part.get(layer):
                    kit.layer(part_id, colours, layer).save(args.parts / f"{part_id}_{layer}.png")
    print(f"Validated {len(kit.parts)} modular parts and {len(kit.recipes)} recipes; "
          f"exported {len(recipes) if args.export else 0} portraits.")


if __name__ == "__main__":
    main()
