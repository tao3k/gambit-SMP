/* Architecture definitions only. No behavior or runtime implementation.
 * Source of prose authority: dev/index.org and owning category Org documents.
 * Necessary predicates are intentionally uninstantiated; no satisfy assertion.
 */
package GambitFoundation {
    private import ScalarValues::*;
    item def SemanticPlan {
        attribute semanticIdentity : String;
        attribute runtimeContractIdentity : String;
        attribute evidenceIdentity : String;
    }
    item def NativeProduct {
        attribute productIdentity : String;
        attribute targetIdentity : String;
        attribute runtimeContractIdentity : String;
    }
    port def NativeService {
        in item request : SemanticPlan;
        out item result : NativeProduct;
    }
    part def Identity {
        attribute ownerId : String;
        attribute subjectId : String;
        attribute epoch : Integer;
        attribute sourceIdentity : String;
    }
}
