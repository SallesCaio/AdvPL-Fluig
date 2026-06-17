/*/{Protheus.doc} ZXMUTIL
Funcoes utilitarias - ZXM010
@type  Function
@author Caio Salles
@since 2026-06-16
@version 2.0
/*/

#Include "Protheus.ch"

//-------------------------------------------------------------------
// Retorna texto do status
//-------------------------------------------------------------------
Static Function ZXMStatusText(cStatus)

    Local cRet := "Desconhecido"

    Do Case
    Case cStatus == "0" ; cRet := "Novo"
    Case cStatus == "1" ; cRet := "Em Analise"
    Case cStatus == "2" ; cRet := "Aprovado"
    Case cStatus == "3" ; cRet := "Reprovado"
    EndCase

Return cRet

//-------------------------------------------------------------------
// Retorna texto da urgencia
//-------------------------------------------------------------------
Static Function ZXMUrgenText(cUrgen)

    Local cRet := ""

    Do Case
    Case cUrgen == "B" ; cRet := "Baixa"
    Case cUrgen == "M" ; cRet := "Media"
    Case cUrgen == "A" ; cRet := "Alta"
    EndCase

Return cRet

//-------------------------------------------------------------------
// Valida campos obrigatorios antes de gravar
//-------------------------------------------------------------------
Static Function ZXMValida(oModel)

    Local aErros    := {}
    Local cDesc     := ""
    Local cTipo     := ""
    Local cFornec   := ""
    Local cLoja     := ""
    Local cUrgen    := ""

    // Obtem valores do modelo
    cDesc   := oModel:GetValue("ZXMMASTER", "ZXM_DESC")
    cTipo   := oModel:GetValue("ZXMMASTER", "ZXM_TIPO")
    cFornec := oModel:GetValue("ZXMMASTER", "ZXM_FORNEC")
    cLoja   := oModel:GetValue("ZXMMASTER", "ZXM_LOJA")
    cUrgen  := oModel:GetValue("ZXMMASTER", "ZXM_URGEN")

    If Empty(cDesc)
        AAdd(aErros, "Descricao e obrigatoria.")
    EndIf

    If Empty(cTipo)
        AAdd(aErros, "Tipo da solicitacao e obrigatorio.")
    EndIf

    If Empty(cFornec)
        AAdd(aErros, "Fornecedor e obrigatorio.")
    EndIf

    If Empty(cLoja)
        AAdd(aErros, "Loja do fornecedor e obrigatoria.")
    EndIf

    If Empty(cUrgen)
        AAdd(aErros, "Urgencia e obrigatoria.")
    EndIf

Return aErros

//-------------------------------------------------------------------
// Obtem nome do usuario logado via SYS_USR (DbSeek - sem FWExecStatement)
//-------------------------------------------------------------------
Static Function ZXMUserName()

    Local cUser  := __cUserID
    Local cNome  := ""
    Local cAliasTmp := "SYS_USR"

    If Select(cAliasTmp) > 0
        DbSelectArea(cAliasTmp)
        If DbSeek(xFilial(cAliasTmp) + cUser)
            cNome := AllTrim((cAliasTmp)->USR_NOME)
        EndIf
    EndIf

Return cNome

//-------------------------------------------------------------------
// Prepara JSON para futura integracao Fluig
//-------------------------------------------------------------------
Static Function ZXMToJson()

    Local cAlias := "ZXM"
    Local oJson  := JsonObject():New()

    If Select(cAlias) == 0
        Return oJson
    EndIf

    oJson["codigo"]     := AllTrim((cAlias)->ZXM_COD)
    oJson["descricao"]  := AllTrim((cAlias)->ZXM_DESC)
    oJson["tipo"]       := AllTrim((cAlias)->ZXM_TIPO)
    oJson["fornecedor"] := AllTrim((cAlias)->ZXM_FORNEC)
    oJson["loja"]       := AllTrim((cAlias)->ZXM_LOJA)
    oJson["status"]     := AllTrim((cAlias)->ZXM_STATUS)
    oJson["urgencia"]   := AllTrim((cAlias)->ZXM_URGEN)
    oJson["valor"]      := (cAlias)->ZXM_VALOR
    oJson["data"]       := DtoS((cAlias)->ZXM_DTAB)
    oJson["usuario"]    := AllTrim((cAlias)->ZXM_USR)

Return oJson
