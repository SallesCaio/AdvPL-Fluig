/*/{Protheus.doc} ZXM010FLUIG
Integracao Workflow Fluig - ZXM010 Fase 2
Baseado em WKFSC.prw (SZ0 -> Fluig)
@type Function
@author Caio Salles
@since 2026-06-23
@version 1.0
/*/

#Include "Protheus.ch"

// ============================================================
// CONFIGURACAO
// ============================================================

Static cFluigUrl    := "http://fluig.local:8080/webdesk/ECMWorkflowEngineService"
Static cFluigUser   := "adm"
Static cFluigPass   := ""  // Configurar senha do ambiente
Static cFluigProcId := "ProcessoAprovacao"
Static cCompanyId   := 2

// ============================================================
// ENVIO PARA FLUIG
// ============================================================

/*/{Protheus.doc} ZXM010Send
Envia solicitacao ZXM para workflow Fluig
@param cCodSolic - Codigo da solicitacao ZXM
@return lRet - .T. se enviou com sucesso
@type User Function
/*/
User Function ZXM010Send(cCodSolic)
    Local lRet       := .F.
    Local cCardData  := ""
    Local cSoapXml   := ""
    Local cResp      := ""
    Local cComment   := ""
    Local aHeaders   := {}
    Local nTimeOut   := 120
    Local oCab       := Nil

    // Valida codigo
    If Empty(cCodSolic)
        FWAlertError("Codigo da solicitacao vazio.", "Erro")
        Return .F.
    EndIf

    // Carrega dados da ZXM
    ZXM->(DbSetOrder(1))
    If !ZXM->(DbSeek(xFilial("ZXM") + cCodSolic))
        FWAlertError("Solicitacao " + cCodSolic + " nao encontrada.", "Erro")
        Return .F.
    EndIf

    // Verifica status (so envia se Novo ou Reprovado)
    If !(ZXM->ZXM_STATUS $ "0/3")
        FWAlertError("Solicitacao nao esta apta para aprovacao. Status: " + ZXM->ZXM_STATUS, "Bloqueio")
        Return .F.
    EndIf

    // Monta cardData
    cCardData := '<cardData>'
    cCardData += '<item><item>ZXM_COD</item><item>' + AllTrim(ZXM->ZXM_COD) + '</item></item>'
    cCardData += '<item><item>ZXM_DESC</item><item>' + AllTrim(ZXM->ZXM_DESC) + '</item></item>'
    cCardData += '<item><item>ZXM_TIPO</item><item>' + AllTrim(ZXM->ZXM_TIPO) + '</item></item>'
    cCardData += '<item><item>ZXM_FORNEC</item><item>' + AllTrim(ZXM->ZXM_FORNEC) + '</item></item>'
    cCardData += '<item><item>ZXM_LOJA</item><item>' + AllTrim(ZXM->ZXM_LOJA) + '</item></item>'
    cCardData += '<item><item>ZXM_VALOR</item><item>' + cValToChar(ZXM->ZXM_VALOR) + '</item></item>'
    cCardData += '<item><item>ZXM_URGEN</item><item>' + AllTrim(ZXM->ZXM_URGEN) + '</item></item>'
    cCardData += '</cardData>'

    // Comentario
    cComment := "Solicitacao tecnica " + AllTrim(ZXM->ZXM_COD) + " - " + AllTrim(ZXM->ZXM_DESC)

    // Monta SOAP XML
    cSoapXml := '<?xml version="1.0" encoding="UTF-8"?>'
    cSoapXml += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.workflow.ecm.technology.totvs.com/">'
    cSoapXml += '<soapenv:Header/>'
    cSoapXml += '<soapenv:Body>'
    cSoapXml += '<ws:startProcess>'
    cSoapXml += '<username>' + cFluigUser + '</username>'
    cSoapXml += '<password>' + cFluigPass + '</password>'
    cSoapXml += '<companyId>' + cValToChar(cCompanyId) + '</companyId>'
    cSoapXml += '<processId>' + cFluigProcId + '</processId>'
    cSoapXml += '<choosedState/>'
    cSoapXml += '<colleagueIds><item>' + cFluigUser + '</item></colleagueIds>'
    cSoapXml += '<comments>' + cComment + '</comments>'
    cSoapXml += '<userId>' + cFluigUser + '</userId>'
    cSoapXml += '<completeTask>true</completeTask>'
    cSoapXml += '<attachments/>'
    cSoapXml += cCardData
    cSoapXml += '<appointment/>'
    cSoapXml += '<managerMode>false</managerMode>'
    cSoapXml += '</ws:startProcess>'
    cSoapXml += '</soapenv:Body>'
    cSoapXml += '</soapenv:Envelope>'

    // Headers
    AAdd(aHeaders, 'User-Agent: Protheus ' + GetBuild())
    AAdd(aHeaders, 'Content-Type: text/xml; charset=UTF-8')
    AAdd(aHeaders, 'SOAPAction: "startProcess"')
    AAdd(aHeaders, 'Accept-Encoding: identity')
    AAdd(aHeaders, 'Connection: Keep-Alive')

    // Envia
    cResp := HttpPost(cFluigUrl, "", cSoapXml, nTimeOut, aHeaders)

    // Verifica resposta
    If !Empty(cResp) .And. "startProcessResponse" $ cResp
        lRet := .T.
        ConOut("[ZXM010FLUIG] Envio OK: " + cCodSolic)

        // Atualiza status local
        ZXM010UpdStatus(cCodSolic, "1") // Em aprovacao

        FWAlertInfo("Solicitacao enviada para aprovacao no Fluig.", "Sucesso")
    Else
        ConOut("[ZXM010FLUIG] Erro: " + Left(cResp, 200))
        FWAlertError("Erro ao enviar para Fluig. Verifique o log.", "Erro")
    EndIf

