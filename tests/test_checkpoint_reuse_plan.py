import copy
import unittest

from gambit_smp.recipes import checkpoint_reuse_plan
from gambit_smp.step_checkpoint import content_id


class CheckpointReusePlanTests(unittest.TestCase):
    def setUp(self):
        self.steps = [dict(id='core', capability='gambit.source-core', arguments={'runtime': 'seed'},
                           dependsOn=[], budgetSeconds=2000),
                      dict(id='review', capability='gambit.review', arguments={},
                           dependsOn=['core'], budgetSeconds=20)]
        self.prior = [dict(step, outcome='PASS', stageSeconds=12) for step in self.steps]
        self.records = [dict(payload=dict(schema='research-step-observation.v1', step=row))
                        for row in self.prior]
        self.eligible = [[row['id'], content_id(row)] for row in self.prior]

    def plan(self, *, same_executor=True):
        return checkpoint_reuse_plan(self.steps, self.records, self.eligible, same_executor=same_executor)

    def test_current_consumable_dependency_chain_is_reused(self):
        retained, decisions = self.plan()
        self.assertEqual(list(retained), ['core', 'review'])
        self.assertEqual([row['reason'] for row in decisions], ['REUSE', 'REUSE'])

    def test_changed_executor_reports_preserved_build_without_admitting_it(self):
        retained, decisions = self.plan(same_executor=False)
        self.assertEqual(retained, {})
        core = decisions[0]
        self.assertEqual(core['reason'], 'EXECUTOR_CHANGED')
        self.assertEqual(core['checkedTransportCapability'], 'gambit.runtime-import')
        self.assertFalse(core['transportAdmitted'])
        self.assertEqual(core['priorStageSeconds'], 12)

    def test_non_consumable_ancestor_prevents_descendant_reuse(self):
        self.eligible = self.eligible[1:]
        retained, decisions = self.plan()
        self.assertEqual(retained, {})
        self.assertEqual([row['reason'] for row in decisions],
                         ['CHECKPOINT_NOT_CONSUMABLE', 'DEPENDENCY_NOT_REUSED'])
        self.assertEqual(decisions[1]['dependenciesNotReused'], ['core'])

    def test_changed_native_contract_is_named_and_not_reused(self):
        self.steps = copy.deepcopy(self.steps)
        self.steps[0]['arguments'] = {'runtime': 'different-seed'}
        retained, decisions = self.plan()
        self.assertEqual(retained, {})
        self.assertEqual(decisions[0]['changedContractFields'], ['arguments'])
        self.assertEqual(decisions[0]['reason'], 'STAGE_CONTRACT_CHANGED')

    def test_failed_or_missing_stage_never_becomes_a_transport_candidate(self):
        self.prior[0]['outcome'] = 'DENY'
        self.records.pop()
        retained, decisions = self.plan()
        self.assertEqual(retained, {})
        self.assertEqual([row['reason'] for row in decisions], ['PRIOR_NOT_PASS', 'NO_PRIOR_STAGE'])
        self.assertNotIn('checkedTransportCapability', decisions[0])

    def test_ordered_campaign_never_reuses_a_prior_stress_step(self):
        for row in (self.steps[1], self.prior[1]):
            row.update(capability='gambit.suite', arguments={'orderedStress': {}})
        self.eligible[1] = [self.prior[1]['id'], content_id(self.prior[1])]
        retained, decisions = self.plan()
        self.assertEqual(list(retained), ['core'])
        self.assertEqual(decisions[1]['reason'], 'ORDERED_CAMPAIGN_REQUIRES_FRESH_CLOCK')
