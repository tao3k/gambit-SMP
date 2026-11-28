# Portable Test Fixtures

These small, hash-checked fixtures let the Python tests run without ignored
`.data/` and `evidence/*-results/` caches. They are not current runtime or
model admissions. The original historical paths and hashes remain in the
Evidence manifests; tests check the retained bytes against those hashes.

`recover-model/` contains parser fixtures derived from the retained TLC logs.
Personal and temporary paths were redacted; these copies are not the original
raw-log evidence and cannot satisfy a current raw-log attestation.

`historical-view-pointers.json` contains only scalar pointer values needed to
exercise retired Scheme rules. Production Evidence loading rejects retired
views regardless of whether a local cache happens to contain their sources.
