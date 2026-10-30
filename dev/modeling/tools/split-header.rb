require 'json';require 'digest';require 'fileutils'
model,out,root=ARGV;root ||= 'vendor/gambit';raise 'model and fresh output required' unless out && !File.exist?(out)
m=JSON.parse(File.read(model));source=m.fetch('source').sub(/\Avendor\/gambit\//,root+'/');bytes=File.binread(source);lines=bytes.lines
raise 'source baseline drift' unless Digest::SHA256.hexdigest(bytes)==m['baselineSha256']
parts=m.fetch('fragments');raise 'private fragment root already exists' if File.exist?(root+'/include/_gambit')
raise 'noncontiguous source partition' unless parts.first['firstLine']==1 && parts.last['pastLine']==lines.size+1 && parts.each_cons(2).all?{|a,b|a['pastLine']==b['firstLine']}
# Check every payload before touching the vendor tree, including conditional
# scopes. Unbalanced guard slices are deliberately emitted in the driver.
payloads=parts.map do |p|
 raise 'private underscored module path required' unless p['file'].match?(%r{\A_gambit/[a-z_]+\.h\.in\z})
 text=lines[(p['firstLine']-1)...(p['pastLine']-1)].join
 unless p['driverInline']
  depth=0;text.each_line{|l|depth+=1 if l.match?(/^\s*#\s*(if|ifdef|ifndef)\b/);depth-=1 if l.match?(/^\s*#\s*endif\b/);raise 'cross-file conditional '+p['file'] if depth<0}
  raise 'unclosed fragment conditional '+p['file'] unless depth==0
 end
 [p,text]
end
raise 'case-fold collision' unless parts.map{|p|p['file'].downcase}.uniq.size==parts.size
raise 'lossy partition' unless payloads.map(&:last).join==bytes
FileUtils.mkdir_p(out);File.binwrite(out+'/before.h.in',bytes)
File.binwrite(out+'/configure-before.ac',File.binread(root+'/configure.ac'))
File.binwrite(out+'/makefile-before.in',File.binread(root+'/include/makefile.in'))
FileUtils.mkdir_p(root+'/include/_gambit')
driver=''
payloads.each do |p,text|
 File.binwrite(root+'/include/'+p['file'],text)
 driver << (p['driverInline'] ? text : "#include \"#{p['file']}\"\n")
end
File.binwrite(source,driver)
config='include/gambit.h:'+parts.map{|p|'include/'+p['file']}.join(':')
p=root+'/configure.ac';s=File.read(p)
raise 'configure header target absent' unless s.sub!("include/gambit.h \\\n",config+" \\\n")
File.write(p,s)
p=root+'/include/makefile.in';s=File.read(p)
definition='HEADER_TEMPLATES = '+parts.map{|p|p['file']}.join(" \\\n  ")+"\nHEADER_CONFIG = #{config}\n\n"
s.sub!('RCFILES =',definition+'RCFILES =') || raise('missing source inventory')
s.sub!('RCFILES = makefile.in gambit.h.in config.h.in stamp-release.h','RCFILES = makefile.in gambit.h.in config.h.in stamp-release.h $(HEADER_TEMPLATES)') || raise('missing revision-control inventory')
s.sub!('gambit.h: gambit.h.in $(rootfromhere)/config.status','gambit.h: gambit.h.in $(HEADER_TEMPLATES) $(rootfromhere)/config.status') || raise('missing header dependencies')
rule='gambit.h: gambit.h.in $(HEADER_TEMPLATES) $(rootfromhere)/config.status'
pos=s.index(rule);a=s[0...pos];b=s[pos..]
b.sub!('CONFIG_FILES=$(herefromroot)/$@',"CONFIG_FILES='$(HEADER_CONFIG)'") || raise('missing config-status publication')
s=a+b
s.sub!("\t@echo \"  Copying distribution files:\"", "\tmkdir $(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot)/_gambit\n\t@echo \"  Copying distribution files:\"") || raise('missing dist directory')
s.gsub!('$(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot) 2>', '$(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot)/$$file 2>')
s.gsub!('cp -p $(srcdirpfx)$$file $(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot);','cp -p $(srcdirpfx)$$file $(rootfromhere)/$(PACKAGE_TARNAME)/$(herefromroot)/$$file;')
File.write(p,s)
# The checked-in configure is a published consumer too. Update only its two
# file-map records; do not import a different Autoconf version's shell logic.
published=root+'/configure'
if File.file?(published)
 s=File.read(published)
 File.binwrite(out+'/published-configure-before',s)
 raise 'missing default published header map' unless s.sub!('makefile include/makefile include/gambit.h lib/makefile',
   'makefile include/makefile '+config+' lib/makefile')
 raise 'missing explicit published header map' unless s.sub!('"include/gambit.h") CONFIG_FILES="$CONFIG_FILES include/gambit.h" ;;',
   '"include/gambit.h") CONFIG_FILES="$CONFIG_FILES '+config+'" ;;')
 File.write(published,s)
end
records=payloads.map{|p,t|p.merge(sha256:Digest::SHA256.hexdigest(t),bytes:t.bytesize)}
File.write(out+'/split.json',JSON.pretty_generate({modelSha256:Digest::SHA256.file(model).hexdigest,baselineSha256:m['baselineSha256'],driverSha256:Digest::SHA256.hexdigest(driver),driverLines:driver.lines.size,fragments:records,byteReconstruction:true,publicHeaderCount:1,publicInstallChanged:false,runtimeInstructionsChangedBySplit:false,commitAdmitted:false})+"\n")
puts JSON.generate(fragments:parts.size,originalLines:lines.size,driverLines:driver.lines.size,byteReconstruction:true)
