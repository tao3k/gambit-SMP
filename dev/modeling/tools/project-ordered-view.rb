# Input is the native SysML query result, never an independently maintained layout.
require 'json'
m=JSON.parse(File.read(ARGV.fetch(0)))
lines=['direction: right']
m.fetch('responsibilities').each do |r|
 lines << r.fetch('id').tr('-','_')+': '+JSON.generate(r.fetch('id')+"\n"+r.fetch('retirement'))
end
m.fetch('transfers').each do |t|
 lines << t.fetch('origin_id').tr('-','_')+' -> '+t.fetch('destination_id').tr('-','_')+': '+JSON.generate(t.fetch('condition'))
end
File.write(ARGV.fetch(1),lines.join("\n")+"\n")
