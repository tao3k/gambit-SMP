"""Lean source checks; separate from Quint transition/checker semantics."""
from pathlib import Path
import json
import re


def observation_command(arguments, context):
    from gambit_smp.research_flow import EvidenceUnavailable
    if not isinstance(arguments,list) or not arguments or not all(isinstance(arg,str) for arg in arguments):
        raise ValueError('explicit Lean source request required')
    source=Path(arguments[-1]);source=source if source.is_absolute() else context.root/source
    if source.suffix!='.lean' or source.is_symlink() or not source.is_file():
        raise EvidenceUnavailable('Lean source is unavailable')
    resolved=source.resolve()
    if not resolved.is_relative_to(context.root) or (resolved.is_relative_to(context.root/'.cache') and not resolved.is_relative_to(context.directory)):
        raise ValueError('Lean source must be maintained or owned generated input')
    options=arguments[:-1]
    if options:
        if len(options)==4 and options[0]=='-R' and options[2]=='-o':
            package=Path(options[1]).resolve()
            if (package!=(context.directory/'work').resolve() or not resolved.is_relative_to(package)
                    or not Path(options[3]).resolve().is_relative_to(package) or not options[3].endswith('.olean')):
                raise ValueError('Lean package/output must be owned by this step')
        elif len(options)!=2 or options[0]!='-o' or not options[1].endswith('.olean'):
            raise ValueError('unsupported Lean request option')
    if not context.tools.get('lean'):
        raise EvidenceUnavailable('sealed Lean provider unavailable')
    context.bind([resolved])
    return [context.tools['lean'],*arguments]


def capabilities(Capability):
    def validate(args,inputs):
        from gambit_smp.recipes import fields
        fields(args,('argv',),('modules',))
        if (not isinstance(args['argv'],list) or not args['argv']
                or not all(isinstance(value,str) for value in args['argv']) or args['argv'][-1] not in inputs):
            raise ValueError('explicit Lean source request required')
        modules=args.get('modules',[])
        if not isinstance(modules,list) or len(modules)>128:raise ValueError('bounded declared Lean module closure required')
        if modules and len(args['argv'])!=1:raise ValueError('module closure owns Lean package and output options')
        names=set()
        for module in modules:
            if (not isinstance(module,dict) or set(module) not in ({'name','source'},{'name','identity'})
                    or not isinstance(module['name'],str)
                    or not re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*',module['name'])
                    or module['name'].casefold() in names):raise ValueError('unique named Lean source module required')
            names.add(module['name'].casefold())
            if 'source' in module and (module['source'] not in inputs or not module['source'].endswith('.lean')):
                raise ValueError('declared maintained Lean dependency required')
            if 'identity' in module and (not isinstance(module['identity'],dict) or module['identity'].get('kind')!='git'):
                raise ValueError('immutable Git Lean source dependency required')
    def check(args,context):
        observation_command(args['argv'],context)
        # An ambient .lake/LEAN_PATH must not satisfy undeclared proof imports.
        imports=context.directory/'work'
        imports.mkdir(exist_ok=True)
        policy=dict(cap=60,stream='stdout',failure='runtime',failParameter=False,expectedParameter=False)
        env={**context.env,'LEAN_PATH':str(imports)};dependencies=[]
        from gambit_smp.source_identity import read_git_sources
        from gambit_smp.recipes import source_path
        from gambit_smp.framework import digest
        modules=args.get('modules',[])
        git_data=iter(read_git_sources(context.root,[module['identity'] for module in modules if 'identity' in module]))
        for module in modules:
            if 'identity' in module:
                data=next(git_data)
                if data is None:raise FileNotFoundError('declared Lean Git source unavailable: '+module['name'])
            else:
                source=source_path(context.root,module['source']);context.bind([source]);data=source.read_bytes()
            target=imports/(module['name'].replace('.','/')+'.lean')
            target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
            context.command('lean-'+module['name'],['lean','-R',str(imports),'-o',str(target.with_suffix('.olean')),str(target)],policy=policy,env=env)
            dependencies.append(dict(module,sourceSha256=digest(target)))
        original=source_path(context.root,args['argv'][-1])
        argv=list(args['argv'])
        if modules:
            target=imports/original.name
            if target.exists():raise ValueError('Lean target collides with a dependency')
            target.write_bytes(original.read_bytes())
            argv=['-R',str(imports),'-o',str(target.with_suffix('.olean')),str(target)]
        text=context.command('lean',['lean',*argv],policy=policy,env=env)
        result=dict(compilerCompleted=True,stdout=text,source=args['argv'][-1],sourceSha256=digest(original),
                    dependencies=dependencies,ambientImportsUsed=False,sourceRefinementAdmitted=False,runtimeAdmitted=False)
        path=context.directory/'observation.json';path.write_text(json.dumps(result,indent=2)+'\n')
        return dict(result,outputs=context.publish('observation','lean-check-observation',path))
    return {'lean.check':Capability(validate,executor=check,
                                  outputs=(('observation','lean-check-observation'),))}