Return lRet
Return lRet
// ============================================================
// ATUALIZACAO DE STATUS
// ============================================================

/*/{Protheus.doc} ZXM010UpdStatus
Atualiza status da solicitacao apos callback Fluig
@param cCodSolic - Codigo da solicitacao
@param cAcao     - "APROVAR" ou "REPROVAR"
@return lRet - .T. se atualizou
@type Static Function
/*/
Static Function ZXM010UpdStatus(cCodSolic, cAcao)
    Local lRet     := .F.
    Local cNovoSts := ""

    If Empty(cCodSolic)
        Return .F.
    EndIf

    // Define novo status
    If cAcao == "APROVAR"
        cNovoSts := "2" // Aprovado
    ElseIf cAcao == "REPROVAR"
        cNovoSts := "3" // Reprovado
    ElseIf cAcao == "CANCELAR"
        cNovoSts := "0" // Volta para Novo
    Else
        Return .F.
    EndIf

    // Atualiza ZXM
    ZXM->(DbSetOrder(1))
    If ZXM->(DbSeek(xFilial("ZXM") + cCodSolic))
        If RecLock("ZXM", .F.)
            ZXM->ZXM_STATUS := cNovoSts
            ZXM->(MsUnLock())
            lRet := .T.
            ConOut("[ZXM010FLUIG] Status atualizado: " + cCodSolic + " -> " + cNovoSts)
        EndIf
    EndIf

Return lRet

// ============================================================
// CONSULTA DE STATUS
// ============================================================

/*/{Protheus.doc} ZXM010Status
Consulta status da solicitacao no Fluig
@param cCodSolic - Codigo da solicitacao
@return cStatus - "PENDENTE", "APROVADO", "REPROVADO"
@type User Function
/*/
User Function ZXM010Status(cCodSolic)
    Local cStatus := "PENDENTE"
    Local cSoapXml := ""
    Local cResp    := ""
    Local aHeaders := {}
    Local nTimeOut := 120

    If Empty(cCodSolic)
        Return cStatus
    EndIf

    // Monta XML de consulta (getProcessState)
    cSoapXml := '<?xml version="1.0" encoding="UTF-8"?>'
    cSoapXml += '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.workflow.ecm.technology.totvs.com/">'
    cSoapXml += '<soapenv:Header/>'
    cSoapXml += '<soapenv:Body>'
    cSoapXml += '<ws:getProcessState>'
    cSoapXml += '<username>' + cFluigUser + '</username>'
    cSoapXml += '<password>' + cFluigPass + '</password>'
    cSoapXml += '<companyId>' + cValToChar(cCompanyId) + '</companyId>'
    cSoapXml += '<processId>' + cFluigProcId + '</processId>'
    cSoapXml += '<processInstanceId>' + cCodSolic + '</processInstanceId>'
    cSoapXml += '</ws:getProcessState>'
    cSoapXml += '</soapenv:Body>'
    cSoapXml += '</soapenv:Envelope>'

    AAdd(aHeaders, 'Content-Type: text/xml; charset=UTF-8')
    AAdd(aHeaders, 'SOAPAction: "getProcessState"')

    cResp := HttpPost(cFluigUrl, "", cSoapXml, nTimeOut, aHeaders)

    // Parse resposta (simplificado)
    If !Empty(cResp)
        If "approved" $ Lower(cResp)
            cStatus := "APROVADO"
        ElseIf "rejected" $ Lower(cResp)
            cStatus := "REPROVADO"
        EndIf
    EndIf

Return cStatus

// ============================================================
// CALLBACK (chamado pelo Fluig)
// ============================================================

/*/{Protheus.doc} ZXM010Callback
Recebe callback do Fluig com decisao de aprovacao
@param cPayload - JSON com dados do callback
@return lRet - .T. se processou
@type User Function
/*/
User Function ZXM010Callback(cPayload)
    Local oJson     := Nil
    Local cCodSolic := ""
    Local cDecision := ""
    Local lRet      := .F.

    If Empty(cPayload)
        Return .F.
    EndIf

    oJson := JsonObject():New()
    If oJson:FromJson(cPayload) != 0
        Return .F.
    EndIf

    cCodSolic := oJson:GetJsonString("codigo")
    cDecision := oJson:GetJsonString("decisao")

    If Empty(cCodSolic)
        Return .F.
    EndIf

    // Atualiza status
    If cDecision == "APROVAR"
        lRet := ZXM010UpdStatus(cCodSolic, "APROVAR")
    ElseIf cDecision == "REPROVAR"
        lRet := ZXM010UpdStatus(cCodSolic, "REPROVAR")
    EndIf

Return lRet
