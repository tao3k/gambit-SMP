#!/bin/bash
set -euo pipefail
r=.cache/tasks/guaranteed-tail-placement
for case_id in "$@"; do
 .venv/bin/gambit-smp --task guaranteed-tail-placement trajectory clues < "$r/case-$case_id.request.scm" > "$r/case-$case_id.read.scm" 2> "$r/case-$case_id.log"
 ASSURANCE_READ="$r/case-$case_id.read.scm" ASSURANCE_JSON="$r/case-$case_id.json" emacs -Q --batch -l "$r/read-association.el"
done
