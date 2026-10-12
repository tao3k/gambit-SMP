# Reproducible Paper Inputs

Reviewed research records live in Git as Markdown, not in the cache:

- `docs/papers/*.md`: focused protocol notes and source/model boundaries.
- `docs/paper-source-reading-ledger.md`: chapter-level Gambit and memory-model notes.
- `evidence/papers.lock.json`: reviewed PDF URLs, SHA-256 pins and note locations.

The lock validator requires Markdown/Org notes inside `docs/`. Cache paths,
parent-directory traversal and links resolving outside `docs/` are rejected;
renaming a cached TXT extraction to Markdown does not make it a research input.

Download locked primary-source PDFs and derive a searchable Markdown cache:

```sh
uv run --locked gambit-smp papers
uv run --locked gambit-smp papers --manifest evidence/papers-audit-expansion.json
rg -n -C 3 'forwarding|termination|contention' docs/papers .data/papers/*/paper.md
```

The tracked paper manifests list sources; the separate lock pins their bytes.
New ignored `.data/papers/<id>/` entries contain `paper.pdf`, derived `paper.md`
and a portable receipt binding their digests, sizes and extracted page count.
Ordinary reruns verify cached bytes without network access. Identity or content
drift fails closed; even `--refresh` must reproduce the locked PDF hash. Updating
a PDF identity requires a reviewed Git lock change, not a cache overwrite.
Downloads are bounded to 16 MiB and HTTPS, with a
30-second network/extraction timeout. Failed extraction leaves no new cache.
PDF identity is independent of the installed extraction tool's output. Derived
Markdown is disposable; reviewed notes are the versioned model input. Receipts
do not claim publication-version authenticity or a runtime proof.

Poppler's `pdftotext` is required. PDFs and extracted full text are not committed
or uploaded by CI. Removing `.data/papers/` reclaims only this reproducible cache;
it does not remove models, counterexamples or tracked source analysis. Legacy
v1 `paper.txt` caches remain readable only to preserve historical hash-bound
evidence. New caches never create TXT; old receipts are not rewritten as if a
Markdown migration were the original run.

A fresh-directory network replay downloaded all three primary-manifest PDFs to
`.data/paper-replay-001`, matching all Git pins and generating Markdown. The
seven existing cached PDFs also matched the lock. This verifies those observed
downloads, not every historical source/native campaign's reproducibility.

See [source reproduction](research-reproduction.md) for the fixed Gambit gitlink
and the remaining clean-checkout dependencies.

The Gambit design references in `docs/workflow.md` remain separate references:
the historic VM DOI is not silently treated as a current SMP collector paper,
and the author's SMP announcements are not PDFs. Add a verified accessible
author/publisher PDF before including a new Gambit paper in this manifest.
