"""Download openly licensed marine models; keep source/credit alongside files."""
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "OceanVR asset downloader"}), timeout=40).read()

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        html = get("https://poly.pizza/search/" + sys.argv[1]).decode()
        match = re.search(r'window.__SERVER_APP_STATE__\s*=\s*(.*?)</script>',html)
        for item in json.loads(match.group(1))["initialData"]["result"]:
            print(item["title"], item["publicID"], item["licence"])
    else:
        folder = ROOT / "assets/models/marine"
        folder.mkdir(parents=True, exist_ok=True)
        credits = ["Downloaded models. Mesh unchanged; scale and motion adjusted in game.",
                   "CC BY 3.0: https://creativecommons.org/licenses/by/3.0/",
                   "CC0: https://creativecommons.org/publicdomain/zero/1.0/"]
        models = {"Octopus":"flkOBUVpPHg", "Clownfish":"769fHo3eEB", "Anglerfish":"MRjSlwCjHM",
                  "BlueTang":"TQaMo8GTJl", "Goldfish":"qS6CgsWFAh", "Puffer":"UKHtgpxTOk",
                  "Jellyfish":"dA5osnS0Rzj", "Seal":"428MKgODp0H", "Eel":"dDzthiG8nr9", "Snail":"aZ_cT-AIu2y"}
        for name, public_id in models.items():
            source = "https://poly.pizza/m/" + public_id
            html = get(source).decode()
            match = re.search(r'window.__SERVER_APP_STATE__\s*=\s*(.*?)</script>',html)
            model = json.loads(match.group(1))["initialData"]["model"]
            assert model["Licence"] in ["CC-BY 3.0", "CC0 1.0"]
            if model["Tris"] > 18000:
                print("Skipped high polygon model",name,model["Tris"])
                continue
            data = get("https://static.poly.pizza/" + model["ResourceID"] + ".glb")
            assert data[:4] == b"glTF"
            (folder / (name + ".glb")).write_bytes(data)
            credits.append(f'{name}: {model["Creator"]["Username"]} — {model["Licence"]}\n{source}')
            print(name, model["Tris"], len(data), flush=True)
        (folder / "CREDITS.txt").write_text('\n\n'.join(credits),encoding="utf-8")
        audio = ROOT / "assets/audio/effects"
        (audio / "encounter_monster_cc0.wav").write_bytes(get("https://opengameart.org/sites/default/files/Monster.wav"))
        (audio / "ENCOUNTER_CREDITS.txt").write_text("Monster by mikeask — CC0\nhttps://opengameart.org/content/monster-5\nUsed as fictional giant-animal encounter sound, pitch varied in game.\n",encoding="utf-8")
        print("Downloaded octopus and encounter audio", len(data))
