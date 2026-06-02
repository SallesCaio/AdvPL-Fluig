User Function TESTEMAIL()
    Local cURL := "http://lab.fluig.com/webdesk/ECMWorkflowEngineService"
    Local cXmlRequest
    Local nHandle
    Local cResponse

    // Monta o XML conforme seu exemplo
    cXmlRequest := '<?xml version="1.0" encoding="UTF-8"?>' + ;
    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.workflow.ecm.technology.totvs.com/">' + ;
    '<soapenv:Header/>' + ;
    '<soapenv:Body>' + ;
    '<ws:startProcess>' + ;
    '<username>academy.aluno</username>' + ;
    '<password>academy.aluno</password>' + ;
    '<companyId>1</companyId>' + ;
    '<processId>registro_aprovacao</processId>' + ;
    '</ws:startProcess>' + ;
    '</soapenv:Body>' + ;
    '</soapenv:Envelope>'

    // Abre conexão HTTP
    nHandle := HttpOpen(cURL)
    If nHandle > 0
        HttpAddHeader(nHandle, "Content-Type", "text/xml; charset=utf-8")
        HttpAddHeader(nHandle, "SOAPAction", "")
        cResponse := HttpSend(nHandle, cXmlRequest)
        HttpClose(nHandle)
        // Aqui você pode tratar a resposta (XML) e mostrar resultado
        MemoWrite("flresp.txt", cResponse)
        MsgInfo("Resposta do Fluig salva em flresp.txt!","Aviso")
    Else
        MsgStop("Erro ao conectar ao Fluig!")
    EndIf
Return
