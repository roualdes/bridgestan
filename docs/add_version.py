import sys
import json


def new_version(version):
    return {
        "name": version,
        "version": version,
        "url": f"https://wardbrian.github.io/bridgestan/{version}/",
    }


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python add_version.py <version>")
        sys.exit(1)
    version = sys.argv[1]
    with open("_static/switcher.json", "r") as f:
        switcher = json.load(f)
    switcher.append(new_version(version))
    with open("_static/switcher.json", "w") as f:
        json.dump(switcher, f, indent=4)
