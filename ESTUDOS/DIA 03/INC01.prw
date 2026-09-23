/*/
CRIE
@author user
@since 22/09/2026
@version version
@example
(examples)
@see (links_or_references)
/*/
#INCLUDE "protheus.ch"

User Function INC01(cCod, cLoja, cNome, cEstado)
    Local cRet := "" 

    DbSelectArea("SA1")
    DbSetOrder(1)

    If DbSeek(xFilial("SA1") + cCod + cLoja)
        cRet:= "JA EXISTE"
    Else
        Reclock("SA1", .T.)
        SA1->A1_COD  := cCod
        SA1->A1_LOJA := cLoja
        SA1->A1_EST  := cEstado
        SA1->A1_NOME := cNome 
        cRet := "INCLUIDO"  
        MsUnlock()
    Endif
    
Return cRet
