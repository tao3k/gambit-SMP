;;; Read the actual native registry count; symbol-table enumeration omits
;;; globals that are not represented by an interned symbol in that table.
(define gambit.smp.globals#registration-count
  (c-lambda () unsigned-long
    "___result = ___GSTATE->mem.glo_list.count;"))
