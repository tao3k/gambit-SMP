(.needs|length)==28 and (.dependencies|length)==27 and
(.initNodes|length)==12 and (.initEdges|length)==18 and
(.initBenefits|length)==5 and (.initGates|length)==8 and
([.initGates[].key]|unique|length)==8 and
all(.initGates[];.qualified==false) and .initConfig.observedClosure==false
