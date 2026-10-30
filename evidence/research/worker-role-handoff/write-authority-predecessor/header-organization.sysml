package GambitHeaderOrganization {
  private import ScalarValues::*;
  attribute source:String="vendor/gambit/include/gambit.h.in";
  attribute baselineSha256:String="20ffe2450d70022fc14cf31088744b9321694d308f79ada21d298a544ca63070";
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
  part h_gvm_operations:Fragment { attribute :>> file="_gambit/gvm_operations.h.in"; attribute :>> firstLine=3887; attribute :>> pastLine=6741; attribute :>> driverInline=false; }
  part h_stack_operations:Fragment { attribute :>> file="_gambit/stack_operations.h.in"; attribute :>> firstLine=6741; attribute :>> pastLine=6998; attribute :>> driverInline=false; }
  part h_gvm_registers:Fragment { attribute :>> file="_gambit/gvm_registers.h.in"; attribute :>> firstLine=6998; attribute :>> pastLine=8062; attribute :>> driverInline=false; }
  part h_temporary_roots:Fragment { attribute :>> file="_gambit/temporary_roots.h.in"; attribute :>> firstLine=8062; attribute :>> pastLine=8093; attribute :>> driverInline=false; }
  part h_labels:Fragment { attribute :>> file="_gambit/labels.h.in"; attribute :>> firstLine=8093; attribute :>> pastLine=8171; attribute :>> driverInline=false; }
  part h_module_generation:Fragment { attribute :>> file="_gambit/module_generation.h.in"; attribute :>> firstLine=8171; attribute :>> pastLine=9708; attribute :>> driverInline=false; }
  part h_foreign_abi:Fragment { attribute :>> file="_gambit/foreign_abi.h.in"; attribute :>> firstLine=9708; attribute :>> pastLine=9967; attribute :>> driverInline=false; }
  part h_foreign_conversion:Fragment { attribute :>> file="_gambit/foreign_conversion.h.in"; attribute :>> firstLine=9967; attribute :>> pastLine=10778; attribute :>> driverInline=false; }
  part h_declarations_begin:Fragment { attribute :>> file="_gambit/declarations_begin.h.in"; attribute :>> firstLine=10778; attribute :>> pastLine=10782; attribute :>> driverInline=true; }
  part h_native_platform:Fragment { attribute :>> file="_gambit/native_platform.h.in"; attribute :>> firstLine=10782; attribute :>> pastLine=11000; attribute :>> driverInline=false; }
  part h_native_types:Fragment { attribute :>> file="_gambit/native_types.h.in"; attribute :>> firstLine=11000; attribute :>> pastLine=11018; attribute :>> driverInline=false; }
  part h_activity_log:Fragment { attribute :>> file="_gambit/activity_log.h.in"; attribute :>> firstLine=11018; attribute :>> pastLine=11333; attribute :>> driverInline=false; }
  part h_processor_os:Fragment { attribute :>> file="_gambit/processor_os.h.in"; attribute :>> firstLine=11333; attribute :>> pastLine=11448; attribute :>> driverInline=false; }
  part h_memory_state:Fragment { attribute :>> file="_gambit/memory_state.h.in"; attribute :>> firstLine=11448; attribute :>> pastLine=11736; attribute :>> driverInline=false; }
  part h_runtime_forwards:Fragment { attribute :>> file="_gambit/runtime_forwards.h.in"; attribute :>> firstLine=11736; attribute :>> pastLine=11742; attribute :>> driverInline=false; }
  part h_synchronization:Fragment { attribute :>> file="_gambit/synchronization.h.in"; attribute :>> firstLine=11742; attribute :>> pastLine=11770; attribute :>> driverInline=false; }
  part h_runtime_roles:Fragment { attribute :>> file="_gambit/runtime_roles.h.in"; attribute :>> firstLine=11770; attribute :>> pastLine=11936; attribute :>> driverInline=false; }
  part h_processor_state:Fragment { attribute :>> file="_gambit/processor_state.h.in"; attribute :>> firstLine=11936; attribute :>> pastLine=12085; attribute :>> driverInline=false; }
  part h_label_types:Fragment { attribute :>> file="_gambit/label_types.h.in"; attribute :>> firstLine=12085; attribute :>> pastLine=12180; attribute :>> driverInline=false; }
  part h_module_state:Fragment { attribute :>> file="_gambit/module_state.h.in"; attribute :>> firstLine=12180; attribute :>> pastLine=12253; attribute :>> driverInline=false; }
  part h_native_activation:Fragment { attribute :>> file="_gambit/native_activation.h.in"; attribute :>> firstLine=12253; attribute :>> pastLine=12268; attribute :>> driverInline=false; }
  part h_vm_state:Fragment { attribute :>> file="_gambit/vm_state.h.in"; attribute :>> firstLine=12268; attribute :>> pastLine=12534; attribute :>> driverInline=false; }
  part h_setup_parameters:Fragment { attribute :>> file="_gambit/setup_parameters.h.in"; attribute :>> firstLine=12534; attribute :>> pastLine=12659; attribute :>> driverInline=false; }
  part h_global_state:Fragment { attribute :>> file="_gambit/global_state.h.in"; attribute :>> firstLine=12659; attribute :>> pastLine=14167; attribute :>> driverInline=false; }
  part h_runtime_protocols:Fragment { attribute :>> file="_gambit/runtime_protocols.h.in"; attribute :>> firstLine=14167; attribute :>> pastLine=15662; attribute :>> driverInline=false; }
  part h_declarations_end:Fragment { attribute :>> file="_gambit/declarations_end.h.in"; attribute :>> firstLine=15662; attribute :>> pastLine=15664; attribute :>> driverInline=true; }
  part h_header_end:Fragment { attribute :>> file="_gambit/header_end.h.in"; attribute :>> firstLine=15664; attribute :>> pastLine=15668; attribute :>> driverInline=true; }
}
