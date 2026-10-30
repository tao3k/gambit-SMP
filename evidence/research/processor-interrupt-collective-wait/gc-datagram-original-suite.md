# Original interpreted runner output

Verbatim stdout; times are rounded cumulative runner times, not independent
per-file durations. Source and receipt bindings are in
[the native observation](gc-datagram-native-observation.md).

```text
[  0|  0]   0% ................  .0s 06-thread/tfib_stress.scm
[  1|  0]  25% ####............ 1536.3s 06-thread/thread_interrupt2_stress.scm
[  2|  0]  50% ########........ 1730.4s 06-thread/thread_interrupt_stress.scm
[  3|  0]  75% ############.... 1808.1s 06-thread/thread_terminate_stress.scm
[  4|  0] 100% ################ 1828.2s
PASSED ALL 4 UNIT TESTS
```
