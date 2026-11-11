# Reviewed defined-access model result

The local campaign reported `accepted=true`, `contextStable=true`, and
46.221 seconds for twelve finite-state checks. The two positive checks
exhausted their queues:

| Model | SHA-256 | Distinct states |
| --- | --- | --- |
| `owner_defined_certificate` | `0b1304a900dd9e73400a1c9489d32b790788e05430b27ff64581e07a4db3b9b3` | 7510 |
| `barrier_local_winner` | `e640b817c211103365c9cdcb701c45b425cf6066bc0d54f7f7c04dded61fdfbe` | 4452 |

Ten negative controls produced the expected invariant counterexamples. The
campaign used the existing default guard. Its raw disposable receipt is
`.cache/consumer-defined-access/receipt.json`, SHA-256
`a2c0b3a0452fe5bed1faeea4814b0bf3b3599d408539c1f2896f0c2908ba6f77`.
The manifest digest is
`38e7ca2c0d09944dca03e4145a592fe260088ef802820c056614ccc7f30f3a75`;
the defined-access contract digest is
`632a0e411c4f40b283598339652aa93eb5af3f3c0e1c2cd0d5c716e0142f89d1`.

The checkpoint receipt for this document attests a review of these bound
results, not a newly executed native command. Its explicitly empty command
inventory is limited to that review. It cannot qualify a native test receipt.
Native/release admission remains false. The initial failed current-ownership
assertion remains reproducible in
`owner_seqlock_publication.failed-current-assertion.qnt` with digest
`a00de3f00eb28eada0fc6d91da0cf8fe578c5d61c45e072b9751b3a765a5a7aa`.

This result does not establish coverage of Scheme lock acquisition, caller
identity in remote C entry points, a current pre-election barrier wait, a
functional lock/collective progress repair, or an original stress pass.
