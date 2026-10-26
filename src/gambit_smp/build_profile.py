"""Read a pinned Bazel build script as data; never execute shell profile code."""
import re
import shlex
import hashlib
import json


def read_profile(path):
    record = json.loads(path.read_text())
    text = record.get("sourceText")
    if (record.get("schema") != "gerbil-bazel-build-profile.v1"
            or record.get("sourcePath") != "tools/ci/build_source_toolchain.sh"
            or record.get("platform") != "Darwin" or not isinstance(text, str)
            or hashlib.sha256(text.encode()).hexdigest() != record.get("sourceSha256")):
        raise ValueError("typed byte-bound Bazel build profile data required")
    profile = darwin_profile(text)
    standard = record.get("languageStandard")
    if standard is not None:
        if standard != "c23":
            raise ValueError("modern-C managed language standard must be c23")
        # Retain the original Bazel arrays and their digest. This is a typed
        # goal overlay, not fabricated sourceText or a changed base profile.
        # Common CFLAGS reaches both generated Scheme C and runtime C. Putting
        # the standard only in --enable-c-opt misses the separate RTS O3 path.
        profile["profileCflags"] = profile["cflags"]
        profile["cflags"] += " -std=c23"
        profile["requiredGoalOverlay"] = [*profile["requiredGoalOverlay"], "-std=c23"]
        profile["languageStandard"] = standard
    return dict(profile, sourceSha256=record["sourceSha256"])


def darwin_profile(text):
    base = re.findall(r'\bargs=\(([^()]*)\)', text)
    extra = re.findall(r'\bargs\+=\(([^()]*)\)', text)
    # Match the two profile arrays without interpreting expansions or commands.
    if len(base) != 1 or len(extra) != 1:
        raise ValueError("one base and Darwin configure profile required")
    branch = re.search(r'if \[\[ "\$platform" == Darwin \]\]; then\s*'
                       r'export GERBIL_BUILD_AOT_TOOLS=yes\s*args\+=\(([^()]*)\)\s*fi', text)
    if branch is None or branch.group(1) != extra[0]:
        raise ValueError("configure extension must belong to the Darwin branch")
    words = shlex.split(base[0]) + shlex.split(extra[0])
    gerbil_only = ("--prefix=", "--with-gambit=", "--version-string=")
    flags = [word for word in words if not word.startswith(gerbil_only)]
    allowed = {"--enable-march=", "--enable-single-host=0", "--enable-multiple-vms",
               "--enable-smp", "--enable-multiple-threaded-vms", "--enable-c-opt=-O1",
               "--enable-c-opt-rts=yes", "--enable-gcc-opts", "--enable-inline-jumps",
               "--enable-dynamic-clib", "--enable-trust-c-tco"}
    if (not flags or len(flags) != len(set(flags)) or not set(flags) <= allowed
            or not {"--enable-smp", "--enable-multiple-vms"} <= set(flags)
            or 'export CFLAGS="-pipe${CFLAGS:+ $CFLAGS}"' not in text
            or 'if [[ "$platform" == Darwin ]]; then' not in text):
        raise ValueError("audited literal GNU Darwin build profile required")
    overlay = [] if "--enable-multiple-threaded-vms" in flags else ["--enable-multiple-threaded-vms"]
    return {"flags": flags + overlay, "profileFlags": flags,
            "requiredGoalOverlay": overlay, "cflags": "-pipe"}
