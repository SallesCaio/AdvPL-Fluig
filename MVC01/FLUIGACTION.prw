#include "protheus.ch"

// Ação chamada pelo menu/botão no Browse
User Function ENVIAFLUIG()
    Local cAlias    := "SZ0"
    Local cUrlFluig := "https://lab.fluig.com/webdesk/ECMWorkflowEngineService"
    Local cUser     := "academy.aluno"
    Local cPass     := "academy.aluno"

    Local cCodigo   := ""
    Local cDescri   := ""
    Local cCodVend  := ""
    Local cStatus   := ""

    Local cCardData := ""
    Local cSoapXml  := ""
    Local aHeaders  := {}
    Local cHeadRet  := ""
    Local nTimeOut  := 120
    Local cResp     := ""
    Local cLogDir   := "\temp\"  // garanta que exista

    // Garante área e registro selecionado no Browse SZ0
    If Select(cAlias) == 0
        MsgAlert("Alias " + cAlias + " não está aberto.")
        Return .F.
    EndIf

    DbSelectArea(cAlias)
    If (cAlias)->(RecNo()) <= 0
        MsgAlert("Nenhum registro selecionado.")
        Return .F.
    EndIf

    // Lê campos do registro atual (sem Z0_NOMEVEN)
    cCodigo   := AllTrim((cAlias)->Z0_CODIGO)
    cDescri   := AllTrim((cAlias)->Z0_DESCRI)
    cCodVend  := AllTrim((cAlias)->Z0_CODVEN)
    cStatus   := AllTrim((cAlias)->Z0_STATUS)

    // Monta cardData (sem Z0_NOMEVEN)
    cCardData := ;
        '<cardData>' + ;
            '<item><item>Z0_CODIGO</item><item>'  + cCodigo   + '</item></item>' + ;
            '<item><item>ZO_DESCRI</item><item>'  + cDescri   + '</item></item>' + ;
            '<item><item>Z0_CODVEN</item><item>'  + cCodVend  + '</item></item>' + ;
            '<item><item>Z0_STATUS</item><item>'  + cStatus   + '</item></item>' + ;
            '<item><item>fluigInstId</item><item></item></item>' + ;
        '</cardData>'

    // Envelope SOAP 1.1
    cSoapXml := ;
        '<?xml version="1.0" encoding="UTF-8"?>' + ;
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.workflow.ecm.technology.totvs.com/">' + ;
          '<soapenv:Header/>' + ;
          '<soapenv:Body>' + ;
            '<ws:startProcess>' + ;
              '<username>' + cUser + '</username>' + ;
              '<password>' + cPass + '</password>' + ;
              '<companyId>1</companyId>' + ;
              '<processId>registro_aprovacao</processId>' + ;
              '<choosedState></choosedState>' + ;
              '<colleagueIds><item>' + cUser + '</item></colleagueIds>' + ;
              '<comments>Solicitacao Protheus</comments>' + ;
              '<userId>' + cUser + '</userId>' + ;
              '<completeTask>true</completeTask>' + ;
              '<attachments/>' + ;
              cCardData + ;
              '<appointment/>' + ;
              '<managerMode>false</managerMode>' + ;
            '</ws:startProcess>' + ;
          '</soapenv:Body>' + ;
        '</soapenv:Envelope>'

    // Headers SOAP 1.1 (assinatura legado do HttpPost)
    AAdd(aHeaders, 'User-Agent: Mozilla/4.0 (compatible; Protheus ' + GetBuild() + ')')
    AAdd(aHeaders, 'Content-Type: text/xml;charset=UTF-8')
    AAdd(aHeaders, 'SOAPAction: "startProcess"')
    AAdd(aHeaders, 'Accept-Encoding: identity')
    AAdd(aHeaders, 'Connection: Keep-Alive')

    // Logs
    MemoWrite(cLogDir + "fluig_req_soap11.xml", cSoapXml)

    // HttpPost( cUrl, cGet="", cPost=cSoapXml, nTimeOut, aHeaders, @cHeadRet )
    cResp := HttpPost(cUrlFluig, "", cSoapXml, nTimeOut, aHeaders, @cHeadRet)
    MemoWrite(cLogDir + "fluig_resp_soap11.txt", cResp)
    MemoWrite(cLogDir + "fluig_resp_headers.txt", cHeadRet)

    If !Empty(cResp) .and. "startProcessResponse" $ cResp
        MsgInfo("Enviado ao Fluig com sucesso.")
        Return .T.
    EndIf

    // Fallback: SOAPAction com namespace completo
    aHeaders := {}
    AAdd(aHeaders, 'User-Agent: Mozilla/4.0 (compatible; Protheus ' + GetBuild() + ')')
    AAdd(aHeaders, 'Content-Type: text/xml;charset=UTF-8')
    AAdd(aHeaders, 'SOAPAction: "http://ws.workflow.ecm.technology.totvs.com/startProcess"')
    AAdd(aHeaders, 'Accept-Encoding: identity')
    AAdd(aHeaders, 'Connection: Keep-Alive')

    cHeadRet := ""
    cResp := HttpPost(cUrlFluig, "", cSoapXml, nTimeOut, aHeaders, @cHeadRet)
    MemoWrite(cLogDir + "fluig_resp_soap11_ns.txt", cResp)

    If !Empty(cResp) .and. "startProcessResponse" $ cResp
        MsgInfo("Enviado ao Fluig com sucesso (namespace).")
        Return .T.
    EndIf

    MsgAlert("Falha no envio ao Fluig. Veja logs em " + cLogDir + ". Retorno: " + Left(cResp, 400))
Return .F.
