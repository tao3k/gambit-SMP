"""Source-bound REV submission using existing Git, SysML and ASCENT services.

This is not a build executor. Native producers supply their completed receipts;
each SysML delivery component selects its own obligations and five common gates.
The real index and unrelated working changes are never the submission index.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import difflib

from gambit_smp.branch_evidence import (
    archive_sources, canonical_source, content_digest, source_manifest,
)
from gambit_smp.task_processes import run


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write_json(path, value):
    Path(path).write_text(json.dumps(value, indent=2) + "\n")


class RevisionSubmission:
    """Freeze one tested tree, project its model, then submit its admitted cut."""

    def __init__(self, root, repository, workspace, storage, evidence, native):
        self.root, self.repository = Path(root), Path(repository)
        self.workspace, self.storage = Path(workspace), Path(storage)
        self.evidence = Path(evidence)
        self.native = native
        self.framework_support = native.get("qualificationKind") == "framework-support"
        if self.framework_support and self.repository.resolve() != self.root.resolve():
            raise ValueError("framework-support scope is restricted to the framework repository")
        self.environment = dict(os.environ, GIT_OPTIONAL_LOCKS="0",
                                GIT_TERMINAL_PROMPT="0")
        self.storage.mkdir(parents=True, exist_ok=True)
        self.evidence.mkdir(parents=True, exist_ok=True)
        if native.get("complete") is not True:
            raise ValueError("completed native source cut required")
        self.check_native()

    def git(self, *arguments, environment=None, data=None):
        result = run(["git", "--no-optional-locks", "-C", str(self.repository),
                      *arguments], cwd=self.root,
                     env=environment or self.environment, input=data,
                     capture_output=True, timeout=30)
        if result.returncode:
            raise ValueError((result.stderr or result.stdout).decode(errors="replace"))
        return result.stdout

    def check_native(self):
        for field in ("canonicalSources", "artifacts", "generatedArtifacts"):
            if field == "generatedArtifacts" and field not in self.native:
                continue
            if not self.native.get(field):
                raise ValueError("explicit native input and output identities required")
            for name, expected in self.native[field].items():
                path = Path(name)
                if path.is_absolute() or ".." in path.parts:
                    raise ValueError("workspace-relative native identity required")
                if digest(self.workspace / path) != expected:
                    raise ValueError("native source/artifact drift: " + name)

    def stage_qualified_changes(self, paths, *, plan_only=False):
        """Apply an incoming source delta without staging unrelated research.

        Three-way merge pending handwritten index/working content separately.
        Generated working bytes remain untouched; only their qualified blob is
        selected. Check every conflict before performing any mutation.
        """
        base = self.git("rev-parse", "HEAD").decode().strip()
        if base != self.native["baseRevision"]:
            raise ValueError("source staging requires the qualified base")
        old = archive_sources(self.git("archive", base))
        index_before = self.git("ls-files", "--stage", "-z")
        plans = []

        def merge(current, original, incoming, name, role):
            if current == original or current == incoming:
                return incoming
            if incoming == original:
                return current
            if original is None or current is None:
                raise ValueError("untracked/deletion collision: " + name)
            directory = self.storage / "merge" / role / name
            directory.mkdir(parents=True, exist_ok=True)
            files = []
            for label, raw in (("current", current), ("base", original), ("incoming", incoming)):
                path = directory / label
                path.write_bytes(raw)
                files.append(str(path))
            try:
                return self.git("merge-file", "-p", *files)
            except ValueError as error:
                raise ValueError("pending source merge conflict: " + name) from error

        for name in paths:
            path = Path(name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError("repository-relative source path required")
            source, target = self.workspace / path, self.repository / path
            if source.is_symlink() or target.is_symlink() or not source.is_file():
                raise ValueError("regular incoming source required: " + name)
            current = target.read_bytes() if target.exists() else None
            incoming = source.read_bytes()
            original = old.get(name, {}).get("data")
            row = self.git("ls-files", "--stage", "--", name).decode().strip()
            staged = self.git("show", ":" + name) if row else None
            mode = row.split()[0] if row else "100644"
            generated = name in self.native.get("generatedArtifacts", {})
            plans.append((name, current, staged,
                          current if generated else merge(current, original, incoming, name, "working"),
                          incoming if generated else merge(staged, original, incoming, name, "index"),
                          mode, generated, bool(row)))
        # No conflict or collision can leave half an applied source merge.
        for name, current, staged, working, selected, mode, generated, tracked in plans:
            target = self.repository / name
            now = target.read_bytes() if target.exists() else None
            if now != current:
                raise ValueError("concurrent working change before source staging")
        if self.git("ls-files", "--stage", "-z") != index_before:
            raise ValueError("concurrent index change before source staging")
        self.check_native()
        if plan_only:
            patch, records = "*** Begin Patch\n", []
            for name, current, staged, working, selected, mode, generated, tracked in plans:
                blob = self.git("hash-object", "-w", "--stdin", data=selected).decode().strip()
                expected = hashlib.sha256(working).hexdigest() if working is not None else None
                records.append(dict(name=name, blob=blob, mode=mode,
                                    workingSha256=expected, tracked=tracked))
                if generated or current == working:
                    continue
                target = str(self.repository / name)
                if current is None:
                    patch += "*** Add File: " + target + "\n"
                    patch += "".join("+" + line + "\n" for line in working.decode().splitlines())
                else:
                    patch += "*** Update File: " + target + "\n"
                    delta = list(difflib.unified_diff(current.decode().splitlines(keepends=True),
                                                     working.decode().splitlines(keepends=True)))
                    patch += "".join("@@\n" if line.startswith("@@") else line for line in delta[2:])
            return dict(baseRevision=base, indexSha256=hashlib.sha256(index_before).hexdigest(),
                        records=records, patch=patch + "*** End Patch\n")
        for name, current, staged, working, selected, mode, generated, tracked in plans:
            target = self.repository / name
            if not generated and working != current:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(working)
                target.chmod(int(mode, 8) & 0o777)
            blob = self.git("hash-object", "-w", "--stdin", data=selected).decode().strip()
            if tracked:
                self.git("update-index", "--no-skip-worktree", "--", name)
            self.git("update-index", "--add", "--cacheinfo", mode + "," + blob + "," + name)
        return dict(paths=list(paths), pendingGeneratedWorkingBytesPreserved=True)

    def apply_staging_plan(self, plan):
        """Accept source-editor changes; keep source writes outside native runs."""
        if self.git("rev-parse", "HEAD").decode().strip() != plan["baseRevision"]:
            raise ValueError("source editor plan base changed")
        index_changed = hashlib.sha256(self.git("ls-files", "--stage", "-z")).hexdigest() != plan["indexSha256"]
        for row in plan["records"]:
            path = self.repository / row["name"]
            now = digest(path) if path.exists() else None
            if now != row["workingSha256"]:
                raise ValueError("source editor result drift: " + row["name"])
            if index_changed:
                staged = self.git("ls-files", "--stage", "--", row["name"]).decode().split()
                if staged[:3] != [row["mode"], row["blob"], "0"]:
                    raise ValueError("source editor plan index changed")
        self.check_native()
        if index_changed:
            return dict(reused=True, selectedBlobsVerified=True)
        for row in plan["records"]:
            if row["tracked"]:
                self.git("update-index", "--no-skip-worktree", "--", row["name"])
            self.git("update-index", "--add", "--cacheinfo",
                     row["mode"] + "," + row["blob"] + "," + row["name"])

    def qualified_paths(self):
        """Cumulative source cut, independent of the last synchronization delta.

        A reused producer can report only its latest changed paths.  Its exact
        tested tree and generated-product identities remain the authority.
        Native binaries are never inferred to be publishable source products.
        """
        target, base = self.native["targetTree"], self.native["baseRevision"]
        names = self.git("diff", "--name-only", "-z", base, target).decode().split("\0")
        paths = {name for name in names if name}
        for name, expected in self.native.get("generatedArtifacts", {}).items():
            old = run(["git", "--no-optional-locks", "-C", str(self.repository),
                       "show", base + ":" + name], cwd=self.root,
                      capture_output=True, timeout=30)
            if old.returncode or hashlib.sha256(old.stdout).hexdigest() != expected:
                paths.add(name)
        return sorted(paths)

    def prepare(self, paths, profile):
        self.base = self.git("rev-parse", "HEAD").decode().strip()
        if self.base != self.native["baseRevision"]:
            raise ValueError("native producer belongs to another base revision")
        self.branch = self.git("symbolic-ref", "--short", "HEAD").decode().strip()
        self.merge_parent = self.native.get("mergeParent")
        if self.merge_parent:
            resolved = self.git("rev-parse", self.merge_parent + "^{commit}").decode().strip()
            if resolved != self.merge_parent or resolved == self.base:
                raise ValueError("explicit distinct merge parent required")
            self.git("merge-base", self.base, self.merge_parent)
        self.gitdir = Path(self.git("rev-parse", "--absolute-git-dir").decode().strip())
        self.index_digest = digest(self.gitdir / "index")
        self.staged = self.git("ls-files", "--stage", "-z")
        self.working = hashlib.sha256(self.git("diff", "HEAD", "--binary")).hexdigest()
        self.index = self.storage / "submission.index"
        if self.index.exists():
            raise ValueError("fresh alternate submission index required")
        self.index_environment = dict(self.environment, GIT_INDEX_FILE=str(self.index))
        self.git("read-tree", self.base, environment=self.index_environment)
        self.paths = list(paths)
        if not self.paths or len(set(self.paths)) != len(self.paths):
            raise ValueError("unique nonempty source cut required")
        if self.framework_support and set(self.paths) != set(self.native["canonicalSources"]) | set(self.native["artifacts"]):
            raise ValueError("framework support must select exactly its tested sources and evidence artifacts")
        for name in self.paths:
            if Path(name).is_absolute() or ".." in Path(name).parts:
                raise ValueError("repository-relative source path required")
        base = self.source_archive(self.base)
        for name in self.paths:
            path = Path(name)
            if path.is_absolute() or ".." in path.parts:
                raise ValueError("repository-relative source path required")
            source = self.workspace / name
            if not source.exists():
                if name not in base:
                    raise ValueError("deletion must name an existing base path")
                self.git("update-index", "--force-remove", "--", name,
                         environment=self.index_environment)
                continue
            if source.is_symlink():
                raise ValueError("explicit symlink migration contract required")
            raw = source.read_bytes()
            blob = self.git("hash-object", "-w", "--stdin", data=raw).decode().strip()
            mode = base.get(name, {}).get("mode", "100644")
            self.git("update-index", "--add", "--cacheinfo", mode + "," + blob + "," + name,
                     environment=self.index_environment)
        # Generated products are accepted byte-for-byte from their qualified
        # producer. Their emitted whitespace must not be edited by hand.
        handwritten = [name for name in self.paths
                       if name not in self.native.get("generatedArtifacts", {})]
        if handwritten:
            comparison = []
            if self.merge_parent:
                merged = self.git("merge-tree", "--write-tree", self.base,
                                  self.merge_parent).decode().splitlines()[0]
                if merged != self.native.get("targetTree"):
                    raise ValueError("native merge tree differs from actual Git merge")
                comparison = [merged]
            # A normal merge preserves upstream source bytes, including its
            # pre-existing style. Check novel handwritten edits against that
            # merge tree, not against a first-parent-only diff of upstream.
            self.git("diff", "--cached", "--check", *comparison, "--", *handwritten,
                     environment=self.index_environment)
        self.tree = self.git("write-tree", environment=self.index_environment).decode().strip()
        files = source_manifest(self.source_archive(self.tree))
        for name, row in files.items():
            if canonical_source(name) and row["mode"] != "120000":
                if self.framework_support and name not in self.paths:
                    continue
                if digest(self.workspace / name) != row["sha256"]:
                    raise ValueError("submission contains untested canonical input: " + name)
        # The complete inventory is execution custody.  The published source
        # contract keeps reviewed paths plus a digest of the whole Git tree;
        # it can be reproduced from that tree without a private run directory.
        inventory = self.storage / "source-manifest.json"
        write_json(inventory, dict(baseRevision=self.base, tree=self.tree, files=files))
        write_json(self.evidence / "source-manifest.json", dict(
            baseRevision=self.base, tree=self.tree, fileCount=len(files),
            fullManifestSha256=digest(inventory),
            inventoryMethod=("Git archive of exact framework-support paths" if self.framework_support
                             else "branch_evidence.source_manifest(Git archive of tree)"),
            canonicalInputEquivalence=not self.framework_support,
            qualificationScope="framework-support" if self.framework_support else "complete-native-source",
            selected={name: files.get(name) for name in self.paths}))
        self.source = dict(baseRevision=self.base, tree=self.tree, paths=self.paths,
                           manifestSha256=digest(self.evidence / "source-manifest.json"),
                           profileSha256=digest(profile), artifacts=self.native["artifacts"],
                           canonicalInputEquivalence=not self.framework_support,
                           qualificationScope="framework-support" if self.framework_support else "complete-native-source",
                           realIndexSha256=self.index_digest,
                           stagedSha256=hashlib.sha256(self.staged).hexdigest(),
                           workingDiffSha256=self.working, sourceCopies=0,
                           wholeSmpAdmitted=False)
        if "generatedArtifacts" in self.native:
            self.source["generatedArtifacts"] = self.native["generatedArtifacts"]
        if self.merge_parent:
            self.source["mergeParent"] = self.merge_parent
        write_json(self.evidence / "source.json", self.source)
        return self.source

    def source_archive(self, revision):
        if not self.framework_support:
            return archive_sources(self.git("archive", revision))
        names = self.git("ls-tree", "-r", "--name-only", "-z", revision, "--", *self.paths)
        selected = [name.decode() for name in names.split(b"\0") if name]
        return archive_sources(self.git("archive", revision, "--", *selected)) if selected else {}

    def project(self, model, namespace, inputs):
        text = (self.root / model).read_text()
        names = re.findall(r"part (\w+):Need \{", text)
        if not names:
            raise ValueError("SysML delivery needs required")
        queries = {field: namespace + "::" + field
                   for field in ("scope", "stage", "formalDuty")}
        for field in ("fields", "allRevisions", "rule", "matrixRequired", "matrixFields", "matrixKinds", "matrixRule",
                      "commitUnitRequired", "supportSurfaces", "supportFiles", "deliveryRule", "deliveryRegistry",
                      "derivedAuditFiles", "publicationPolicy"):
            queries["comment." + field] = "GambitCommitGates::revisionAudit." + field
        for field in ("kind", "result", "progressDelta", "supportPaths"):
            queries["unit." + field] = namespace + "::submission." + field
        for field in ("sourceCases", "requiredCases"):
            if re.search(r"attribute\s+" + field + r"\s*:", text):
                queries["unit." + field] = namespace + "::" + field
        for name in names:
            for field in ("id", "gate.id", "method", "artifact", "scope"):
                queries[name + "." + field] = namespace + "::" + name + "." + field
        for name in ("tests", "learning", "process", "models", "questions"):
            for field in ("id", "purpose"):
                queries["gate." + name + "." + field] = "GambitCommitGates::" + name + "." + field
        self.model_inputs = {name: digest(self.root / name)
                             for name in dict.fromkeys([*inputs, model])}
        argv = [shutil.which(os.environ.get("SYSML", "sysml")), "-strict", "-validate", "-json"]
        for query in queries.values():
            argv += ["-e", query]
        result = run([*argv, *self.model_inputs], cwd=self.root,
                     capture_output=True, text=True, timeout=60)
        (self.storage / "sysml.stdout").write_text(result.stdout)
        if result.returncode:
            raise ValueError("native SysML failed: " + result.stdout[:2500])
        parsed = json.loads(result.stdout)
        values = [json.loads(line[4:]) for line in parsed["output"] if line.startswith("  = ")]
        if parsed["exit"] or len(values) != len(queries):
            raise ValueError("complete native SysML projection required")
        self.values = dict(zip(queries, values))
        if self.framework_support:
            policy = self.values["comment.publicationPolicy"]
            path = Path(policy)
            if path.is_absolute() or ".." in path.parts or ".cache" in path.parts:
                raise ValueError("repository publication policy required")
            self.model_inputs[policy] = digest(self.root / path)
            result = run([shutil.which(os.environ.get("SYSML", "sysml")), "-strict", "-validate", "-json",
                          "-e", "GambitResearchStorage::policy.maxMetadataBytes", *self.model_inputs],
                         cwd=self.root, capture_output=True, text=True, timeout=60)
            parsed = json.loads(result.stdout) if not result.returncode else {}
            values = [json.loads(line[4:]) for line in parsed.get("output", []) if line.startswith("  = ")]
            if result.returncode or parsed.get("exit") or len(values) != 1 or type(values[0]) is not int or values[0] <= 0:
                raise ValueError("native documentary publication bound required")
            self.values["comment.maxMetadataBytes"] = values[0]
            with (self.storage / "sysml.stdout").open("a") as output:
                output.write("\n" + result.stdout)
        if self.values["unit.kind"] == "integration":
            # Resolve the registry from native SysML; never maintain a second
            # Python list of result IDs or their required obligations.
            registry = self.values["comment.deliveryRegistry"]
            if registry not in self.model_inputs:
                raise ValueError("integration registry and dependencies must be projected inputs")
            registry_text = (self.root / registry).read_text()
            required = {}
            for member in re.findall(r"part (\w+):Need \{", registry_text):
                for field in ("id", "result.id"):
                    required["resultNeed." + member + "." + field] = "GambitModernCOutcomes::" + member + "." + field
            for member in re.findall(r"part (\w+):Depends \{", registry_text):
                for field in ("predecessor.id", "successor.id"):
                    required["resultEdge." + member + "." + field] = "GambitModernCOutcomes::" + member + "." + field
            argv = [shutil.which(os.environ.get("SYSML", "sysml")), "-strict", "-validate", "-json"]
            for expression in required.values():
                argv += ["-e", expression]
            result = run([*argv, *self.model_inputs], cwd=self.root, capture_output=True, text=True, timeout=60)
            with (self.storage / "sysml.stdout").open("a") as output:
                output.write("\n" + result.stdout)
            if result.returncode:
                raise ValueError("native delivery registry projection failed: " + result.stdout[:2500])
            parsed = json.loads(result.stdout)
            values = [json.loads(line[4:]) for line in parsed["output"] if line.startswith("  = ")]
            if parsed["exit"] or not required or len(values) != len(required):
                raise ValueError("complete native delivery registry projection required")
            self.values.update(zip(required, values))
        self.need_names = names
        write_json(self.evidence / "model-contract.json", dict(inputs=self.model_inputs,
                   values=self.values, nativeOutputSha256=digest(self.storage / "sysml.stdout")))
        return self.values

    def delivery_contract(self):
        """Bind a complete integration or a strictly non-runtime support cut.

        Receipt contents still require source/native review; this enforces their
        identity, completeness and custody, not the truth of arbitrary JSON.
        """
        p = getattr(self, "values", {})
        required = ("unit.kind", "unit.result", "unit.progressDelta", "unit.supportPaths")
        if p.get("comment.commitUnitRequired") is not True or any(k not in p for k in required):
            raise ValueError("explicit SysML submission unit required; five gates alone are insufficient")
        kind, target, progress = (p["unit." + k] for k in ("kind", "result", "progressDelta"))
        if kind not in {"integration", "support"} or type(progress) is not int:
            raise ValueError("invalid SysML submission unit")
        if self.framework_support and kind != "support":
            raise ValueError("framework-support qualification cannot authorize runtime integration")
        changed = self.git("diff", "--name-only", "-z", self.base, self.tree).decode().split("\0")
        changed = sorted(n for n in changed if n)
        contract = dict(kind=kind, result=target, progressDelta=progress,
                        changedPaths=changed, requirements=[], evidence={})
        if kind == "support":
            if target != "" or progress != 0:
                raise ValueError("support correction cannot claim an integration result or progress")
            allowed = p["unit.supportPaths"].split(";") if p["unit.supportPaths"] else []
            surfaces = tuple(x for x in p["comment.supportSurfaces"].split(";") if x)
            files = p["comment.supportFiles"].split(";")
            for name in allowed:
                path = Path(name)
                if (path.is_absolute() or ".." in path.parts or any(c in name for c in "*?[]")
                        or str(path) != name or not (name.startswith(surfaces) or name in files)):
                    raise ValueError("support path is not an exact non-runtime surface: " + name)
            if not set(changed) <= set(allowed):
                raise ValueError("runtime or undeclared path cannot enter a support correction")
            return contract
        if progress != 1 or p["unit.supportPaths"]:
            raise ValueError("integration must deliver one whole result, without a support-path escape")
        edges = [(value, p[key.replace("predecessor.id", "successor.id")])
                 for key, value in p.items() if key.startswith("resultEdge.") and key.endswith("predecessor.id")]
        members = {target}
        while True:
            expanded = members | {a for a, b in edges if b in members}
            if expanded == members:
                break
            members = expanded
        needs = {value for key, value in p.items() if key.startswith("resultNeed.") and key.endswith(".id")
                 and not key.endswith("result.id") and p[key[:-2] + "result.id"] in members}
        own = {value for key, value in p.items() if key.startswith("resultNeed.") and key.endswith(".id")
               and not key.endswith("result.id") and p[key[:-2] + "result.id"] == target}
        if not own or not p.get("unit.sourceCases") or not p.get("unit.requiredCases"):
            raise ValueError("whole integration result and source/native cases required")
        needs |= {"source:" + x for x in p["unit.sourceCases"].split(";") if x}
        needs |= {"native:" + x for x in p["unit.requiredCases"].split(";") if x}
        runtime = [n for n in changed if n.startswith(("lib/", "include/", "gsc/"))
                   and not n.endswith(("makefile.in", "makefile"))
                   and n not in self.native.get("generatedArtifacts", {})]
        if not runtime:
            raise ValueError("integration progress requires an actual runtime/generator responsibility replacement")
        contract.update(requirements=sorted(needs), runtimePaths=runtime)
        name = self.native.get("deliveryEvidence")
        path = Path(name) if isinstance(name, str) else None
        if (path is None or path.is_absolute() or ".." in path.parts or ".cache" in path.parts
                or not (self.root / path).is_file()
                or not (self.root / path).resolve().is_relative_to(self.root.resolve())):
            raise ValueError("durable complete-delivery evidence required")
        packet = json.loads((self.root / path).read_text())
        expected = dict(sourceTree=self.tree, baseRevision=self.base,
                        profileSha256=self.source["profileSha256"], result=target)
        if any(packet.get(k) != v for k, v in expected.items()):
            raise ValueError("delivery evidence belongs to another source/result/profile")
        observations = packet.get("observations", [])
        observed = [row.get("requirement") for row in observations]
        if len(observed) != len(set(observed)) or set(observed) != needs:
            raise ValueError("complete result/predecessor/component requirements must be observed exactly once")
        evidence = {str(path): digest(self.root / path)}
        for row in observations:
            artifact = Path(row["artifact"])
            if (artifact.is_absolute() or ".." in artifact.parts or ".cache" in artifact.parts
                    or not (self.root / artifact).is_file()
                    or not (self.root / artifact).resolve().is_relative_to(self.root.resolve())
                    or row.get("status") != "pass" or digest(self.root / artifact) != row.get("sha256")):
                raise ValueError("missing, failed or changed delivery obligation evidence")
            receipt = json.loads((self.root / artifact).read_text())
            if (receipt.get("complete") is not True or any(receipt.get(k) != v for k, v in expected.items())
                    or row["requirement"] not in receipt.get("requirements", [])):
                raise ValueError("source-bound complete obligation receipt required")
            evidence[str(artifact)] = row["sha256"]
        contract.update(evidence=evidence, observations=observations)
        return contract

    def prepare_audit(self, report):
        """Freeze the model-required, human-reviewed REV comment before admission.

        The narrative is not another proof engine. ASCENT still requires actual
        scoped observations. This binds what the reviewer saw to what Git will
        publish, including the checklist and remaining gaps for a small REV.
        """
        values = getattr(self, "values", {})
        if values.get("comment.allRevisions") is not True:
            raise ValueError("native SysML comment contract required for every REV")
        fields = values.get("comment.fields", "").split(",")
        if not fields or any(not field for field in fields) or len(fields) != len(set(fields)):
            raise ValueError("complete SysML REV comment fields required")
        if not isinstance(report, dict) or set(report) != set(fields) | {"matrix"}:
            raise ValueError("REV audit must supply every model-required field")
        if any(not isinstance(report[field], str) or not report[field].strip() for field in fields):
            raise ValueError("REV audit fields must contain explicit review text")
        delivery = self.delivery_contract()
        from gambit_smp.revision_matrix import normalize_matrix
        if values.get("comment.matrixRequired") is not True:
            raise ValueError("native SysML matrix contract required")
        matrix = normalize_matrix(self.root, report["matrix"], self.source,
            values["comment.matrixFields"].split(","),
            values["comment.matrixKinds"].split(","))
        checklist = Path(report["checklist"].split("#", 1)[0])
        if (checklist.is_absolute() or ".." in checklist.parts or ".cache" in checklist.parts
                or checklist.suffix != ".org"
                or not (self.root / checklist).is_file()
                or not (self.root / checklist).resolve().is_relative_to(self.root.resolve())):
            raise ValueError("repository Org checklist required; cache locators are not audit assets")
        anchor = report["checklist"].partition("#")[2]
        if anchor and len(re.findall(r"(?m)^\s*:(?:CUSTOM_ID|ID):\s*" + re.escape(anchor) + r"\s*$",
                                     (self.root / checklist).read_text())) != 1:
            raise ValueError("REV checklist requires one real Org ID anchor")
        self.audit_path = self.evidence / "comment.json"
        write_json(self.audit_path, dict(baseRevision=self.base, tree=self.tree,
            profileSha256=self.source["profileSha256"],
            manifestSha256=self.source["manifestSha256"],
            checklistSha256=digest(self.root / checklist),
            fields={field: report[field].strip() for field in fields}, matrix=matrix,
            delivery=delivery))
        return digest(self.audit_path)

    def audit_comment(self, expected_digest):
        if not getattr(self, "audit_path", None) or digest(self.audit_path) != expected_digest:
            raise ValueError("reviewed REV audit changed after admission")
        report = json.loads(self.audit_path.read_text())
        checklist = self.root / report["fields"]["checklist"].split("#", 1)[0]
        if not checklist.is_file() or digest(checklist) != report["checklistSha256"]:
            raise ValueError("reviewed REV checklist changed after audit preparation")
        if (report["tree"] != self.tree or report["baseRevision"] != self.base
                or report["profileSha256"] != self.source["profileSha256"]
                or report["manifestSha256"] != self.source["manifestSha256"]):
            raise ValueError("REV audit belongs to another source cut")
        from gambit_smp.revision_matrix import normalize_matrix, render_matrix
        verified = normalize_matrix(self.root, report["matrix"]["input"], self.source,
            self.values["comment.matrixFields"].split(","),
            self.values["comment.matrixKinds"].split(","))
        if verified != report["matrix"]:
            raise ValueError("reviewed REV matrix evidence changed")
        if self.delivery_contract() != report.get("delivery"):
            raise ValueError("reviewed complete-delivery contract changed")
        lines = ["REV audit", "", "Base: " + self.base, "Tree: " + self.tree,
                 "Profile-SHA256: " + report["profileSha256"],
                 "Source-manifest-SHA256: " + report["manifestSha256"],
                 "Checklist-SHA256: " + report["checklistSha256"],
                 "Audit-SHA256: " + expected_digest]
        unit = report["delivery"]
        lines += ["Submission-unit: " + unit["kind"],
                  "Integration-result: " + (unit["result"] or "none"),
                  "Progress-delta: " + str(unit["progressDelta"]),
                  "Required-delivery-obligations: " + str(len(unit["requirements"]))]
        for field, value in report["fields"].items():
            lines += ["", field.capitalize() + ":", value]
        lines += ["", "Matrix-SHA256: " + content_digest(report["matrix"]),
                  render_matrix(report["matrix"])]
        return "\n".join(lines) + "\n"

    def check_custody(self):
        self.check_native()
        if self.git("rev-parse", "HEAD").decode().strip() != self.base:
            raise ValueError("branch advanced after source freeze")
        if self.git("symbolic-ref", "--short", "HEAD").decode().strip() != self.branch:
            raise ValueError("branch changed after source freeze")
        if digest(self.gitdir / "index") != self.index_digest or self.git("ls-files", "--stage", "-z") != self.staged:
            raise ValueError("concurrent staging changed; preserve it")
        if hashlib.sha256(self.git("diff", "HEAD", "--binary")).hexdigest() != self.working:
            raise ValueError("concurrent working changes; preserve them")
        for name, expected in self.model_inputs.items():
            if digest(self.root / name) != expected:
                raise ValueError("model changed after projection")

    def admit(self):
        """Evaluate the shared policy; absence/staleness controls use real rules."""
        from gambit_smp.ascent_program import load_catalog, query
        if not getattr(self, "audit_path", None):
            raise ValueError("reviewed REV audit required before ASCENT admission")
        audit_digest = digest(self.audit_path)
        self.audit_comment(audit_digest)
        p = self.values
        needs = [[p[name + "." + field]
                  for field in ("id", "gate.id", "method", "artifact", "scope")]
                 for name in self.need_names]
        artifacts = {artifact: digest(self.root / artifact)
                     for _, _, _, artifact, _ in needs}
        for _, _, method, artifact, _ in needs:
            if method in {"native", "formal"}:
                value = json.loads((self.root / artifact).read_text())
                if value.get("complete") is not True:
                    raise ValueError("required native/formal evidence incomplete")
        missing = next(row[0] for row in needs
                       if row[1] == "tests" and row[2] == "native")
        policy = self.root / "dev/modeling/ascent/commit-admission.rules.scm"
        context = self.root / "dev/modeling/ascent/commit-context.rules.scm"
        for path in (context, policy):
            artifacts[str(path.relative_to(self.root))] = digest(path)
        head, tree = self.base, self.tree
        manifest, profile = self.source["manifestSha256"], self.source["profileSha256"]
        case = str(self.evidence.relative_to(self.root))
        missing_obligations = {"missing-obligation:" + row[0]: row[0] for row in needs}
        report = json.loads(self.audit_path.read_text())
        matrix = report["matrix"]
        unit = self.delivery_contract()
        artifacts.update(unit["evidence"])
        for path, expected in matrix["evidence"].items():
            if digest(self.root / path) != expected:
                raise ValueError("reviewed REV matrix evidence changed")
            artifacts[path] = expected
        missing_audit = {"missing-audit:" + field: field for field in report["fields"]}
        scenarios = ("current", "missing-native", "stale-tree", "wrong-artifact",
                     "wrong-profile", "model-only", *missing_obligations,
                     "missing-audit-packet", "stale-audit-tree", *missing_audit,
                     "missing-matrix", "stale-matrix", "missing-matrix-row", "missing-matrix-evidence",
                     "missing-submission-unit", "support-progress", "unapproved-support-path",
                     "fragment-integration", *["missing-delivery:" + x for x in unit["requirements"]],
                     *(["stale-delivery-tree"] if unit["kind"] == "integration" else []))
        rows = dict(
            commitStudyFact=[[case]], commitPolicyFact=[[digest(policy)]],
            commitGateFact=[[p["gate." + name + ".id"], p["gate." + name + ".purpose"]]
                            for name in ("tests", "learning", "process", "models", "questions")],
            commitNeedFact=needs,
            commitArtifactFact=[[name, value] for name, value in artifacts.items()],
            commitEvidenceFact=[[row[0], artifacts[row[3]], "selected-source-and-native"]
                                for row in needs],
            commitScenarioClassFact=[], commitSourceFact=[[head, tree, manifest, profile]],
            commitCandidateFact=[], commitObservationFact=[],
            commitAuditRequiredFact=[[field] for field in report["fields"]],
            commitAuditPacketFact=[], commitAuditFieldFact=[],
            commitMatrixRequiredFact=[["matrix"]],
            commitMatrixFieldRequiredFact=[[field] for field in self.values["comment.matrixFields"].split(",")],
            commitMatrixPacketFact=[], commitMatrixRowFact=[], commitMatrixFieldFact=[],
            commitMatrixRefFact=[], commitMatrixValueValidFact=[],
            commitUnitFact=[], commitUnitNeedFact=[[unit["result"], x] for x in unit["requirements"]],
            commitUnitEvidenceFact=[], commitUnitPathViolationFact=[], commitUnitRuntimeFact=[],
            controlExpectReadyFact=[["current"]],
            controlExpectBlockedFact=[[name] for name in scenarios[1:]],
        )
        for scenario in scenarios:
            if scenario != "missing-submission-unit":
                kind, target, progress = unit["kind"], unit["result"], unit["progressDelta"]
                if scenario == "support-progress":
                    kind, target, progress = "support", "", 1
                if scenario == "fragment-integration":
                    kind, target, progress = "integration", "undeclared-fragment", 1
                rows["commitUnitFact"].append([scenario, kind, target, str(progress)])
            if scenario == "unapproved-support-path":
                rows["commitUnitPathViolationFact"].append([scenario, "lib/unapproved-runtime.c"])
            for path in unit.get("runtimePaths", []):
                rows["commitUnitRuntimeFact"].append([scenario, path])
            for observation in unit.get("observations", []):
                if scenario == "missing-delivery:" + observation["requirement"]:
                    continue
                rows["commitUnitEvidenceFact"].append([
                    scenario, head, "different" if scenario == "stale-delivery-tree" else tree,
                    manifest, profile, unit["result"], observation["requirement"],
                    observation["artifact"], observation["sha256"]])
            rows["commitScenarioClassFact"].append([
                scenario, "model-only" if scenario == "model-only" else "selected-source-and-native"])
            rows["commitCandidateFact"].append([
                scenario, head, "different" if scenario == "stale-tree" else tree,
                manifest, "different" if scenario == "wrong-profile" else profile])
            if scenario != "missing-audit-packet":
                fields = {field: text for field, text in report["fields"].items()
                          if field != missing_audit.get(scenario)}
                report_digest = (content_digest(fields) if scenario in missing_audit else audit_digest)
                rows["commitAuditPacketFact"].append([
                    scenario, head, "different" if scenario == "stale-audit-tree" else tree,
                    manifest, profile, report_digest])
                for field, text in fields.items():
                    row = [report_digest, field, text]
                    if row not in rows["commitAuditFieldFact"]:
                        rows["commitAuditFieldFact"].append(row)
            if scenario not in {"missing-matrix", "missing-audit-packet"}:
                mh = content_digest(matrix) if scenario == "current" else content_digest([matrix, scenario])
                ah = "wrong-audit" if scenario == "stale-matrix" else report_digest
                if scenario != "missing-audit-packet":
                    rows["commitMatrixPacketFact"].append([scenario, ah, mh])
                for metric in ([] if scenario == "missing-matrix-row" else matrix["rows"]):
                    mid = metric["id"]
                    rows["commitMatrixRowFact"].append([mh, mid, metric["kind"], metric["unit"]])
                    rows["commitMatrixValueValidFact"].append([mh, mid])
                    for field in self.values["comment.matrixFields"].split(","):
                        rows["commitMatrixFieldFact"].append([mh, mid, field, content_digest(metric[field])])
                    for path, expected in ([] if scenario == "missing-matrix-evidence" else metric["evidenceSha256"].items()):
                        rows["commitMatrixRefFact"].append([mh, mid, path, expected])
            for obligation, _, method, artifact, scope in needs:
                if scenario == "missing-native" and obligation == missing:
                    continue
                if missing_obligations.get(scenario) == obligation:
                    continue
                observed = ("different" if scenario == "wrong-artifact"
                            and obligation == needs[0][0] else artifacts[artifact])
                rows["commitObservationFact"].append([
                    scenario, head, tree, manifest, profile, obligation, method,
                    artifact, observed, scope, "pass", obligation, artifacts[artifact]])
        queries = {name: name for name in ("commitReady", "commitCovered", "commitMissing",
                                          "commitGateReady", "commitAuditMissing", "commitMatrixMissing", "controlFailure",
                                          "commitUnitReady", "commitUnitGap", "commitProgressReady")}
        pairs = [("target-model-bundle-sha256", content_digest(self.model_inputs)),
                 ("native-output-sha256", digest(self.storage / "sysml.stdout")),
                 ("planner-dsl-sha256", digest(policy))]
        facts = dict(rows, clue=[["context", "selected-submission", case, "source", "llm", "review"]],
                     factor=[["context", "selected-submission", key, value] for key, value in pairs],
                     binding=[[key, value] for key, value in pairs])
        write_json(self.storage / "policy-facts.json", facts)
        catalog = load_catalog(context, policy)
        # These maintained files contain relation/rule bodies also used by
        # existing Evidence constructors. Supply the native fragment envelope;
        # observations remain session data, never interpolated Scheme source.
        catalog["sourceTexts"] = ["(ascent-fragment\n" + text + "\n)"
                                  for text in catalog["sourceTexts"]]
        metrics = {}
        result = query(facts, catalog, queries, metrics=metrics)
        answers = {name: [list(row) for row in value] for name, value in result.items()}
        write_json(self.storage / "answers.json", answers)
        write_json(self.storage / "ascent-metrics.json", metrics)
        covered = [row for row in answers["commitCovered"] if row[0] == "current"]
        if (answers["commitReady"] != [["current"]] or answers["controlFailure"]
                or len(covered) != len(needs)
                or [row for row in answers["commitUnitReady"] if row[0] == "current"] != [["current"]]
                or answers["commitProgressReady"] != ([["current", unit["result"]]] if unit["kind"] == "integration" else [])):
            raise ValueError("selected REV or rejection controls failed shared ASCENT policy")
        self.check_custody()
        self.audit_comment(audit_digest)
        self.admission = dict(tree=tree, baseRevision=head, artifacts=artifacts,
                              answers=answers, negativeControls=len(scenarios)-1,
                              gateReady=[row[1] for row in answers["commitGateReady"]
                                         if row[0] == "current"],
                              modelInputs=self.model_inputs, commitAdmitted=True,
                              auditSha256=audit_digest, matrixSha256=content_digest(matrix),
                              deliveryContract=unit, progressDelta=unit["progressDelta"],
                              wholeSmpAdmitted=False)
        write_json(self.evidence / "admission.json", self.admission)
        return self.admission

    def commit(self, message, admission):
        if (admission is not getattr(self, "admission", None)
                or admission.get("commitAdmitted") is not True or admission.get("tree") != self.tree):
            raise ValueError("matching ASCENT admission required")
        comment = self.audit_comment(admission.get("auditSha256"))
        self.check_custody()
        for name, expected in admission["artifacts"].items():
            if digest(self.root / name) != expected:
                raise ValueError("admission artifact changed")
        if self.git("write-tree", environment=self.index_environment).decode().strip() != self.tree:
            raise ValueError("submission index changed")
        publication_tree = self.tree
        if self.framework_support:
            # A framework reviews its own source tree. Its generated review
            # envelope cannot contain its own commit hash. Add only the five
            # model-declared JSON outputs after source admission, preserving
            # the separately bound tested subject tree and unchanged code.
            names = self.values["comment.derivedAuditFiles"].split(";")
            if set(names) != {"source.json", "source-manifest.json", "model-contract.json", "comment.json", "admission.json"}:
                raise ValueError("only fixed generated audit metadata may extend framework publication")
            metadata = []
            for name in names:
                path = self.evidence / name
                raw = path.read_bytes()
                if len(raw) > self.values["comment.maxMetadataBytes"]:
                    raise ValueError("audit metadata exceeds documentary publication bound")
                json.loads(raw)
                relative = str(path.relative_to(self.root))
                blob = self.git("hash-object", "-w", "--stdin", data=raw).decode().strip()
                self.git("update-index", "--add", "--cacheinfo", "100644," + blob + "," + relative,
                         environment=self.index_environment)
                metadata.append(relative)
            publication_tree = self.git("write-tree", environment=self.index_environment).decode().strip()
            extra = self.git("diff", "--name-only", "-z", self.tree, publication_tree).decode().split("\0")
            if not set(x for x in extra if x) <= set(metadata):
                raise ValueError("framework audit envelope changed tested source")
        body = self.storage / "message.txt"
        body.write_text(message.rstrip() + "\n\n" + comment)
        if self.merge_parent:
            output = self.git("commit-tree", self.tree, "-p", self.base,
                              "-p", self.merge_parent, "-F", str(body))
            merge_commit = output.decode().strip()
            self.git("update-ref", "-m", "qualified REV merge", "HEAD",
                     merge_commit, self.base)
        else:
            output = self.git("commit", "--file", str(body), environment=self.index_environment)
        (self.storage / "commit.stdout").write_bytes(output)
        revision = self.git("rev-parse", "HEAD").decode().strip()
        if self.git("rev-parse", "HEAD^{tree}").decode().strip() != publication_tree:
            raise ValueError("committed tree differs from admission")
        if digest(self.gitdir / "index") != self.index_digest:
            raise ValueError("commit changed unrelated index custody")
        result = dict(repository=str(self.repository.relative_to(self.root)),
                      branch=self.branch, revision=revision, parent=self.base,
                      tree=publication_tree, testedSourceTree=self.tree, paths=self.paths, realIndexUnchanged=True,
                      sourceCopies=0, pushed=False, wholeSmpAdmitted=False)
        unit = self.delivery_contract()
        result.update(submissionKind=unit["kind"], integrationResult=unit["result"],
                      progressDelta=unit["progressDelta"])
        if self.merge_parent:
            result["mergeParent"] = self.merge_parent
        write_json(self.evidence / "revision.json", result)
        return result
