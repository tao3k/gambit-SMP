# Local Paper Cache

Download primary-source PDFs once and extract locally searchable text:

```sh
uv run --locked gambit-smp papers
rg -n -C 3 'forwarding|termination|contention' .data/papers/*/paper.txt
```

The tracked `evidence/papers.json` lists sources. Ignored `.data/papers/<id>/`
contains `paper.pdf`, layout-preserving `paper.txt`, and a portable receipt
binding the source URL, both SHA-256 digests, sizes and extracted page count.
Ordinary reruns verify cached bytes without network access. Identity or content
drift fails closed; `--refresh` explicitly replaces that cache after successful
download and extraction. Downloads are bounded to 16 MiB and HTTPS, with a
30-second network/extraction timeout. Failed extraction leaves no new cache.
Receipts do not claim publication-version authenticity or a runtime proof.

Poppler's `pdftotext` is required. PDFs and extracted full text are not committed
or uploaded by CI. Removing `.data/papers/` reclaims only this reproducible cache;
it does not remove models, counterexamples or tracked source analysis.

The Gambit design references in `docs/workflow.md` remain separate references:
the historic VM DOI is not silently treated as a current SMP collector paper,
and the author's SMP announcements are not PDFs. Add a verified accessible
author/publisher PDF before including a new Gambit paper in this manifest.
