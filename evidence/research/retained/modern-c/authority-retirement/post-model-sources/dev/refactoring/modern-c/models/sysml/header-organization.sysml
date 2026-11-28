package GambitHeaderOrganization {
  private import ScalarValues::*;
  attribute baseRevision:String="bd0991ed9e348c7abc39a9db4b5a18653f6758c2";
  attribute source:String="vendor/gambit/include/gambit.h.in";
  attribute baselineSha256:String="017e83314a64243b3daf7998ac4258578baa9917859493bf5dde59bdf93528b0";
  attribute publication:String="One configured public gambit.h, byte-identical to ordered concatenation; private source modules live under include/_gambit; no extra runtime includes or ABI aliases";
  part def Fragment { attribute file:String; attribute firstLine:Integer; attribute pastLine:Integer; attribute driverInline:Boolean; }
  part h_header_begin:Fragment { attribute :>> file="_gambit/header_begin.h.in"; attribute :>> firstLine=1; attribute :>> pastLine=22; attribute :>> driverInline=false; }
  part h_platform:Fragment { attribute :>> file="_gambit/platform.h.in"; attribute :>> firstLine=22; attribute :>> pastLine=997; attribute :>> driverInline=false; }
  part h_compiler:Fragment { attribute :>> file="_gambit/compiler.h.in"; attribute :>> firstLine=997; attribute :>> pastLine=1208; attribute :>> driverInline=false; }
  part h_configuration:Fragment { attribute :>> file="_gambit/configuration.h.in"; attribute :>> firstLine=1208; attribute :>> pastLine=1576; attribute :>> driverInline=false; }
  part h_language:Fragment { attribute :>> file="_gambit/language.h.in"; attribute :>> firstLine=1576; attribute :>> pastLine=1716; attribute :>> driverInline=false; }
  part h_math:Fragment { attribute :>> file="_gambit/math.h.in"; attribute :>> firstLine=1716; attribute :>> pastLine=1809; attribute :>> driverInline=false; }
  part h_signals:Fragment { attribute :>> file="_gambit/signals.h.in"; attribute :>> firstLine=1809; attribute :>> pastLine=1835; attribute :>> driverInline=false; }
  part h_visibility:Fragment { attribute :>> file="_gambit/visibility.h.in"; attribute :>> firstLine=1835; attribute :>> pastLine=1911; attribute :>> driverInline=false; }
  part h_code_generation:Fragment { attribute :>> file="_gambit/code_generation.h.in"; attribute :>> firstLine=1911; attribute :>> pastLine=2012; attribute :>> driverInline=false; }
  part h_integer_representation:Fragment { attribute :>> file="_gambit/integer_representation.h.in"; attribute :>> firstLine=2012; attribute :>> pastLine=2275; attribute :>> driverInline=false; }
  part h_value_types:Fragment { attribute :>> file="_gambit/value_types.h.in"; attribute :>> firstLine=2275; attribute :>> pastLine=2464; attribute :>> driverInline=false; }
  part h_object_tags:Fragment { attribute :>> file="_gambit/object_tags.h.in"; attribute :>> firstLine=2464; attribute :>> pastLine=3070; attribute :>> driverInline=false; }
  part h_utilities:Fragment { attribute :>> file="_gambit/utilities.h.in"; attribute :>> firstLine=3070; attribute :>> pastLine=3124; attribute :>> driverInline=false; }
  part h_object_access:Fragment { attribute :>> file="_gambit/object_access.h.in"; attribute :>> firstLine=3124; attribute :>> pastLine=3908; attribute :>> driverInline=false; }
  part h_gvm_operations:Fragment { attribute :>> file="_gambit/gvm_operations.h.in"; attribute :>> firstLine=3908; attribute :>> pastLine=6823; attribute :>> driverInline=false; }
  part h_stack_operations:Fragment { attribute :>> file="_gambit/stack_operations.h.in"; attribute :>> firstLine=6823; attribute :>> pastLine=7086; attribute :>> driverInline=false; }
  part h_gvm_registers:Fragment { attribute :>> file="_gambit/gvm_registers.h.in"; attribute :>> firstLine=7086; attribute :>> pastLine=8150; attribute :>> driverInline=false; }
  part h_temporary_roots:Fragment { attribute :>> file="_gambit/temporary_roots.h.in"; attribute :>> firstLine=8150; attribute :>> pastLine=8179; attribute :>> driverInline=false; }
  part h_labels:Fragment { attribute :>> file="_gambit/labels.h.in"; attribute :>> firstLine=8179; attribute :>> pastLine=8257; attribute :>> driverInline=false; }
  part h_module_generation:Fragment { attribute :>> file="_gambit/module_generation.h.in"; attribute :>> firstLine=8257; attribute :>> pastLine=9794; attribute :>> driverInline=false; }
  part h_foreign_abi:Fragment { attribute :>> file="_gambit/foreign_abi.h.in"; attribute :>> firstLine=9794; attribute :>> pastLine=10053; attribute :>> driverInline=false; }
  part h_foreign_conversion:Fragment { attribute :>> file="_gambit/foreign_conversion.h.in"; attribute :>> firstLine=10053; attribute :>> pastLine=10867; attribute :>> driverInline=false; }
  part h_declarations_begin:Fragment { attribute :>> file="_gambit/declarations_begin.h.in"; attribute :>> firstLine=10867; attribute :>> pastLine=10871; attribute :>> driverInline=false; }
  part h_native_platform:Fragment { attribute :>> file="_gambit/native_platform.h.in"; attribute :>> firstLine=10871; attribute :>> pastLine=11113; attribute :>> driverInline=false; }
  part h_native_types:Fragment { attribute :>> file="_gambit/native_types.h.in"; attribute :>> firstLine=11113; attribute :>> pastLine=11131; attribute :>> driverInline=false; }
  part h_activity_log:Fragment { attribute :>> file="_gambit/activity_log.h.in"; attribute :>> firstLine=11131; attribute :>> pastLine=11450; attribute :>> driverInline=false; }
  part h_processor_os:Fragment { attribute :>> file="_gambit/processor_os.h.in"; attribute :>> firstLine=11450; attribute :>> pastLine=11565; attribute :>> driverInline=false; }
  part h_memory_state:Fragment { attribute :>> file="_gambit/memory_state.h.in"; attribute :>> firstLine=11565; attribute :>> pastLine=11904; attribute :>> driverInline=false; }
  part h_runtime_forwards:Fragment { attribute :>> file="_gambit/runtime_forwards.h.in"; attribute :>> firstLine=11904; attribute :>> pastLine=11910; attribute :>> driverInline=false; }
  part h_synchronization:Fragment { attribute :>> file="_gambit/synchronization.h.in"; attribute :>> firstLine=11910; attribute :>> pastLine=11918; attribute :>> driverInline=false; }
  part h_processor_state:Fragment { attribute :>> file="_gambit/processor_state.h.in"; attribute :>> firstLine=11918; attribute :>> pastLine=12103; attribute :>> driverInline=false; }
  part h_label_types:Fragment { attribute :>> file="_gambit/label_types.h.in"; attribute :>> firstLine=12103; attribute :>> pastLine=12198; attribute :>> driverInline=false; }
  part h_module_state:Fragment { attribute :>> file="_gambit/module_state.h.in"; attribute :>> firstLine=12198; attribute :>> pastLine=12271; attribute :>> driverInline=false; }
  part h_write_authority:Fragment { attribute :>> file="_gambit/write_authority.h.in"; attribute :>> firstLine=12271; attribute :>> pastLine=12286; attribute :>> driverInline=false; }
  part h_vm_state:Fragment { attribute :>> file="_gambit/vm_state.h.in"; attribute :>> firstLine=12286; attribute :>> pastLine=12334; attribute :>> driverInline=false; }
  part h_setup_parameters:Fragment { attribute :>> file="_gambit/setup_parameters.h.in"; attribute :>> firstLine=12334; attribute :>> pastLine=12459; attribute :>> driverInline=false; }
  part h_global_state:Fragment { attribute :>> file="_gambit/global_state.h.in"; attribute :>> firstLine=12459; attribute :>> pastLine=13975; attribute :>> driverInline=false; }
  part h_runtime_protocols:Fragment { attribute :>> file="_gambit/runtime_protocols.h.in"; attribute :>> firstLine=13975; attribute :>> pastLine=15479; attribute :>> driverInline=false; }
  part h_declarations_end:Fragment { attribute :>> file="_gambit/declarations_end.h.in"; attribute :>> firstLine=15479; attribute :>> pastLine=15516; attribute :>> driverInline=false; }
  part h_header_end:Fragment { attribute :>> file="_gambit/header_end.h.in"; attribute :>> firstLine=15516; attribute :>> pastLine=15520; attribute :>> driverInline=false; }
}
