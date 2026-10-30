from pathlib import Path
import tempfile
import unittest

from gambit_smp.compiler_cost import EXECUTION_WITNESS, LOAD_PROBE, stage_accepted, phase_commands


class CompilerCostTests(unittest.TestCase):
    def test_numeric_execution_uses_actual_generated_module_linker(self):
        from gambit_smp.compiler_phase_primitives import numeric_execution_expression
        expression = numeric_execution_expression('numeric-witness')
        self.assertIn('(##load "_test.o1" (lambda (script path) #f) #t #t "_test.o1" #f)', expression)
        self.assertIn('(quote numeric-not-executed)', expression)
        self.assertIn('(eq? ##failed-test? #f)', expression)
        self.assertIn('numeric-witness\\n', expression)

    def test_assertion_partition_rejects_missing_order_barrier_and_large_groups(self):
        from gambit_smp.compiler_phase_primitives import assertion_group_manifest
        rows=['0\tinclude\t-1\n','1\ttest-eqv\t1\n','2\ttest-eq\t1\n','3\ttest-error-tail\t-1\n']
        value=assertion_group_manifest(rows,['include','test-eqv','test-eq','test-error-tail'])
        self.assertEqual((value['forms'],value['groups'],value['maxGroup']),(4,1,2))
        controls=[rows[:2]+rows[3:], [rows[0],rows[2],rows[1],rows[3]],
                  rows[:3]+['3\ttest-error-tail\t1\n'],
                  [str(i)+'\ttest-eqv\t1\n' for i in range(33)]]
        for bad in controls:
            with self.assertRaises(ValueError):assertion_group_manifest(bad)
        with self.assertRaises(ValueError):assertion_group_manifest(rows,['include','test-eqv'])

    def test_phase_observer_rejects_peer_or_reparented_compiler(self):
        from gambit_smp.compiler_phase_primitives import owned_cc1
        parent=dict(pid=11,pgid=11,uid=501)
        child=dict(pid=12,ppid=11,pgid=11,uid=501,name='cc1')
        self.assertTrue(owned_cc1(parent,child))
        for changed in (dict(child,ppid=9),dict(child,pgid=9),dict(child,uid=502),dict(child,name='as'),None):
            self.assertFalse(owned_cc1(parent,changed))

    def test_generated_host_census_scopes_procedures_and_rejects_truncation(self):
        from gambit_smp.compiler_phase_primitives import generated_host_census
        text=('#define ___PH_PROC main\n___BEGIN_P_COD\n'
              '___IF(___NOT(___EQP(x,y)))\n___JUMPGLOSAFE(___SET_NARGS(2),52,___G_cmp)\n'
              '___END_P_COD\n___GOTO(outside)\n')
        row=generated_host_census(text.splitlines())['functions'][0]
        self.assertEqual(row['globalCalls'],{'___G_cmp':1})
        self.assertEqual(row['macros']['___EQP'],1)
        self.assertNotIn('___GOTO',row['macros'])
        with self.assertRaises(ValueError):generated_host_census(text.split('___END_P_COD')[0].splitlines())

    def test_reconstruction_buffers_files_without_changing_console_or_processors(self):
        from gambit_smp.compiler_phase_primitives import numeric_generation_runtime_options
        option=numeric_generation_runtime_options(Path('/retained/runtime'))
        self.assertIn('io-settings=lu',option)
        self.assertIn('file-settings=lf',option)
        self.assertIn('~~lib=/retained/runtime/lib',option)
        self.assertNotIn('p1',option)

    def test_alias_solution_units_and_partial_dump_do_not_admit(self):
        from gambit_smp.compiler_phase_primitives import alias_detail_census
        text = (';; Function f (f)\nConstraints:\nx = &a\ny = x\n'
                'Collapsing static cycles and doing variable substitution\n'
                'Equivalence classes for direct node id 7 "x": pointer 2, location 0\n'
                'Equivalence classes for indirect node id 8 "y": pointer 2, location 3\n'
                'Points-to sets\nx = { a b }\ny = { a b } same as x\n'
                'Alias information for f\n')
        value = alias_detail_census(text.splitlines(keepends=True))
        row = value['functions'][0]
        self.assertTrue(value['allSolutionsClosed'])
        self.assertEqual((row['constraintsObserved'],row['equivalenceNodesObserved']), (2,2))
        self.assertEqual((row['pointerEquivalenceClassesObserved'],row['locationEquivalenceClassesObserved']), (1,1))
        self.assertEqual((row['pointsToMembershipsObserved'],row['pointsToNamedTargetsObserved']), (4,2))
        for partial in (text.split('Points-to sets')[0], text.split('Alias information')[0],
                        text.replace('y = { a b } same as x','y = { a b'),
                        text.replace('y = { a b } same as x','y = { a a }')):
            self.assertFalse(alias_detail_census(partial.splitlines(keepends=True))['allSolutionsClosed'])

    def test_partial_cfg_observations_are_separate_from_ssa_completion(self):
        from gambit_smp.compiler_phase_primitives import cfg_representation_census
        lines=';; Function f (\n;; 2 succs { 3 4 }\n<bb 2> :\n;; Function g (\n'
        value=cfg_representation_census(lines.splitlines())
        self.assertEqual(len(value['functions']),2)
        self.assertEqual(value['functions'][0]['maxFanoutObserved'],2)
        self.assertEqual(value['functions'][1]['bodyBlocksObserved'],0)

    def test_real_ir_units_and_abnormal_ssa_names(self):
        from gambit_smp.compiler_phase_primitives import retained_ir_representation
        cfg = ';; Function f (\n;; 2 succs { 4 }\n;; 3 succs { 4 }\n<bb 2> :\n<bb 3> :\n<bb 4> :\n'
        ssa = (';; Function f (\n<bb 4> :\n'
               '# ___hp_42(ab) = PHI <___hp_1(2), ___hp_2(ab)(3)>\n'
               '# gotovar.53_9 = PHI <gotovar.53_1(2), gotovar.53_2(3)>\n'
               '// goto predictor.\ngoto gotovar.53_9;\n')
        row = retained_ir_representation(cfg.splitlines(), ssa.splitlines())['functions'][0]
        self.assertEqual((row['phiOperands'], row['phiIncomingEdges']), (4, 2))
        self.assertEqual(row['operandClasses'], {'___hp': 2, 'gotovar': 2})
        self.assertEqual((row['indirectGotos'], row['gotoComments']), (1, 1))
        self.assertEqual(row['phiEdgesAbsentFromEarlierCfg'], 0)
        self.assertTrue(row['topJoins'][0]['sharedPredecessorSet'])
        different = ssa.replace('gotovar.53_2(3)', 'gotovar.53_2(5)')
        changed = retained_ir_representation(cfg.splitlines(), different.splitlines())['functions'][0]
        self.assertFalse(changed['topJoins'][0]['sharedPredecessorSet'])
        self.assertEqual(changed['phiEdgesAbsentFromEarlierCfg'], 1)
        # CFG successor metadata belongs to the following function, not the
        # previous function's last body block.
        extra = ';; Function g (\n;; 2 succs { 1 }\n<bb 2> :\n'
        rows = retained_ir_representation((cfg+extra).splitlines(), (ssa+extra).splitlines())['functions']
        self.assertEqual([row['edges'] for row in rows], [2, 1])
        for bad in (ssa.replace('(3)>', '(3)'), ssa.replace('(3)>', '(2)>'),
                    ssa.replace('(3)>', '>'), ssa.replace('Function f', 'Function g')):
            with self.assertRaises(ValueError):
                retained_ir_representation(cfg.splitlines(), bad.splitlines())

    def test_each_requested_alias_pass_requires_its_own_function_constraints(self):
        from gambit_smp.compiler_phase_primitives import alias_passes_exercised
        text=';; Function numeric_alias_probe (\nConstraints:\n'
        self.assertTrue(alias_passes_exercised(0,False,{'alias':[text],'ealias':[text]}))
        for texts in ({},{'alias':[text]},{'ealias':[text]},
                      {'alias':['Constraints:'],'ealias':[text]},
                      {'alias':[text],'ealias':[';; Function numeric_alias_probe (']}):
            self.assertFalse(alias_passes_exercised(0,False,texts))
        self.assertFalse(alias_passes_exercised(0,True,{'alias':[text],'ealias':[text]}))

    def test_clean_options_and_public_c_compilation_api(self):
        stages = phase_commands(Path("03-number/_num.scm"), Path("work"))
        self.assertTrue(all(options[0] == "-f" for _, _, options, _ in stages))
        self.assertIn('compile-file "probe.c"', stages[1][2][2])
        self.assertFalse(stage_accepted(0, False, "Unknown or improperly placed -f option ignored", None))

    def test_execution_uses_generated_linker_and_original_assertion_state(self):
        stages = phase_commands(Path("03-number/_num.scm"), Path("work"))
        self.assertEqual(stages[2][2], ["-f", "-e", LOAD_PROBE])
        self.assertIn('(##load "probe.o1" (lambda (script path) #f) #t #t "probe" #f)', LOAD_PROBE)
        self.assertIn("'phase-module-not-executed", LOAD_PROBE)
        self.assertIn("(eq? ##failed-test? #f)", LOAD_PROBE)
        self.assertNotIn("##tested-procs", LOAD_PROBE)

    def test_execution_rejects_missing_duplicate_and_failed_witness(self):
        self.assertFalse(stage_accepted(0, False, "", None, EXECUTION_WITNESS))
        self.assertTrue(stage_accepted(0, False, EXECUTION_WITNESS + "\n", None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(0, False, (EXECUTION_WITNESS + "\n") * 2, None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(2, False, EXECUTION_WITNESS, None, EXECUTION_WITNESS))
        self.assertFalse(stage_accepted(0, True, EXECUTION_WITNESS, None, EXECUTION_WITNESS))
    def test_stage_needs_exit_zero_no_timeout_and_expected_artifact(self):
        with tempfile.TemporaryDirectory() as temporary:
            artifact = Path(temporary) / "module.o1"
            self.assertFalse(stage_accepted(0, False, "", artifact))
            artifact.write_bytes(b"module")
            self.assertTrue(stage_accepted(0, False, "", artifact))
            self.assertFalse(stage_accepted(1, False, "", artifact))
            self.assertFalse(stage_accepted(0, True, "", artifact))
            self.assertFalse(stage_accepted(0, False, "FAILED assertion", artifact))
            self.assertTrue(stage_accepted(0, False, "", None))
