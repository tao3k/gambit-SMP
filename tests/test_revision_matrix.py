"""REV metric provenance/arithmetic controls; these are not runtime benchmarks."""
import copy
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.revision_matrix import normalize_matrix, render_matrix

FIELDS = 'id,kind,metric,unit,direction,baseline,candidate,workload,method,evidence,limitation'.split(',')
KINDS = 'measurement,control,accounted-cost,structural,unmeasured'.split(',')


class EfficiencyClaimTests(unittest.TestCase):
    """Typed synthetic benchmark controls, never measured runtime evidence."""
    policy = dict(requiredMetrics="pause;throughput;rss",
                  includedCosts="build;load;allocation;gc;cleanup",
                  fixedOverhead="fixed-overhead")

    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = dict(baseRevision="base", tree="candidate", profileSha256="profile")
        self.identity = dict(baseRevision="base", sourceTree="candidate", profileSha256="profile")

    def population(self):
        import hashlib
        raw = dict(self.identity, values={}, complete=True,
                   processes=[dict(exit=0, timeout=False, parentReaped=True,
                                   processGroupQuiescent=True)])
        quantities = dict(self.identity, values={})
        rows = []
        for dimension, unit, before, after, direction in [
            ("pause", "s", 20, 10, "lower"),
            ("throughput", "requests/s", 20, 30, "higher"),
            ("rss", "bytes", 200, 100, "lower"),
            ("fixed-overhead", "s", 2, 1, "lower"),
        ]:
            raw["values"][dimension] = {}
            quantities["values"][dimension] = {}
            for arm, value in [("before", before), ("after", after)]:
                value = dict(value=value, unit=unit, samples=2)
                raw["values"][dimension][arm] = value
                quantities["values"][dimension][arm] = dict(value, origin=dict(
                    path="raw.json", pointer="/values/" + dimension + "/" + arm))
            rows.append(dict(id=dimension, dimension=dimension, kind="measurement",
                metric=dimension, unit=unit, direction=direction,
                baseline=dict(path="quantities.json", pointer="/values/" + dimension + "/before"),
                candidate=dict(path="quantities.json", pointer="/values/" + dimension + "/after"),
                workload="Whole paired synthetic population", method="Typed policy control",
                evidence=["raw.json"], limitation="Synthetic, not native performance."))
        for name, value in [("raw.json", raw), ("quantities.json", quantities)]:
            (self.root / name).write_text(json.dumps(value))
        plan = dict(plannedSamples={k: 2 for k in ("pause", "throughput", "rss")},
                    workloadSha256="1" * 64, limitsSha256="2" * 64,
                    rssScope="coincident whole process-group RSS",
                    costsIncluded=self.policy["includedCosts"].split(";"))
        (self.root / "plan.json").write_text(json.dumps(plan))
        plan_sha = hashlib.sha256((self.root / "plan.json").read_bytes()).hexdigest()
        self.benchmark = dict(self.identity, **plan, complete=True, selection="all-planned",
            excludedSamples=[], controlsComplete=True,
            baselineWorkloadSha256=plan["workloadSha256"], baselineLimitsSha256=plan["limitsSha256"],
            baselineRssScope=plan["rssScope"], samplePlanSha256=plan_sha,
            samplePlan=dict(path="plan.json", sha256=plan_sha),
            nativeReceipt=dict(path="raw.json", sha256=hashlib.sha256(
                (self.root / "raw.json").read_bytes()).hexdigest()),
            avoidedFixedWork="Repeated setup eliminated", residualFixedWork="One validated setup remains")
        self.matrix = dict(rows=rows, claim="efficiency-upgrade")
        self.save_benchmark()

    def save_benchmark(self):
        import hashlib
        path = self.root / "benchmark.json"
        path.write_text(json.dumps(self.benchmark))
        self.matrix["benchmark"] = dict(path="benchmark.json",
            sha256=hashlib.sha256(path.read_bytes()).hexdigest())

    def decision(self):
        from gambit_smp.revision_matrix import benefit_admission
        packet = normalize_matrix(self.root, self.matrix, self.source, FIELDS, KINDS,
                                  efficiency_policy=self.policy)
        return benefit_admission(packet, integration=True)

    def test_local_positive_remains_foundation_and_cannot_upgrade_without_population(self):
        self.population()
        self.matrix.pop("benchmark")
        self.assertFalse(self.decision()["admitted"])
        self.matrix["claim"] = "foundation"
        self.assertTrue(self.decision()["admitted"])

    def test_complete_population_is_necessary_and_each_missing_dimension_denies(self):
        self.population()
        self.assertTrue(self.decision()["admitted"])
        original = copy.deepcopy(self.matrix)
        for dimension in ("pause", "throughput", "rss", "fixed-overhead"):
            self.matrix = copy.deepcopy(original)
            self.matrix["rows"] = [r for r in self.matrix["rows"] if r["dimension"] != dimension]
            with self.subTest(dimension=dimension):
                self.assertFalse(self.decision()["admitted"])

    def test_changed_limits_excluded_samples_or_omitted_fixed_work_deny(self):
        self.population()
        original = copy.deepcopy(self.benchmark)
        for key, value in [("baselineLimitsSha256", "3" * 64),
                           ("excludedSamples", [0]), ("residualFixedWork", "")]:
            self.benchmark = dict(original, **{key: value})
            self.save_benchmark()
            with self.subTest(key=key):
                self.assertFalse(self.decision()["admitted"])


