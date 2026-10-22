. as $profile |
all($profile.needs[] | select(.slot=="history" or .slot=="induction"); . as $need |
 if $need.component=="gc-synchronous-publication" and $need.slot=="history" then
   $previous[0].sourceBindings[$need.subjectPath]==$need.digest and $previous[0].formal.quint.deterministicTests==15
 else
   any($formal[0][]; .source==$need.subjectPath and .sourceSha256==$need.digest and .exitCode==0 and
     (if $need.slot=="history" then .stage=="bounded-histories" and .scope==$need.subjectScope
      else .stage=="inductive-preservation" end))
 end)
