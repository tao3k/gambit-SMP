import io
import tarfile
import unittest
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from gambit_smp.branch_evidence import (archive_sources, source_manifest,
    unit_inventory, bind_case, case_verdict, progress)


class BranchEvidenceTests(unittest.TestCase):
    def directive_control(self, before=b'', after=b''):
        return (self.recorded_macro_dump() + b'\n#define ___PH_PROC proc\n' + before
                + b'___SET_R3(___F64BOX(x))\n' + after)

    def inspect_directive_control(self, source):
        from gambit_smp.branch_evidence import inspect_directive_macro_points
        return inspect_directive_macro_points(source, 'proc', ['___SET_R3(___F64BOX(x))'])

    def test_point_context_is_not_the_end_context(self):
        changed = b'#undef ___ALLOC\n#define ___ALLOC(n) ___hp += 100\n'
        result = self.inspect_directive_control(self.directive_control(after=changed))
        self.assertTrue(next(iter(result['points'].values()))['inspection']['standard64MemoryBoxMatched'])
        self.assertFalse(result['runtimeAdmitted'])
        restored = b'#undef ___ALLOC\n#define ___ALLOC(n) ___hp += (n)\n'
        result = self.inspect_directive_control(self.directive_control(changed, restored))
        self.assertFalse(next(iter(result['points'].values()))['inspection']['standard64MemoryBoxMatched'])

    def test_point_context_observes_undef_and_empty_probe(self):
        for before in [b'#undef ___ALLOC\n', b'#define ___GAMBIT_DEV_RESTORE_PROBE\n']:
            with self.subTest(before=before):
                result = self.inspect_directive_control(self.directive_control(before))
                self.assertFalse(next(iter(result['points'].values()))['inspection']['standard64MemoryBoxMatched'])

    def test_point_context_ignores_comment_lookalikes(self):
        comment = b'/* "\n#define ___ALLOC(n) broken\n___SET_R3(___F64BOX(x))\n*/\n'
        result = self.inspect_directive_control(self.directive_control(comment))
        self.assertTrue(next(iter(result['points'].values()))['inspection']['standard64MemoryBoxMatched'])

    def test_point_context_rejects_unknown_directives_and_macro_stack(self):
        for before in [b'#pragma push_macro("___ALLOC")\n', b'#if 1\n',
                       b'#include "unobserved.h"\n', b'#define X \\\n+1\n']:
            with self.subTest(before=before), self.assertRaises(ValueError):
                self.inspect_directive_control(self.directive_control(before))

    def test_point_context_requires_unique_statement_and_matching_procedure(self):
        for source in [self.directive_control(after=b'___SET_R3(___F64BOX(x))\n'),
                       self.directive_control().replace(b'___PH_PROC proc', b'___PH_PROC other'),
                       self.directive_control().replace(b'___SET_R3(___F64BOX(x))', b'// absent'),
                       self.directive_control(after=b'/* never closed')]:
            with self.subTest(source=source[-70:]), self.assertRaises(ValueError):
                self.inspect_directive_control(source)

    def test_terminal_evidence_does_not_trust_a_complete_flag(self):
        from gambit_smp.branch_evidence import terminal_status
        process = dict(exit=0, timeout=False, parentReaped=True,
                       processGroupQuiescent=True, complete=True)
        self.assertEqual(terminal_status(process, contract_complete=True), 'PASS')
        for key in ('timeout', 'parentReaped', 'processGroupQuiescent'):
            changed = dict(process)
            changed.pop(key)
            self.assertNotEqual(terminal_status(changed, contract_complete=True), 'PASS')
        self.assertNotEqual(terminal_status(process, contract_complete=False), 'PASS')
        self.assertEqual(terminal_status(dict(process, exit=False), contract_complete=True), 'UNRESOLVED')

    def test_recorded_case_validation_distinguishes_reliability_from_success(self):
        from copy import deepcopy
        from gambit_smp.branch_evidence import validate_recorded_cases
        record = dict(schema='gambit-smp.recorded-cases.v1', sourceTree='a' * 40,
            profileSha256='b' * 64, runtimeAdmitted=False, branchQualified=False,
            positiveExecutions=1, compilations=0, historicalCounterexamples=0,
            cases=[dict(id='actual-failure', role='execution', terminalStatus='FAIL',
                process=dict(exit=70, timeout=False, parentReaped=True,
                             processGroupQuiescent=True),
                markers={'DONE': False}, streamIdentitiesChecked=True)])
        checked = validate_recorded_cases(record)
        self.assertEqual(checked['outcomes'], dict(PASS=0, FAIL=1, UNRESOLVED=0))
        self.assertFalse(checked['allExpectedOutcomes'])
        self.assertFalse(checked['runtimeAdmitted'])
        for mutation in ('verdict', 'admission', 'BooleanExit', 'missingFlag'):
            bad = deepcopy(record)
            if mutation == 'verdict':
                bad['cases'][0]['terminalStatus'] = 'PASS'
            elif mutation == 'admission':
                bad['runtimeAdmitted'] = True
            elif mutation == 'BooleanExit':
                bad['cases'][0]['process']['exit'] = False
            else:
                bad['cases'][0]['process'].pop('parentReaped')
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                validate_recorded_cases(bad)

    def test_generated_closure_keeps_allocation_witnesses_and_unknown_jumps(self):
        from gambit_smp.branch_evidence import inspect_generated_c
        source = b"""#define ___PH_PROC ___Hroot
___BEGIN_P_COD
___JUMPINT(___SET_NARGS(1),___PRC(1),___Lchild)
___JUMPRET(___R0)
___END_P_COD
#define ___PH_PROC ___Hchild
___BEGIN_P_COD
___SET_R1(___F64BOX(___F64V1))
___CHECK_HEAP_FLO(1,4096)
___JUMPPRM(___R1)
___END_P_COD
"""
        result = inspect_generated_c(source, ['___Hroot'])
        self.assertEqual(result['helperCount'], 2)
        self.assertEqual(result['witnessCount'], 2)
        self.assertEqual(result['unknownSchemeJumpCount'], 1)
        self.assertFalse(result['runtimeAdmitted'])
        for changed, roots in [(source, ['___Hmissing']),
                               (source + source, ['___Hroot']),
                               (source.replace(b'___END_P_COD', b'', 1), ['___Hroot'])]:
            with self.assertRaises(ValueError):
                inspect_generated_c(changed, roots)

    @staticmethod
    def recorded_macro_dump():
        return (Path(__file__).resolve().parents[1] /
                'evidence/research/retained/modern-c/stress-gsi/dev-gcc-numeric-macros.txt').read_bytes()

    def test_recorded_gcc_macros_do_not_admit_a_runtime(self):
        from gambit_smp.branch_evidence import inspect_preprocessed_macros
        result = inspect_preprocessed_macros(self.recorded_macro_dump())
        self.assertTrue(result['standard64MemoryBoxMatched'])
        self.assertEqual(2, result['perBoxWordsUpperBound'])
        self.assertFalse(result['runtimeAdmitted'])
        self.assertFalse(result['effectiveRuntimeAbiQualified'])
        self.assertEqual('end-of-translation-unit', result['observationPoint'])

    def test_macro_context_rejects_missing_or_changed_bindings(self):
        from gambit_smp.branch_evidence import inspect_preprocessed_macros
        source = self.recorded_macro_dump()
        for index, changed in enumerate([source.replace(b'#define ___FLONUM_SIZE 1\n', b''),
                        source.replace(b'#define ___ALLOC(n) ___hp += (n)',
                                       b'#define ___ALLOC(n) unknown_allocator(n)'),
                        source.replace(b'#define ___ALLOC(n)', b'#define ___ALLOC(other)'),
                        source.replace(b'#define ___ALLOC(n) ___hp += (n)',
                                       b'#define ___ALLOC(n) ___hp + = (n)'),
                        source.replace(b'#define __GNUC__ 16', b'#define __GNUC__(arg) 16'),
                        source.replace(b'#define ___GET_FLONUM() ___FLONUM_FROM_END(___hp)',
                                       b'#define ___GET_FLONUM() unknown_result_allocator()'),
                        source.replace(b'__STDC_VERSION__ 202311L', b'__STDC_VERSION__ 201112L'),
                        source+b'\n#define ___GAMBIT_DEV_RESTORE_PROBE\n',
                        source+b'\n#define __clang__ 1\n']):
            with self.subTest(control=index):
                result = inspect_preprocessed_macros(changed)
                self.assertFalse(result['standard64MemoryBoxMatched'])
                self.assertIsNone(result['perBoxWordsUpperBound'])
                self.assertFalse(result['runtimeAdmitted'])

    def test_two_macro_observations_cannot_be_concatenated(self):
        from gambit_smp.branch_evidence import inspect_preprocessed_macros
        with self.assertRaisesRegex(ValueError, 'duplicate protected macro context'):
            inspect_preprocessed_macros(self.recorded_macro_dump()+b'\n#define ___WS 4\n')

    def test_boxing_group_records_locations_without_capacity_credit(self):
        from gambit_smp.branch_evidence import inspect_generated_c
        source = self.boxing_source()
        result = inspect_generated_c(source, ['___Hroot'])
        groups = result['procedures']['___Hroot']['boxingGroups']
        self.assertEqual(1, len(groups['groups']))
        group = groups['groups'][0]
        self.assertEqual(24, group['heapWords'])
        self.assertEqual(['STK', 'R3', 'R4'], [row['location'] for row in group['boxStores']])
        self.assertEqual(0, group['boxStores'][0]['stackOffset'])
        self.assertFalse(group['capacityAdmitted'])
        self.assertFalse(result['runtimeAdmitted'])

    def test_boxing_group_rejects_unresolved_control_and_mismatched_commit(self):
        from gambit_smp.branch_evidence import inspect_generated_c
        source = self.boxing_source()
        for changed in [source.replace(b'___LBL(6),___demand_attempt);',
                                       b'___LBL(7),___demand_attempt);'),
                        source.replace(b'   ___SET_R3', b'   ___IF(___R1)\n   ___SET_R3'),
                        source.replace(b'   ___SET_R3', b'/* unexpanded */\n   ___SET_R3'),
                        source.replace(b'___SET_R4(', b'___SET_R4(1,')]:
            with self.subTest(changed=changed):
                found = inspect_generated_c(changed, ['___Hroot'])['procedures']['___Hroot']['boxingGroups']
                self.assertEqual([], found['groups'])
                self.assertEqual(1, found['unsupportedCanonicalHeaders'])

    def test_boxing_labels_are_scoped_to_each_physical_procedure(self):
        from gambit_smp.branch_evidence import inspect_generated_c
        root = self.boxing_source()
        child = root.replace(b'___Hroot', b'___Hchild').replace(b',0,24,', b',0,48,')
        found = inspect_generated_c(root + child, ['___Hroot', '___Hchild'])
        self.assertEqual([24, 48], [found['procedures'][name]['boxingGroups']['groups'][0]['heapWords']
                                   for name in ['___Hroot', '___Hchild']])

    @staticmethod
    def boxing_source():
        return b'''#define ___PH_PROC ___Hroot
___BEGIN_P_COD
if(!___group_demand_enter(___ps,&___hp,&___fp,0,24,___LBL(6),&___demand_attempt)){___ps->temp1=___LBL(6);___JUMPEXTPRM(___NOTHING,___ps->handler_stack_limit);}
   ___SET_STK(0,___F64BOX(___F64V5))
   ___SET_R3(___F64BOX(___F64V2))
   ___SET_R4(___F64BOX(___F64V4))
___group_demand_commit(___ps,___LBL(6),___demand_attempt);
___END_P_COD
'''

    def setUp(self):
        self.plan = dict(branch="modern-c", revision="commit-a", tree="tree-a",
                         sourceManifestSha256="source-a", profileSha256="profile-a",
                         cases={"original-gsi": {}}, requirements=["Complete GSI inventory"])
        self.producer = {key: self.plan[key] for key in
                         ("revision", "tree", "sourceManifestSha256", "profileSha256")}
        self.producer.update(sourceOverlay=False, artifacts={"gsi/gsi": "binary-a"})
        self.process = dict(exit=0, timeout=False, parentReaped=True, processGroupQuiescent=True)

    def test_dirty_overlay_cannot_become_branch_evidence(self):
        self.producer["sourceOverlay"] = True
        with self.assertRaises(ValueError):
            bind_case(self.plan, "original-gsi", self.producer)

    def test_different_revision_or_binary_cannot_reuse_case(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        result = case_verdict(binding, self.process, contract_complete=True)
        for key in ("revision", "profileSha256"):
            changed = dict(self.producer, **{key: "different"})
            with self.assertRaises(ValueError):
                progress(self.plan, changed, {"original-gsi": result})
        changed = dict(self.producer, artifacts={"gsi/gsi": "binary-b"})
        with self.assertRaises(ValueError):
            progress(self.plan, changed, {"original-gsi": result})

    def test_exit_zero_without_complete_inventory_is_not_pass(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        self.assertEqual(case_verdict(binding, self.process, contract_complete=False)["status"], "FAIL")

    def test_unknown_exit_retains_unresolved_status(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        self.assertEqual(case_verdict(binding, dict(self.process, exit=None),
                                      contract_complete=True)["status"], "UNRESOLVED")

    def test_pass_does_not_import_patch_count_or_close_semantic_requirement(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        result = case_verdict(binding, self.process, contract_complete=True)
        state = progress(self.plan, self.producer, {"original-gsi": result})
        self.assertEqual(state["cases"]["original-gsi"], "PASS")
        self.assertEqual(state["requirements"]["Complete GSI inventory"], "UNESTABLISHED")
        self.assertIsNone(state["aggregateProgress"])
        self.assertFalse(state["inheritedPatchCredit"])

    def test_archive_and_inventory_bind_bytes_without_another_checkout(self):
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w") as archive:
            for name in ("tests/unit-tests/a.scm", "tests/unit-tests/#.scm",
                         "tests/unit-tests/a_stress.scm"):
                entry = tarfile.TarInfo(name); entry.size = 2
                archive.addfile(entry, io.BytesIO(b"()"))
        manifest = source_manifest(archive_sources(stream.getvalue()))
        self.assertEqual(unit_inventory(manifest), ["tests/unit-tests/a.scm"])
        self.assertEqual(unit_inventory(manifest, stress=True), ["tests/unit-tests/a_stress.scm"])

    def test_archive_rejects_path_escape(self):
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w") as archive:
            entry = tarfile.TarInfo("../outside"); entry.size = 1
            archive.addfile(entry, io.BytesIO(b"x"))
        with self.assertRaises(ValueError):
            archive_sources(stream.getvalue())

    def test_forged_pass_cannot_override_a_failed_process(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        result = case_verdict(binding, dict(self.process, exit=2), contract_complete=False)
        result["status"] = "PASS"
        with self.assertRaises(ValueError):
            progress(self.plan, self.producer, {"original-gsi": result})

    def test_failed_build_checkpoint_admits_only_declared_broken_links(self):
        from gambit_smp.workspace import checkpoint_build_source
        with TemporaryDirectory() as directory:
            parent = Path(directory)
            source = parent / "source"
            (source / "bin").mkdir(parents=True)
            (source / "bin/gsc-script").symlink_to("../gsc/gsc")
            state = parent / "source-state.json"
            state.write_text(json.dumps(dict(inputs={"bin/gsc-script": {}}, observed={})))
            with self.assertRaises(ValueError):
                checkpoint_build_source(source)
            checkpoint_build_source(source, broken_links={"bin/gsc-script": "../gsc/gsc"},
                                    phase="failed-bootstrap")
            self.assertEqual(json.loads(state.read_text())["phase"], "failed-bootstrap")
            (source / "bin/unknown").symlink_to("../unknown")
            with self.assertRaises(ValueError):
                checkpoint_build_source(source, broken_links={"bin/gsc-script": "../gsc/gsc"})
