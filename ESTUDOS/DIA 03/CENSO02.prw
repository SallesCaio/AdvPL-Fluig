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

User Function CENSO02()
    Local nSoma   := 0
    Local cEstado := ""

    DbSelectArea("SA1")
    DbGoTop()

    While !EOF()
        cEstado := SA1->A1_EST
        If cEstado == "SP"
            nSoma += SA1->A1_LC
        Endif
        DbSkip()
    EndDo

Return nSoma
