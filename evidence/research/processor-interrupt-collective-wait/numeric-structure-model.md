# Numeric structure model

Status: model and specification, not verified. Performance claims are false. Native qualification is false. This note records current observations, a structural source fact, an open hypothesis, and a discrimination plan. It does not name a root cause and does not treat a count or a sample as a complexity theorem.

## Verified observations

The source under the current Apple GCC flags is unchanged. Preprocess takes 3.6458 seconds and writes `num.i` at 23032952 bytes. Syntax-only compilation takes 24.8125 seconds and exits 0 inside a 60 second bound. The original 90 second timeout includes about 15 seconds of Scheme-to-C translation before the C compiler starts. The syntax-only command includes preprocessing and frontend semantic work; its wall time is not a measurement of the parser alone. That cost does not establish the parser as the sole cause. Later passes stay in scope. A scheduling-flag sweep is out of scope for this model.

## Structural source fact

The stack-write diagnostic macro is defined around header line 6759 (this is a line location, NOT an occurrence count). On Apple GCC each generated stack store expands to a compound statement of this shape:

```c
do {
  WORD *target = fp - fpo;
  if (EXPECT_FALSE(target < ps->mem.alloc_stack_limit_))
    diagnose_stack_write(ps, fp, target, R0, FILE, LINE);
  *target = val;
} while (0);
```

The expansion is a retained diagnostic abort guard. The baseline header from before that diagnostic used a direct `FP_SET_STK`. Label placement is concentrated: the single-host profile combines the module code in one host function, and 7613 of them sit in the largest Scheme procedure.

## Hypothesis

Repeated introduction of a local block, a temporary, and a limit check on every store may change C parser scope work or later code generation, or some other backend cost may dominate. Either reading is a hypothesis. The expansion must be discriminated before any source change is treated as evidence.

## Discrimination

Derive exact current C macro-expansion counts and lexical-block counts from the preprocessed text. Do not use an AST for that count. Compare controlled header variants with the diagnostic on and with the diagnostic off, and only inside the DIAGNOSTIC phase. Removing the guard is not a qualified fix. Removing printer protection is not a qualified fix. The preferred shape, if a later change is justified, is a source-preserving diagnostic helper that factors the check while keeping evaluation order, garbage-collection obligations, and the ABI explicit.

Sample the project's own compiler at post-parse intervals. Keep the full numeric workload and the unchanged capability cap as the final acceptance gate. A sample or a count does not yield a complexity theorem.

## Costs tuple

| Quantity | Current value |
| --- | --- |
| Preprocessed bytes | 23032952 |
| Labels | 8008, all in one host |
| Largest Scheme procedure label count | 7613; this is not a local-variable count |
| Blocks | unknown until the lexical-block census |
| Phase times | Scheme-to-C about 15 s inside the old 90 s timeout; preprocess 3.6458 s; syntax-only 24.8125 s, exit 0, within 60 s |

## Prediction matrix

Rows are mechanisms. Columns are what a DIAGNOSTIC-only on/off header compare would have to show before the mechanism stays plausible. None of these cells is confirmed.

| Mechanism | Bytes | Labels | Max-host locals | Blocks | Phase times |
| --- | --- | --- | --- | --- | --- |
| Per-store block and temporary inflate parser scope work | `num.i` grows with each expanded store | Label count stays near 8008 if the Scheme compiler is unchanged | Local introductions rise about one per `___SET_STK` | Lexical blocks rise about one `do` per store | Syntax-only moves when the diagnostic macro is toggled; later passes may still dominate |
| Check or call, not the block, dominates frontend work | Bytes move with the `if` and `diagnose_stack_write` text | Labels unchanged | Locals rise only for `write_target` | Blocks rise, but time tracks the call text more than the `do` | Syntax-only delta survives a helper that keeps one block and drops repeated call text, or the reverse |
| Backend or post-parse pass, not the parser | Preprocess stays near 3.6458 s and 23032952 bytes | 8008 / 7613 split unchanged | Locals may rise without explaining syntax-only | Block census can be large while syntax-only stays flat | Interval samples after parse move; syntax-only near 24.8125 s does not explain the old 90 s budget |
| Scheme-to-C or host label volume | Bytes follow generated C, not only the header | Single-host 8008 and largest-procedure 7613 stay the mass | Locals follow the largest procedure | Blocks follow generated control flow | About 15 s remains outside C syntax-only; flag sweeps do not address it |

Acceptance remains the full numeric run under the unchanged capability cap. Until the census and the diagnostic-only compare exist, this file stays a model: not verified, performance false, native false.

## Auditor corrections and census

Header line 6759 was misread as a count in the Grok draft; the draft is retained in the public write event. Syntax-only timing is not pure parser time. The diagnostic expansion is a compound statement, not a GNU statement expression. Actual counts are retained in `.cache/current-numeric-phase-discrimination-01/structure-census.json`: {"astMeasured": false, "expandedDiagnosticCallTokens": 3308, "expandedStackTargetDeclarations": 3307, "generatedCBytes": 5541691, "generatedCSha256": "35f9489c4e709579d094fafc04f05c2248fcecfb1c804db06940c20122e61158", "generatedStackStoreInvocations": 3307, "lexicalBraceFinalBalance": 0, "lexicalBraceMaxDepth": 5, "lexicalBraceOpens": 55846, "nativeAdmitted": false, "preprocessedBytes": 23032952, "preprocessedSha256": "25c915b8ab956f484e0a930ec4005cc052c4026a6ac56b4683260a35dfe1b201"}. Lexical braces do not establish AST depth or asymptotic cost. No source repair follows from these counts alone.

## Current post-parse audit boundary

The initial census regex counted both declarations and assignments, yielding
6614. The corrected declaration-only census records 3307, matching generated
stack-store invocations; the preceding document bytes are retained in
`.cache/numeric-structure-model-precount-audit-01.md`. This correction is a
measurement repair, not a change to any historical test outcome.

The unchanged full C compile timed out after 60.208 s in the diagnostic sampling
run (`current-numeric-postparse-sample-01/receipt.json`). The isolated global-cell
noinline control also timed out after 60.270 s with no artifact
(`current-numeric-globalcell-outline-01/receipt.json`). Explicit no-PTA sampling
still timed out after 60.033 s with no artifact
(`current-numeric-no-pta-postparse-01/receipt.json`). Grok reports that the latter
samples no longer contain the PTA pass names and include a later combine phase.
That report distinguishes a shifted bottleneck; it does not establish a complete
source-level cause or qualify disabling PTA as a fix. The original 90 s numerical
case and full GSC/Gerbil gates remain unchanged and open.
