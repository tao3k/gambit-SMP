# Explicit opam tool environments

Agentic AI does not need shell activation or eval. The framework uses official
opam exec with an explicit switch and --set-switch. Each invocation receives
its own environment; the parent PATH and current switch are unchanged. No
opam init, switch set, install, shell startup file or fallback backend is used.

```sh
gambit-smp tool-environment \
  --request evidence/tool-environments/herdtools7-opam.json \
  --out .cache/herd-environment-new --timeout 15
```

The generic Python entry is `gambit_smp.tool_environment.observe`. The caller
declares the switch, executable basename, supported information-only version
flag and optional read-only opam variables. Tool names are not whitelisted;
arbitrary research argv, shell expressions and variable assignments are not
part of this discovery operation. A trusted executable's version probe is
still host execution, not a sandbox. Supply an explicit manager path when it
is absent from the declared PATH. No missing-switch search or silent fallback
changes the requested environment.

The observation contains resolved manager/tool paths and SHA256, actual
versions, every argv, stdout/stderr, final exit/timeout/group state, total
budget/time, opam variable outputs and an explicit launchPrefix. All processes
share one deadline. Missing tools, failed queries, denied writes to opam logs,
timeouts, and manager/tool byte drift remain failed observations. Output
directories are never overwritten. The opam installation may write its own
logs even for a read query; a denied query needs legitimate host permission,
not a substitute opam root.

The launch prefix is a proposed route, not perpetual validity or execution
authority. Re-observe and bind identities when executing an experiment. The
discovery hashes manager/tool bytes only, not OCaml dependencies or the full
transitive .cat closure. Resource directory discovery does not hash its
contents. It does not execute a litmus, establish source refinement, admit a
retry, grant permission, or prove a repair.

The tool-reasoning Evidence view exposes source-bound environment_options for
the two herd7 analysis profiles and the Action query
inspect-tool-environment-route. It only points to the declaration. Discovery
does not run implicitly during Action discovery, and an environment hint does
not discharge herd memory-model or source-mapping premises. Other tools and
environment mechanisms remain open-world options.

## Actual local observation

`.cache/tool-environment-063-real-001/observation.json` completed in0.592s under
the original15s whole budget. Actual herd7 was7.58, Rev: exported, binary SHA
c46aa819461a6049744da0a9c21433173e04aace427f9b28f0d157eec541ee65.
All five queries exited0 without timeout and with quiescent process groups.
The selected manager was Homebrew opam2.6.1; lib/share directories came from
the selected switch's own opam variables. The receipt SHA is
077f70576353c9a7062f26eab6db486b02833b38467e165db0da90f50df5f514.
This is a local observation, not a portable installation or archived model run.

Initial resource queries were denied access to opam's own logs; the actual
successful observation used explicit host permission. Initial unit tests
retained a /var versus /private/var path expectation failure; canonicalizing
the temporary fixture root corrected that test, not production identity checks.
The final four transport controls passed0.147s/15. They are not full consumer
or complete-current-graph qualification.

Official basis: https://opam.ocaml.org/doc/man/opam-exec.html and
https://opam.ocaml.org/doc/man/opam-var.html.
