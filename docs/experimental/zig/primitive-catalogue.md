# Primitive Catalogue: Source Metadata, Not MLIR Admission

Date: 2026-10-19. Documentation census only; no compiler was executed.

Source: [vendor/gambit/gsc/_prims.scm](../../../vendor/gambit/gsc/_prims.scm),
`prim-procs` literal table at vendor commit
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
Source SHA-256: `c6bc87cc87cb596c7b5bb71f51efeed44f2a1e3fac7a6a0084c09d4a10b807f1`.

The census preserves every active, single-line named record in this specific
literal table. All six metadata fields are copied as Scheme data, including
adjacent `)#f` tokens. Entry-line count equals extracted-row count; each row
has six fields and a Boolean side-effect field. This is text/data inspection,
not interpretation of Scheme or validation of a compiler export.

There are **1,588 source rows / 1,587 distinct names**. `##values` occurs twice
at lines 1464 and 1467 with identical fields; both occurrences are preserved.
`_back.scm:288-301` constructs the table by successive `table-set!` calls.
The table has **1,287 `#f` / 301 `#t` side-effect records**. Neither number
counts operations safe to annotate as MLIR `Pure`.

The C target additionally registers `##c-code` in `_t-c-1.scm:294-300`:
`("##c-code" 0 #t 0 0 (#f) extended)`. Thus the inspected base table plus this
one C-target addition contains **1,588 distinct names**. This is not the set
of every callable library procedure, generated FFI name or other backend's
extensions. The open-world default remains mandatory.

Every row has status **CAT**: catalogued, with no MLIR implementation or pass
admission established. Raw strictness/lift/type fields must not be read as
complete effect summaries or LLVM attributes. Family decisions, FFI forms,
required changes and the unknown-name policy are in
[primitive/FFI coverage](primitive-ffi-coverage.md).

## Standard Tags in the Literal Table

| Raw standard tag | Source rows |
| --- | --- |
| `ieee` | 176 |
| `extended` | 994 |
| `r7rs` | 26 |
| `r6rs` | 80 |
| `gambit` | 289 |
| `r4rs` | 15 |
| `r5rs` | 7 |
| `multilisp` | 1 |

## Complete Literal-Table Records

Each line number identifies its evidence in the source file linked above.
`Call`, `Strict`, `Lift`, `Result` and `Standard` are raw database fields,
not newly inferred contracts. All rows are CAT.

