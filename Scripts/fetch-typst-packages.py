#!/usr/bin/env python3
"""Downloads the Typst packages remn ships for offline use, with everything they import.

    Scripts/fetch-typst-packages.py

Packages land in inkept/Resources/TypstPackages/preview/<name>/<version>/, the layout the Typst
engine reads. Documentation, examples and tests are left out to keep the app small.
"""
import io
import json
import re
import shutil
import tarfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "inkept" / "Resources" / "TypstPackages" / "preview"
INDEX = "https://packages.typst.org/preview/index.json"

# What people draw in notes: plots, diagrams, circuits, timelines, annotated maths, chemistry, algorithms.
WANTED = [
    "cetz", "cetz-plot", "cetz-venn", "fletcher", "quill", "timeliney", "chronos", "lilaq",
    "mannot", "physica", "unify", "alchemist", "finite", "curryst", "lovelace",
    "gentle-clues", "showybox", "tablem",
]
SKIP_DIRS = {"docs", "doc", "examples", "example", "gallery", "tests", "test", "manual", "screenshots", "assets-docs", ".github"}
SKIP_SUFFIXES = {".pdf", ".md", ".png", ".jpg", ".jpeg", ".gif", ".webp"}
# Manuals and examples written in Typst pull in their own tooling; the app doesn't need them.
DOC_WORDS = ("manual", "example", "readme", "changelog", "gallery", "showcase", "demo", "thumbnail", "docs")
IMPORT = re.compile(r'@preview/([a-z0-9-]+):([0-9]+\.[0-9]+\.[0-9]+)')


def latest_versions():
    index = json.load(urllib.request.urlopen(INDEX))
    latest = {}
    for package in index:
        version = tuple(int(part) for part in package["version"].split("."))
        if package["name"] not in latest or version > latest[package["name"]]:
            latest[package["name"]] = version
    return {name: ".".join(map(str, version)) for name, version in latest.items()}


def fetch(name, version):
    target = DEST / name / version
    if target.exists():
        return target
    url = f"https://packages.typst.org/preview/{name}-{version}.tar.gz"
    for attempt in range(4):
        try:
            data = urllib.request.urlopen(url, timeout=60).read()
            break
        except OSError:
            if attempt == 3:
                raise
    with tarfile.open(fileobj=io.BytesIO(data), mode="r:gz") as archive:
        for member in archive.getmembers():
            parts = Path(member.name).parts
            if any(part in SKIP_DIRS for part in parts[:-1]):
                continue
            if member.isfile() and Path(member.name).suffix.lower() in SKIP_SUFFIXES and not member.name.lower().startswith("license"):
                continue
            stem = Path(member.name).stem.lower()
            if member.isfile() and any(word in stem for word in DOC_WORDS):
                continue
            if (member.isfile() or member.isdir()) and not member.name.startswith(("/", "..")) and ".." not in parts:
                archive.extract(member, target)
    return target


def main():
    versions = latest_versions()
    queue = [(name, versions[name]) for name in WANTED]
    seen = set()
    while queue:
        name, version = queue.pop()
        if (name, version) in seen:
            continue
        seen.add((name, version))
        folder = fetch(name, version)
        print(f"{name} {version}")
        for source in folder.rglob("*.typ"):
            for dependency in IMPORT.findall(source.read_text(errors="ignore")):
                queue.append(dependency)
    total = sum(path.stat().st_size for path in DEST.rglob("*") if path.is_file())
    print(f"{len(seen)} packages, {total / 1_000_000:.1f} MB")


if __name__ == "__main__":
    main()
