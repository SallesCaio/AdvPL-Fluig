/*/{Protheus.doc} nomeFunction
(long_description)
@type user function
@author user
@since 21/09/2026
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
#INCLUDE "protheus.ch"

User Function ALT01(cCod)
    Local lAchou := .F.
    Local cRet   := " "

    DbSelectArea("SB1")
    DbSetOrder(1)

    lAchou:= DbSeek(xFilial("SB1") + cCod)

    If !lAchou
        cRet:= "PRODUTO INEXISTENTE"
    Else
        If RecLock("SB1", .F.)
            SB1->B1_DESC := SB1->B1_DESC + " [REV]"
            MsUnlock()
            cRet := "OK"
        Else
            cRet:= "REGISTRO TRAVADO"
        Endif
    Endif
        
Return cRet
