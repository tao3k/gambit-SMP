(.needs|length)==32 and (.dependencies|length)==31 and
(.readerRegions|length)==12 and (.readerEdges|length)==19 and
(.readerBenefits|length)==4 and (.readerGates|length)==5 and
([.readerGates[].key]|unique|length)==5 and
all(.readerGates[];.qualified==false) and .readerConfig.actualAdmitted==false
