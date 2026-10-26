import CatcherSettlementAst
open CatcherSettlementAst
set_option maxRecDepth 10000
example (q : State) (h : Safe q) (g : prepareFirstGuard q) : Safe (prepareFirstNext q) := by
 grind [Safe,prepareFirstGuard,prepareFirstNext]
