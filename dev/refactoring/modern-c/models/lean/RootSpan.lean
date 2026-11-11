import Std.Tactic

/- Pure root-span layout arithmetic. Lifecycle, epochs and retirement belong
   to QNT, not to another transition-system proof here. C pointer provenance,
   allocator effects and synchronization remain separate refinement premises. -/
namespace Gambit.RootSpan

def payloadAddress (header stride index : Nat) : Nat :=
  header + index * stride

def rootAddresses (data header stride count : Nat) : List Nat :=
  data :: (List.range count).map (payloadAddress header stride)

theorem allocationFits {limit header stride count : Nat}
    (headerFits : header ≤ limit) (positiveStride : 0 < stride)
    (accepted : count ≤ (limit - header) / stride) :
    header + count * stride ≤ limit := by
  have productFits := (Nat.le_div_iff_mul_le positiveStride).mp accepted
  omega

theorem everyPayloadCellFits {header stride count index : Nat}
    (inside : index < count) :
    payloadAddress header stride index + stride ≤ header + count * stride := by
  have next : index + 1 ≤ count := by omega
  have bound := Nat.mul_le_mul_right stride next
  simp only [Nat.add_mul, Nat.one_mul] at bound
  unfold payloadAddress
  omega

theorem payloadAddressesInjective {header stride i j : Nat}
    (positiveStride : 0 < stride)
    (same : payloadAddress header stride i = payloadAddress header stride j) :
    i = j := by
  exact Nat.mul_right_cancel positiveStride (Nat.add_left_cancel same)

theorem primaryDoesNotAliasPayload {data header stride index : Nat}
    (positiveStride : 0 < stride) (primaryFits : data + stride ≤ header) :
    data < payloadAddress header stride index := by
  unfold payloadAddress
  omega

theorem exactRootCount (data header stride count : Nat) :
    (rootAddresses data header stride count).length = count + 1 := by
  simp [rootAddresses]

end Gambit.RootSpan
