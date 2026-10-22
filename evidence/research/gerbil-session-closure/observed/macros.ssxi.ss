prelude: :gerbil/compiler/ssxi
package: std/iter

(begin
  (declare-type
   |std/iter/macros[1]#binding-contract?|
   (@lambda 1
            #f
            signature:
            (return:
             boolean::t
             effect:
             #f
             arguments:
             #f
             unchecked:
             #f
             origin:
             std/iter/macros)))
  (declare-type
   |std/iter/macros[1]#for-binding?|
   (@lambda 1
            #f
            signature:
            (return:
             t::t
             effect:
             #f
             arguments:
             #f
             unchecked:
             #f
             origin:
             std/iter/macros))))
