s=File.read('.cache/tasks/rest-gc-resume-envelope/renderer-template.jq')
s=s.gsub('guaranteedNodes','restNodes').gsub('guaranteedEdges','restEdges').gsub('guaranteedCallers','restCallers').gsub('guaranteedCosts','restCosts').gsub('Guaranteed-tail placement and peak','Rest construction, GC resume and peak').gsub('guaranteed-','rest-').gsub('GT-','RG-').gsub('[163:]','[186:]')
File.write('dev/modeling/ascent/render-rest-gc-resume-envelope.jq',s)
