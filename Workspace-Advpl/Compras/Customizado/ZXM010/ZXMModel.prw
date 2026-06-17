/*/{Protheus.doc} ZXMModel
Funcoes de modelo e acesso a dados - ZXM010
@type  Function
@author Caio Salles
@since 2026-06-16
@version 2.0
/*/

#Include "Protheus.ch"

//-------------------------------------------------------------------
// Busca solicitacao por codigo
//-------------------------------------------------------------------
Static Function ZXMGetByCod(cCodigo)

    Local cAlias := "ZXM"
    Local cKey   := ""

    If Select(cAlias) == 0
        Return .F.
    EndIf

    cKey := xFilial(cAlias) + PadR(cCodigo, TamSX3("ZXM_COD")[1])

    DbSelectArea(cAlias)
    DbSeek(cKey)

Return Found()

//-------------------------------------------------------------------
// Altera status da solicitacao
//-------------------------------------------------------------------
Static Function ZXMSetStatus(cCodigo, cStatus)

    Local cAlias := "ZXM"
    Local lRet   := .F.

    If Select(cAlias) == 0
        Return .F.
    EndIf

    DbSelectArea(cAlias)

    If ZXMGetByCod(cCodigo)
        If RecLock(cAlias, .F.)
            (cAlias)->ZXM_STATUS := cStatus
            (cAlias)->(DbCommit())
            MsUnlock()
            lRet := .T.
        EndIf
    EndIf

Return lRet

//-------------------------------------------------------------------
// Proximo codigo via GetSXENum
//-------------------------------------------------------------------
Static Function ZXMNextCod()

    Local cNum := GetSXENum("ZXM", "ZXM_COD")

Return cNum

//-------------------------------------------------------------------
// Verifica se solicitacao pode ser editada
//-------------------------------------------------------------------
Static Function ZXMCanEdit(cStatus)

    // So permite editar status 0 (Novo) e 3 (Reprovado)
Return (cStatus == "0" .Or. cStatus == "3")
