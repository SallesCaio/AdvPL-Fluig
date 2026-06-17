/*/{Protheus.doc} ZXMModel
Funcoes de modelo e acesso a dados - ZXM010 v3.0
@type  Function
@author Caio Salles
@since 2026-06-17
@version 3.0
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

Return (cStatus == "0" .Or. cStatus == "1")

//-------------------------------------------------------------------
// Calcula valor total da solicitacao (soma dos itens)
//-------------------------------------------------------------------
Static Function ZXMCalcTotal(cCodigo)

    Local cAlias := "ZXN"
    Local nTotal := 0

    If Select(cAlias) == 0
        Return 0
    EndIf

    DbSelectArea(cAlias)
    DbSeek(xFilial(cAlias) + cCodigo)

    While !Eof() .And. (cAlias)->ZXN_FILIAL == xFilial(cAlias) .And. (cAlias)->ZXN_COD == cCodigo
        nTotal += (cAlias)->ZXN_VLTOT
        DbSkip()
    End

Return nTotal

//-------------------------------------------------------------------
// Busca itens da solicitacao
//-------------------------------------------------------------------
Static Function ZXMGetItens(cCodigo)

    Local aItens := {}
    Local cAlias := "ZXN"

    If Select(cAlias) == 0
        Return aItens
    EndIf

    DbSelectArea(cAlias)
    DbSeek(xFilial(cAlias) + cCodigo)

    While !Eof() .And. (cAlias)->ZXN_FILIAL == xFilial(cAlias) .And. (cAlias)->ZXN_COD == cCodigo
        AAdd(aItens, {;
            (cAlias)->ZXN_ITEM,;
            (cAlias)->ZXN_PROD,;
            (cAlias)->ZXN_DESC,;
            (cAlias)->ZXN_QTD,;
            (cAlias)->ZXN_VLUNI,;
            (cAlias)->ZXN_VLTOT;
        })
        DbSkip()
    End

Return aItens
