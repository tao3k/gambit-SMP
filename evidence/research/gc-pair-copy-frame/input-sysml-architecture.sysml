/* Category architecture model; necessary conditions, not a runtime proof.
 * Owning Org: dev/architecture/toolchain/index.org. Unbound subjects; no satisfaction asserted.
 * Validation diagnostics are separate from behavior, solver and native tests. */
package GambitToolchain {
    private import ScalarValues::*;
    private import GambitFoundation::*;

    part def ArtifactBoundary {
        part identity : Identity;
        port service : NativeService;
        attribute cacheReuseRequested : Boolean;
        attribute allInputIdentitiesMatched : Boolean;
        attribute freshInstanceRequested : Boolean;
        attribute instanceInitializationComplete : Boolean;
    }

    requirement def ArtifactReuseLaw {
        subject boundary : ArtifactBoundary;
        require constraint { not boundary.cacheReuseRequested or boundary.allInputIdentitiesMatched }
    }

    requirement def InstanceLaw {
        subject boundary : ArtifactBoundary;
        require constraint { not boundary.freshInstanceRequested or boundary.instanceInitializationComplete }
    }


    part def MulticoreArtifactWitness {
        attribute sharedVmParallelismClaimed : Boolean;
        attribute effectiveThreadedVmVerified : Boolean;
        attribute effectiveSchedulerVerified : Boolean;
        attribute threadBackendVerified : Boolean;
        attribute processorBoundVerified : Boolean;
        attribute linkedRuntimeIdentityVerified : Boolean;
        attribute observedRuntimePopulationVerified : Boolean;
        attribute artifactReuseRequested : Boolean;
        attribute relevantInputProjectionMatched : Boolean;
        attribute frameRootAbiMatched : Boolean;
    }
    requirement def EffectiveMulticoreProfileLaw {
        subject witness : MulticoreArtifactWitness;
        require constraint { not witness.sharedVmParallelismClaimed or
            (witness.effectiveThreadedVmVerified and witness.effectiveSchedulerVerified and
             witness.threadBackendVerified and witness.processorBoundVerified and
             witness.linkedRuntimeIdentityVerified and witness.observedRuntimePopulationVerified) }
    }
    requirement def NativeArtifactProfileLaw {
        subject witness : MulticoreArtifactWitness;
        require constraint { not witness.artifactReuseRequested or
            (witness.relevantInputProjectionMatched and witness.frameRootAbiMatched) }
    }
}
