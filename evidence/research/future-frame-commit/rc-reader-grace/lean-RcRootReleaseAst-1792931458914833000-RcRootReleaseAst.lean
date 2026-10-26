import Std
namespace RcRootReleaseAst
set_option maxRecDepth 10000
structure State where
 admission : Int
 owner : Int
 borrow : Int
 scanner : Int
 alias : Int
 registered : Int
 permit : Int
 phase : Int
 origin : Int
 receipt : Int
 domainLive : Int
 reader : Int
 deriving DecidableEq
def Safe (q : State) : Prop := ((q.admission≥(0)) ∧ (q.owner≥(0)) ∧ (q.borrow≥(0)) ∧ (q.scanner≥(0)) ∧ (q.alias≥(0)) ∧ (q.registered≥(0)) ∧ (q.permit≥(0)) ∧ (q.phase≥(0)) ∧ (q.origin≥(0)) ∧ (q.receipt≥(0)) ∧ (q.domainLive≥(0)) ∧ (q.reader≥(0)) ∧ (q.admission≤(1)) ∧ (q.owner≤(1)) ∧ (q.borrow≤(1)) ∧ (q.scanner≤(1)) ∧ (q.alias≤(1)) ∧ (q.registered≤(1)) ∧ (q.permit≤(1)) ∧ (q.phase≤(3)) ∧ (q.origin≤(1)) ∧ (q.receipt≤(1)) ∧ (q.domainLive≤(1)) ∧ (q.reader≤(1)) ∧ ((q.registered=(0)) → ((q.owner=(0)) ∧ (q.borrow=(0)) ∧ (q.scanner=(0)) ∧ (q.alias=(0)) ∧ (q.admission=(0)))) ∧ ((q.permit=(1)) → ((q.registered=(0)) ∧ (q.phase=(0)) ∧ (q.origin=(1)))) ∧ ((q.phase≥(1)) → ((q.registered=(0)) ∧ (q.permit=(0)))) ∧ ((q.phase≤(2)) → (q.origin=(1))) ∧ ((q.phase=(3)) → ((q.origin=(0)) ∧ (q.receipt=(1)))) ∧ ((q.phase=(0)) → (q.receipt=(0))) ∧ ((q.domainLive=(0)) → ((q.admission=(0)) ∧ (q.reader=(0)) ∧ (q.registered=(0)) ∧ (q.phase=(3)))) ∧ ((q.scanner=(1)) → ((q.registered=(1)) ∧ (q.domainLive=(1)))) ∧ ((q.registered=(1)) → ((q.phase=(0)) ∧ (q.permit=(0)) ∧ (q.domainLive=(1)))) ∧ ((q.admission=(1)) → (q.registered=(1))) ∧ ((q.reader=(1)) → (q.domainLive=(1))) ∧ (((q.phase=(0)) ∧ (q.registered=(0))) → (q.permit=(1))))
def initial : State := {admission:=(1), owner:=(1), borrow:=(0), scanner:=(0), alias:=(0), registered:=(1), permit:=(0), phase:=(0), origin:=(1), receipt:=(0), domainLive:=(1), reader:=(0)}
def acquireBorrowGuard (q : State) : Prop := ((((q.admission=(1)) ∧ (q.owner=(1))) ∧ (q.borrow=(0))) ∧ (q.scanner=(0)))
def acquireBorrowNext (q : State) : State := {q with borrow:=(1)}
def exportAliasGuard (q : State) : Prop := (((q.admission=(1)) ∧ (q.owner=(1))) ∧ (q.alias=(0)))
def exportAliasNext (q : State) : State := {q with alias:=(1)}
def closeSourceGuard (q : State) : Prop := (q.admission=(1))
def closeSourceNext (q : State) : State := {q with admission:=(0)}
def dropOwnerGuard (q : State) : Prop := ((q.owner=(1)) ∧ (q.scanner=(0)))
def dropOwnerNext (q : State) : State := {q with owner:=(0)}
def returnBorrowGuard (q : State) : Prop := ((q.borrow=(1)) ∧ (q.scanner=(0)))
def returnBorrowNext (q : State) : State := {q with borrow:=(0)}
def returnAliasGuard (q : State) : Prop := (q.alias=(1))
def returnAliasNext (q : State) : State := {q with alias:=(0)}
def beginScanGuard (q : State) : Prop := ((q.registered=(1)) ∧ (q.scanner=(0)))
def beginScanNext (q : State) : State := {q with scanner:=(1)}
def endScanGuard (q : State) : Prop := (q.scanner=(1))
def endScanNext (q : State) : State := {q with scanner:=(0)}
def enterReaderGuard (q : State) : Prop := (((q.admission=(1)) ∧ (q.domainLive=(1))) ∧ (q.reader=(0)))
def enterReaderNext (q : State) : State := {q with reader:=(1)}
def exitReaderGuard (q : State) : Prop := (q.reader=(1))
def exitReaderNext (q : State) : State := {q with reader:=(0)}
def unlinkAndPermitGuard (q : State) : Prop := ((((((q.admission=(0)) ∧ (q.owner=(0))) ∧ (q.borrow=(0))) ∧ (q.scanner=(0))) ∧ (q.alias=(0))) ∧ (q.registered=(1)))
def unlinkAndPermitNext (q : State) : State := {q with registered:=(0), permit:=(1)}
def beginFreeGuard (q : State) : Prop := (((q.permit=(1)) ∧ (q.phase=(0))) ∧ (q.origin=(1)))
def beginFreeNext (q : State) : State := {q with phase:=(1), permit:=(0)}
def loseFreeResultGuard (q : State) : Prop := (q.phase=(1))
def loseFreeResultNext (q : State) : State := {q with phase:=(2)}
def backendReceiptGuard (q : State) : Prop := (((q.phase=(1)) ∨ (q.phase=(2))) ∧ (q.receipt=(0)))
def backendReceiptNext (q : State) : State := {q with receipt:=(1)}
def settleFreeGuard (q : State) : Prop := (((q.phase=(1)) ∨ (q.phase=(2))) ∧ (q.receipt=(1)))
def settleFreeNext (q : State) : State := {q with phase:=(3), origin:=(0)}
def retireDomainGuard (q : State) : Prop := (((((((((q.admission=(0)) ∧ (q.reader=(0))) ∧ (q.registered=(0))) ∧ (q.owner=(0))) ∧ (q.borrow=(0))) ∧ (q.scanner=(0))) ∧ (q.alias=(0))) ∧ (q.phase=(3))) ∧ (q.domainLive=(1)))
def retireDomainNext (q : State) : State := {q with domainLive:=(0)}
def Step (q r : State) : Prop := (acquireBorrowGuard q ∧ r=acquireBorrowNext q) ∨ (exportAliasGuard q ∧ r=exportAliasNext q) ∨ (closeSourceGuard q ∧ r=closeSourceNext q) ∨ (dropOwnerGuard q ∧ r=dropOwnerNext q) ∨ (returnBorrowGuard q ∧ r=returnBorrowNext q) ∨ (returnAliasGuard q ∧ r=returnAliasNext q) ∨ (beginScanGuard q ∧ r=beginScanNext q) ∨ (endScanGuard q ∧ r=endScanNext q) ∨ (enterReaderGuard q ∧ r=enterReaderNext q) ∨ (exitReaderGuard q ∧ r=exitReaderNext q) ∨ (unlinkAndPermitGuard q ∧ r=unlinkAndPermitNext q) ∨ (beginFreeGuard q ∧ r=beginFreeNext q) ∨ (loseFreeResultGuard q ∧ r=loseFreeResultNext q) ∨ (backendReceiptGuard q ∧ r=backendReceiptNext q) ∨ (settleFreeGuard q ∧ r=settleFreeNext q) ∨ (retireDomainGuard q ∧ r=retireDomainNext q) ∨ r=q
end RcRootReleaseAst