| Source line | Name | Call | Side effects? | Strict | Lift | Result | Standard |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 26 | `boolean?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 27 | `##boolean?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 28 | `not` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 29 | `##not` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 31 | `boolean=?` | `0` | `#f` | `0` | `0` | `boolean` | `r7rs` |
| 32 | `##boolean=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 36 | `*` | `0` | `#f` | `0` | `0` | `number` | `ieee` |
| 37 | `##*` | `0` | `#f` | `()` | `0` | `number` | `extended` |
| 38 | `+` | `0` | `#f` | `0` | `0` | `number` | `ieee` |
| 39 | `##+` | `0` | `#f` | `()` | `0` | `number` | `extended` |
| 40 | `-` | `1` | `#f` | `0` | `0` | `number` | `ieee` |
| 41 | `##-` | `1` | `#f` | `()` | `0` | `number` | `extended` |
| 42 | `/` | `1` | `#f` | `0` | `0` | `number` | `ieee` |
| 43 | `##/` | `1` | `#f` | `()` | `0` | `number` | `extended` |
| 44 | `<` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 45 | `##<` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 46 | `<=` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 47 | `##<=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 48 | `=` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 49 | `##=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 50 | `>` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 51 | `##>` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 52 | `>=` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 53 | `##>=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 54 | `abs` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 55 | `##abs` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 56 | `acos` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 57 | `##acos` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 58 | `angle` | `(1)` | `#f` | `0` | `0` | `real` | `ieee` |
| 59 | `##angle` | `(1)` | `#f` | `()` | `0` | `real` | `extended` |
| 60 | `asin` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 61 | `##asin` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 62 | `atan` | `(1 2)` | `#f` | `0` | `0` | `number` | `ieee` |
| 63 | `##atan` | `(1 2)` | `#f` | `()` | `0` | `number` | `extended` |
| 64 | `ceiling` | `(1)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 65 | `##ceiling` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 66 | `complex?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 67 | `##complex?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 68 | `cos` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 69 | `##cos` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 70 | `denominator` | `(1)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 71 | `##denominator` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 72 | `even?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 73 | `##even?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 74 | `exact->inexact` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 75 | `##exact->inexact` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 76 | `exact?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 77 | `##exact?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 78 | `exp` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 79 | `##exp` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 80 | `expt` | `(2)` | `#f` | `0` | `0` | `number` | `ieee` |
| 81 | `##expt` | `(2)` | `#f` | `()` | `0` | `number` | `extended` |
| 82 | `floor` | `(1)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 83 | `##floor` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 84 | `gcd` | `1` | `#f` | `0` | `0` | `integer` | `ieee` |
| 85 | `##gcd` | `1` | `#f` | `()` | `0` | `integer` | `extended` |
| 86 | `imag-part` | `(1)` | `#f` | `0` | `0` | `real` | `ieee` |
| 87 | `##imag-part` | `(1)` | `#f` | `()` | `0` | `real` | `extended` |
| 88 | `inexact->exact` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 89 | `##inexact->exact` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 90 | `inexact?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 91 | `##inexact?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 92 | `integer?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 93 | `##integer?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 94 | `lcm` | `1` | `#f` | `0` | `0` | `integer` | `ieee` |
| 95 | `##lcm` | `1` | `#f` | `()` | `0` | `integer` | `extended` |
| 96 | `log` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 97 | `##log` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 98 | `magnitude` | `(1)` | `#f` | `0` | `0` | `real` | `ieee` |
| 99 | `##magnitude` | `(1)` | `#f` | `()` | `0` | `real` | `extended` |
| 100 | `make-polar` | `(2)` | `#f` | `0` | `0` | `number` | `ieee` |
| 101 | `##make-polar` | `(2)` | `#f` | `()` | `0` | `number` | `extended` |
| 102 | `make-rectangular` | `(2)` | `#f` | `0` | `0` | `number` | `ieee` |
| 103 | `##make-rectangular` | `(2)` | `#f` | `()` | `0` | `number` | `extended` |
| 104 | `max` | `1` | `#f` | `0` | `0` | `number` | `ieee` |
| 105 | `##max` | `1` | `#f` | `()` | `0` | `number` | `extended` |
| 106 | `min` | `1` | `#f` | `0` | `0` | `number` | `ieee` |
| 107 | `##min` | `1` | `#f` | `()` | `0` | `number` | `extended` |
| 108 | `modulo` | `(2)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 109 | `##modulo` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 110 | `negative?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 111 | `##negative?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 112 | `number->string` | `(1 2)` | `#f` | `0` | `0` | `string` | `ieee` |
| 113 | `##number->string` | `(1 2)` | `#f` | `()` | `0` | `string` | `extended` |
| 114 | `number?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 115 | `##number?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 116 | `numerator` | `(1)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 117 | `##numerator` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 118 | `odd?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 119 | `##odd?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 120 | `positive?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 121 | `##positive?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 122 | `quotient` | `(2)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 123 | `##quotient` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 124 | `rational?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 125 | `##rational?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 126 | `rationalize` | `(2)` | `#f` | `0` | `0` | `number` | `ieee` |
| 127 | `##rationalize` | `(2)` | `#f` | `()` | `0` | `number` | `extended` |
| 128 | `real-part` | `(1)` | `#f` | `0` | `0` | `real` | `ieee` |
| 129 | `##real-part` | `(1)` | `#f` | `()` | `0` | `real` | `extended` |
| 130 | `real?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 131 | `##real?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 132 | `remainder` | `(2)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 133 | `##remainder` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 134 | `round` | `(1)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 135 | `##round` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 136 | `sin` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 137 | `##sin` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 138 | `sqrt` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 139 | `##sqrt` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 140 | `string->number` | `(1 2)` | `#f` | `0` | `0` | `number` | `ieee` |
| 141 | `##string->number` | `(1 2)` | `#f` | `()` | `0` | `number` | `extended` |
| 142 | `tan` | `(1)` | `#f` | `0` | `0` | `number` | `ieee` |
| 143 | `##tan` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 144 | `truncate` | `(1)` | `#f` | `0` | `0` | `integer` | `ieee` |
| 145 | `##truncate` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 146 | `zero?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 147 | `##zero?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 149 | `bitwise-and` | `0` | `#f` | `0` | `0` | `integer` | `r6rs` |
| 150 | `##bitwise-and` | `0` | `#f` | `()` | `0` | `integer` | `extended` |
| 151 | `bitwise-andc1` | `(2)` | `#f` | `()` | `0` | `integer` | `gambit` |
| 152 | `##bitwise-andc1` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 153 | `bitwise-andc2` | `(2)` | `#f` | `()` | `0` | `integer` | `gambit` |
| 154 | `##bitwise-andc2` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 155 | `bitwise-eqv` | `0` | `#f` | `0` | `0` | `integer` | `gambit` |
| 156 | `##bitwise-eqv` | `0` | `#f` | `()` | `0` | `integer` | `extended` |
| 157 | `bitwise-ior` | `0` | `#f` | `0` | `0` | `integer` | `r6rs` |
| 158 | `##bitwise-ior` | `0` | `#f` | `()` | `0` | `integer` | `extended` |
| 159 | `bitwise-nand` | `(2)` | `#f` | `()` | `0` | `integer` | `gambit` |
| 160 | `##bitwise-nand` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 161 | `bitwise-nor` | `(2)` | `#f` | `()` | `0` | `integer` | `gambit` |
| 162 | `##bitwise-nor` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 163 | `bitwise-not` | `(1)` | `#f` | `0` | `0` | `integer` | `r6rs` |
| 164 | `##bitwise-not` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 165 | `bitwise-orc1` | `(2)` | `#f` | `()` | `0` | `integer` | `gambit` |
| 166 | `##bitwise-orc1` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 167 | `bitwise-orc2` | `(2)` | `#f` | `()` | `0` | `integer` | `gambit` |
| 168 | `##bitwise-orc2` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 169 | `bitwise-xor` | `0` | `#f` | `0` | `0` | `integer` | `r6rs` |
| 170 | `##bitwise-xor` | `0` | `#f` | `()` | `0` | `integer` | `extended` |
| 171 | `exact-integer-sqrt` | `(1)` | `#f` | `0` | `0` | `#f` | `r6rs` |
| 172 | `##exact-integer-sqrt` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 173 | `finite?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 174 | `##finite?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 175 | `infinite?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 176 | `##infinite?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 177 | `nan?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 178 | `##nan?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 179 | `inexact` | `(1)` | `#f` | `0` | `0` | `number` | `r6rs` |
| 180 | `##inexact` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 181 | `exact` | `(1)` | `#f` | `0` | `0` | `number` | `r6rs` |
| 182 | `##exact` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 184 | `exact-integer?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r7rs` |
| 185 | `##exact-integer?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 186 | `floor-quotient` | `(2)` | `#f` | `0` | `0` | `integer` | `r7rs` |
| 187 | `##floor-quotient` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 188 | `floor-remainder` | `(2)` | `#f` | `0` | `0` | `integer` | `r7rs` |
| 189 | `##floor-remainder` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 190 | `floor/` | `(2)` | `#f` | `0` | `0` | `#f` | `r7rs` |
| 191 | `##floor/` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 192 | `square` | `(1)` | `#f` | `0` | `0` | `number` | `r7rs` |
| 193 | `##square` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 194 | `truncate-quotient` | `(2)` | `#f` | `0` | `0` | `integer` | `r7rs` |
| 195 | `##truncate-quotient` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 196 | `truncate-remainder` | `(2)` | `#f` | `0` | `0` | `integer` | `r7rs` |
| 197 | `##truncate-remainder` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 198 | `truncate/` | `(2)` | `#f` | `0` | `0` | `#f` | `r7rs` |
| 199 | `##truncate/` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 201 | `acosh` | `(1)` | `#f` | `0` | `0` | `number` | `gambit` |
| 202 | `##acosh` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 203 | `all-bits-set?` | `(2)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 204 | `##all-bits-set?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 205 | `any-bits-set?` | `(2)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 206 | `##any-bits-set?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 207 | `arithmetic-shift` | `(2)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 208 | `##arithmetic-shift` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 209 | `asinh` | `(1)` | `#f` | `0` | `0` | `number` | `gambit` |
| 210 | `##asinh` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 211 | `atanh` | `(1)` | `#f` | `0` | `0` | `number` | `gambit` |
| 212 | `##atanh` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 213 | `bit-count` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 214 | `##bit-count` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 215 | `bit-set?` | `(2)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 216 | `##bit-set?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 217 | `bitwise-merge` | `(3)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 218 | `##bitwise-merge` | `(3)` | `#f` | `()` | `0` | `integer` | `extended` |
| 219 | `clear-bit-field` | `(3)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 220 | `##clear-bit-field` | `(3)` | `#f` | `()` | `0` | `integer` | `extended` |
| 221 | `conjugate` | `(1)` | `#f` | `0` | `0` | `number` | `gambit` |
| 222 | `##conjugate` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 223 | `copy-bit-field` | `(4)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 224 | `##copy-bit-field` | `(4)` | `#f` | `()` | `0` | `integer` | `extended` |
| 225 | `cosh` | `(1)` | `#f` | `0` | `0` | `number` | `gambit` |
| 226 | `##cosh` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 227 | `extract-bit-field` | `(3)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 228 | `##extract-bit-field` | `(3)` | `#f` | `()` | `0` | `integer` | `extended` |
| 229 | `first-set-bit` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 230 | `##first-set-bit` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 231 | `integer-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 232 | `##integer-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 233 | `integer-nth-root` | `(2)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 234 | `##integer-nth-root` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 235 | `integer-sqrt` | `(1)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 236 | `##integer-sqrt` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 237 | `replace-bit-field` | `(4)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 238 | `##replace-bit-field` | `(4)` | `#f` | `()` | `0` | `integer` | `extended` |
| 239 | `sinh` | `(1)` | `#f` | `0` | `0` | `number` | `gambit` |
| 240 | `##sinh` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 241 | `tanh` | `(1)` | `#f` | `0` | `0` | `number` | `gambit` |
| 242 | `##tanh` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 243 | `test-bit-field?` | `(3)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 244 | `##test-bit-field?` | `(3)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 246 | `##bignum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 247 | `##bignum.negative?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 248 | `##bignum.adigit-length` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 249 | `##bignum.adigit-inc!` | `(2)` | `#t` | `()` | `0` | `integer` | `extended` |
| 250 | `##bignum.adigit-dec!` | `(2)` | `#t` | `()` | `0` | `integer` | `extended` |
| 251 | `##bignum.adigit-add!` | `(5)` | `#t` | `()` | `0` | `integer` | `extended` |
| 252 | `##bignum.adigit-sub!` | `(5)` | `#t` | `()` | `0` | `integer` | `extended` |
| 253 | `##bignum.mdigit-length` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 254 | `##bignum.mdigit-ref` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 255 | `##bignum.mdigit-set!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 256 | `##bignum.mdigit-mul!` | `(6)` | `#t` | `()` | `0` | `integer` | `extended` |
| 257 | `##bignum.mdigit-div!` | `(6)` | `#t` | `()` | `0` | `integer` | `extended` |
| 258 | `##bignum.mdigit-quotient` | `(3)` | `#f` | `()` | `0` | `integer` | `extended` |
| 259 | `##bignum.mdigit-remainder` | `(4)` | `#f` | `()` | `0` | `integer` | `extended` |
| 260 | `##bignum.mdigit-test?` | `(4)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 261 | `##bignum.adigit-ones?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 262 | `##bignum.adigit-zero?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 263 | `##bignum.adigit-negative?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 264 | `##bignum.adigit-=` | `(3)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 265 | `##bignum.adigit-<` | `(3)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 266 | `##bignum.make` | `(3)` | `#f` | `()` | `0` | `integer` | `extended` |
| 267 | `##fixnum->bignum` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 268 | `##bignum.adigit-shrink!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 269 | `##bignum.adigit-copy!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 270 | `##bignum.adigit-cat!` | `(7)` | `#t` | `()` | `0` | `#f` | `extended` |
| 271 | `##bignum.adigit-bitwise-and!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 272 | `##bignum.adigit-bitwise-andc1!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 273 | `##bignum.adigit-bitwise-andc2!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 274 | `##bignum.adigit-bitwise-eqv!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 275 | `##bignum.adigit-bitwise-ior!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 276 | `##bignum.adigit-bitwise-nand!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 277 | `##bignum.adigit-bitwise-nor!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 278 | `##bignum.adigit-bitwise-not!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 279 | `##bignum.adigit-bitwise-orc1!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 280 | `##bignum.adigit-bitwise-orc2!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 281 | `##bignum.adigit-bitwise-xor!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 282 | `##bignum.fdigit-length` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 283 | `##bignum.fdigit-ref` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 284 | `##bignum.fdigit-set!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 286 | `##bignum.adigit-width` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 287 | `##bignum.mdigit-width` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 288 | `##bignum.fdigit-width` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 290 | `##ratnum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 291 | `##ratnum-make` | `(2)` | `#f` | `()` | `0` | `number` | `extended` |
| 292 | `##ratnum-numerator` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 293 | `##ratnum-denominator` | `(1)` | `#f` | `()` | `0` | `integer` | `extended` |
| 295 | `##cpxnum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 296 | `##cpxnum-make` | `(2)` | `#f` | `()` | `0` | `number` | `extended` |
| 297 | `##cpxnum-real` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 298 | `##cpxnum-imag` | `(1)` | `#f` | `()` | `0` | `number` | `extended` |
| 302 | `fixnum?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 303 | `##fixnum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 304 | `##fixnums?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 305 | `fx*` | `0` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 306 | `##fx*` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 307 | `##fx*?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 308 | `fx+` | `0` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 309 | `##fx+` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 310 | `##fx+?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 311 | `fx-` | `1` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 312 | `##fx-` | `1` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 313 | `##fx-?` | `(1 2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 314 | `fx<` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 315 | `##fx<` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 316 | `fx<=` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 317 | `##fx<=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 318 | `fx=` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 319 | `##fx=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 320 | `fx>` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 321 | `##fx>` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 322 | `fx>=` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 323 | `##fx>=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 324 | `fxand` | `0` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 325 | `##fxand` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 326 | `fxandc1` | `(2)` | `#f` | `0` | `0` | `fixnum` | `extended` |
| 327 | `##fxandc1` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 328 | `fxandc2` | `(2)` | `#f` | `0` | `0` | `fixnum` | `extended` |
| 329 | `##fxandc2` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 330 | `fxarithmetic-shift` | `(2)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 331 | `##fxarithmetic-shift` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 332 | `##fxarithmetic-shift?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 333 | `fxarithmetic-shift-left` | `(2)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 334 | `##fxarithmetic-shift-left` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 335 | `##fxarithmetic-shift-left?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 336 | `fxarithmetic-shift-right` | `(2)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 337 | `##fxarithmetic-shift-right` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 338 | `##fxarithmetic-shift-right?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 339 | `fxbit-count` | `(1)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 340 | `##fxbit-count` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 341 | `fxbit-set?` | `(2)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 342 | `##fxbit-set?` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 343 | `fxeven?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 344 | `##fxeven?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 345 | `fxeqv` | `0` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 346 | `##fxeqv` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 347 | `fxfirst-set-bit` | `(1)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 348 | `##fxfirst-set-bit` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 349 | `fxif` | `(3)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 350 | `##fxif` | `(3)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 351 | `fxior` | `0` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 352 | `##fxior` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 353 | `fxlength` | `(1)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 354 | `##fxlength` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 355 | `fxmax` | `1` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 356 | `##fxmax` | `1` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 357 | `fxmin` | `1` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 358 | `##fxmin` | `1` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 359 | `fxmodulo` | `(2)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 360 | `##fxmodulo` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 361 | `fxnegative?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 362 | `##fxnegative?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 363 | `fxnand` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 364 | `##fxnand` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 365 | `fxnor` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 366 | `##fxnor` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 367 | `fxnot` | `(1)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 368 | `##fxnot` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 369 | `fxodd?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 370 | `##fxodd?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 371 | `fxorc1` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 372 | `##fxorc1` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 373 | `fxorc2` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 374 | `##fxorc2` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 375 | `fxpositive?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 376 | `##fxpositive?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 377 | `fxquotient` | `(2)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 378 | `##fxquotient` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 379 | `fxremainder` | `(2)` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 380 | `##fxremainder` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 381 | `fxxor` | `0` | `#f` | `0` | `0` | `fixnum` | `r6rs` |
| 382 | `##fxxor` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 383 | `fxzero?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 384 | `##fxzero?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 386 | `##fixnum-width` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 387 | `##fixnum-width-neg` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 388 | `##least-fixnum` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 389 | `##greatest-fixnum` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 407 | `fxabs` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 408 | `##fxabs` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 409 | `##fxabs?` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 410 | `fxsquare` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 411 | `##fxsquare` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 412 | `##fxsquare?` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 413 | `fxwrap*` | `0` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 414 | `##fxwrap*` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 415 | `fxwrap+` | `0` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 416 | `##fxwrap+` | `0` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 417 | `fxwrap-` | `1` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 418 | `##fxwrap-` | `1` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 419 | `fxwrapabs` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 420 | `##fxwrapabs` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 421 | `fxwraparithmetic-shift` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 422 | `##fxwraparithmetic-shift` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 423 | `##fxwraparithmetic-shift?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 424 | `fxwraparithmetic-shift-left` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 425 | `##fxwraparithmetic-shift-left` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 426 | `##fxwraparithmetic-shift-left?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 427 | `fxwraplogical-shift-right` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 428 | `##fxwraplogical-shift-right` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 429 | `##fxwraplogical-shift-right?` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 430 | `fxwrapquotient` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 431 | `##fxwrapquotient` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 432 | `fxwrapsquare` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 433 | `##fxwrapsquare` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 437 | `fixnum->flonum` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 438 | `##fixnum->flonum` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 439 | `fl*` | `0` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 440 | `##fl*` | `0` | `#f` | `()` | `0` | `flonum` | `extended` |
| 441 | `##ifl*` | `0` | `#f` | `()` | `0` | `flonum` | `extended` |
| 442 | `fl+` | `0` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 443 | `##fl+` | `0` | `#f` | `()` | `0` | `flonum` | `extended` |
| 444 | `##ifl+` | `0` | `#f` | `()` | `0` | `flonum` | `extended` |
| 445 | `fl-` | `1` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 446 | `##fl-` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 447 | `##ifl-` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 448 | `fl/` | `1` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 449 | `##fl/` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 450 | `##ifl/` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 451 | `fl<` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 452 | `##fl<` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 453 | `##ifl<` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 454 | `fl<=` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 455 | `##fl<=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 456 | `##ifl<=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 457 | `fl=` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 458 | `##fl=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 459 | `##ifl=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 460 | `fl>` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 461 | `##fl>` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 462 | `##ifl>` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 463 | `fl>=` | `0` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 464 | `##fl>=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 465 | `##ifl>=` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 466 | `flabs` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 467 | `##flabs` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 468 | `##iflabs` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 469 | `flacos` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 470 | `##flacos` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 471 | `##iflacos` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 472 | `flasin` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 473 | `##flasin` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 474 | `##iflasin` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 475 | `flatan` | `(1 2)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 476 | `##flatan` | `(1 2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 477 | `##iflatan` | `(1 2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 478 | `flceiling` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 479 | `##flceiling` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 480 | `##iflceiling` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 481 | `flcos` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 482 | `##flcos` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 483 | `##iflcos` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 484 | `fldenominator` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 485 | `##fldenominator` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 486 | `##ifldenominator` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 487 | `fleven?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 488 | `##fleven?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 489 | `##ifleven?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 490 | `flexp` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 491 | `##flexp` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 492 | `##iflexp` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 493 | `flexpt` | `(2)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 494 | `##flexpt` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 495 | `##iflexpt` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 496 | `flfinite?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 497 | `##flfinite?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 498 | `##iflfinite?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 499 | `flfloor` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 500 | `##flfloor` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 501 | `##iflfloor` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 502 | `flinfinite?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 503 | `##flinfinite?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 504 | `##iflinfinite?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 505 | `flinteger?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 506 | `##flinteger?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 507 | `##iflinteger?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 508 | `fllog` | `(1 2)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 509 | `##fllog` | `(1 2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 510 | `##ifllog` | `(1 2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 511 | `flmax` | `1` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 512 | `##flmax` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 513 | `##iflmax` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 514 | `flmin` | `1` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 515 | `##flmin` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 516 | `##iflmin` | `1` | `#f` | `()` | `0` | `flonum` | `extended` |
| 517 | `flnan?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 518 | `##flnan?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 519 | `##iflnan?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 520 | `flnegative?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 521 | `##flnegative?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 522 | `##iflnegative?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 523 | `flnumerator` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 524 | `##flnumerator` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 525 | `##iflnumerator` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 526 | `flodd?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 527 | `##flodd?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 528 | `##iflodd?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 529 | `flonum?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 530 | `##flonum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 531 | `##iflonum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 532 | `##flonums?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 533 | `##iflonums?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 534 | `flpositive?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 535 | `##flpositive?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 536 | `##iflpositive?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 537 | `flround` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 538 | `##flround` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 539 | `##iflround` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 540 | `flsin` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 541 | `##flsin` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 542 | `##iflsin` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 543 | `flsqrt` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 544 | `##flsqrt` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 545 | `##iflsqrt` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 546 | `fltan` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 547 | `##fltan` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 548 | `##ifltan` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 549 | `fltruncate` | `(1)` | `#f` | `0` | `0` | `flonum` | `r6rs` |
| 550 | `##fltruncate` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 551 | `##ifltruncate` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 552 | `flzero?` | `(1)` | `#f` | `0` | `0` | `boolean` | `r6rs` |
| 553 | `##flzero?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 554 | `##iflzero?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 564 | `flacosh` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 565 | `##flacosh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 566 | `##iflacosh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 567 | `flasinh` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 568 | `##flasinh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 569 | `##iflasinh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 570 | `flatanh` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 571 | `##flatanh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 572 | `##iflatanh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 573 | `flcosh` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 574 | `##flcosh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 575 | `##iflcosh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 576 | `flexpm1` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 577 | `##flexpm1` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 578 | `##iflexpm1` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 579 | `flhypot` | `(2)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 580 | `##flhypot` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 581 | `##iflhypot` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 582 | `flilogb` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 583 | `##flilogb` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 584 | `##iflilogb` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 585 | `fllog1p` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 586 | `##fllog1p` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 587 | `##ifllog1p` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 588 | `flscalbn` | `(2)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 589 | `##flscalbn` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 590 | `##iflscalbn` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 591 | `flsinh` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 592 | `##flsinh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 593 | `##iflsinh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 594 | `flsquare` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 595 | `##flsquare` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 596 | `##iflsquare` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 597 | `fltanh` | `(1)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 598 | `##fltanh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 599 | `##ifltanh` | `(1)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 601 | `##flcopysign` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 602 | `##iflcopysign` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 603 | `##fleqv?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 604 | `##ifleqv?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 606 | `##flonum->fixnum` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 607 | `##iflonum->fixnum` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 608 | `##fixnum->flonum-exact?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 609 | `##flonum->string-host` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 613 | `append` | `0` | `#f` | `0` | `0` | `list` | `ieee` |
| 614 | `##append` | `0` | `#f` | `()` | `0` | `list` | `extended` |
| 615 | `assoc` | `(2)` | `#f` | `0` | `0` | `#f` | `ieee` |
| 616 | `##assoc` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 617 | `assq` | `(2)` | `#f` | `0` | `0` | `#f` | `ieee` |
| 618 | `##assq` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 619 | `assv` | `(2)` | `#f` | `0` | `0` | `#f` | `ieee` |
| 620 | `##assv` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 621 | `caaaar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 622 | `##caaaar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 623 | `caaadr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 624 | `##caaadr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 625 | `caaar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 626 | `##caaar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 627 | `caadar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 628 | `##caadar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 629 | `caaddr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 630 | `##caaddr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 631 | `caadr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 632 | `##caadr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 633 | `caar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 634 | `##caar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 635 | `cadaar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 636 | `##cadaar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 637 | `cadadr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 638 | `##cadadr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 639 | `cadar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 640 | `##cadar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 641 | `caddar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 642 | `##caddar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 643 | `cadddr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 644 | `##cadddr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 645 | `caddr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 646 | `##caddr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 647 | `cadr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 648 | `##cadr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 649 | `car` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 650 | `##car` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 651 | `cdaaar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 652 | `##cdaaar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 653 | `cdaadr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 654 | `##cdaadr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 655 | `cdaar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 656 | `##cdaar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 657 | `cdadar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 658 | `##cdadar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 659 | `cdaddr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 660 | `##cdaddr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 661 | `cdadr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 662 | `##cdadr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 663 | `cdar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 664 | `##cdar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 665 | `cddaar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 666 | `##cddaar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 667 | `cddadr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 668 | `##cddadr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 669 | `cddar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 670 | `##cddar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 671 | `cdddar` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 672 | `##cdddar` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 673 | `cddddr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 674 | `##cddddr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 675 | `cdddr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 676 | `##cdddr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 677 | `cddr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 678 | `##cddr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 679 | `cdr` | `(1)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 680 | `##cdr` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 681 | `cons` | `(2)` | `#f` | `()` | `0` | `pair` | `ieee` |
| 682 | `##cons` | `(2)` | `#f` | `()` | `0` | `pair` | `extended` |
| 683 | `length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `ieee` |
| 684 | `##length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 685 | `list` | `0` | `#f` | `()` | `0` | `list` | `ieee` |
| 686 | `##list` | `0` | `#f` | `()` | `0` | `list` | `extended` |
| 687 | `list-ref` | `(2)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 688 | `##list-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 689 | `list?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 690 | `##list?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 691 | `member` | `(2)` | `#f` | `0` | `0` | `list` | `ieee` |
| 692 | `##member` | `(2)` | `#f` | `()` | `0` | `list` | `extended` |
| 693 | `memq` | `(2)` | `#f` | `0` | `0` | `list` | `ieee` |
| 694 | `##memq` | `(2)` | `#f` | `()` | `0` | `list` | `extended` |
| 695 | `memv` | `(2)` | `#f` | `0` | `0` | `list` | `ieee` |
| 696 | `##memv` | `(2)` | `#f` | `()` | `0` | `list` | `extended` |
| 697 | `null?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 698 | `##null?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 699 | `pair?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 700 | `##pair?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 701 | `reverse` | `(1)` | `#f` | `0` | `0` | `list` | `ieee` |
| 702 | `##reverse` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 703 | `set-car!` | `(2)` | `#t` | `(1)` | `0` | `pair` | `ieee` |
| 704 | `##set-car!` | `(2)` | `#t` | `()` | `0` | `pair` | `extended` |
| 705 | `set-cdr!` | `(2)` | `#t` | `(1)` | `0` | `pair` | `ieee` |
| 706 | `##set-cdr!` | `(2)` | `#t` | `()` | `0` | `pair` | `extended` |
| 708 | `list-tail` | `(2)` | `#f` | `0` | `0` | `(#f)` | `r4rs` |
| 709 | `##list-tail` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 711 | `make-list` | `(1 2)` | `#f` | `(1)` | `0` | `list` | `r7rs` |
| 712 | `##make-list` | `(1 2)` | `#f` | `()` | `0` | `list` | `extended` |
| 713 | `list-copy` | `(1)` | `#f` | `0` | `0` | `list` | `r7rs` |
| 714 | `##list-copy` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 715 | `list-set!` | `(3)` | `#t` | `(1 2)` | `0` | `#f` | `r7rs` |
| 716 | `##list-set!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 718 | `circular-list` | `1` | `#f` | `()` | `0` | `list` | `gambit` |
| 719 | `##circular-list` | `1` | `#f` | `()` | `0` | `list` | `extended` |
| 720 | `cons*` | `1` | `#f` | `()` | `0` | `#f` | `gambit` |
| 721 | `##cons*` | `1` | `#f` | `()` | `0` | `#f` | `extended` |
| 722 | `drop` | `(2)` | `#f` | `0` | `0` | `list` | `gambit` |
| 723 | `##drop` | `(2)` | `#f` | `()` | `0` | `list` | `extended` |
| 724 | `fold` | `3` | `#t` | `(1 . 3)` | `0` | `(#f)` | `gambit` |
| 725 | `##fold` | `3` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 726 | `fold-right` | `3` | `#t` | `(1 . 3)` | `0` | `(#f)` | `gambit` |
| 727 | `##fold-right` | `3` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 728 | `iota` | `(1 2 3)` | `#f` | `0` | `0` | `list` | `gambit` |
| 729 | `##iota` | `(1 2 3)` | `#f` | `()` | `0` | `list` | `extended` |
| 730 | `last` | `(1)` | `#f` | `0` | `0` | `(#f)` | `gambit` |
| 731 | `##last` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 732 | `last-pair` | `(1)` | `#f` | `0` | `0` | `pair` | `gambit` |
| 733 | `##last-pair` | `(1)` | `#f` | `()` | `0` | `pair` | `extended` |
| 734 | `list-set` | `(3)` | `#f` | `(1 2)` | `0` | `pair` | `gambit` |
| 735 | `##list-set` | `(3)` | `#f` | `()` | `0` | `pair` | `extended` |
| 736 | `list-tabulate` | `(2)` | `#t` | `0` | `0` | `list` | `gambit` |
| 737 | `##list-tabulate` | `(2)` | `#t` | `()` | `0` | `list` | `extended` |
| 738 | `reverse!` | `(1)` | `#t` | `0` | `0` | `list` | `gambit` |
| 739 | `##reverse!` | `(1)` | `#t` | `()` | `0` | `list` | `extended` |
| 740 | `take` | `(2)` | `#f` | `0` | `0` | `list` | `gambit` |
| 741 | `##take` | `(2)` | `#f` | `()` | `0` | `list` | `extended` |
| 742 | `xcons` | `(2)` | `#f` | `()` | `0` | `pair` | `gambit` |
| 743 | `##xcons` | `(2)` | `#f` | `()` | `0` | `pair` | `extended` |
| 747 | `char->integer` | `(1)` | `#f` | `0` | `0` | `fixnum` | `ieee` |
| 748 | `##char->integer` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 749 | `char-alphabetic?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 750 | `##char-alphabetic?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 751 | `char-ci<=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 752 | `##char-ci<=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 753 | `char-ci<?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 754 | `##char-ci<?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 755 | `char-ci=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 756 | `##char-ci=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 757 | `char-ci>=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 758 | `##char-ci>=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 759 | `char-ci>?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 760 | `##char-ci>?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 761 | `char-downcase` | `(1)` | `#f` | `0` | `0` | `char` | `ieee` |
| 762 | `##char-downcase` | `(1)` | `#f` | `()` | `0` | `char` | `extended` |
| 763 | `char-lower-case?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 764 | `##char-lower-case?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 765 | `char-numeric?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 766 | `##char-numeric?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 767 | `char-upcase` | `(1)` | `#f` | `0` | `0` | `char` | `ieee` |
| 768 | `##char-upcase` | `(1)` | `#f` | `()` | `0` | `char` | `extended` |
| 769 | `char-upper-case?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 770 | `##char-upper-case?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 771 | `char-whitespace?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 772 | `##char-whitespace?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 773 | `char<=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 774 | `##char<=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 775 | `char<?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 776 | `##char<?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 777 | `char=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 778 | `##char=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 779 | `char>=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 780 | `##char>=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 781 | `char>?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 782 | `##char>?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 783 | `char?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 784 | `##char?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 785 | `integer->char` | `(1)` | `#f` | `0` | `0` | `char` | `ieee` |
| 786 | `##integer->char` | `(1)` | `#f` | `()` | `0` | `char` | `extended` |
| 787 | `##max-char-code` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 789 | `char-foldcase` | `(1)` | `#f` | `0` | `0` | `char` | `r7rs` |
| 790 | `##char-foldcase` | `(1)` | `#f` | `()` | `0` | `char` | `extended` |
| 791 | `digit-value` | `(1)` | `#f` | `0` | `0` | `#f` | `r7rs` |
| 792 | `##digit-value` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 796 | `list->string` | `(1)` | `#f` | `0` | `0` | `string` | `r4rs` |
| 797 | `##list->string` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 798 | `make-string` | `(1 2)` | `#f` | `0` | `0` | `string` | `ieee` |
| 799 | `##make-string` | `(1 2)` | `#f` | `()` | `0` | `string` | `extended` |
| 800 | `##make-string-small` | `(1 2)` | `#f` | `()` | `0` | `string` | `extended` |
| 801 | `substring` | `(3)` | `#f` | `0` | `0` | `string` | `ieee` |
| 802 | `##substring` | `(3)` | `#f` | `()` | `0` | `string` | `extended` |
| 803 | `##substring-small` | `(3)` | `#f` | `()` | `0` | `string` | `extended` |
| 804 | `string` | `0` | `#f` | `0` | `0` | `string` | `ieee` |
| 805 | `##string` | `0` | `#f` | `()` | `0` | `string` | `extended` |
| 806 | `string->list` | `(1)` | `#f` | `0` | `0` | `list` | `r4rs` |
| 807 | `##string->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 808 | `string-append` | `0` | `#f` | `0` | `0` | `string` | `ieee` |
| 809 | `##string-append` | `0` | `#f` | `()` | `0` | `string` | `extended` |
| 810 | `string-copy` | `(1 2 3)` | `#f` | `0` | `0` | `string` | `r4rs` |
| 811 | `##string-copy` | `(1 2 3)` | `#f` | `()` | `0` | `string` | `extended` |
| 812 | `##string-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `string` | `extended` |
| 813 | `string-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `r4rs` |
| 814 | `##string-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 815 | `string-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `ieee` |
| 816 | `##string-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 817 | `string-ref` | `(2)` | `#f` | `0` | `0` | `char` | `ieee` |
| 818 | `##string-ref` | `(2)` | `#f` | `()` | `0` | `char` | `extended` |
| 819 | `string-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 820 | `##string-set!` | `(3)` | `#t` | `()` | `0` | `string` | `extended` |
| 821 | `string?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 822 | `##string?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 823 | `string<=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 824 | `##string<=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 825 | `string<?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 826 | `##string<?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 827 | `string=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 828 | `##string=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 829 | `string>=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 830 | `##string>=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 831 | `string>?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 832 | `##string>?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 833 | `string-ci<=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 834 | `##string-ci<=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 835 | `string-ci<?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 836 | `##string-ci<?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 837 | `string-ci=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 838 | `##string-ci=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 839 | `string-ci>=?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 840 | `##string-ci>=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 841 | `string-ci>?` | `0` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 842 | `##string-ci>?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 844 | `utf8->string` | `(1)` | `#f` | `0` | `0` | `string` | `r7rs` |
| 845 | `##utf8->string` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 846 | `string->utf8` | `(1)` | `#f` | `0` | `0` | `u8vector` | `r7rs` |
| 847 | `##string->utf8` | `(1)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 848 | `string-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `r7rs` |
| 849 | `##string-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `string` | `extended` |
| 850 | `##string-insert` | `(3)` | `#f` | `()` | `0` | `string` | `extended` |
| 851 | `##string-insert-small` | `(3)` | `#f` | `()` | `0` | `string` | `extended` |
| 852 | `##string-delete` | `(2)` | `#f` | `()` | `0` | `string` | `extended` |
| 853 | `##string-delete-small` | `(2)` | `#f` | `()` | `0` | `string` | `extended` |
| 854 | `string-foldcase` | `(1)` | `#f` | `0` | `0` | `string` | `r7rs` |
| 855 | `##string-foldcase` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 856 | `string-upcase` | `(1)` | `#f` | `0` | `0` | `string` | `r7rs` |
| 857 | `##string-upcase` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 858 | `string-downcase` | `(1)` | `#f` | `0` | `0` | `string` | `r7rs` |
| 859 | `##string-downcase` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 861 | `string-concatenate` | `(1 2)` | `#f` | `0` | `0` | `string` | `gambit` |
| 862 | `##string-concatenate` | `(1 2)` | `#f` | `()` | `0` | `string` | `extended` |
| 863 | `substring-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 864 | `##substring-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 865 | `substring-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 866 | `##substring-move!` | `(5)` | `#t` | `()` | `0` | `string` | `extended` |
| 867 | `string-set` | `(3)` | `#f` | `0` | `0` | `string` | `gambit` |
| 868 | `##string-set` | `(3)` | `#f` | `()` | `0` | `string` | `extended` |
| 869 | `##string-set-small` | `(3)` | `#f` | `()` | `0` | `string` | `extended` |
| 870 | `string-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 871 | `##string-shrink!` | `(2)` | `#t` | `()` | `0` | `string` | `extended` |
| 872 | `##string-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 876 | `list->vector` | `(1)` | `#f` | `0` | `0` | `vector` | `r4rs` |
| 877 | `##list->vector` | `(1)` | `#f` | `()` | `0` | `vector` | `extended` |
| 878 | `make-vector` | `(1 2)` | `#f` | `(1)` | `0` | `vector` | `ieee` |
| 879 | `##make-vector` | `(1 2)` | `#f` | `()` | `0` | `vector` | `extended` |
| 880 | `##make-vector-small` | `(1 2)` | `#f` | `()` | `0` | `vector` | `extended` |
| 881 | `vector` | `0` | `#f` | `()` | `0` | `vector` | `ieee` |
| 882 | `##vector` | `0` | `#f` | `()` | `0` | `vector` | `extended` |
| 883 | `vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `r4rs` |
| 884 | `##vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 885 | `vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `r4rs` |
| 886 | `##vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 887 | `vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `ieee` |
| 888 | `##vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 889 | `vector-ref` | `(2)` | `#f` | `0` | `0` | `(#f)` | `ieee` |
| 890 | `##vector-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 891 | `vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 892 | `##vector-set!` | `(3)` | `#t` | `()` | `0` | `vector` | `extended` |
| 893 | `vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 894 | `##vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 896 | `vector-append` | `0` | `#f` | `0` | `0` | `vector` | `r7rs` |
| 897 | `##vector-append` | `0` | `#f` | `()` | `0` | `vector` | `extended` |
| 898 | `vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `vector` | `r7rs` |
| 899 | `##vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 900 | `##vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 901 | `vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `r7rs` |
| 902 | `##vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `vector` | `extended` |
| 903 | `##vector-insert` | `(3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 904 | `##vector-insert-small` | `(3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 905 | `##vector-delete` | `(2)` | `#f` | `()` | `0` | `vector` | `extended` |
| 906 | `##vector-delete-small` | `(2)` | `#f` | `()` | `0` | `vector` | `extended` |
| 908 | `vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `vector` | `gambit` |
| 909 | `##vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `vector` | `extended` |
| 910 | `subvector` | `(3)` | `#f` | `0` | `0` | `vector` | `gambit` |
| 911 | `##subvector` | `(3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 912 | `##subvector-small` | `(3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 913 | `subvector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 914 | `##subvector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 915 | `subvector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 916 | `##subvector-move!` | `(5)` | `#t` | `()` | `0` | `vector` | `extended` |
| 917 | `vector-cas!` | `(4)` | `#t` | `(1 2 4)` | `0` | `#f` | `gambit` |
| 918 | `##vector-cas!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 919 | `vector-inc!` | `(2 3)` | `#t` | `0` | `0` | `fixnum` | `gambit` |
| 920 | `##vector-inc!` | `(2 3)` | `#t` | `()` | `0` | `fixnum` | `extended` |
| 921 | `vector-set` | `(3)` | `#f` | `0` | `0` | `vector` | `gambit` |
| 922 | `##vector-set` | `(3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 923 | `##vector-set-small` | `(3)` | `#f` | `()` | `0` | `vector` | `extended` |
| 924 | `vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 925 | `##vector-shrink!` | `(2)` | `#t` | `()` | `0` | `vector` | `extended` |
| 926 | `##vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 930 | `s8vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 931 | `##s8vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 932 | `list->s8vector` | `(1)` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 933 | `##list->s8vector` | `(1)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 934 | `make-s8vector` | `(1 2)` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 935 | `##make-s8vector` | `(1 2)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 936 | `##make-s8vector-small` | `(1 2)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 937 | `subs8vector` | `(3)` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 938 | `##subs8vector` | `(3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 939 | `##subs8vector-small` | `(3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 940 | `subs8vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 941 | `##subs8vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 942 | `subs8vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 943 | `##subs8vector-move!` | `(5)` | `#t` | `()` | `0` | `s8vector` | `extended` |
| 944 | `s8vector` | `0` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 945 | `##s8vector` | `0` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 946 | `s8vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 947 | `##s8vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 948 | `s8vector-append` | `0` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 949 | `##s8vector-append` | `0` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 950 | `s8vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 951 | `##s8vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 952 | `##s8vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 953 | `s8vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 954 | `##s8vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `s8vector` | `extended` |
| 955 | `s8vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 956 | `##s8vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 957 | `s8vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 958 | `##s8vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 959 | `s8vector-ref` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 960 | `##s8vector-ref` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 961 | `s8vector-set` | `(3)` | `#f` | `0` | `0` | `s8vector` | `gambit` |
| 962 | `##s8vector-set` | `(3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 963 | `##s8vector-set-small` | `(3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 964 | `s8vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 965 | `##s8vector-set!` | `(3)` | `#t` | `()` | `0` | `s8vector` | `extended` |
| 966 | `s8vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 967 | `##s8vector-shrink!` | `(2)` | `#t` | `()` | `0` | `s8vector` | `extended` |
| 968 | `##s8vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 969 | `s8vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 970 | `##s8vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 971 | `##s8vector-insert` | `(3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 972 | `##s8vector-insert-small` | `(3)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 973 | `##s8vector-delete` | `(2)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 974 | `##s8vector-delete-small` | `(2)` | `#f` | `()` | `0` | `s8vector` | `extended` |
| 976 | `u8vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 977 | `##u8vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 978 | `list->u8vector` | `(1)` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 979 | `##list->u8vector` | `(1)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 980 | `make-u8vector` | `(1 2)` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 981 | `##make-u8vector` | `(1 2)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 982 | `##make-u8vector-small` | `(1 2)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 983 | `subu8vector` | `(3)` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 984 | `##subu8vector` | `(3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 985 | `##subu8vector-small` | `(3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 986 | `subu8vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 987 | `##subu8vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 988 | `subu8vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 989 | `##subu8vector-move!` | `(5)` | `#t` | `()` | `0` | `u8vector` | `extended` |
| 990 | `u8vector` | `0` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 991 | `##u8vector` | `0` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 992 | `u8vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 993 | `##u8vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 994 | `u8vector-append` | `0` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 995 | `##u8vector-append` | `0` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 996 | `u8vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 997 | `##u8vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 998 | `##u8vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 999 | `u8vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1000 | `##u8vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `u8vector` | `extended` |
| 1001 | `u8vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1002 | `##u8vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1003 | `u8vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1004 | `##u8vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1005 | `u8vector-ref` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1006 | `##u8vector-ref` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1007 | `u8vector-set` | `(3)` | `#f` | `0` | `0` | `u8vector` | `gambit` |
| 1008 | `##u8vector-set` | `(3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 1009 | `##u8vector-set-small` | `(3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 1010 | `u8vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1011 | `##u8vector-set!` | `(3)` | `#t` | `()` | `0` | `u8vector` | `extended` |
| 1012 | `u8vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1013 | `##u8vector-shrink!` | `(2)` | `#t` | `()` | `0` | `u8vector` | `extended` |
| 1014 | `##u8vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1015 | `u8vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1016 | `##u8vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1017 | `##u8vector-insert` | `(3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 1018 | `##u8vector-insert-small` | `(3)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 1019 | `##u8vector-delete` | `(2)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 1020 | `##u8vector-delete-small` | `(2)` | `#f` | `()` | `0` | `u8vector` | `extended` |
| 1022 | `s16vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1023 | `##s16vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1024 | `list->s16vector` | `(1)` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1025 | `##list->s16vector` | `(1)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1026 | `make-s16vector` | `(1 2)` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1027 | `##make-s16vector` | `(1 2)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1028 | `##make-s16vector-small` | `(1 2)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1029 | `subs16vector` | `(3)` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1030 | `##subs16vector` | `(3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1031 | `##subs16vector-small` | `(3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1032 | `subs16vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1033 | `##subs16vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1034 | `subs16vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1035 | `##subs16vector-move!` | `(5)` | `#t` | `()` | `0` | `s16vector` | `extended` |
| 1036 | `s16vector` | `0` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1037 | `##s16vector` | `0` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1038 | `s16vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1039 | `##s16vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1040 | `s16vector-append` | `0` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1041 | `##s16vector-append` | `0` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1042 | `s16vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1043 | `##s16vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1044 | `##s16vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1045 | `s16vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1046 | `##s16vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `s16vector` | `extended` |
| 1047 | `s16vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1048 | `##s16vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1049 | `s16vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1050 | `##s16vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1051 | `s16vector-ref` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1052 | `##s16vector-ref` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1053 | `s16vector-set` | `(3)` | `#f` | `0` | `0` | `s16vector` | `gambit` |
| 1054 | `##s16vector-set` | `(3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1055 | `##s16vector-set-small` | `(3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1056 | `s16vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1057 | `##s16vector-set!` | `(3)` | `#t` | `()` | `0` | `s16vector` | `extended` |
| 1058 | `s16vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1059 | `##s16vector-shrink!` | `(2)` | `#t` | `()` | `0` | `s16vector` | `extended` |
| 1060 | `##s16vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1061 | `s16vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1062 | `##s16vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1063 | `##s16vector-insert` | `(3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1064 | `##s16vector-insert-small` | `(3)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1065 | `##s16vector-delete` | `(2)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1066 | `##s16vector-delete-small` | `(2)` | `#f` | `()` | `0` | `s16vector` | `extended` |
| 1068 | `u16vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1069 | `##u16vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1070 | `list->u16vector` | `(1)` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1071 | `##list->u16vector` | `(1)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1072 | `make-u16vector` | `(1 2)` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1073 | `##make-u16vector` | `(1 2)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1074 | `##make-u16vector-small` | `(1 2)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1075 | `subu16vector` | `(3)` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1076 | `##subu16vector` | `(3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1077 | `##subu16vector-small` | `(3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1078 | `subu16vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1079 | `##subu16vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1080 | `subu16vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1081 | `##subu16vector-move!` | `(5)` | `#t` | `()` | `0` | `u16vector` | `extended` |
| 1082 | `u16vector` | `0` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1083 | `##u16vector` | `0` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1084 | `u16vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1085 | `##u16vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1086 | `u16vector-append` | `0` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1087 | `##u16vector-append` | `0` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1088 | `u16vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1089 | `##u16vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1090 | `##u16vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1091 | `u16vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1092 | `##u16vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `u16vector` | `extended` |
| 1093 | `u16vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1094 | `##u16vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1095 | `u16vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1096 | `##u16vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1097 | `u16vector-ref` | `(2)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1098 | `##u16vector-ref` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1099 | `u16vector-set` | `(3)` | `#f` | `0` | `0` | `u16vector` | `gambit` |
| 1100 | `##u16vector-set` | `(3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1101 | `##u16vector-set-small` | `(3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1102 | `u16vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1103 | `##u16vector-set!` | `(3)` | `#t` | `()` | `0` | `u16vector` | `extended` |
| 1104 | `u16vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1105 | `##u16vector-shrink!` | `(2)` | `#t` | `()` | `0` | `u16vector` | `extended` |
| 1106 | `##u16vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1107 | `u16vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1108 | `##u16vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1109 | `##u16vector-insert` | `(3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1110 | `##u16vector-insert-small` | `(3)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1111 | `##u16vector-delete` | `(2)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1112 | `##u16vector-delete-small` | `(2)` | `#f` | `()` | `0` | `u16vector` | `extended` |
| 1114 | `s32vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1115 | `##s32vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1116 | `list->s32vector` | `(1)` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1117 | `##list->s32vector` | `(1)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1118 | `make-s32vector` | `(1 2)` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1119 | `##make-s32vector` | `(1 2)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1120 | `##make-s32vector-small` | `(1 2)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1121 | `subs32vector` | `(3)` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1122 | `##subs32vector` | `(3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1123 | `##subs32vector-small` | `(3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1124 | `subs32vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1125 | `##subs32vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1126 | `subs32vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1127 | `##subs32vector-move!` | `(5)` | `#t` | `()` | `0` | `s32vector` | `extended` |
| 1128 | `s32vector` | `0` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1129 | `##s32vector` | `0` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1130 | `s32vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1131 | `##s32vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1132 | `s32vector-append` | `0` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1133 | `##s32vector-append` | `0` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1134 | `s32vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1135 | `##s32vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1136 | `##s32vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1137 | `s32vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1138 | `##s32vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `s32vector` | `extended` |
| 1139 | `s32vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1140 | `##s32vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1141 | `s32vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1142 | `##s32vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1143 | `s32vector-ref` | `(2)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 1144 | `##s32vector-ref` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 1145 | `##s32vector-ref-fixnum` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1146 | `s32vector-set` | `(3)` | `#f` | `0` | `0` | `s32vector` | `gambit` |
| 1147 | `##s32vector-set` | `(3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1148 | `##s32vector-set-small` | `(3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1149 | `s32vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1150 | `##s32vector-set!` | `(3)` | `#t` | `()` | `0` | `s32vector` | `extended` |
| 1151 | `##s32vector-set!-fixnum` | `(3)` | `#t` | `()` | `0` | `s32vector` | `extended` |
| 1152 | `s32vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1153 | `##s32vector-shrink!` | `(2)` | `#t` | `()` | `0` | `s32vector` | `extended` |
| 1154 | `##s32vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1155 | `s32vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1156 | `##s32vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1157 | `##s32vector-insert` | `(3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1158 | `##s32vector-insert-small` | `(3)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1159 | `##s32vector-delete` | `(2)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1160 | `##s32vector-delete-small` | `(2)` | `#f` | `()` | `0` | `s32vector` | `extended` |
| 1162 | `u32vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1163 | `##u32vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1164 | `list->u32vector` | `(1)` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1165 | `##list->u32vector` | `(1)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1166 | `make-u32vector` | `(1 2)` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1167 | `##make-u32vector` | `(1 2)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1168 | `##make-u32vector-small` | `(1 2)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1169 | `subu32vector` | `(3)` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1170 | `##subu32vector` | `(3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1171 | `##subu32vector-small` | `(3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1172 | `subu32vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1173 | `##subu32vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1174 | `subu32vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1175 | `##subu32vector-move!` | `(5)` | `#t` | `()` | `0` | `u32vector` | `extended` |
| 1176 | `u32vector` | `0` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1177 | `##u32vector` | `0` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1178 | `u32vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1179 | `##u32vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1180 | `u32vector-append` | `0` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1181 | `##u32vector-append` | `0` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1182 | `u32vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1183 | `##u32vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1184 | `##u32vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1185 | `u32vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1186 | `##u32vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `u32vector` | `extended` |
| 1187 | `u32vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1188 | `##u32vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1189 | `u32vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1190 | `##u32vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1191 | `u32vector-ref` | `(2)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 1192 | `##u32vector-ref` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 1193 | `##u32vector-ref-fixnum` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1194 | `u32vector-set` | `(3)` | `#f` | `0` | `0` | `u32vector` | `gambit` |
| 1195 | `##u32vector-set` | `(3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1196 | `##u32vector-set-small` | `(3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1197 | `u32vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1198 | `##u32vector-set!` | `(3)` | `#t` | `()` | `0` | `u32vector` | `extended` |
| 1199 | `##u32vector-set!-fixnum` | `(3)` | `#t` | `()` | `0` | `u32vector` | `extended` |
| 1200 | `u32vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1201 | `##u32vector-shrink!` | `(2)` | `#t` | `()` | `0` | `u32vector` | `extended` |
| 1202 | `##u32vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1203 | `u32vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1204 | `##u32vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1205 | `##u32vector-insert` | `(3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1206 | `##u32vector-insert-small` | `(3)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1207 | `##u32vector-delete` | `(2)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1208 | `##u32vector-delete-small` | `(2)` | `#f` | `()` | `0` | `u32vector` | `extended` |
| 1210 | `s64vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1211 | `##s64vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1212 | `list->s64vector` | `(1)` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1213 | `##list->s64vector` | `(1)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1214 | `make-s64vector` | `(1 2)` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1215 | `##make-s64vector` | `(1 2)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1216 | `##make-s64vector-small` | `(1 2)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1217 | `subs64vector` | `(3)` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1218 | `##subs64vector` | `(3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1219 | `##subs64vector-small` | `(3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1220 | `subs64vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1221 | `##subs64vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1222 | `subs64vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1223 | `##subs64vector-move!` | `(5)` | `#t` | `()` | `0` | `s64vector` | `extended` |
| 1224 | `s64vector` | `0` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1225 | `##s64vector` | `0` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1226 | `s64vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1227 | `##s64vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1228 | `s64vector-append` | `0` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1229 | `##s64vector-append` | `0` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1230 | `s64vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1231 | `##s64vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1232 | `##s64vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1233 | `s64vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1234 | `##s64vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `s64vector` | `extended` |
| 1235 | `s64vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1236 | `##s64vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1237 | `s64vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1238 | `##s64vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1239 | `s64vector-ref` | `(2)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 1240 | `##s64vector-ref` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 1241 | `##s64vector-ref-fixnum` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1242 | `s64vector-set` | `(3)` | `#f` | `0` | `0` | `s64vector` | `gambit` |
| 1243 | `##s64vector-set` | `(3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1244 | `##s64vector-set-small` | `(3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1245 | `s64vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1246 | `##s64vector-set!` | `(3)` | `#t` | `()` | `0` | `s64vector` | `extended` |
| 1247 | `##s64vector-set!-fixnum` | `(3)` | `#t` | `()` | `0` | `s64vector` | `extended` |
| 1248 | `s64vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1249 | `##s64vector-shrink!` | `(2)` | `#t` | `()` | `0` | `s64vector` | `extended` |
| 1250 | `##s64vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1251 | `s64vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1252 | `##s64vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1253 | `##s64vector-insert` | `(3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1254 | `##s64vector-insert-small` | `(3)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1255 | `##s64vector-delete` | `(2)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1256 | `##s64vector-delete-small` | `(2)` | `#f` | `()` | `0` | `s64vector` | `extended` |
| 1258 | `u64vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1259 | `##u64vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1260 | `list->u64vector` | `(1)` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1261 | `##list->u64vector` | `(1)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1262 | `make-u64vector` | `(1 2)` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1263 | `##make-u64vector` | `(1 2)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1264 | `##make-u64vector-small` | `(1 2)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1265 | `subu64vector` | `(3)` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1266 | `##subu64vector` | `(3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1267 | `##subu64vector-small` | `(3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1268 | `subu64vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1269 | `##subu64vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1270 | `subu64vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1271 | `##subu64vector-move!` | `(5)` | `#t` | `()` | `0` | `u64vector` | `extended` |
| 1272 | `u64vector` | `0` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1273 | `##u64vector` | `0` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1274 | `u64vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1275 | `##u64vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1276 | `u64vector-append` | `0` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1277 | `##u64vector-append` | `0` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1278 | `u64vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1279 | `##u64vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1280 | `##u64vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1281 | `u64vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1282 | `##u64vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `u64vector` | `extended` |
| 1283 | `u64vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1284 | `##u64vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1285 | `u64vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1286 | `##u64vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1287 | `u64vector-ref` | `(2)` | `#f` | `0` | `0` | `integer` | `gambit` |
| 1288 | `##u64vector-ref` | `(2)` | `#f` | `()` | `0` | `integer` | `extended` |
| 1289 | `##u64vector-ref-fixnum` | `(2)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1290 | `u64vector-set` | `(3)` | `#f` | `0` | `0` | `u64vector` | `gambit` |
| 1291 | `##u64vector-set` | `(3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1292 | `##u64vector-set-small` | `(3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1293 | `u64vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1294 | `##u64vector-set!` | `(3)` | `#t` | `()` | `0` | `u64vector` | `extended` |
| 1295 | `##u64vector-set!-fixnum` | `(3)` | `#t` | `()` | `0` | `u64vector` | `extended` |
| 1296 | `u64vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1297 | `##u64vector-shrink!` | `(2)` | `#t` | `()` | `0` | `u64vector` | `extended` |
| 1298 | `##u64vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1299 | `u64vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1300 | `##u64vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1301 | `##u64vector-insert` | `(3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1302 | `##u64vector-insert-small` | `(3)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1303 | `##u64vector-delete` | `(2)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1304 | `##u64vector-delete-small` | `(2)` | `#f` | `()` | `0` | `u64vector` | `extended` |
| 1306 | `f32vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1307 | `##f32vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1308 | `list->f32vector` | `(1)` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1309 | `##list->f32vector` | `(1)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1310 | `make-f32vector` | `(1 2)` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1311 | `##make-f32vector` | `(1 2)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1312 | `##make-f32vector-small` | `(1 2)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1313 | `subf32vector` | `(3)` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1314 | `##subf32vector` | `(3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1315 | `##subf32vector-small` | `(3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1316 | `subf32vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1317 | `##subf32vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1318 | `subf32vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1319 | `##subf32vector-move!` | `(5)` | `#t` | `()` | `0` | `f32vector` | `extended` |
| 1320 | `f32vector` | `0` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1321 | `##f32vector` | `0` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1322 | `f32vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1323 | `##f32vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1324 | `f32vector-append` | `0` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1325 | `##f32vector-append` | `0` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1326 | `f32vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1327 | `##f32vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1328 | `##f32vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1329 | `f32vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1330 | `##f32vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `f32vector` | `extended` |
| 1331 | `f32vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1332 | `##f32vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1333 | `f32vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1334 | `##f32vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1335 | `f32vector-ref` | `(2)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 1336 | `##f32vector-ref` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 1337 | `f32vector-set` | `(3)` | `#f` | `0` | `0` | `f32vector` | `gambit` |
| 1338 | `##f32vector-set` | `(3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1339 | `##f32vector-set-small` | `(3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1340 | `f32vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1341 | `##f32vector-set!` | `(3)` | `#t` | `()` | `0` | `f32vector` | `extended` |
| 1342 | `f32vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1343 | `##f32vector-shrink!` | `(2)` | `#t` | `()` | `0` | `f32vector` | `extended` |
| 1344 | `##f32vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1345 | `f32vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1346 | `##f32vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1347 | `##f32vector-insert` | `(3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1348 | `##f32vector-insert-small` | `(3)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1349 | `##f32vector-delete` | `(2)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1350 | `##f32vector-delete-small` | `(2)` | `#f` | `()` | `0` | `f32vector` | `extended` |
| 1352 | `f64vector-concatenate` | `(1 2)` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1353 | `##f64vector-concatenate` | `(1 2)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1354 | `list->f64vector` | `(1)` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1355 | `##list->f64vector` | `(1)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1356 | `make-f64vector` | `(1 2)` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1357 | `##make-f64vector` | `(1 2)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1358 | `##make-f64vector-small` | `(1 2)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1359 | `subf64vector` | `(3)` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1360 | `##subf64vector` | `(3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1361 | `##subf64vector-small` | `(3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1362 | `subf64vector-fill!` | `(4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1363 | `##subf64vector-fill!` | `(4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1364 | `subf64vector-move!` | `(5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1365 | `##subf64vector-move!` | `(5)` | `#t` | `()` | `0` | `f64vector` | `extended` |
| 1366 | `f64vector` | `0` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1367 | `##f64vector` | `0` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1368 | `f64vector->list` | `(1)` | `#f` | `0` | `0` | `list` | `gambit` |
| 1369 | `##f64vector->list` | `(1)` | `#f` | `()` | `0` | `list` | `extended` |
| 1370 | `f64vector-append` | `0` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1371 | `##f64vector-append` | `0` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1372 | `f64vector-copy` | `(1 2 3)` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1373 | `##f64vector-copy` | `(1 2 3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1374 | `##f64vector-copy-small` | `(1 2 3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1375 | `f64vector-copy!` | `(3 4 5)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1376 | `##f64vector-copy!` | `(3 4 5)` | `#t` | `()` | `0` | `f64vector` | `extended` |
| 1377 | `f64vector-fill!` | `(2 3 4)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1378 | `##f64vector-fill!` | `(2 3 4)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1379 | `f64vector-length` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1380 | `##f64vector-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1381 | `f64vector-ref` | `(2)` | `#f` | `0` | `0` | `flonum` | `gambit` |
| 1382 | `##f64vector-ref` | `(2)` | `#f` | `()` | `0` | `flonum` | `extended` |
| 1383 | `f64vector-set` | `(3)` | `#f` | `0` | `0` | `f64vector` | `gambit` |
| 1384 | `##f64vector-set` | `(3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1385 | `##f64vector-set-small` | `(3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1386 | `f64vector-set!` | `(3)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1387 | `##f64vector-set!` | `(3)` | `#t` | `()` | `0` | `f64vector` | `extended` |
| 1388 | `f64vector-shrink!` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1389 | `##f64vector-shrink!` | `(2)` | `#t` | `()` | `0` | `f64vector` | `extended` |
| 1390 | `##f64vector-in-bounds?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1391 | `f64vector?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1392 | `##f64vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1393 | `##f64vector-insert` | `(3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1394 | `##f64vector-insert-small` | `(3)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1395 | `##f64vector-delete` | `(2)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1396 | `##f64vector-delete-small` | `(2)` | `#f` | `()` | `0` | `f64vector` | `extended` |
| 1400 | `symbol?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1401 | `##symbol?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1402 | `symbol->string` | `(1)` | `#f` | `0` | `0` | `string` | `ieee` |
| 1403 | `##symbol->string` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 1404 | `##symbol->string?` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1405 | `string->symbol` | `(1)` | `#f` | `0` | `0` | `symbol` | `ieee` |
| 1406 | `##string->symbol` | `(1)` | `#f` | `()` | `0` | `symbol` | `extended` |
| 1408 | `symbol=?` | `0` | `#f` | `0` | `0` | `boolean` | `r7rs` |
| 1409 | `##symbol=?` | `0` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1411 | `gensym` | `(1 2)` | `#f` | `0` | `0` | `symbol` | `gambit` |
| 1412 | `##gensym` | `(1 2)` | `#f` | `()` | `0` | `symbol` | `extended` |
| 1413 | `string->uninterned-symbol` | `(1 2)` | `#f` | `0` | `0` | `symbol` | `gambit` |
| 1414 | `##string->uninterned-symbol` | `(1 2)` | `#f` | `()` | `0` | `symbol` | `extended` |
| 1415 | `symbol-hash` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1416 | `##symbol-hash` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1417 | `##symbol-hash-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1418 | `uninterned-symbol?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1419 | `##uninterned-symbol?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1421 | `##make-uninterned-symbol` | `(2)` | `#f` | `()` | `0` | `symbol` | `extended` |
| 1422 | `##symbol-name` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 1423 | `##symbol-name-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1424 | `##symbol-interned?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1428 | `keyword->string` | `(1)` | `#f` | `0` | `0` | `string` | `gambit` |
| 1429 | `##keyword->string` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 1430 | `##keyword->string?` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1431 | `keyword-hash` | `(1)` | `#f` | `0` | `0` | `fixnum` | `gambit` |
| 1432 | `##keyword-hash` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1433 | `##keyword-hash-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1434 | `keyword?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1435 | `##keyword?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1436 | `string->keyword` | `(1)` | `#f` | `0` | `0` | `keyword` | `gambit` |
| 1437 | `##string->keyword` | `(1)` | `#f` | `()` | `0` | `keyword` | `extended` |
| 1438 | `string->uninterned-keyword` | `(1 2)` | `#f` | `0` | `0` | `keyword` | `gambit` |
| 1439 | `##string->uninterned-keyword` | `(1 2)` | `#f` | `()` | `0` | `keyword` | `extended` |
| 1440 | `uninterned-keyword?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1441 | `##uninterned-keyword?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1443 | `##make-uninterned-keyword` | `(2)` | `#f` | `()` | `0` | `keyword` | `extended` |
| 1444 | `##keyword-name` | `(1)` | `#f` | `()` | `0` | `string` | `extended` |
| 1445 | `##keyword-name-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1446 | `##keyword-interned?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1450 | `box?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1451 | `##box?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1452 | `box` | `(1)` | `#f` | `()` | `0` | `box` | `gambit` |
| 1453 | `##box` | `(1)` | `#f` | `()` | `0` | `box` | `extended` |
| 1454 | `unbox` | `(1)` | `#f` | `0` | `0` | `(#f)` | `gambit` |
| 1455 | `##unbox` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1456 | `set-box!` | `(2)` | `#t` | `(1)` | `0` | `#f` | `gambit` |
| 1457 | `##set-box!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1461 | `call-with-values` | `(2)` | `#t` | `0` | `0` | `(#f)` | `r5rs` |
| 1462 | `##call-with-values` | `(2)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1463 | `values` | `0` | `#f` | `()` | `0` | `(#f)` | `r5rs` |
| 1464 | `##values` | `0` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1466 | `##values?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1467 | `##values` | `0` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1468 | `##make-values` | `(1 2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1469 | `##make-values-small` | `(1 2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1470 | `##values-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1471 | `##values-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1472 | `##values-set!` | `(3)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1473 | `##values-set` | `(3)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1474 | `##values-set-small` | `(3)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1475 | `##values-insert` | `(3)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1476 | `##values-insert-small` | `(3)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1477 | `##values-delete` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1478 | `##values-delete-small` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1482 | `##gc-hash-table?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1483 | `##gc-hash-table-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1484 | `##gc-hash-table-set!` | `(3)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1485 | `##gc-hash-table-union!` | `(3)` | `#t` | `()` | `0` | `fixnum` | `extended` |
| 1486 | `##gc-hash-table-find!` | `(3)` | `#t` | `()` | `0` | `fixnum` | `extended` |
| 1487 | `##gc-hash-table-rehash!` | `(2)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1489 | `##gc-hash-table-make` | `(5)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1490 | `##gc-hash-table-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1491 | `##gc-hash-table-field-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1492 | `##gc-hash-table-field-set!` | `(3)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1496 | `make-will` | `(2)` | `#t` | `(2)` | `0` | `#f` | `gambit` |
| 1497 | `##make-will` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1498 | `will-testator` | `(1)` | `#f` | `0` | `0` | `(#f)` | `gambit` |
| 1499 | `##will-testator` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1500 | `##will-testator-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1501 | `will?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1502 | `##will?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1504 | `##will-action` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1505 | `##will-action-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1509 | `call-with-input-file` | `(2)` | `#t` | `0` | `0` | `(#f)` | `ieee` |
| 1510 | `call-with-output-file` | `(2)` | `#t` | `0` | `0` | `(#f)` | `ieee` |
| 1511 | `input-port?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1512 | `output-port?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1515 | `open-input-file` | `(1)` | `#t` | `0` | `0` | `port` | `ieee` |
| 1516 | `open-output-file` | `(1)` | `#t` | `0` | `0` | `port` | `ieee` |
| 1517 | `close-input-port` | `(1)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1518 | `close-output-port` | `(1)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1519 | `with-input-from-file` | `(2)` | `#t` | `0` | `0` | `(#f)` | `r4rs` |
| 1520 | `with-output-to-file` | `(2)` | `#t` | `0` | `0` | `(#f)` | `r4rs` |
| 1522 | `char-ready?` | `(0 1)` | `#f` | `0` | `0` | `boolean` | `r4rs` |
| 1523 | `##char-ready?` | `(0 1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1524 | `##char-ready?0` | `(0)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1525 | `##char-ready?1` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1526 | `read` | `(0 1)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1527 | `##read` | `(0 1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1528 | `read-char` | `(0 1)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1529 | `##read-char` | `(0 1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1530 | `##read-char0` | `(0)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1531 | `##read-char1` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1532 | `##read-char0?` | `(0)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1533 | `##read-char1?` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1534 | `peek-char` | `(0 1)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1535 | `##peek-char` | `(0 1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1536 | `##peek-char0` | `(0)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1537 | `##peek-char1` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1538 | `##peek-char0?` | `(0)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1539 | `##peek-char1?` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1540 | `write` | `(1 2)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1541 | `##write` | `(1 2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1542 | `display` | `(1 2)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1543 | `##display` | `(1 2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1544 | `newline` | `(0 1)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1545 | `##newline` | `(0 1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1546 | `##newline0` | `(0)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1547 | `##newline1` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1548 | `write-char` | `(1 2)` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1549 | `##write-char` | `(1 2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1550 | `##write-char1` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1551 | `##write-char2` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1552 | `##write-char1?` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1553 | `##write-char2?` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1554 | `##char-input-port?-cached` | `(1)` | `#f` | `0` | `0` | `boolean` | `extended` |
| 1555 | `##char-output-port?-cached` | `(1)` | `#f` | `0` | `0` | `boolean` | `extended` |
| 1557 | `eof-object?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1558 | `##eof-object?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1559 | `eof-object` | `(0)` | `#f` | `0` | `0` | `#f` | `r7rs` |
| 1560 | `##eof-object` | `(0)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1564 | `procedure?` | `(1)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1565 | `##procedure?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1566 | `apply` | `2` | `#t` | `0` | `0` | `(#f)` | `ieee` |
| 1567 | `##apply` | `(2)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1568 | `map` | `2` | `#t` | `0` | `0` | `list` | `ieee` |
| 1569 | `##map` | `2` | `#t` | `()` | `0` | `list` | `extended` |
| 1570 | `for-each` | `2` | `#t` | `0` | `0` | `#f` | `ieee` |
| 1571 | `##for-each` | `2` | `#t` | `()` | `0` | `#f` | `extended` |
| 1573 | `##closure?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1574 | `##make-closure` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1575 | `##closure-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1576 | `##closure-code` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1577 | `##closure-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1578 | `##closure-set!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1580 | `##subprocedure?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1581 | `##make-subprocedure` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1582 | `##subprocedure-id` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1583 | `##subprocedure-nb-parameters` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1584 | `##subprocedure-nb-closed` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1585 | `##subprocedure-parent` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1586 | `##subprocedure-parent-name` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1587 | `##subprocedure-parent-info` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1591 | `call-with-current-continuation` | `1` | `#t` | `0` | `1113` | `(#f)` | `ieee` |
| 1592 | `##call-with-current-continuation` | `1` | `#t` | `()` | `1113` | `(#f)` | `extended` |
| 1593 | `dynamic-wind` | `(3)` | `#t` | `0` | `0` | `(#f)` | `r5rs` |
| 1594 | `##dynamic-wind` | `(3)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1596 | `call/cc` | `1` | `#t` | `0` | `1113` | `(#f)` | `gambit` |
| 1597 | `continuation?` | `(1)` | `#f` | `0` | `0` | `boolean` | `gambit` |
| 1598 | `##continuation?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1599 | `continuation-capture` | `1` | `#t` | `0` | `1113` | `(#f)` | `gambit` |
| 1600 | `##continuation-capture` | `1` | `#t` | `()` | `1113` | `(#f)` | `extended` |
| 1601 | `continuation-graft` | `2` | `#t` | `0` | `2203` | `#f` | `gambit` |
| 1602 | `##continuation-graft` | `2` | `#t` | `()` | `2203` | `#f` | `extended` |
| 1603 | `##continuation-graft-no-winding` | `2` | `#t` | `()` | `2203` | `#f` | `extended` |
| 1604 | `continuation-return` | `(2)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1605 | `##continuation-return` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1606 | `##continuation-return-no-winding` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1608 | `##make-continuation` | `(2)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1609 | `##continuation-frame` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1610 | `##continuation-frame-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1611 | `##continuation-denv` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1612 | `##continuation-denv-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1613 | `##continuation-next` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1614 | `##continuation-ret` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1615 | `##continuation-fs` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1616 | `##continuation-link` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1617 | `##continuation-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1618 | `##continuation-set!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1619 | `##continuation-slot-live?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1621 | `##frame?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1622 | `##make-frame` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1623 | `##frame-ret` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1624 | `##frame-fs` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1625 | `##frame-link` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1626 | `##frame-ref` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1627 | `##frame-set!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1628 | `##frame-slot-live?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1630 | `##return?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1631 | `##return-fs` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1633 | `##with-exception-catcher` | `(2)` | `#t` | `0` | `0` | `(#f)` | `extended` |
| 1634 | `##r7rs-with-exception-catcher` | `(2)` | `#t` | `0` | `0` | `(#f)` | `extended` |
| 1638 | `load` | `(1)` | `#t` | `0` | `0` | `(#f)` | `r4rs` |
| 1639 | `transcript-on` | `(1)` | `#t` | `0` | `0` | `#f` | `r4rs` |
| 1640 | `transcript-off` | `(0)` | `#t` | `0` | `0` | `#f` | `r4rs` |
| 1642 | `eval` | `(1 2)` | `#t` | `0` | `0` | `(#f)` | `r5rs` |
| 1643 | `interaction-environment` | `(0)` | `#f` | `0` | `0` | `#f` | `r5rs` |
| 1644 | `null-environment` | `(0)` | `#f` | `0` | `0` | `#f` | `r5rs` |
| 1645 | `scheme-report-environment` | `(1)` | `#f` | `0` | `0` | `#f` | `r5rs` |
| 1647 | `##make-global-var` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1648 | `##global-var?` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1649 | `##global-var-ref` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1650 | `##global-var-primitive-ref` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1651 | `##global-var-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1652 | `##global-var-primitive-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1656 | `force` | `(1)` | `#t` | `0` | `0` | `#f` | `r4rs` |
| 1657 | `##force` | `(1)` | `#t` | `0` | `0` | `#f` | `extended` |
| 1659 | `promise?` | `(1)` | `#f` | `()` | `0` | `boolean` | `r7rs` |
| 1660 | `##promise?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1661 | `##make-delay-promise` | `(1)` | `#f` | `0` | `0` | `(#f)` | `extended` |
| 1662 | `##promise-state` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1663 | `##promise-state-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1665 | `touch` | `(1)` | `#t` | `0` | `0` | `#f` | `multilisp` |
| 1669 | `##foreign?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1670 | `##foreign-address` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1671 | `##foreign-tags` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1672 | `##foreign-release!` | `(1)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1673 | `##foreign-released?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1677 | `##structure?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1678 | `##structure-direct-instance-of?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1679 | `##structure-instance-of?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1680 | `##structure-type` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1681 | `##structure-type-set!` | `(2)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1682 | `##structure` | `1` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1683 | `##make-structure` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1684 | `##structure-length` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1685 | `##structure-ref` | `(4)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1686 | `##structure-set!` | `(5)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1687 | `##structure-cas!` | `(6)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1688 | `##direct-structure-ref` | `(4)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1689 | `##direct-structure-set!` | `(5)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1690 | `##direct-structure-cas!` | `(6)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1691 | `##unchecked-structure-ref` | `(4)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1692 | `##unchecked-structure-set!` | `(5)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1693 | `##unchecked-structure-cas!` | `(6)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1695 | `##type-id` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1696 | `##type-name` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1697 | `##type-flags` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1698 | `##type-super` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1699 | `##type-fields` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1703 | `current-thread` | `(0)` | `#f` | `()` | `0` | `#f` | `gambit` |
| 1704 | `##current-thread` | `(0)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1705 | `##current-processor` | `(0)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1706 | `##current-processor-id` | `(0)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1707 | `##processor` | `(1)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1708 | `##current-vm` | `(0)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1710 | `##thread-save!` | `1` | `#t` | `()` | `1113` | `(#f)` | `extended` |
| 1711 | `##thread-restore!` | `2` | `#t` | `()` | `2203` | `#f` | `extended` |
| 1713 | `##primitive-lock!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1714 | `##primitive-trylock!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1715 | `##primitive-unlock!` | `(3)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1717 | `##cpu-cycle-count-start` | `(0)` | `#t` | `()` | `0` | `fixnum` | `extended` |
| 1718 | `##cpu-cycle-count-end` | `(0)` | `#t` | `()` | `0` | `fixnum` | `extended` |
| 1722 | `eq?` | `(2)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1723 | `##eq?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1724 | `equal?` | `(2)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1725 | `##equal?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1726 | `##possibly-equal?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1727 | `eqv?` | `(2)` | `#f` | `0` | `0` | `boolean` | `ieee` |
| 1728 | `##eqv?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1729 | `##possibly-eqv?` | `(2)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1731 | `identity` | `(1)` | `#f` | `0` | `0` | `(#f)` | `gambit` |
| 1732 | `##identity` | `(1)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1734 | `void` | `(0)` | `#f` | `0` | `0` | `#f` | `gambit` |
| 1735 | `##void` | `(0)` | `#f` | `()` | `0` | `#f` | `extended` |
| 1737 | `dead-end` | `(0)` | `#t` | `0` | `0` | `#f` | `gambit` |
| 1738 | `##dead-end` | `(0)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1742 | `##type` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1743 | `##type-cast` | `(2)` | `#f` | `()` | `0` | `(#f)` | `extended` |
| 1744 | `##subtype` | `(1)` | `#f` | `()` | `0` | `fixnum` | `extended` |
| 1745 | `##subtype-set!` | `(2)` | `#t` | `()` | `0` | `#f` | `extended` |
| 1747 | `##false-or-null?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1748 | `##false-or-void?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1749 | `##unbound?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1751 | `##mutable?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1753 | `##special?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1754 | `##meroon?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1755 | `##jazz?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1756 | `##mem-allocated?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1757 | `##subtyped?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1758 | `##subtyped.vector?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1759 | `##subtyped.symbol?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1760 | `##subtyped.flonum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1761 | `##subtyped.bignum?` | `(1)` | `#f` | `()` | `0` | `boolean` | `extended` |
| 1763 | `##object-before?` | `(2)` | `#t` | `()` | `0` | `boolean` | `extended` |
| 1765 | `##first-argument` | `1` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1766 | `##check-heap-limit` | `(0)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1768 | `##poll-point` | `(0)` | `#t` | `()` | `0` | `(#f)` | `extended` |
| 1772 | `##quasi-append` | `0` | `#f` | `0` | `0` | `list` | `extended` |
| 1773 | `##quasi-list` | `0` | `#f` | `()` | `0` | `list` | `extended` |
| 1774 | `##quasi-cons` | `(2)` | `#f` | `()` | `0` | `pair` | `extended` |
| 1775 | `##quasi-list->vector` | `(1)` | `#f` | `0` | `0` | `vector` | `extended` |
| 1776 | `##quasi-vector` | `0` | `#f` | `()` | `0` | `vector` | `extended` |
| 1777 | `##case-memv` | `(2)` | `#f` | `0` | `0` | `list` | `extended` |
