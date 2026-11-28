/* Design cut for one write-group grant. Finite requirements only. */
package GambitGrantStability {
  private import ScalarValues::*;

  part def GrantRun {
    attribute enters : Integer;
    attribute commits : Integer;
    attribute stores : Integer;
    attribute grantedRuns : Integer;
    attribute refusedRuns : Integer;
    attribute phase : Integer;
    attribute nativeAdmitted : Boolean;
    attribute remainWords : Integer;
    attribute groupWords : Integer;
    attribute freeWords : Integer;
    attribute sectionWords : Integer;
    attribute nextNodeIsLiveStack : Boolean;
    attribute floatVectorPresent : Boolean;
    attribute heartbeatYields : Boolean;
    attribute barrierChildCounted : Boolean;
    attribute barrierChildNativeLive : Boolean;
  }

  requirement def OneEnterBeforeStores {
    subject g : GrantRun;
    require constraint {
      g.enters == 1 and g.commits == 1 and g.stores > 0
    }
  }

  requirement def IdenticalInputHasOneOutcome {
    subject g : GrantRun;
    require constraint {
      g.grantedRuns == 0 or g.refusedRuns == 0
    }
  }

  requirement def PhaseThreeOrFourIsRefusal {
    subject g : GrantRun;
    require constraint {
      g.phase == 3 or g.phase == 4
    }
  }

  requirement def ModelCheckIsNotNativeAdmission {
    subject g : GrantRun;
    require constraint {
      not g.nativeAdmitted
    }
  }

  requirement def PartialBudgetCannotBuyOneSection {
    subject g : GrantRun;
    require constraint {
      g.freeWords > 0 and g.freeWords < g.sectionWords
    }
  }

  requirement def LiveStackIsNotTheHeapSection {
    subject g : GrantRun;
    require constraint {
      not g.nextNodeIsLiveStack
    }
  }

  requirement def AbsentFloatVectorDoesNotYield {
    subject g : GrantRun;
    require constraint {
      g.floatVectorPresent or not g.heartbeatYields
    }
  }

  requirement def PhaseTwoIsRepairedReturn {
    subject g : GrantRun;
    require constraint {
      g.phase == 2
    }
  }

  requirement def BarrierWaitsOnlyForALiveChild {
    subject g : GrantRun;
    require constraint {
      not g.barrierChildCounted or g.barrierChildNativeLive
    }
  }

  part observedLeaf : GrantRun {
    attribute :>> enters = 1;
    attribute :>> commits = 1;
    attribute :>> stores = 3;
    attribute :>> grantedRuns = 3;
    attribute :>> refusedRuns = 5;
    attribute :>> phase = 4;
    attribute :>> nativeAdmitted = false;
    attribute :>> remainWords = 1;
    attribute :>> groupWords = 12;
    attribute :>> freeWords = 57336;
    attribute :>> sectionWords = 131072;
    attribute :>> nextNodeIsLiveStack = true;
    attribute :>> floatVectorPresent = false;
    attribute :>> heartbeatYields = true;
    attribute :>> barrierChildCounted = true;
    attribute :>> barrierChildNativeLive = false;
  }
}
