"""One task-bound tool family; implementation modules are not alternate policies."""
import argparse
from importlib import import_module

TOOLS={name.replace('_','-'):name for name in (
    'grok_event_wait','locked_object','process_observation','induction_reuse',
    'source_provision','wakeup_fairness','fixture_storage','guard_projection',
    'model_projection','view_materialize','unicode_campaign','notification_schedule','native_archive')}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('tool',choices=TOOLS)
    parser.add_argument('arguments',nargs=argparse.REMAINDER)
    args=parser.parse_args()
    import sys
    previous=sys.argv
    try:
        sys.argv=['gambit-smp tool '+args.tool,*args.arguments]
        return import_module('gambit_smp.'+TOOLS[args.tool]).main()
    finally:sys.argv=previous
