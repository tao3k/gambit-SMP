"""REV metric provenance/arithmetic controls; these are not runtime benchmarks."""
import copy
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.revision_matrix import normalize_matrix, render_matrix

FIELDS = 'id,kind,metric,unit,direction,baseline,candidate,workload,method,evidence,limitation'.split(',')
KINDS = 'measurement,control,accounted-cost,structural,unmeasured'.split(',')


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
