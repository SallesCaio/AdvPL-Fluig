/*
User Function MT110GRV

	SC1->(RecLock("SC1",.F.))

	SC1->C1_FILENT	:= SC1->C1_XFILENT
	SC1->C1_XPRESOL	:= IIf(FunName() == "STAA053", "S", "N")
	SC1->(MsUnLock("SC1"))

Return
*/
