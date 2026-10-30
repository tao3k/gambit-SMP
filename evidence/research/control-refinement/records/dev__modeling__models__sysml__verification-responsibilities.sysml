/* Verification organization policy, not an additional runtime component. */
package GambitVerificationResponsibilities {
  private import ScalarValues::*;
  attribute llmIsWorkingEnvironment:Boolean=true;
  attribute oneOwnerPerObligation:Boolean=true;
  attribute duplicateSemanticKeysForbidden:Boolean=true;
  part def Responsibility {
    attribute id:String; attribute domains:String;
    attribute owns:String; attribute excludes:String;
  }
  part quint:Responsibility {
    attribute :>> id="quint"; attribute :>> domains="control";
    attribute :>> owns="Transition ordering, concurrent interleavings and permit/task/root lifetime protocols within declared bounds";
    attribute :>> excludes="Payload algebra, unbounded data-coherence proofs and claims of concrete native correctness";
  }
  part lean:Responsibility {
    attribute :>> id="lean"; attribute :>> domains="data";
    attribute :>> owns="General mathematical/data representation properties under explicit hypotheses";
    attribute :>> excludes="A duplicate scheduler, bounded trace tests, wind interleavings and claims that premises automatically hold in C";
  }
  part source:Responsibility {
    attribute :>> id="source"; attribute :>> domains="source;semantics;refinement";
    attribute :>> owns="Actual source writers/consumers, semantic correspondence and refinement of imported premises";
    attribute :>> excludes="Declaring an unresolved native/refinement obligation proved by source-token presence or LLM judgment alone";
  }
  part native:Responsibility {
    attribute :>> id="native"; attribute :>> domains="native";
    attribute :>> owns="Source/profile-bound execution, semantic regression, progress and measured resource/performance acceptance";
    attribute :>> excludes="Promotion of finite models, conditional laws or historical binaries to new native completion";
  }
}
