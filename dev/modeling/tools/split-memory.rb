require 'json'; require 'digest'; require 'fileutils'
model=ARGV.fetch(0); out=ARGV.fetch(1); root=ARGV.fetch(2,'vendor/gambit')
raise 'fresh receipt directory required' if File.exist?(out)
m=JSON.parse(File.read(model)); path=m.fetch('source').sub(/\Avendor\/gambit\//,root+'/'); source=File.binread(path)
sha=->s { Digest::SHA256.hexdigest(s) }
raise 'baseline differs from native model' unless sha.call(source)==m.fetch('baselineSha256')
raise 'reserved macro collision' if source.include?('___MEM_SOURCE_FILE')
fragments=m.fetch('fragments'); starts=fragments.map { |f| f.fetch('firstLine') }
raise 'noncontiguous plan' unless starts==starts.sort.uniq && starts.first==m.fetch('preambleLines')+1
lines=source.lines; FileUtils.mkdir_p(out); File.binwrite(out+'/mem-before.c',source)
driver=lines.take(m['preambleLines']).join
driver<<"/* Internal source organization; inclusion order is part of the contract.\n * Preserve original logical diagnostic coordinates across fragments. */\n"
driver<<"#if defined(__BASE_FILE__)\n#define ___MEM_SOURCE_FILE __BASE_FILE__\n#else\n#define ___MEM_SOURCE_FILE \"mem.c\"\n#endif\n\n"
records=[]
fragments.each_with_index do |f,i|
  first=f['firstLine']; past=starts[i+1] || lines.size+1
  payload=lines[(first-1)...(past-1)].join
  # A preprocessing group must not cross an included-file boundary.
  depth=0
  payload.each_line do |l|
    depth+=1 if l.match?(/^\s*#\s*(if|ifdef|ifndef)\b/)
    depth-=1 if l.match?(/^\s*#\s*endif\b/)
    raise "cross-fragment conditional #{f['file']}" if depth<0
  end
  raise "unclosed conditional #{f['file']}" unless depth==0
  target=File.join(File.dirname(path),f['file'])
  raise 'refuse existing fragment' if File.exist?(target)
  FileUtils.mkdir_p(File.dirname(target))
  prologue="#line #{first} ___MEM_SOURCE_FILE\n"
  File.binwrite(target,prologue+payload+m.fetch("fragmentSuffix"))
  driver<<"#include \"#{f['file']}\"\n"
  records<<f.merge('pastLine'=>past,'payloadSha256'=>sha.call(payload),'fragmentSha256'=>sha.call(prologue+payload+m.fetch("fragmentSuffix")))
end
driver<<"\n#undef ___MEM_SOURCE_FILE\n"
File.binwrite(path,driver)
mkpath=File.join(File.dirname(path),'makefile.in'); mk=File.read(mkpath)
File.binwrite(out+'/lib-makefile-before.in',mk)
definition="MEMORY_SOURCES = "+fragments.map { |f| f['file'] }.join(" \\\n  ")+"\n"
mk.sub!('NORMAL_CPP =',definition+"NORMAL_CPP =") || raise('missing normal sources')
mk.sub!('NORMAL_SOURCES = $(NORMAL_C) $(NORMAL_CPP) $(NORMAL_H)',
        'NORMAL_SOURCES = $(NORMAL_C) $(NORMAL_CPP) $(NORMAL_H) $(MEMORY_SOURCES)') || raise('missing distribution list')
mk.sub!('mem@obj@: mem.c ', 'mem@obj@: mem.c $(MEMORY_SOURCES) ') || raise('missing dependency rule')
anchor="\t@echo \"  Copying distribution files:\""
mk.sub!(anchor,"\tmkdir $(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot)/_mem\n"+anchor) || raise('missing distribution directory')
mk.sub!('$(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot) 2>',
        '$(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot)/$$file 2>') || raise('missing distribution link')
mk.sub!('cp -p $(srcdirpfx)$$file $(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot);',
        'cp -p $(srcdirpfx)$$file $(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot)/$$file;') || raise('missing distribution copy')
File.write(mkpath,mk)
receipt={modelSha256:sha.call(File.binread(model)),sourceSha256:sha.call(source),preambleLines:m['preambleLines'],
  preambleSha256:sha.call(lines.take(m['preambleLines']).join),sourceLines:lines.size,sourceBytes:source.bytesize,
  driverSha256:sha.call(driver),driverLines:driver.lines.size,fragments:records,
  translationUnitsBefore:1,translationUnitsAfter:1,semanticChangesIntended:false,commitAdmitted:false}
File.write(out+'/split.json',JSON.pretty_generate(receipt)+"\n")
puts JSON.generate(fragments:records.size,sourceLines:lines.size,driverLines:driver.lines.size)
