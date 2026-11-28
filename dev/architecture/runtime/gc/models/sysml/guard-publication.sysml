/* Guard publication for one generated write group. Finite model only. */
package GambitGuardPublication {
  private import ScalarValues::*;

  part def GuardView {
    attribute contextLimit : Integer;
    attribute processorLimit : Integer;
    attribute trip : Integer;
    attribute refreshed : Boolean;
    attribute fp : Integer;
    attribute hp : Integer;
    attribute hard : Integer;
    attribute past : Integer;
    attribute fudge : Integer;
    attribute spins : Integer;
    attribute allocated : Boolean;
  }

  requirement def PollReadsRefreshedContextLimit {
    subject g : GuardView;
    require constraint {
      not g.refreshed or g.trip == g.contextLimit
    }
  }

  requirement def ProcessorFieldIsNotTheTrip {
    subject g : GuardView;
    require constraint {
      not g.refreshed or g.trip == g.contextLimit
    }
  }

  requirement def BreakFrameStaysInHalf {
    subject g : GuardView;
    require constraint {
      g.fp >= 4
    }
  }

  requirement def HeapBurstStaysInside {
    subject g : GuardView;
    require constraint {
      g.hp + g.fudge <= g.hard and g.hard <= g.past
    }
  }

  requirement def DescriptorAfterInsideRefresh {
    subject g : GuardView;
    require constraint {
      not g.allocated or (g.refreshed and g.spins == 0 and g.fp >= 0 and g.hp + g.fudge <= g.hard and g.hard <= g.past)
    }
  }

  part measuredHeap : GuardView {
    attribute :>> contextLimit = 9222;
    attribute :>> processorLimit = 0;
    attribute :>> trip = 0;
    attribute :>> refreshed = false;
    attribute :>> fp = -4;
    attribute :>> hp = 56315;
    attribute :>> hard = 65535;
    attribute :>> past = 65536;
    attribute :>> fudge = 9222;
    attribute :>> spins = 0;
    attribute :>> allocated = false;
  }
}
