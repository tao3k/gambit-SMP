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
        base = archive_sources(self.git("archive", self.base))
        self.paths = list(paths)
        if not self.paths or len(set(self.paths)) != len(self.paths):
            raise ValueError("unique nonempty source cut required")
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
        files = source_manifest(archive_sources(self.git("archive", self.tree)))
        for name, row in files.items():
            if canonical_source(name) and row["mode"] != "120000":
                if digest(self.workspace / name) != row["sha256"]:
                    raise ValueError("submission contains untested canonical input: " + name)
        write_json(self.evidence / "source-manifest.json",
                   dict(baseRevision=self.base, tree=self.tree, files=files))
        self.source = dict(baseRevision=self.base, tree=self.tree, paths=self.paths,
                           manifestSha256=digest(self.evidence / "source-manifest.json"),
                           profileSha256=digest(profile), artifacts=self.native["artifacts"],
                           canonicalInputEquivalence=True, realIndexSha256=self.index_digest,
                           stagedSha256=hashlib.sha256(self.staged).hexdigest(),
                           workingDiffSha256=self.working, sourceCopies=0,
                           wholeSmpAdmitted=False)
        if "generatedArtifacts" in self.native:
            self.source["generatedArtifacts"] = self.native["generatedArtifacts"]
        if self.merge_parent:
            self.source["mergeParent"] = self.merge_parent
        write_json(self.evidence / "source.json", self.source)
        return self.source

    def project(self, model, namespace, inputs):
        text = (self.root / model).read_text()
        names = re.findall(r"part (\w+):Need \{", text)
        if not names:
            raise ValueError("SysML delivery needs required")
        queries = {field: namespace + "::" + field
                   for field in ("scope", "stage", "formalDuty")}
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
        self.need_names = names
        write_json(self.evidence / "model.json", dict(inputs=self.model_inputs,
                   values=self.values, nativeOutputSha256=digest(self.storage / "sysml.stdout")))
        return self.values

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
        scenarios = ("current", "missing-native", "stale-tree", "wrong-artifact",
                     "wrong-profile", "model-only", *missing_obligations)
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
            controlExpectReadyFact=[["current"]],
            controlExpectBlockedFact=[[name] for name in scenarios[1:]],
        )
        for scenario in scenarios:
            rows["commitScenarioClassFact"].append([
                scenario, "model-only" if scenario == "model-only" else "selected-source-and-native"])
            rows["commitCandidateFact"].append([
                scenario, head, "different" if scenario == "stale-tree" else tree,
                manifest, "different" if scenario == "wrong-profile" else profile])
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
                                          "commitGateReady", "controlFailure")}
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
        if answers["commitReady"] != [["current"]] or answers["controlFailure"] or len(covered) != len(needs):
            raise ValueError("selected REV or rejection controls failed shared ASCENT policy")
        self.check_custody()
        self.admission = dict(tree=tree, baseRevision=head, artifacts=artifacts,
                              answers=answers, negativeControls=len(scenarios)-1,
                              gateReady=[row[1] for row in answers["commitGateReady"]
                                         if row[0] == "current"],
                              modelInputs=self.model_inputs, commitAdmitted=True,
                              wholeSmpAdmitted=False)
        write_json(self.evidence / "admission.json", self.admission)
        return self.admission

    def commit(self, message, admission):
        if (admission is not getattr(self, "admission", None)
                or admission.get("commitAdmitted") is not True or admission.get("tree") != self.tree):
            raise ValueError("matching ASCENT admission required")
        self.check_custody()
        for name, expected in admission["artifacts"].items():
            if digest(self.root / name) != expected:
                raise ValueError("admission artifact changed")
        if self.git("write-tree", environment=self.index_environment).decode().strip() != self.tree:
            raise ValueError("submission index changed")
        body = self.storage / "message.txt"
        body.write_text(message)
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
        if self.git("rev-parse", "HEAD^{tree}").decode().strip() != self.tree:
            raise ValueError("committed tree differs from admission")
        if digest(self.gitdir / "index") != self.index_digest:
            raise ValueError("commit changed unrelated index custody")
        result = dict(repository=str(self.repository.relative_to(self.root)),
                      branch=self.branch, revision=revision, parent=self.base,
                      tree=self.tree, paths=self.paths, realIndexUnchanged=True,
                      sourceCopies=0, pushed=False, wholeSmpAdmitted=False)
        if self.merge_parent:
            result["mergeParent"] = self.merge_parent
        write_json(self.evidence / "revision.json", result)
        return result
