"""Bounded, integrity-checked local paper cache; no network on a valid hit."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
from urllib.parse import urlparse
from urllib.request import Request, urlopen

from gambit_smp.framework import ROOT
MAX_BYTES = 16 * 1024 * 1024
LOCK = ROOT / "evidence/papers.lock.json"


class EmptyText(ValueError):
    pass


def sha(data):
    return hashlib.sha256(data).hexdigest()


def paper_pins(path, papers, root=ROOT):
    saved = json.loads(path.read_text())
    if saved.get("schema") != "gambit-smp-paper-lock.v1":
        raise ValueError("unsupported paper lock")
    pins = {}
    for pin in saved["papers"]:
        identifier = pin["id"]
        if identifier in pins or not re.fullmatch(r"[0-9a-f]{64}", pin["pdfSha256"]):
            raise ValueError("duplicate or invalid PDF pin")
        notes = Path(pin["notes"])
        target = (root / notes).resolve()
        if (notes.is_absolute() or not notes.parts or notes.parts[0] != "docs" or
                ".." in notes.parts or notes.suffix not in (".md", ".org") or
                not target.is_relative_to(root.resolve() / "docs") or not target.is_file()):
            raise ValueError("tracked Markdown/Org paper notes required")
        pins[identifier] = pin
    for paper in papers:
        pin = pins.get(paper["id"])
        if not pin or pin["url"] != paper["url"]:
            raise ValueError("paper source is missing or differs from lock")
    return pins


def markdown(paper, text):
    # This derived full-text search aid stays ignored; reviewed notes live in Git.
    return (f"# {paper['title']}\n\nSource: {paper['url']}\n\n"
            "Derived PDF extraction, not reviewed research notes.\n\n" +
            text.decode("utf-8").replace("\f", "\n\n---\n\n")).encode("utf-8")


def download(url):
    request = Request(url, headers={"User-Agent": "curl/8.7.1"})
    with urlopen(request, timeout=30) as response:
        if urlparse(response.geturl()).scheme != "https":
            raise ValueError("non-HTTPS paper redirect")
        data = response.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES or not data.startswith(b"%PDF-"):
        raise ValueError("oversized or non-PDF response")
    return data


def extract(pdf):
    result = subprocess.run(["pdftotext", "-layout", str(pdf), "-"],
                            check=True, capture_output=True, timeout=30)
    text = result.stdout.decode("utf-8")
    if not text.strip():
        raise EmptyText("PDF has no extractable text")
    return text.encode("utf-8")


def ocr_scanned(pdf):
    """Explicit, page-bounded fallback; retain no rendered-page cache."""
    info = subprocess.run(["pdfinfo", str(pdf)], check=True, capture_output=True,
                          text=True, timeout=10).stdout
    match = re.search(r"^Pages:\s+(\d+)\s*$", info, re.MULTILINE)
    if not match or not 1 <= int(match[1]) <= 16:
        raise ValueError("OCR requires a known page count from 1 to 16")
    pages = int(match[1])
    text = []
    with tempfile.TemporaryDirectory(prefix="ocr-", dir=pdf.parent) as temporary:
        prefix = Path(temporary) / "page"
        for page in range(1, pages + 1):
            subprocess.run(["pdftoppm", "-f", str(page), "-l", str(page),
                "-r", "150", "-singlefile", "-png", str(pdf), str(prefix)],
                check=True, capture_output=True, timeout=30)
            result = subprocess.run(["tesseract", str(prefix.with_suffix(".png")), "stdout",
                "-l", "eng"], check=True, capture_output=True, timeout=30)
            page_text = result.stdout.decode("utf-8")
            if not page_text.strip():
                raise ValueError("empty OCR page; visual review required")
            text.append(page_text + "\f")
    return "".join(text).encode("utf-8")


def cache(paper, directory, refresh=False, allow_ocr=False, expected_pdf=None):
    identifier, url = paper["id"], paper["url"]
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", identifier):
        raise ValueError("invalid paper identifier")
    if urlparse(url).scheme != "https":
        raise ValueError("paper source must be HTTPS")
    if expected_pdf is not None and not re.fullmatch(r"[0-9a-f]{64}", expected_pdf):
        raise ValueError("invalid PDF pin")
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / identifier
    if target.exists() and not refresh:
        receipt = json.loads((target / "receipt.json").read_text())
        schema = receipt.get("schema")
        derived = "paper.txt" if schema == "gambit-smp-paper-cache.v1" else "paper.md"
        if schema not in ("gambit-smp-paper-cache.v1", "gambit-smp-paper-cache.v2") or receipt["source"] != paper or any(
            sha((target / name).read_bytes()) != receipt["sha256"][name]
            for name in ("paper.pdf", derived)
        ):
            raise ValueError("paper cache identity/integrity mismatch; explicit refresh required")
        if expected_pdf is not None and receipt["sha256"]["paper.pdf"] != expected_pdf:
            raise ValueError("cached PDF differs from tracked pin")
        return receipt, "cached"
    # Validate PDF and extraction before publishing either file or receipt.
    with tempfile.TemporaryDirectory(prefix="paper-", dir=directory) as temporary:
        staging = Path(temporary)
        data = download(url)
        if expected_pdf is not None and sha(data) != expected_pdf:
            raise ValueError("downloaded PDF differs from tracked pin; refresh cannot change identity")
        (staging / "paper.pdf").write_bytes(data)
        extractor = "pdftotext -layout"
        try:
            text = extract(staging / "paper.pdf")
        except EmptyText:
            if not allow_ocr:
                raise
            text = ocr_scanned(staging / "paper.pdf")
            extractor = "pdftoppm 150dpi + tesseract eng; OCR needs visual verification"
        derived = markdown(paper, text)
        (staging / "paper.md").write_bytes(derived)
        receipt = {"schema": "gambit-smp-paper-cache.v2", "source": paper,
                   "sha256": {"paper.pdf": sha(data), "paper.md": sha(derived)},
                   "pdfBytes": len(data), "textBytes": len(text),
                   "extractor": extractor, "pages": text.count(b"\f")}
        (staging / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
        target.mkdir(exist_ok=True)
        for name in ("paper.pdf", "paper.md", "receipt.json"):
            (staging / name).replace(target / name)
    return receipt, "downloaded"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=ROOT / "evidence/papers.json")
    from gambit_smp.artifact_storage import cache_path, runtime_output
    parser.add_argument("--cache", type=Path, default=cache_path(ROOT, "papers"))
    parser.add_argument("--lock", type=Path, default=LOCK,
                        help="tracked source URL/PDF hash and Markdown/Org notes")
    parser.add_argument("--refresh", action="store_true")
    parser.add_argument("--ocr-scanned", action="store_true",
                        help="explicit OCR fallback for scanned PDFs of at most 16 pages")
    args = parser.parse_args()
    args.cache = runtime_output(ROOT, args.cache)
    manifest = json.loads(args.manifest.read_text())
    if manifest["schema"] != "gambit-smp-papers.v1":
        parser.error("unsupported paper manifest")
    identifiers = [p["id"] for p in manifest["papers"]]
    if len(set(identifiers)) != len(identifiers):
        parser.error("duplicate paper identifiers")
    pins = paper_pins(args.lock, manifest["papers"])
    for paper in manifest["papers"]:
        receipt, status = cache(paper, args.cache, args.refresh, args.ocr_scanned,
                                pins[paper["id"]]["pdfSha256"])
        print(f"{paper['id']}: {status}, {receipt['pages']} pages, "
              f"{receipt['pdfBytes']} bytes, SHA256 {receipt['sha256']['paper.pdf']}", flush=True)


if __name__ == "__main__":
    main()
