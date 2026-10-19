"""Provision an exact upstream revision using verified Git objects, online or offline."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

from gambit_smp.framework import ROOT, digest, relative

MANIFEST = "evidence/runtime-source-provisioning.json"
DEFAULT_CACHE = ".cache/source-cache/gambit.git"


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   stderr=subprocess.STDOUT, text=True, timeout=30).strip()


def input_path(root, name):
    path = relative(root, name)
    if any(part in {".data", ".cache"} for part in path.relative_to(root.resolve()).parts) or not path.is_file():
        raise ValueError("source lock must be a repository input, not a cache")
    return path


def validate(root, manifest=MANIFEST):
    record = json.loads(input_path(root, manifest).read_text())
    lock_path = input_path(root, record["sourceLock"])
    lock = json.loads(lock_path.read_text())
    if (record.get("schema") != "gambit-source-provisioning.v2" or
            digest(lock_path) != record["sourceLockSha256"] or
            lock.get("schema") != "gambit-runtime-source-lock.v1" or
            not re.fullmatch(r"[0-9a-f]{40}", record["revision"]) or
            any(record[key] != lock[key] for key in ("revision", "submodule", "repository")) or
            any(key in record for key in ("bundle", "bundleSha256", "shallowBoundary", "omittedParents")) or
            any(not re.fullmatch(r"[0-9a-f]{64}", record.get(key, ""))
                for key in ("commitSha256", "treeManifestSha256")) or
            not isinstance(record.get("parents"), list) or
            any(not re.fullmatch(r"[0-9a-f]{40}", p) for p in record["parents"]) or
            any(record.get(key) is not False for key in ("networkReproductionChecked",
                "configuredToolchainReproduced", "runtimeAdmitted", "releaseAdmitted"))):
        raise ValueError("invalid source revision binding")
    relative(root, record["submodule"])
    transport = record.get("transportRepository", record["repository"])
    if not isinstance(transport, str) or not transport:
        raise ValueError("invalid source transport repository")
    if git(root, "config", "-f", ".gitmodules", "--get",
           f"submodule.{record['submodule']}.url") != transport:
        raise ValueError("canonical submodule URL drift")
    entry = git(root, "ls-files", "--stage", "--", record["submodule"]).split()
    if entry[:3] != ["160000", record["revision"], "0"]:
        raise ValueError("submodule index does not bind the locked revision")
    return record, lock


def verify_objects(repository, record):
    """Cache location is transport only; the locked commit and tree are authority."""
    revision = record["revision"]
    git(repository, "fsck", "--full", "--no-reflogs")
    for field, args in (("commitSha256", ("cat-file", "commit", revision)),
                        ("treeManifestSha256", ("ls-tree", "-r", "-z", revision))):
        value = subprocess.check_output(["git", "-C", str(repository), *args],
                                        stderr=subprocess.PIPE, timeout=30)
        if hashlib.sha256(value).hexdigest() != record[field]:
            raise ValueError("source object digest drift: " + field)
    parents = [line.split()[1] for line in git(repository, "cat-file", "commit",
               revision).splitlines() if line.startswith("parent ")]
    if parents != record["parents"]:
        raise ValueError("source commit parents drift")


def prepare_cache(root, out, manifest=MANIFEST, *, source=None):
    """Fetch only the pinned revision, or transfer already verified local objects."""
    record, _ = validate(root, manifest)
    transport = record.get("transportRepository", record["repository"])
    out = Path(out).absolute()
    if out.exists():
        raise ValueError("fresh source cache required; existing repository is never modified")
    out.parent.mkdir(parents=True, exist_ok=True)
    if source is not None:
        source = Path(source).resolve(strict=True)
        verify_objects(source, record)
        git(root, "-c", "protocol.file.allow=always", "clone", "--bare", "--no-local",
            source.as_uri(), str(out))
        git(out, "remote", "set-url", "origin", transport)
    else:
        git(root, "init", "--bare", str(out))
        git(out, "-c", "http.sslVerify=true", "fetch", "--no-tags", "--depth=1",
            transport, record["revision"])
        git(out, "update-ref", "refs/heads/pinned-source", record["revision"])
        git(out, "symbolic-ref", "HEAD", "refs/heads/pinned-source")
        git(out, "remote", "add", "origin", transport)
    verify_objects(out, record)
    validate(root, manifest)
    return {"schema": "gambit-source-cache-receipt.v1", "revision": record["revision"],
            "cache": str(out), "sourceTransport": "verified-local-git" if source else "upstream-fetch",
            "networkReproductionChecked": source is None and transport.startswith(
                ("https://", "http://", "ssh://", "git://")), "runtimeAdmitted": False,
            "commitSha256": record["commitSha256"], "treeManifestSha256": record["treeManifestSha256"]}


def initialize(root, manifest=MANIFEST, *, cache=None, offline=False):
    root = root.resolve()
    record, lock = validate(root, manifest)
    transport = record.get("transportRepository", record["repository"])
    checkout = relative(root, record["submodule"])
    if checkout.exists() and (not checkout.is_dir() or any(checkout.iterdir())):
        raise ValueError("fresh unpopulated submodule required; existing checkout is never modified")
    from gambit_smp.artifact_storage import cache_path
    cache = (cache_path(root, DEFAULT_CACHE.removeprefix(".cache/")) if cache is None else Path(cache)).resolve()
    if not cache.exists():
        if offline:
            raise ValueError("offline source cache missing; prepare the pinned objects before disconnecting")
        prepare_cache(root, cache, manifest)
    if git(cache, "rev-parse", "--is-bare-repository") != "true":
        raise ValueError("bare source cache required")
    if git(cache, "config", "--get", "remote.origin.url") != transport:
        raise ValueError("source cache canonical URL drift")
    verify_objects(cache, record)
    # Override transport for this invocation only; keep the canonical URL in .gitmodules.
    git(root, "-c", "protocol.file.allow=always", "-c",
        f"submodule.{record['submodule']}.url={cache.as_uri()}", "submodule", "update", "--init",
        "--", record["submodule"])
    if git(checkout, "rev-parse", "HEAD") != record["revision"]:
        raise ValueError("initialized source revision drift")
    gitdir = Path(git(checkout, "rev-parse", "--absolute-git-dir"))
    if not gitdir.is_relative_to(root):
        raise ValueError("initialized submodule metadata escapes checkout")
    # Git transport carries its own shallow metadata; never manufacture it.
    verify_objects(checkout, record)
    git(checkout, "remote", "set-url", "origin", transport)
    for name, row in lock["files"].items():
        if digest(input_path(root, record["submodule"] + "/" + name)) != row["baseSha256"]:
            raise ValueError("initialized base source digest drift")
    validate(root, manifest)
    return {"schema": "gambit-source-provisioning-receipt.v2",
            "revision": record["revision"], "commitSha256": record["commitSha256"],
            "treeManifestSha256": record["treeManifestSha256"],
            "status": "source-tree-reproduced", "fsckPassed": True, "offline": offline,
            "shallowHistory": git(checkout, "rev-parse", "--is-shallow-repository") == "true",
            "networkReproductionChecked": False,
            "configuredToolchainReproduced": False, "runtimeAdmitted": False,
            "releaseAdmitted": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default=MANIFEST)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--cache", type=runtime_argument, help="verified bare Git object cache; never a source-lock input")
    parser.add_argument("--offline", action="store_true", help="reject a missing cache without network access")
    parser.add_argument("--prepare-cache", type=runtime_argument, help="prepare a fresh portable Git object cache")
    parser.add_argument("--from-repository", type=Path, help="transfer verified local objects instead of fetching upstream")
    args = parser.parse_args()
    try:
        if args.prepare_cache:
            if args.cache or args.offline:
                parser.error("--prepare-cache does not accept --cache or --offline")
            result = prepare_cache(ROOT, args.prepare_cache, args.manifest, source=args.from_repository)
        else:
            if args.from_repository:
                parser.error("--from-repository requires --prepare-cache")
            result = initialize(ROOT, args.manifest, cache=args.cache, offline=args.offline)
        print(json.dumps(result, sort_keys=True))
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f"SOURCE-PROVISION-DENY: {error}\n")


if __name__ == "__main__":
    main()
