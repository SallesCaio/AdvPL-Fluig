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

User Function CENSO01()
    Local cTipo := ""
    Local nCont := 0

    DbSelectArea("SB1")
    DbGoTop()
    
    While !EOF()
        cTipo := SB1->B1_TIPO
        If cTipo == "PA"
            nCont++
        Endif
        DbSkip()
    EndDo

Return nCont
