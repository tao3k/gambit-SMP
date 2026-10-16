# BTQ Incident Word Provenance

## Checked ABI Fact

The current exact-image incident records sibling word `0x923e8b031` and child
word `0xffffd4ffffffffff`. The preceding sibling-field load is word aligned;
the following color load faults at child + 39. No captured address is
dereferenced by the classification fixture.

The sealed recipe compiles against the current producer's configured header
with GNU GCC. It checks 64-bit words, three tag bits, STRUCTURE tag 1 and the
captured child tag 7. Tag 7 also names the configured heap-flonum tag, but this
does not make the captured word a valid flonum object. It is not ABSENT, TRUE
or FALSE. The native classification passed in 12.705 whole seconds.

## Consequence For The Model

The source forwarding expression is:

```c
___TAG(___UNTAG_AS(head_now, ___FORW), ___TYP(obj))
```

For aligned forwarding destinations and a structure-tagged input, it preserves
tag 1. Reconstructing a header that would yield the captured child does not
yield a FORW header. Therefore a wrong destination alone is insufficient under
these preconditions. This is not an exhaustive explanation of corruption.

The CAS-loser branch in `mark_array` assumes the competing header is the valid
forwarding pointer. The model currently guarantees that premise by construction;
the native incident does not establish it. Likewise, the physical-copy model
starts with valid projected payloads. A model PASS cannot validate either input
premise for the real runtime.

Before another native candidate, establish source payload/object-layout
provenance and the old-header lifetime across collector participation and
allocation generations. Invalid CAS return headers, a malformed source edge,
wrong object/layout, lifetime violation or other corruption remain open. The
captured words alone do not select among them. Do not retry the unchanged
stress, add a speculative barrier, or label this classification a source fix.

The portable classification binds its C fixture, recipe, source lock and
whitelisted crash record under `evidence/fixtures/darwin-ffi-return-premise/`.
The report is image-bound, not child-PID-bound. No sixth milestone gate closes.
