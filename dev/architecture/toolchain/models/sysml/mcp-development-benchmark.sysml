package GambitMcpDevelopmentBenchmark {
    private import ScalarValues::*;
    part def OfficialPackageBenchmark {
        ref part target:GambitDarwinDevelopment::DevelopmentTarget;
        ref part launchFactor:GambitDarwinDevelopment::CostFactor;
        attribute root:String;
        attribute cleanArgv:String;
        attribute buildArgv:String;
        attribute inputManifest:String;
        attribute resultManifest:String;
        attribute toolchainScope:String;
        attribute timing:String;
        attribute cacheScope:String;
        attribute failurePolicy:String;
        attribute causalAdmission:String;
    }
    part workload:OfficialPackageBenchmark {
        ref part :>> target=GambitDarwinDevelopment::target0;
        ref part :>> launchFactor=GambitDarwinDevelopment::costFactor8;
        attribute :>> root="../gerbil-mcp";
        attribute :>> cleanArgv="[gerbil,clean]";
        attribute :>> buildArgv="[gerbil,build]";
        attribute :>> inputManifest=".cache/tasks/future-frame-commit/runs/research/darwin-turbo/mcp-baseline/plan.json";
        attribute :>> resultManifest=".cache/tasks/future-frame-commit/runs/research/darwin-turbo/mcp-baseline/result.json";
        attribute :>> toolchainScope="Resolve actual dispatcher/runtime/compiler identities; installed SDK result is not vendor modern-c qualification";
        attribute :>> timing="Complete official clean then build, including startup, process waits and final exit; completed request required for full elapsed comparison";
        attribute :>> cacheScope="Official package clean only; no fully-cold machine or shared-cache claim";
        attribute :>> failurePolicy="Fixed work deadline; retain partial logs and unknown completion; no automatic retry or candidate gain credit";
        attribute :>> causalAdmission="Join exact package/toolchain/input/clock and mechanism evidence in ASCENT; no Linux ratio without qualified counterpart";
    }
}
