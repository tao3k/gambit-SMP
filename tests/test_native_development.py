"""Stage admission controls; these do not qualify native code or GC."""
import copy
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from gambit_smp.native_development import validate, current_scheme_matches, generated_inventory, execute, invalidate_native_outputs, generation_recipe_projection, native_parameter_projection, configuration_request, copy_changed
from gambit_smp.native_development import native_relocations, apply_native_delta, relocated_native_line
from gambit_smp.native_development import configure_replay_projection
from gambit_smp.native_development import native_object_context


class NativeDevelopmentTests(unittest.TestCase):
    def object_context_fixture(self, root):
        for name in ('makefile','lib/makefile','gsi/makefile','gsc/makefile'):
            p=root/name;p.parent.mkdir(parents=True,exist_ok=True)
            p.write_text('C_COMPILER = cc\nFLAGS_OBJ = -O1\nNORMAL_C = first.c\nNORMAL_O = first.o\n')
        (root/'include').mkdir();(root/'include/gambit.h').write_text('ABI');(root/'include/config.h').write_text('features')
        return {'tools':{'gcc':'compiler-A'},'environment':{'CFLAGS':'-std=c23'}}

    def test_same_completed_object_context_is_not_invalidated_by_a_repeated_move_request(self):
        with tempfile.TemporaryDirectory() as temp:
            source=Path(temp);request=self.object_context_fixture(source)
            first=native_object_context(source,request)
            self.assertEqual(first,native_object_context(source,request))
            (source/'lib/first.c').write_text('a body edit belongs to Make target invalidation')
            self.assertEqual(first,native_object_context(source,request))

    def test_public_header_or_feature_header_change_invalidates_built_object_context(self):
        for name in ('include/gambit.h','include/config.h'):
            with self.subTest(name=name),tempfile.TemporaryDirectory() as temp:
                source=Path(temp);request=self.object_context_fixture(source);first=native_object_context(source,request)
                (source/name).write_text('different ABI/features')
                self.assertNotEqual(first,native_object_context(source,request))

    def test_configure_command_expansion_is_a_native_object_input(self):
        with tempfile.TemporaryDirectory() as temp:
            source=Path(temp);request=self.object_context_fixture(source)
            p=source/'lib/makefile'
            p.write_text(p.read_text()+"CONFIGURE_COMMAND = ./configure '--enable-smp'\n")
            before=native_object_context(source,request)
            p.write_text(p.read_text().replace('--enable-smp','--enable-smp --cache-file=another'))
            self.assertNotEqual(before,native_object_context(source,request))

    def test_compiler_environment_and_native_flags_change_the_completed_object_context(self):
        with tempfile.TemporaryDirectory() as temp:
            source=Path(temp);request=self.object_context_fixture(source);first=native_object_context(source,request)
            for key in ('tools','environment'):
                changed=copy.deepcopy(request);changed[key]['changed']='new identity'
                self.assertNotEqual(first,native_object_context(source,changed))
            p=source/'lib/makefile';p.write_text(p.read_text().replace('-O1','-O2'))
            self.assertNotEqual(first,native_object_context(source,request))

    def test_archive_membership_is_part_of_context_even_when_compiler_flags_are_unchanged(self):
        with tempfile.TemporaryDirectory() as temp:
            source=Path(temp);request=self.object_context_fixture(source);first=native_object_context(source,request)
            p=source/'lib/makefile';p.write_text(p.read_text().replace('first.c','second.c').replace('first.o','second.o'))
            self.assertNotEqual(first,native_object_context(source,request))

    def test_only_owned_configure_cache_argument_leaves_generation_replay_metadata(self):
        with tempfile.TemporaryDirectory() as temp:
            source=Path(temp)/'source';cache=source.parent.resolve()/('configure-cache-'+'1'*64)
            original="CONFIGURE_COMMAND = ./configure '--enable-smp' 'CFLAGS=-std=c23'\n"
            cached=original.replace(" 'CFLAGS=",f" '--cache-file={cache}' 'CFLAGS=")
            self.assertEqual(configure_replay_projection(cached,source),original)
            changed=cached.replace('--enable-smp','--disable-smp')
            self.assertNotEqual(configure_replay_projection(changed,source),original)

    def test_external_duplicate_or_untyped_cache_options_remain_significant(self):
        source=Path('/owned/source');base="CONFIGURE_COMMAND = ./configure '--enable-smp'"
        for argument in (" '--cache-file=/outside/cache'", " --cache-file=/owned/configure-cache-"+'1'*64,
                         " '--cache-file=/owned/configure-cache-not-a-key'",
                         (" '--cache-file=/owned/configure-cache-"+'1'*64+"'")*2):
            line=base+argument+'\n'
            with self.subTest(argument=argument):self.assertEqual(configure_replay_projection(line,source),line)

    def test_cache_path_in_a_scheme_recipe_is_never_normalized(self):
        line="\t../gsc-boot -e \"--cache-file=/owned/configure-cache-"+'1'*64+"\"\n"
        self.assertEqual(configure_replay_projection(line,Path('/owned/source')),line)

    def relocation_fixture(self, root):
        from gambit_smp.framework import digest
        from types import SimpleNamespace
        old=root/'source/lib/before.c';old.parent.mkdir(parents=True);old.write_text('old authority')
        new=root/'vendor/gambit/lib/after.c';new.parent.mkdir(parents=True);new.write_text('new authority')
        delta={'files':{'lib/after.c':{'candidateSha256':digest(new)}},
               'relocations':{'lib/before.c':{'target':'lib/after.c','sourceSha256':digest(old)}}}
        return SimpleNamespace(root=root,bind=lambda p:None),root/'source',delta

    def test_source_relocation_removes_old_name_and_resumes_without_second_move(self):
        with tempfile.TemporaryDirectory() as temp:
            ctx,source,delta=self.relocation_fixture(Path(temp))
            first=apply_native_delta(ctx,source,delta)
            self.assertIsNone(first['lib/before.c']['after'])
            self.assertFalse((source/'lib/before.c').exists())
            self.assertEqual((source/'lib/after.c').read_text(),'new authority')
            self.assertNotIn('lib/before.c',apply_native_delta(ctx,source,delta))

    def test_bad_predecessor_or_parallel_target_changes_no_source(self):
        for parallel in (False,True):
            with self.subTest(parallel=parallel),tempfile.TemporaryDirectory() as temp:
                ctx,source,delta=self.relocation_fixture(Path(temp))
                if parallel:(source/'lib/after.c').write_text('parallel')
                else:delta['relocations']['lib/before.c']['sourceSha256']='0'*64
                with self.assertRaisesRegex(ValueError,'predecessor differs|both names'):
                    apply_native_delta(ctx,source,delta)
                self.assertEqual((source/'lib/before.c').read_text(),'old authority')

    def test_new_unpaired_file_is_not_admitted_as_a_relocation(self):
        with tempfile.TemporaryDirectory() as temp:
            ctx,source,delta=self.relocation_fixture(Path(temp));delta.pop('relocations')
            with self.assertRaisesRegex(ValueError,'existing regular leaf'):
                apply_native_delta(ctx,source,delta)

    def test_relocation_rejects_generator_cross_kind_and_duplicate_target(self):
        with tempfile.TemporaryDirectory() as temp:
            _,_,delta=self.relocation_fixture(Path(temp))
            for old in ('lib/before.scm','lib/before.h'):
                wrong=copy.deepcopy(delta);wrong['relocations']={old:next(iter(delta['relocations'].values()))}
                with self.subTest(old=old),self.assertRaises(ValueError):native_relocations(wrong)
            delta['relocations']['lib/other.c']=delta['relocations']['lib/before.c'].copy()
            with self.assertRaisesRegex(ValueError,'unique'):native_relocations(delta)

    def test_only_literal_native_lists_and_rules_can_normalize_source_moves(self):
        moves={'lib/before.c':{'target':'lib/after.c'},'lib/before.h':{'target':'lib/after.h'}}
        for line in ('NORMAL_C = after.c main.c\n','NORMAL_O = +after.o,main.o\n',
                     'after.o: after.c after.h\n','setup.o: setup.c after.h\n'):
            with self.subTest(line=line):self.assertEqual(relocated_native_line(line,moves),line.replace('after','before'))
        for line in ('MODULES_C = after.c\n','PRELUDE_OPT = after.c\n',
                     '\t../gsc-boot -c after.c\n','NORMAL_C = $(shell after.c)\n',
                     'after.o: after.c; ../gsc-boot -c after.c\n'):
            with self.subTest(line=line):self.assertEqual(relocated_native_line(line,moves),line)

    def test_withdrawn_profile_is_only_ignored_in_known_root_distribution_and_configure_lines(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            text=('RCFILES = README \\\n'
                  'makefile.in configure configure.ac native-profile.m4 config.sub\n'
                  'configure: configure.ac native-profile.m4\n')
            for name in ('makefile','lib/makefile','gsi/makefile','gsc/makefile'):
                p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text if name=='makefile' else '')
            old=generation_recipe_projection(root)
            (root/'makefile').write_text(text.replace(' native-profile.m4',''))
            self.assertEqual(old,generation_recipe_projection(root))
            (root/'makefile').write_text(text+'MODULES = native-profile.m4\n')
            self.assertNotEqual(old,generation_recipe_projection(root))

    def test_configuration_identity_ignores_native_body_but_binds_profile_tools_and_templates(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);(root/'lib').mkdir()
            for name in ('configure.ac','acinclude.m4','lib/makefile.in','lib/mem.c','gcc'):
                (root/name).write_text(name)
            tools={'gcc':root/'gcc'}; profile={'flags':['--enable-smp'],'cflags':'-std=c23'}
            key=configuration_request(root,profile,tools,{'SDKROOT':'selected-sdk'})
            (root/'lib/mem.c').write_text('changed native body')
            self.assertEqual(key,configuration_request(root,profile,tools,{'SDKROOT':'selected-sdk'}))
            for name in ('configure.ac','lib/makefile.in','gcc'):
                (root/name).write_text('changed '+name)
                self.assertNotEqual(key,configuration_request(root,profile,tools,{'SDKROOT':'selected-sdk'}))
                (root/name).write_text(name)
            self.assertNotEqual(key,configuration_request(root,profile,tools,{'SDKROOT':'different-sdk'}))

    def test_unchanged_native_input_preserves_make_timestamp(self):
        with tempfile.TemporaryDirectory() as temp:
            origin,target=Path(temp)/'origin',Path(temp)/'target'
            origin.write_text('same');target.write_text('same')
            before=target.stat().st_mtime_ns
            self.assertFalse(copy_changed(origin,target))
            self.assertEqual(before,target.stat().st_mtime_ns)
            origin.write_text('real edit')
            self.assertTrue(copy_changed(origin,target))
            self.assertEqual('real edit',target.read_text())

    def test_missing_make_definition_and_explicit_empty_default_are_the_same_native_context(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            text='FLAGS_OBJ = -O1\n\t${C_COMPILER} ${FLAGS_OBJ} ${DEFS_OBJ} -c a.c\n'
            for name in ('makefile','lib/makefile','gsi/makefile','gsc/makefile'):
                p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
            native=native_parameter_projection(root);generation=generation_recipe_projection(root)
            path=root/'lib/makefile';path.write_text(text+'DEFS_OBJ ?= \n')
            self.assertEqual(native_parameter_projection(root),native)
            self.assertEqual(generation_recipe_projection(root),generation)
            path.write_text(text.replace('-O1','-O2'))
            self.assertNotEqual(native_parameter_projection(root),native)
            self.assertEqual(generation_recipe_projection(root),generation)
            path.write_text(text+'FLAGS_SCHEME = -new-query\n')
            self.assertNotEqual(generation_recipe_projection(root),generation)
            path.write_text(text.replace('-c a.c','-c a.c; ../gsc-boot -c a.scm'))
            self.assertNotEqual(generation_recipe_projection(root),generation)

    def test_native_flags_leave_generation_cut_but_preludes_and_module_edges_do_not(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            text=('FLAGS_OBJ = -O1\nPRELUDE_OPT = enable-smp\nMODULES_C = _map.c\n'
                  '\t${C_COMPILER} ${FLAGS_OBJ} -c map.c\n'
                  '\t../gsc-boot -c map.scm\n')
            for name in ('makefile','lib/makefile','gsi/makefile','gsc/makefile'):
                p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
            original=generation_recipe_projection(root)
            path=root/'lib/makefile';path.write_text(text.replace('-O1','-O2'))
            self.assertEqual(generation_recipe_projection(root),original)
            for old,new in (('enable-smp','disable-smp'),('_map.c','_map.c _new.c'),
                            ('gsc-boot -c','other-gsc -c')):
                path.write_text(text.replace(old,new))
                self.assertNotEqual(generation_recipe_projection(root),original)

    def test_recipe_change_invalidates_native_outputs_but_not_the_generation_product(self):
        with tempfile.TemporaryDirectory() as temp:
            source=Path(temp)
            native=('lib/mem.o','lib/libgambit.a','gsc/libgambitgsc.a')
            retained=('lib/_kernel.c','gsc/_link.c','gsc/_front.scm','gsc-boot','gsc/gsc','gsi/gsi')
            for name in native+retained:
                p=source/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(name)
            self.assertEqual(invalidate_native_outputs(source,[]),[])
            self.assertTrue(all((source/n).is_file() for n in native))
            self.assertEqual(invalidate_native_outputs(source,['lib/makefile']),sorted(native))
            self.assertTrue(all((source/n).read_text()==n for n in retained))

    def test_fragment_omission_and_mutation_cannot_reuse_a_runtime(self):
        from types import SimpleNamespace
        from gambit_smp.native_capabilities import identity
        from gambit_smp.suite_primitives import check_runtime
        import json
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);source=root/'source';out=root/'proof';out.mkdir()
            names=('lib/_setup/vm-registry.inc','lib/_mem/root-origins.inc',
                   'gsi/gsi','gsc/gsc','lib/libgambit.a')
            for name in names:
                p=source/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(name)
            ctx=SimpleNamespace(directory=out,publish=lambda *args: {})
            identity(ctx,source)
            proof=json.loads((out/'identity.json').read_text())
            check_runtime(source,proof)
            omitted=copy.deepcopy(proof)
            omitted['sourceFiles'].pop(names[0])
            with self.assertRaisesRegex(ValueError,'omits native source fragments'):
                check_runtime(source,omitted)
            (source/names[0]).write_text('changed registry ownership')
            with self.assertRaises(ValueError):
                check_runtime(source,proof)

    def test_generation_product_is_declared_and_cannot_use_an_identity_as_generated_code(self):
        from gambit_smp.generation_artifacts import validate as generation_validate
        from gambit_smp.native_capabilities import graph
        from gambit_smp.recipes import CAPABILITIES
        generation_validate({'sourceLock':'source.lock.json','producer':'producer.json'},
                            ['source.lock.json','producer.json'])
        with self.assertRaises(ValueError):
            generation_validate({'sourceLock':'source.lock.json','producer':'undeclared.json'},
                                ['source.lock.json','producer.json'])
        producer={'id':'producer','capability':'gambit.generation-artifact'}
        native={'id':'native','capability':'gambit.native-development',
                'arguments':self.args,'dependsOn':['producer']}
        graph(native, {'producer':producer}, CAPABILITIES)
        broken=copy.deepcopy(native);broken['arguments']['generation']['output']='identity'
        with self.assertRaisesRegex(ValueError,'artifact reference type mismatch'):
            graph(broken, {'producer':producer}, CAPABILITIES)

    def test_selected_configuration_tools_are_available_to_the_native_stage(self):
        from gambit_smp.native_capabilities import host_tools
        with tempfile.TemporaryDirectory() as temp:
            directory=Path(temp)
            for name in ('gcc','as','ld','git','make','sh','tar','aclocal','autoconf','m4'):
                p=directory/name;p.write_text('fixture only; never executed');p.chmod(0o700)
            with patch('gambit_smp.native_capabilities.sys.platform','linux'):
                tools,_=host_tools(directory/'gcc', [{'capability':'gambit.native-development'}],
                                  {'PATH':str(directory)})
            self.assertTrue({'aclocal','autoconf','m4'} <= tools.keys())

    def test_autoconf_consumes_explicit_m4_instead_of_system_path_precedence(self):
        from gambit_smp.native_capabilities import host_tools
        with tempfile.TemporaryDirectory() as temp:
            directory=Path(temp)
            for name in ('gcc','as','ld','git','make','sh','tar','aclocal','autoconf','m4','chosen-m4'):
                p=directory/name;p.write_text('fixture only; never executed');p.chmod(0o700)
            with patch('gambit_smp.native_capabilities.sys.platform','linux'):
                tools,env=host_tools(directory/'gcc',[{'capability':'gambit.native-development'}],
                                    {'PATH':str(directory),'M4':str(directory/'chosen-m4')})
            self.assertEqual((directory/'chosen-m4').resolve(),tools['m4'])
            self.assertEqual(str(tools['m4']),env['M4'])

    def test_m4_from_caller_path_is_passed_to_autoconf(self):
        from gambit_smp.native_capabilities import host_tools
        with tempfile.TemporaryDirectory() as temp:
            directory=Path(temp)
            for name in ('gcc','as','ld','git','make','sh','tar','aclocal','autoconf','m4'):
                p=directory/name;p.write_text('fixture only; never executed');p.chmod(0o700)
            with patch('gambit_smp.native_capabilities.sys.platform','linux'):
                tools,env=host_tools(directory/'gcc',[{'capability':'gambit.native-development'}],
                                    {'PATH':str(directory)})
            self.assertEqual((directory/'m4').resolve(),tools['m4'])
            self.assertEqual(str(tools['m4']),env['M4'])

    def test_darwin_does_not_select_autoconf_m4_through_xcrun(self):
        from gambit_smp.native_capabilities import host_tools
        with tempfile.TemporaryDirectory() as temp:
            directory=Path(temp)
            for name in ('gcc','as','ld','git','make','sh','tar','aclocal','autoconf','m4'):
                p=directory/name;p.write_text('fixture only; never executed');p.chmod(0o700)
            def developer(argv,*args,**kwargs):
                self.assertNotEqual('m4',argv[-1])
                return 0,str(directory/argv[-1])+'\n',False,0
            with patch('gambit_smp.native_capabilities.sys.platform','darwin'), \
                 patch('gambit_smp.framework.execute',side_effect=developer):
                tools,env=host_tools(directory/'gcc',[{'capability':'gambit.configure'}],
                                    {'PATH':str(directory)})
            self.assertEqual((directory/'m4').resolve(),tools['m4'])
            self.assertEqual(str(tools['m4']),env['M4'])

    def test_executor_assembles_real_dependencies_before_rejecting_an_unknown_artifact(self):
        from types import SimpleNamespace
        def unavailable(*args):
            raise ValueError('unknown producer artifact')
        with self.assertRaisesRegex(ValueError, 'unknown producer artifact'):
            execute(self.args, SimpleNamespace(artifact=unavailable))

    def setUp(self):
        self.args = dict(runtime=dict(step='producer', output='runtime'),
                         identity=dict(step='producer', output='identity'),
                         generation=dict(step='producer', output='generation'),
                         nativeDelta='delta.lock.json',
                         buildProfile='profile.json', policy='vendor/gambit/configure.ac',
                         nativeChanges=['lib/_mem/configuration.inc'],
                         templates=['vendor/gambit/makefile.in']+['vendor/gambit/'+p+'/makefile.in' for p in ('lib','gsi','gsc')],
                         generationDemand='reuse-explicit-artifact')
        self.inputs = [self.args[n] for n in ('buildProfile', 'policy', 'nativeDelta')]
        self.inputs += self.args['templates']

    def test_runtime_leaf_is_distinct_from_generation_or_generated_inputs(self):
        validate(self.args, self.inputs)
        for bad in ('gsc/_t-c-1.scm', 'lib/_kernel.c',
                    'lib/_mem/../_kernel.c', 'lib/gambit.h'):
            row = copy.deepcopy(self.args); row['nativeChanges'] = [bad]
            with self.subTest(path=bad), self.assertRaises(ValueError):
                validate(row, self.inputs + [bad])
        for demand in ('automatic-cache-hit', '', None):
            row = dict(self.args, generationDemand=demand)
            with self.assertRaises(ValueError):
                validate(row, self.inputs)

    def test_internal_header_demand_does_not_admit_generated_or_generator_sources(self):
        from gambit_smp.native_development import native_source_kind
        for name in ('include/_gambit/runtime_roles.h.in','include/_gambit/vm_state.h.in'):
            self.assertEqual(native_source_kind(name),'native-header-template')
            validate(dict(self.args,nativeChanges=[name]),self.inputs)
        for name in ('include/gambit.h','include/gambit.h.in','include/config.h.in',
                     'include/_gambit/../vm_state.h.in','include//_gambit/vm_state.h.in',
                     '/include/_gambit/vm_state.h.in','gsc/_t-c-1.scm'):
            with self.subTest(path=name), self.assertRaises(ValueError):
                native_source_kind(name)

    def test_header_output_requires_complete_native_recompilation_and_declared_template(self):
        from gambit_smp.native_development import native_header_invalidation
        changes=['include/_gambit/runtime_roles.h.in']
        self.assertTrue(native_header_invalidation(['include/gambit.h'],changes))
        self.assertFalse(native_header_invalidation([],changes))
        for outputs,delta in ((['include/config.h'],changes),
                              (['include/gambit.h'],['lib/mem.c']),
                              (['include/gambit.h','include/config.h'],changes)):
            with self.subTest(outputs=outputs,delta=delta), self.assertRaises(ValueError):
                native_header_invalidation(outputs,delta)

    def test_scheme_mutation_and_new_module_cannot_hide_behind_native_demand(self):
        with tempfile.TemporaryDirectory() as temp:
            old, current = Path(temp)/'old', Path(temp)/'current'
            for root in (old, current):
                for part in ('lib', 'gsi', 'gsc'):
                    (root/part).mkdir(parents=True)
                (root/'gsc/compiler.scm').write_text('(define x 1)')
                (root/'lib/runtime.c').write_text('native')
                (root/'lib/_link.c').write_text('generated linker metadata')
            current_scheme_matches(old, current)
            (current/'lib/runtime.c').write_text('refined native C')
            current_scheme_matches(old, current)
            (current/'gsc/compiler.scm').write_text('(define x 2)')
            with self.assertRaisesRegex(ValueError, 'generation demand'):
                current_scheme_matches(old, current)
            (current/'gsc/compiler.scm').write_text('(define x 1)')
            (current/'gsc/new-macro.scm').write_text('(define macro 2)')
            with self.assertRaisesRegex(ValueError, 'generation demand'):
                current_scheme_matches(old, current)
            inventory=generated_inventory(old)
            self.assertEqual(set(inventory), {'lib/_link.c'})
