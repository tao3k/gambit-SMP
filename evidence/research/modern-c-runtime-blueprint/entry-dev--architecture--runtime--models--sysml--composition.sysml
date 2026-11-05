/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitRuntimeComposition {
    private import ScalarValues::*;

    part def RuntimeComposition {
        part execution : GambitRuntime::ExecutionBoundary;
        part collector : GambitGc::CollectorBoundary;
        part control : GambitControl::ResumptionBoundary;
        part foreign : GambitFfi::ForeignBoundary;
        part rootHandoff : GambitRuntimeInterfaces::RootHandoff;
        part controlOrigins : GambitRuntimeInterfaces::ControlOrigins;
        part retirement : GambitRuntimeInterfaces::RetirementWindow;
        part completion : GambitRuntimeInterfaces::WorkClosure;
    }

}
