package StructuralFixture {
 private import ScalarValues::*;
 part def Component { attribute owner:String; }
 part root:Component { attribute :>> owner="shared-framework"; attribute enabled:Boolean=false; }
 part child { attribute count:Integer=3; }
}
