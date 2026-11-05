from pathlib import Path
import json
r=Path.cwd();t=r/'.cache/tasks/build-cut-snapshot-refinement'
for name in ['ascent-submit.scm','ascent-submit.stderr.txt','ascent-read.scm','ascent-read.stderr.txt','ascent-read.request.scm']:
 p=t/name
 if p.exists():p.rename(t/('prior-source-attribution-'+name))
(t/'source-attribution-correction.json').write_text(json.dumps({'status':'corrected-before-final-receipt','earlierAttribution':'_source.scm 1559 include path treated as current behavior','sourceCorrection':'1386 starts a quoted historical datum; active include is 457-466, read-source is 419-455, and top-level _front.scm 218 passes true while include passes false','effect':'Extension-priority counterexample belongs to top-level source lookup; no current include probe/reopen or extension claim','historicalAscentSubmission':'retained as unqualified design hypothesis; new exact-bundle hypotheses required','runtimeOrNativeClaimPromoted':False},indent=2)+'\n')
p=r/'dev/architecture/toolchain/models/sysml/architecture.sysml';s=p.read_text().replace('sourceRanges = "1559-1638"','sourceRanges = "419-466"').replace('sourceRanges = "1569-1614"','sourceRanges = "419-466"').replace('a previously absent higher-priority extension appears, changing include resolution','a previously absent higher-priority extension appears, changing top-level source resolution')
facts=[('active-read-source','vendor/gambit/gsc/_source.scm','419-466','Active read-source uses the current readtable and optional extension search; active include passes false','Quoted tail at 1386-1642 is historical data, not this call path'),('top-source-reader','vendor/gambit/gsc/_front.scm','200-223','compile-source input path calls read-source with true for extension search','In-memory source input bypasses file reading; not every generation performs an extension search'),('quoted-reader-history','vendor/gambit/gsc/_source.scm','1384-1396;1553-1563','Quoted datum starts at 1386 and contains the later same-name include definition','Do not infer active probe/reopen behavior from this historical copy'),('extension-order','vendor/gambit/lib/_io.scm','10506-10513','Current runtime extension list orders .sld before .scm before .six and has a setter','The host fallback table differs; actual active producer context must be bound'),('reader-path-primitive','vendor/gambit/lib/_eval.scm','1145-1194','Current reader builds path settings with EOL encoding and invokes generic file open via psettings','Path/open error details and primitive read authority require their own mediation; no snapshot isolation proved')]
extra=''
for i,(ident,path,extent,obs,limit) in enumerate(facts,9):
 extra+='    part chainFact'+str(i)+' : SourceChainFact {\n'
 for k,v in zip(['factId','sourcePath','sourceRanges','observation','limit'],[ident,path,extent,obs,limit]):extra+='        attribute :>> '+k+' = '+json.dumps(v)+';\n'
 extra+='    }\n'
s=s.rstrip();p.write_text(s[:-1]+extra+'}\n')
p=r/'dev/modeling/models/sysml/assurance.sysml';s=p.read_text().replace('Stable whole-action snapshot, complete expected outputs, file visibility/durability and failed exec ownership','B-SNAPSHOT and B-GROUP: coherent source image plus validated output catalogue, revocation/commit linearization, complete groups, reader lifetime and failure custody');p.write_text(s)
p=r/'dev/architecture/toolchain/correctness-design.org';s=p.read_text();start=s.index('[[file:../../../vendor/gambit/gsc/_source.scm::1559]');end=s.index('\n[[file:../../../vendor/gambit/gsc/_ptree1.scm::1534]',start)
s=s[:start]+'''[[file:../../../vendor/gambit/gsc/_source.scm::419][The active read-source]] reads through the runtime path reader and current
readtable. Its optional extension search retries when the result is a fixnum;
its fallback resolves a path relative to the source context. The active
[[file:../../../vendor/gambit/gsc/_source.scm::457][include-expr->source]] passes #f for extension search, whereas the
[[file:../../../vendor/gambit/gsc/_front.scm::218][top-level compile-source reader]] passes #t for a path input. In-memory source
input follows another branch. Therefore extension-order observations belong to
the enabled top-level path, not all ordinary include calls. The runtime
[[file:../../../vendor/gambit/lib/_io.scm::10506][extension list]] orders .sld, .scm, .six and has a setter; the host fallback
list differs. Bind the actual compiler context and preserve resolution/error
answers, content, reader settings and relative path identity.

[[file:../../../vendor/gambit/lib/_eval.scm::1145][The runtime reader]] constructs path settings including EOL encoding and
reaches generic file opening. This does not establish immutable input reads.
The same-name include definition at line 1559 belongs to the quoted historical
datum beginning at [[file:../../../vendor/gambit/gsc/_source.scm::1386][line 1386]]. Its probe/close/reopen sequence is not an active
caller in this source path. The earlier unqualified attribution and generated
hypotheses are retained in the task evidence and corrected here; no native
failure is inferred from that historical copy.
''' + s[end:]
s=s.replace('record only selected foo.scm while\nan earlier-priority foo.sld appears','record only selected foo.scm for a top-level extensionless input while\nan earlier-priority foo.sld appears')
s=s.replace('Record only selected foo.scm','Record only selected foo.scm')
s=s.replace('End-of-run equal hashes','End-of-run equal hashes')
p.write_text(s)
p=r/'dev/research/validation.org';s=p.read_text().replace('Their ASCENT factors are hypotheses tied to the exact source/receipt bundle;','A source-attribution correction separates active read-source/include callers\nfrom the quoted legacy definition; the earlier hypothesis bundle stays\nunqualified and retained. Their current ASCENT factors are hypotheses tied to\nthe exact source/receipt bundle;');p.write_text(s)
print('Corrected active/quoted source distinction; retained earlier hypothesis evidence')
