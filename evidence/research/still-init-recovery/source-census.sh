#!/bin/bash
set -euo pipefail
r=.cache/tasks/still-init-recovery
rg -n 'NONNULLSTRING_to_SCMOBJ|STRING_to_SCMOBJ|release_scmobj' vendor/gambit/lib/os_base.c vendor/gambit/lib/os_io.c > "$r/native-output-callers.txt"
rg -n '___alloc_scmobj|___release_scmobj|\*obj =|___UTF_8_get_var|___STRINGSET|___make_pair' vendor/gambit/lib/c_intf.c > "$r/conversion-endpoints.txt"
sed -n '5413,5500p' vendor/gambit/lib/c_intf.c > "$r/utf8-cursor-and-failure.txt"
sed -n '5732,5803p' vendor/gambit/lib/c_intf.c > "$r/string-list-handoff.txt"
sed -n '11412,11428p' vendor/gambit/lib/os_io.c > "$r/directory-effect-return.txt"
sed -n '1730,1818p' vendor/gambit/lib/mem.c > "$r/still-native-constructors.txt"
sed -n '4016,4040p' vendor/gambit/lib/mem.c > "$r/atomic-scan-classification.txt"
sed -n '23864,23904p' vendor/gambit/lib/_kernel.c > "$r/structure-result-handoff.txt"
