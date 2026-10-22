#!/bin/bash
set -euo pipefail
r=.cache/tasks/component-assurance
for query_name in "$@"; do
 .venv/bin/gambit-smp --task component-assurance trajectory clues < "$r/$query_name.request.scm" > "$r/$query_name.read.scm" 2> "$r/$query_name.log"
 ASSURANCE_READ="$r/$query_name.read.scm" ASSURANCE_JSON="$r/$query_name.json" emacs -Q --batch -l "$r/read-association.el"
done
