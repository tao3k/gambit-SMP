require 'json';require 'digest';require 'fileutils';require 'open3'
b='.cache/tasks/modern-c-frame-contract/cohort/control-references'
e='evidence/research/continuation-segments';raise 'fresh lock required' if File.exist?(e+'/source.lock.json')
FileUtils.mkdir_p(e+'/sources');sha=->p { Digest::SHA256.file(p).hexdigest }
sources={
 'gambit'=>['vendor/gambit',%w[lib/_kernel.scm lib/_thread.scm lib/mem.c lib/c_intf.c lib/setup.c include/gambit.h.in gsc/_t-c-1.scm gsc/_t-c-2.scm gsc/_t-c-3.scm tests/frame-continuation-roots.scm]],
 'chez'=>['vendor/chez',%w[c/schsig.c c/alloc.c s/mkgc.ss s/4.ss csug/control.stex csug/csug.bib]],
 'guile'=>[b+'/guile',%w[libguile/vm.c libguile/vm.h libguile/control.c libguile/continuations.c libguile/continuations.h libguile/dynstack.c libguile/dynstack.h module/ice-9/control.scm .tarball-version COPYING COPYING.LESSER]]
}
files={}
sources.each do |project,(root,paths)|
 paths.each do |p|
  src=root+'/'+p;name=project+'__'+p.gsub('/','__');dst=e+'/sources/'+name
  before=sha.call(src);FileUtils.cp(src,dst);raise 'source changed' unless sha.call(src)==before&&sha.call(dst)==before
  files[project+'/'+p]={source:src,path:dst,sha256:before}
 end
end
papers=JSON.parse(File.read(b+'/papers.json'))
copy=b+'/chez-control-copy.pdf'
if File.file?(copy) && File.binread(copy,5)=='%PDF-'
 o,err,status=Open3.capture3('pdftotext','-layout',copy,b+'/chez-control-copy.txt')
 File.write(b+'/chez-control-copy.extract.log',o+err);raise 'paper extraction' unless status.success?
 papers<<{id:'chez-control-copy',url:'https://www.cs.tufts.edu/comp/150VM/modules/archive/kent-dybvig/one-shot-continuations.pdf',pdf:true,sha256:sha.call(copy),textExtracted:true,textSha256:sha.call(b+'/chez-control-copy.txt')}
end
%w[delimited-control handling-control].each do |id|
 row=papers.find { |x| x['id']==id };raise 'missing original paper '+id unless row && row['pdf']
 raise 'paper drift' unless sha.call(b+'/'+id+'.pdf')==row['sha256']
end
git=lambda do |dir,*args|
 o,err,status=Open3.capture3('git','-C',dir,*args);raise err unless status.success?;o.strip
end
lock={scope:'Pinned research source excerpts and original papers; no third-party build or native acceptance',
 projects:{gambit:{head:git.call('vendor/gambit','rev-parse','HEAD'),branch:git.call('vendor/gambit','branch','--show-current'),
   candidateLock:'evidence/research/modern-c-bootstrap/request-custody-source.lock.json',candidateLockSha256:sha.call('evidence/research/modern-c-bootstrap/request-custody-source.lock.json')},
   chez:{head:git.call('vendor/chez','rev-parse','HEAD')},
   guile:{release:File.read(b+'/guile/.tarball-version').strip,url:'https://ftp.gnu.org/gnu/guile/guile-3.0.11.tar.xz',
     retrievedFrom:'https://mirrors.kernel.org/gnu/guile/guile-3.0.11.tar.xz',archiveSha256:sha.call(b+'/guile-source.tar.xz'),archive:b+'/guile-source.tar.xz'}},
 files:files,papers:papers,sourceRetrievalHistory:['Official GNU FTP host TLS connection failed; same release obtained from GNU mirror',
   'Legacy Chez author host TLS failed; university copy is a separate recorded retrieval'],runtimeAdmitted:false,commitAdmitted:false}
File.write(e+'/source.lock.json',JSON.pretty_generate(lock)+"\n")
puts JSON.generate(sourceFiles:files.size,originalPapers:papers.count { |p| p[:pdf] || p['pdf'] },guile:lock[:projects][:guile][:release])
