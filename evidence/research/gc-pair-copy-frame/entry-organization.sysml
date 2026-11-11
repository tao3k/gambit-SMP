/* Authored architecture/model definition only. No behavior, satisfaction or native acceptance asserted. */
package GambitDevelopmentOrganization {
    private import ScalarValues::*;
    part def Area {
        attribute relativePath : String;
        attribute purpose : String;
        attribute orgEntry : String [0..1];
        attribute structureModel : String [0..1];
        attribute d2View : String [0..1];
        attribute quintIndex : String [0..1];
        attribute leanIndex : String [0..1];
    }
    /* Contract bindings and proof-obligation ownership live with the runtime
     * interface owner, not in another layout or model-list configuration. */
    alias runtimeRelations for GambitRuntimeModelRelations::relations;
    part development {
        part knowledge : Area {
            attribute :>> relativePath = "dev/knowledge";
            attribute :>> orgEntry = "dev/knowledge/index.org";
            attribute :>> structureModel = "dev/knowledge/models/sysml/learning.sysml";
            attribute :>> d2View = "dev/knowledge/diagrams/learning.d2";
            attribute :>> purpose = "Mechanism learning; facts separated from Gambit inference";
            part gambit : Area {
                attribute :>> relativePath = "dev/knowledge/gambit";
                attribute :>> orgEntry = "dev/knowledge/gambit/index.org";
                attribute :>> purpose = "gambit responsibility";
            }
            part ocaml : Area {
                attribute :>> relativePath = "dev/knowledge/ocaml";
                attribute :>> orgEntry = "dev/knowledge/ocaml/index.org";
                attribute :>> purpose = "ocaml responsibility";
            }
            part chez : Area {
                attribute :>> relativePath = "dev/knowledge/chez";
                attribute :>> orgEntry = "dev/knowledge/chez/index.org";
                attribute :>> purpose = "chez responsibility";
            }
            part systems : Area {
                attribute :>> relativePath = "dev/knowledge/systems";
                attribute :>> orgEntry = "dev/knowledge/systems/index.org";
                attribute :>> purpose = "systems responsibility";
            }
        }
        part architecture : Area {
            attribute :>> relativePath = "dev/architecture";
            attribute :>> orgEntry = "dev/architecture/index.org";
            attribute :>> structureModel = "dev/architecture/models/sysml/organization.sysml";
            attribute :>> d2View = "dev/architecture/diagrams/organization.d2";
            attribute :>> purpose = "Language-independent Gambit system responsibilities";
            part system : Area {
                attribute :>> relativePath = "dev/architecture/system";
                attribute :>> orgEntry = "dev/architecture/system/index.org";
                attribute :>> structureModel = "dev/architecture/system/models/sysml/architecture.sysml";
                attribute :>> d2View = "dev/architecture/system/diagrams/overview.d2";
                attribute :>> purpose = "system responsibility";
            }
            part runtime : Area {
                attribute :>> relativePath = "dev/architecture/runtime";
                attribute :>> orgEntry = "dev/architecture/runtime/index.org";
                attribute :>> structureModel = "dev/architecture/runtime/models/sysml/composition.sysml";
                attribute :>> d2View = "dev/architecture/runtime/diagrams/composition.d2";
                attribute :>> purpose = "runtime responsibility";
                part execution : Area {
                    attribute :>> relativePath = "dev/architecture/runtime/execution";
                    attribute :>> orgEntry = "dev/architecture/runtime/execution/index.org";
                    attribute :>> structureModel = "dev/architecture/runtime/execution/models/sysml/architecture.sysml";
                    attribute :>> d2View = "dev/architecture/runtime/execution/diagrams/overview.d2";
                    attribute :>> quintIndex = "dev/architecture/runtime/execution/models/quint/index.org";
                    attribute :>> leanIndex = "dev/architecture/runtime/execution/models/lean/index.org";
                    attribute :>> purpose = "execution responsibility";
                }
                part gc : Area {
                    attribute :>> relativePath = "dev/architecture/runtime/gc";
                    attribute :>> orgEntry = "dev/architecture/runtime/gc/index.org";
                    attribute :>> structureModel = "dev/architecture/runtime/gc/models/sysml/architecture.sysml";
                    attribute :>> d2View = "dev/architecture/runtime/gc/diagrams/overview.d2";
                    attribute :>> quintIndex = "dev/architecture/runtime/gc/models/quint/index.org";
                    attribute :>> leanIndex = "dev/architecture/runtime/gc/models/lean/index.org";
                    attribute :>> purpose = "gc responsibility";
                }
                part control : Area {
                    attribute :>> relativePath = "dev/architecture/runtime/control";
                    attribute :>> orgEntry = "dev/architecture/runtime/control/index.org";
                    attribute :>> structureModel = "dev/architecture/runtime/control/models/sysml/architecture.sysml";
                    attribute :>> d2View = "dev/architecture/runtime/control/diagrams/overview.d2";
                    attribute :>> quintIndex = "dev/architecture/runtime/control/models/quint/index.org";
                    attribute :>> leanIndex = "dev/architecture/runtime/control/models/lean/index.org";
                    attribute :>> purpose = "control responsibility";
                }
                part ffi : Area {
                    attribute :>> relativePath = "dev/architecture/runtime/ffi";
                    attribute :>> orgEntry = "dev/architecture/runtime/ffi/index.org";
                    attribute :>> structureModel = "dev/architecture/runtime/ffi/models/sysml/architecture.sysml";
                    attribute :>> d2View = "dev/architecture/runtime/ffi/diagrams/overview.d2";
                    attribute :>> quintIndex = "dev/architecture/runtime/ffi/models/quint/index.org";
                    attribute :>> leanIndex = "dev/architecture/runtime/ffi/models/lean/index.org";
                    attribute :>> purpose = "ffi responsibility";
                }
                part interfaces : Area {
                    attribute :>> relativePath = "dev/architecture/runtime/interfaces";
                    attribute :>> orgEntry = "dev/architecture/runtime/interfaces/index.org";
                    attribute :>> structureModel = "dev/architecture/runtime/interfaces/models/sysml/interfaces.sysml";
                    attribute :>> d2View = "dev/architecture/runtime/interfaces/diagrams/relations.d2";
                    attribute :>> purpose = "interfaces responsibility";
                }
            }
            part compiler : Area {
                attribute :>> relativePath = "dev/architecture/compiler";
                attribute :>> orgEntry = "dev/architecture/compiler/index.org";
                attribute :>> structureModel = "dev/architecture/compiler/models/sysml/architecture.sysml";
                attribute :>> d2View = "dev/architecture/compiler/diagrams/overview.d2";
                attribute :>> purpose = "compiler responsibility";
            }
            part toolchain : Area {
                attribute :>> relativePath = "dev/architecture/toolchain";
                attribute :>> orgEntry = "dev/architecture/toolchain/index.org";
                attribute :>> structureModel = "dev/architecture/toolchain/models/sysml/architecture.sysml";
                attribute :>> d2View = "dev/architecture/toolchain/diagrams/overview.d2";
                attribute :>> purpose = "toolchain responsibility";
            }
        }
        part refactoring : Area {
            attribute :>> relativePath = "dev/refactoring";
            attribute :>> orgEntry = "dev/refactoring/index.org";
            attribute :>> structureModel = "dev/refactoring/models/sysml/adoption.sysml";
            attribute :>> d2View = "dev/refactoring/diagrams/adoption.d2";
            attribute :>> purpose = "Implementation replacement and retirement";
            part modernC : Area {
                attribute :>> relativePath = "dev/refactoring/modern-c";
                attribute :>> orgEntry = "dev/refactoring/modern-c/index.org";
                attribute :>> structureModel = "dev/refactoring/modern-c/models/sysml/architecture.sysml";
                attribute :>> d2View = "dev/refactoring/modern-c/diagrams/overview.d2";
                attribute :>> purpose = "modern c responsibility";
            }
            part zig : Area {
                attribute :>> relativePath = "dev/refactoring/zig";
                attribute :>> orgEntry = "dev/refactoring/zig/index.org";
                attribute :>> structureModel = "dev/refactoring/zig/models/sysml/architecture.sysml";
                attribute :>> d2View = "dev/refactoring/zig/diagrams/overview.d2";
                attribute :>> purpose = "zig responsibility";
            }
        }
        part modeling : Area {
            attribute :>> relativePath = "dev/modeling";
            attribute :>> orgEntry = "dev/modeling/index.org";
            attribute :>> structureModel = "dev/modeling/models/sysml/assurance.sysml";
            attribute :>> d2View = "dev/modeling/diagrams/assurance.d2";
            attribute :>> purpose = "Methods, correspondence and shared vocabulary";
            part org : Area {
                attribute :>> relativePath = "dev/modeling/org";
                attribute :>> purpose = "org responsibility";
            }
            part libraries : Area {
                attribute :>> relativePath = "dev/modeling/libraries";
                attribute :>> orgEntry = "dev/modeling/libraries/index.org";
                attribute :>> purpose = "libraries responsibility";
                part sysml : Area {
                    attribute :>> relativePath = "dev/modeling/libraries/sysml";
                    attribute :>> purpose = "sysml responsibility";
                }
            }
        }
        part research : Area {
            attribute :>> relativePath = "dev/research";
            attribute :>> orgEntry = "dev/research/index.org";
            attribute :>> structureModel = "dev/research/models/sysml/architecture.sysml";
            attribute :>> d2View = "dev/research/diagrams/overview.d2";
            attribute :>> purpose = "Questions, arguments, counterexamples and evidence";
        }
    }
}
