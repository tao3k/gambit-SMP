# Stored Map Points and Proposed Frame Contracts

This is a bounded textual inventory, not compiler output from this study.
The [JSON](map-generated-c-points.json) includes exact source/hash correspondence
and proposed record field sets. See ME02, ME05–ME08 and ME14 in the
[evidence ledger](map-generated-c-evidence.md).

Entry L0 has the procedure descriptor, not a return-frame descriptor. L1–L22
below cover the stored return table. Local goto labels L23–L39 are not additional
addressable return-table entries. New PointIds are assigned to semantic graph
occurrences and role/resume outcomes; none is derived from these C ordinals.

| Stored point | Kind | Encoded fs / link | Literal gcmap | Decoded fs / physical words | Actual origin or next action |
| --- | --- | --- | --- | --- | --- |
| [L1](../../../vendor/gambit/lib/_std.c#L74775) | RETI | 8 / 0 | `0x3f07` | 17 / 20 | one-list wrapper entry checkpoint |
| [L2](../../../vendor/gambit/lib/_std.c#L74780) | RETN | 5 / 0 | `0x7` | 5 / 8 | one-list arbitrary callback returned |
| [L3](../../../vendor/gambit/lib/_std.c#L74795) | RETI | 8 / 0 | `0x3f07` | 17 / 20 | one-list callback pre-transfer checkpoint |
| [L4](../../../vendor/gambit/lib/_std.c#L74798) | RETN | 5 / 0 | `0x9` | 5 / 8 | one-list recursive tail returned; construct output pair |
| [L5](../../../vendor/gambit/lib/_std.c#L74806) | RETI | 1 / 0 | `0x3f1` | 13 / 16 | one-list output pair already constructed |
| [L6](../../../vendor/gambit/lib/_std.c#L74809) | RETN | 5 / 0 | `0x9` | 5 / 8 | multi-list recursive tail returned; inspect sentinel |
| [L7](../../../vendor/gambit/lib/_std.c#L74820) | RETI | 1 / 0 | `0x3f1` | 13 / 16 | multi-list output pair already constructed |
| [L8](../../../vendor/gambit/lib/_std.c#L74828) | RETN | 5 / 0 | `0xf` | 5 / 8 | cdrs returned during multi-list recursion |
| [L9](../../../vendor/gambit/lib/_std.c#L74839) | RETN | 5 / 0 | `0x7` | 5 / 8 | initial cdrs returned to multi-list wrapper |
| [L10](../../../vendor/gambit/lib/_std.c#L74865) | RETI | 8 / 0 | `0x3f07` | 17 / 20 | before cars helper transfer |
| [L11](../../../vendor/gambit/lib/_std.c#L74868) | RETN | 5 / 0 | `0x7` | 5 / 8 | cars returned; prepare apply |
| [L12](../../../vendor/gambit/lib/_std.c#L74873) | RETN | 5 / 0 | `0x7` | 5 / 8 | apply returned; save callback element |
| [L13](../../../vendor/gambit/lib/_std.c#L74897) | RETI | 8 / 8 | `0x3f03` | 17 / 20 | before tail transfer to fail-check-list |
| [L14](../../../vendor/gambit/lib/_std.c#L74900) | RETN | 5 / 0 | `0x7` | 5 / 8 | map-n helper returned to checked wrapper |
| [L15](../../../vendor/gambit/lib/_std.c#L74922) | RETI | 8 / 8 | `0x3f03` | 17 / 20 | before tail transfer to raise length mismatch |
| [L16](../../../vendor/gambit/lib/_std.c#L74941) | RETI | 8 / 8 | `0x3f03` | 17 / 20 | before tail transfer to fail-check-proper-list |
| [L17](../../../vendor/gambit/lib/_std.c#L74947) | RETN | 5 / 0 | `0x7` | 5 / 8 | one-list helper returned to checked wrapper |
| [L18](../../../vendor/gambit/lib/_std.c#L74958) | RETI | 8 / 8 | `0x3f01` | 17 / 20 | before tail transfer to one-list proper-list failure |
| [L19](../../../vendor/gambit/lib/_std.c#L74968) | RETI | 1 / 4 | `0x3f1` | 13 / 16 | before tail transfer to initial list failure |
| [L20](../../../vendor/gambit/lib/_std.c#L74978) | RETI | 8 / 0 | `0x3f07` | 17 / 20 | list-of-lists pair already constructed |
| [L21](../../../vendor/gambit/lib/_std.c#L74980) | RETI | 8 / 0 | `0x3f07` | 17 / 20 | before initial cdrs helper transfer |
| [L22](../../../vendor/gambit/lib/_std.c#L74989) | RETI | 3 / 4 | `0x3f7` | 13 / 16 | before procedure-check failure transfer |

Encoded RETI fs is caller extent and expands by the saved-register/actual-return
area. The arithmetic uses the selected header template constants, not an active
Darwin preprocessing result. Physical words include FRAME_SPACE alignment and
reserve; they are not live-root counts. Literal maps are not reinterpreted as
semantic variable names. Producer and independent reader agreement is required.

L2 and L4 both have RETN size 5/link 0 but different maps (0x7 versus 0x9).
L13/L15/L16 use internal link 8, whereas L19/L22 use link 4. This reflects real
argument/stack rearrangement and makes one universal map frame invalid. The new
planner must calculate equivalent meaning from completed homes and effects,
not copy one old mask or use a maximum-size catch-all frame.

The 13 internal descriptions correspond to ten poll resumptions and three
heap-check resumptions. This does not enumerate every collecting point inside
callbacks/helpers, rest/arity handlers, foreign bridges or GC runtime. The
transitive closed domain is a separate obligation.

Proposed records separate logical FrameSpec, semantic PointIntent, physical
FrameLayout and ModulePlan. Their fields in the JSON are design data only.
A renderer must reject missing representation, link, role-entry, relocation or
failure-state fields; it cannot supply them by silently invoking old C semantic
inference. Zero records have new-generator/native witnesses.