class RevisionMatrixTests(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = dict(baseRevision='base', tree='candidate', profileSha256='profile')
        self.data = dict(baseRevision='base', sourceTree='candidate', profileSha256='profile',
                         before=dict(value=20, unit='s', samples=1),
                         after=dict(value=10, unit='s', samples=1))
        self.save()
        self.matrix = {'rows': [dict(id='compile',kind='measurement',metric='Compile time',
            unit='s',direction='lower',baseline={'path':'evidence.json','pointer':'/before'},
            candidate={'path':'evidence.json','pointer':'/after'},workload='One exact cohort',
            method='Native command elapsed time',evidence=['evidence.json'],
            limitation='Single observation, no causal/statistical theorem')]}

    def save(self):
        raw = {k: v for k, v in self.data.items() if k not in {'before', 'after'}}
        for key in ['before', 'after']:
            self.data[key]['origin'] = {'path': 'raw.json', 'pointer': '/'+key}
            raw[key] = {k: v for k, v in self.data[key].items() if k != 'origin'}
        (self.root/'raw.json').write_text(json.dumps(raw))
        (self.root/'evidence.json').write_text(json.dumps(self.data))

    def normalize(self):
        return normalize_matrix(self.root,self.matrix,self.source,FIELDS,KINDS)

    def test_evidenced_values_and_signed_changes(self):
        packet=self.normalize();row=packet['rows'][0]
        self.assertEqual((row['delta'],row['delta_percent'],row['candidate_over_baseline']),('-10','-50.0','0.5'))
        self.assertEqual(row['outcome'],'observed-improvement')
        self.assertFalse(row['generalized_performance_claim'])
        self.assertIn('1/1',render_matrix(packet))
        self.assertIn('Single observation',render_matrix(packet))

    def test_control_timing_is_never_a_performance_improvement(self):
        self.matrix['rows'][0]['kind']='control'
        self.assertEqual(self.normalize()['rows'][0]['outcome'],'control-only')

    def test_zero_baseline_does_not_invent_a_percentage(self):
        self.data['before']['value']=0;self.save()
        row=self.normalize()['rows'][0]
        self.assertIsNone(row['delta_percent']);self.assertIsNone(row['candidate_over_baseline'])

    def test_regression_is_not_hidden(self):
        self.data['after']['value']=25;self.save()
        self.assertEqual(self.normalize()['rows'][0]['outcome'],'observed-regression')

    def test_regression_blocks_publication_even_beside_a_positive_row(self):
        from gambit_smp.revision_matrix import benefit_admission
        good = self.normalize()['rows'][0]
        self.data['after']['value'] = 25
        self.save()
        bad = self.normalize()['rows'][0]
        bad['id'] = 'adverse'
        decision = benefit_admission({'rows': [good, bad]}, integration=True)
        self.assertFalse(decision['admitted'])
        self.assertEqual(decision['regressionRows'], ['adverse'])
        self.assertEqual(decision['positiveRows'], ['compile'])

    def test_runtime_requires_measured_positive_benefit(self):
        from gambit_smp.revision_matrix import benefit_admission
        self.assertTrue(benefit_admission(self.normalize(), integration=True)['admitted'])
        for kind in ['control', 'unmeasured', 'structural']:
            row = dict(self.normalize()['rows'][0], kind=kind,
                       outcome={'control': 'control-only', 'unmeasured': 'not-measured',
                                'structural': 'structural-only'}[kind])
            with self.subTest(kind=kind):
                result = benefit_admission({'rows': [row]}, integration=True)
                self.assertFalse(result['admitted'])
                self.assertIn('positive-benefit-unproven', result['reasons'])

    def test_units_source_profile_and_sample_count_are_checked(self):
        variants=[('after','unit','ms'),('after','samples',0),('after','samples',True),
                  ('after','value','NaN'),('after','value','Infinity'),('after','value',-1)]
        original=copy.deepcopy(self.data)
        for section,key,value in variants:
            with self.subTest(key=key,value=value):
                self.data=copy.deepcopy(original);self.data[section][key]=value;self.save()
                with self.assertRaises(ValueError):self.normalize()
        for key in ['sourceTree','profileSha256','baseRevision']:
            self.data=copy.deepcopy(original);self.data[key]='wrong';self.save()
            with self.assertRaises(ValueError):self.normalize()

    def test_missing_duplicate_literal_and_cache_rows_are_rejected(self):
        original=copy.deepcopy(self.matrix)
        for change in ['empty','duplicate','missing','literal','cache','pointer']:
            self.matrix=copy.deepcopy(original)
            if change=='empty':self.matrix['rows']=[]
            elif change=='duplicate':self.matrix['rows']*=2
            elif change=='missing':del self.matrix['rows'][0]['limitation']
            elif change=='literal':self.matrix['rows'][0]['baseline']=20
            elif change=='cache':self.matrix['rows'][0]['evidence']=['.cache/result.json']
            else:self.matrix['rows'][0]['baseline']['pointer']='/absent'
            with self.subTest(change=change),self.assertRaises(ValueError):self.normalize()

    def test_unmeasured_and_accounted_cost_do_not_fabricate_samples(self):
        row=self.matrix['rows'][0];row.update(kind='unmeasured',direction='none',baseline=None,candidate=None)
        self.assertEqual(self.normalize()['rows'][0]['outcome'],'not-measured')
        row.update(kind='accounted-cost',candidate={'path':'evidence.json','pointer':'/after'})
        self.data['after']['samples']=0;self.save()
        self.assertEqual(self.normalize()['rows'][0]['outcome'],'accounted-cost')
        row['kind']='measurement';row['direction']='lower'
        with self.assertRaises(ValueError):self.normalize()

    def test_curated_number_cannot_disagree_with_raw_observation(self):
        self.data['after']['value']=999
        (self.root/'evidence.json').write_text(json.dumps(self.data))
        with self.assertRaisesRegex(ValueError,'raw evidence'):
            self.normalize()
        # Python's True == 1 must not turn a boolean raw field into a quantity.
        self.data['after']['value']=1
        for field in ['value','samples']:
            self.save()
            raw=json.loads((self.root/'raw.json').read_text())
            raw['after'][field]=True
            (self.root/'raw.json').write_text(json.dumps(raw))
            with self.subTest(field=field),self.assertRaisesRegex(ValueError,'raw evidence'):
                self.normalize()


class HistogramQuantileTests(unittest.TestCase):
    def test_retained_frequencies_reproduce_nearest_rank_and_median(self):
        from gambit_smp.revision_matrix import histogram_quantiles
        self.assertEqual(histogram_quantiles([
            dict(seconds=0.0, count=2), dict(seconds=2.0, count=2)], 4),
            dict(p50Seconds=1.0, p95Seconds=2.0, p99Seconds=2.0))
        self.assertEqual(histogram_quantiles([dict(seconds=.5, count=3)], 3)['p50Seconds'], .5)

    def test_missing_samples_duplicates_nan_and_boolean_counts_are_rejected(self):
        from gambit_smp.revision_matrix import histogram_quantiles
        for rows, count in [([], 1), ([dict(seconds=0, count=1)], 2),
                            ([dict(seconds=0, count=True)], 1),
                            ([dict(seconds=float('nan'), count=1)], 1),
                            ([dict(seconds=-1, count=1)], 1),
                            ([dict(seconds=0, count=1), dict(seconds=0, count=1)], 2)]:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                histogram_quantiles(rows, count)


class CompiledReleaseEvidenceTests(unittest.TestCase):
    def test_actual_compiled_population_replays_quantiles_and_preserves_outliers(self):
        import statistics
        from gambit_smp.branch_evidence import validate_recorded_cases
        from gambit_smp.revision_matrix import histogram_quantiles
        root = Path(__file__).resolve().parents[1]
        p = root / 'evidence/research/retained/modern-c/request-product/compiled-release.json'
        data = json.loads(p.read_text())
        self.assertEqual(validate_recorded_cases(data)['outcomes'],
                         dict(PASS=32, FAIL=0, UNRESOLVED=0))
        self.assertFalse(data['runtimeAdmitted'])
        self.assertEqual([v['role'] for v in data['builds']],
                         ['baseline', 'candidate', 'candidate', 'baseline'] * 2)
        self.assertEqual(len({v['moduleSha256'] for v in data['samples']}), 1)
        for row in data['samples']:
            for key, value in histogram_quantiles(row['latencyHistogram'], 4096).items():
                self.assertEqual(value, row['metrics'][key])
        for role in ['baseline', 'candidate']:
            for processors in [1, 2]:
                selected = [v for v in data['samples'] if v['role'] == role
                            and v['processors'] == processors]
                self.assertEqual(len(selected), 4)
                self.assertTrue(all(v['accepted'] for v in selected))
                field = data['summaryMeasurements'][role + '-p' + str(processors) + '-bodySeconds']
                self.assertEqual(field['value'], statistics.median(v['metrics']['bodySeconds'] for v in selected))


class GerbilConsumerEvidenceTests(unittest.TestCase):
    def test_successful_real_map_consumer_cannot_clear_failed_whole_build(self):
        from gambit_smp.branch_evidence import validate_recorded_cases
        root = Path(__file__).resolve().parents[1]
        folder = root / 'evidence/research/retained/modern-c/request-product'
        record = json.loads((folder / 'gerbil-map-consumer.json').read_text())
        self.assertEqual(validate_recorded_cases(record)['outcomes'],
                         dict(PASS=2, FAIL=0, UNRESOLVED=0))
        history = json.loads((folder / 'gerbil-consumer-history.json').read_text())
        self.assertFalse(history['wholeProductAdmitted'])
        runs = {v['id']: v for v in history['history']}
        self.assertTrue(runs['request-product-gerbil-official-bach-current-context']['complete'])
        failed = runs['request-product-gerbil-downstream']
        self.assertFalse(failed['complete'])
        self.assertEqual([c['stage'] for c in failed['commands']], ['gerbil-official-stdlib'])
        self.assertTrue(failed['commands'][0]['timeout'])
        self.assertTrue(failed['commands'][0]['processGroupQuiescent'])
        self.assertTrue(history['pendingPhaseOutputs'])
        source = history['buildSourceEvidence']['src/std/make.ss']['text']
        # Keep the original source counterexample, not a simulated native PASS.
        self.assertIn('(def (gxc-outputs mod opts settings)', source)
        self.assertIn('(execute-pending-compile-jobs!)', source)
