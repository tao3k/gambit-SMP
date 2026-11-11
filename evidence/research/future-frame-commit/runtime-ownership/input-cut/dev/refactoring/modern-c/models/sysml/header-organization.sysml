package GambitHeaderOrganization {
  private import ScalarValues::*;
  attribute baseRevision:String="dfec5508118afef2dc9bd1ade5c928930e63c0fa";
  attribute source:String="vendor/gambit/include/gambit.h.in";
  attribute baselineSha256:String="0288b0ca9f0799a6aeafd8058ae5b20a796d36307b8ca48cd5cfc87684e3abfb";
  attribute publication:String="One configured public gambit.h, byte-identical to ordered concatenation; private source modules live under include/_gambit; no extra runtime includes or ABI aliases";
  part def Fragment { attribute file:String; attribute firstLine:Integer; attribute pastLine:Integer; attribute driverInline:Boolean; }
  part h_header_begin:Fragment { attribute :>> file="_gambit/header_begin.h.in"; attribute :>> firstLine=1; attribute :>> pastLine=22; attribute :>> driverInline=true; }
  part h_platform:Fragment { attribute :>> file="_gambit/platform.h.in"; attribute :>> firstLine=22; attribute :>> pastLine=997; attribute :>> driverInline=false; }
  part h_compiler:Fragment { attribute :>> file="_gambit/compiler.h.in"; attribute :>> firstLine=997; attribute :>> pastLine=1208; attribute :>> driverInline=false; }
  part h_configuration:Fragment { attribute :>> file="_gambit/configuration.h.in"; attribute :>> firstLine=1208; attribute :>> pastLine=1555; attribute :>> driverInline=false; }
  part h_language:Fragment { attribute :>> file="_gambit/language.h.in"; attribute :>> firstLine=1555; attribute :>> pastLine=1695; attribute :>> driverInline=false; }
  part h_math:Fragment { attribute :>> file="_gambit/math.h.in"; attribute :>> firstLine=1695; attribute :>> pastLine=1788; attribute :>> driverInline=false; }
  part h_signals:Fragment { attribute :>> file="_gambit/signals.h.in"; attribute :>> firstLine=1788; attribute :>> pastLine=1814; attribute :>> driverInline=false; }
  part h_visibility:Fragment { attribute :>> file="_gambit/visibility.h.in"; attribute :>> firstLine=1814; attribute :>> pastLine=1890; attribute :>> driverInline=false; }
  part h_code_generation:Fragment { attribute :>> file="_gambit/code_generation.h.in"; attribute :>> firstLine=1890; attribute :>> pastLine=1991; attribute :>> driverInline=false; }
  part h_integer_representation:Fragment { attribute :>> file="_gambit/integer_representation.h.in"; attribute :>> firstLine=1991; attribute :>> pastLine=2254; attribute :>> driverInline=false; }
  part h_value_types:Fragment { attribute :>> file="_gambit/value_types.h.in"; attribute :>> firstLine=2254; attribute :>> pastLine=2443; attribute :>> driverInline=false; }
  part h_object_tags:Fragment { attribute :>> file="_gambit/object_tags.h.in"; attribute :>> firstLine=2443; attribute :>> pastLine=3049; attribute :>> driverInline=false; }
  part h_utilities:Fragment { attribute :>> file="_gambit/utilities.h.in"; attribute :>> firstLine=3049; attribute :>> pastLine=3103; attribute :>> driverInline=false; }
  part h_object_access:Fragment { attribute :>> file="_gambit/object_access.h.in"; attribute :>> firstLine=3103; attribute :>> pastLine=3887; attribute :>> driverInline=false; }
  part h_gvm_operations:Fragment { attribute :>> file="_gambit/gvm_operations.h.in"; attribute :>> firstLine=3887; attribute :>> pastLine=6736; attribute :>> driverInline=false; }
  part h_stack_operations:Fragment { attribute :>> file="_gambit/stack_operations.h.in"; attribute :>> firstLine=6736; attribute :>> pastLine=6993; attribute :>> driverInline=false; }
  part h_gvm_registers:Fragment { attribute :>> file="_gambit/gvm_registers.h.in"; attribute :>> firstLine=6993; attribute :>> pastLine=8057; attribute :>> driverInline=false; }
  part h_temporary_roots:Fragment { attribute :>> file="_gambit/temporary_roots.h.in"; attribute :>> firstLine=8057; attribute :>> pastLine=8086; attribute :>> driverInline=false; }
  part h_labels:Fragment { attribute :>> file="_gambit/labels.h.in"; attribute :>> firstLine=8086; attribute :>> pastLine=8164; attribute :>> driverInline=false; }
  part h_module_generation:Fragment { attribute :>> file="_gambit/module_generation.h.in"; attribute :>> firstLine=8164; attribute :>> pastLine=9688; attribute :>> driverInline=false; }
  part h_foreign_abi:Fragment { attribute :>> file="_gambit/foreign_abi.h.in"; attribute :>> firstLine=9688; attribute :>> pastLine=9947; attribute :>> driverInline=false; }
  part h_foreign_conversion:Fragment { attribute :>> file="_gambit/foreign_conversion.h.in"; attribute :>> firstLine=9947; attribute :>> pastLine=10758; attribute :>> driverInline=false; }
  part h_declarations_begin:Fragment { attribute :>> file="_gambit/declarations_begin.h.in"; attribute :>> firstLine=10758; attribute :>> pastLine=10762; attribute :>> driverInline=true; }
  part h_native_platform:Fragment { attribute :>> file="_gambit/native_platform.h.in"; attribute :>> firstLine=10762; attribute :>> pastLine=10980; attribute :>> driverInline=false; }
  part h_native_types:Fragment { attribute :>> file="_gambit/native_types.h.in"; attribute :>> firstLine=10980; attribute :>> pastLine=10998; attribute :>> driverInline=false; }
  part h_activity_log:Fragment { attribute :>> file="_gambit/activity_log.h.in"; attribute :>> firstLine=10998; attribute :>> pastLine=11262; attribute :>> driverInline=false; }
  part h_processor_os:Fragment { attribute :>> file="_gambit/processor_os.h.in"; attribute :>> firstLine=11262; attribute :>> pastLine=11377; attribute :>> driverInline=false; }
  part h_memory_state:Fragment { attribute :>> file="_gambit/memory_state.h.in"; attribute :>> firstLine=11377; attribute :>> pastLine=11702; attribute :>> driverInline=false; }
  part h_runtime_forwards:Fragment { attribute :>> file="_gambit/runtime_forwards.h.in"; attribute :>> firstLine=11702; attribute :>> pastLine=11708; attribute :>> driverInline=false; }
  part h_synchronization:Fragment { attribute :>> file="_gambit/synchronization.h.in"; attribute :>> firstLine=11708; attribute :>> pastLine=11716; attribute :>> driverInline=false; }
  part h_processor_state:Fragment { attribute :>> file="_gambit/processor_state.h.in"; attribute :>> firstLine=11716; attribute :>> pastLine=11888; attribute :>> driverInline=false; }
  part h_label_types:Fragment { attribute :>> file="_gambit/label_types.h.in"; attribute :>> firstLine=11888; attribute :>> pastLine=11983; attribute :>> driverInline=false; }
  part h_module_state:Fragment { attribute :>> file="_gambit/module_state.h.in"; attribute :>> firstLine=11983; attribute :>> pastLine=12056; attribute :>> driverInline=false; }
  part h_write_authority:Fragment { attribute :>> file="_gambit/write_authority.h.in"; attribute :>> firstLine=12056; attribute :>> pastLine=12071; attribute :>> driverInline=false; }
  part h_vm_state:Fragment { attribute :>> file="_gambit/vm_state.h.in"; attribute :>> firstLine=12071; attribute :>> pastLine=12117; attribute :>> driverInline=false; }
  part h_setup_parameters:Fragment { attribute :>> file="_gambit/setup_parameters.h.in"; attribute :>> firstLine=12117; attribute :>> pastLine=12242; attribute :>> driverInline=false; }
  part h_global_state:Fragment { attribute :>> file="_gambit/global_state.h.in"; attribute :>> firstLine=12242; attribute :>> pastLine=13745; attribute :>> driverInline=false; }
  part h_runtime_protocols:Fragment { attribute :>> file="_gambit/runtime_protocols.h.in"; attribute :>> firstLine=13745; attribute :>> pastLine=15235; attribute :>> driverInline=false; }
  part h_declarations_end:Fragment { attribute :>> file="_gambit/declarations_end.h.in"; attribute :>> firstLine=15235; attribute :>> pastLine=15237; attribute :>> driverInline=true; }
  part h_header_end:Fragment { attribute :>> file="_gambit/header_end.h.in"; attribute :>> firstLine=15237; attribute :>> pastLine=15241; attribute :>> driverInline=true; }
}
