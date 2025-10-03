#include "protheus.ch"

#Define ST_NOVO          "0"
#Define ST_EM_APROVACAO  "1"
#Define ST_APROVADO      "2"
#Define ST_REPROVADO     "3"

User Function ENVIAFLUIG()
    Local cAlias       := "SZ0"
    Local cAliasVend   := "SA3"
    Local cUrlFluig    := "http://fluig.local:8080/webdesk/ECMWorkflowEngineService"
    Local cUser        := "adm"
    Local cPass        := "protheus123"
    Local nCompany     := 2
    Local cProcId      := "registro_aprovacao"

    Local cCodigo      := ""
    Local cDescri      := ""
    Local cCodVend     := ""
    Local cStatusLocal := ""
    Local cVendNome    := ""
    Local cCardData    := ""
    Local cSoapXml     := ""
    Local aHeaders     := {}
    Local cHeadRet     := ""
    Local nTimeOut     := 120
    Local cResp        := ""
    Local cLogDir      := "\temp\"
    Local lSucesso     := .F.

    ConOut("[ENVIAFLUIG] Inicio")       

    If Select(cAlias) == 0
        MsgAlert("Alias "+cAlias+" não aberto.")
        Return .F.
    EndIf
    If Select(cAliasVend) == 0
        MsgAlert("Alias "+cAliasVend+" não aberto.")
        Return .F.
    EndIf

    DbSelectArea(cAlias)
    If (cAlias)->(RecNo()) <= 0
        MsgAlert("Nenhum registro selecionado.")
        Return .F.
    EndIf

    cCodigo      := AllTrim((cAlias)->Z0_CODIGO)
    cDescri      := AllTrim((cAlias)->Z0_DESCRI)
    cCodVend     := AllTrim((cAlias)->Z0_CODVEN)
    cStatusLocal := AllTrim((cAlias)->Z0_STATUS)

    DbSelectArea(cAliasVend)
    cVendNome := AllTrim((cAliasVend)->A3_NOME)

    //Validação de preechimento
    If Empty(cCodigo) .or. Empty(cDescri) .or. Empty(cCodVend)
        MsgAlert("Preencha Código/Descrição/Vendedor antes de enviar.")
        Return .F.
    EndIf

    //Validação do status
    If !( cStatusLocal $ ( ST_NOVO + ST_REPROVADO ) )
        MsgAlert("Status "+cStatusLocal+" não permite envio (somente 0 ou 3).")
        Return .F.
    EndIf

    ConOut("[ENVIAFLUIG] COD="+cCodigo+" STATUS="+cStatusLocal)

    cCardData := ;
        '<cardData>' + ;
          '<item><item>Z0_CODIGO</item><item>'+cCodigo   +'</item></item>' + ;
          '<item><item>Z0_DESCRI</item><item>'+cDescri   +'</item></item>' + ;
          '<item><item>Z0_CODVEN</item><item>'+cCodVend  +'</item></item>' + ;
          '<item><item>Z0_STATUS</item><item>'+cStatusLocal+'</item></item>' + ;
          '<item><item>Z0_NOMEVEN</item><item>'+cVendNome+'</item></item>' + ;
          '<item><item>fluigInstId</item><item></item></item>' + ;
        '</cardData>'

    cSoapXml := ;
        '<?xml version="1.0" encoding="UTF-8"?>' + ;
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ws="http://ws.workflow.ecm.technology.totvs.com/">' + ;
          '<soapenv:Header/>' + ;
          '<soapenv:Body>' + ;
            '<ws:startProcess>' + ;
              '<username>'  + cUser               + '</username>' + ;
              '<password>'  + cPass               + '</password>' + ;
              '<companyId>' + cValToChar(nCompany)+ '</companyId>' + ;
              '<processId>' + cProcId             + '</processId>' + ;
              '<choosedState/>' + ;
              '<colleagueIds><item>'+cUser+'</item></colleagueIds>' + ;
              '<comments>Envio carteira</comments>' + ;
              '<userId>' + cUser + '</userId>' + ;
              '<completeTask>true</completeTask>' + ;
              '<attachments/>' + ;
              cCardData + ;
              '<appointment/>' + ;
              '<managerMode>false</managerMode>' + ;
            '</ws:startProcess>' + ;
          '</soapenv:Body>' + ;
        '</soapenv:Envelope>'

    AAdd(aHeaders,'User-Agent: Protheus '+GetBuild())
    AAdd(aHeaders,'Content-Type: text/xml; charset=UTF-8')
    AAdd(aHeaders,'SOAPAction: "startProcess"')
    AAdd(aHeaders,'Accept-Encoding: identity')
    AAdd(aHeaders,'Connection: Keep-Alive')

    cResp := HttpPost(cUrlFluig, "", cSoapXml, nTimeOut, aHeaders, @cHeadRet)
    MemoWrite(cLogDir+"fluig_resp_startProcess.txt", cResp)

    If !Empty(cResp) .and. "startProcessResponse"$cResp
        lSucesso := .T.
    EndIf

    If lSucesso
        ConOut("[ENVIAFLUIG] Envio OK. Atualizando status (RLock).")
        If Z0SetStsRL()
            MsgInfo("Enviado. Status agora 1 (Em Aprovação).")
            Return .T.
        Else
            ConOut("[ENVIAFLUIG] RLock falhou. Tentando Model.")
            If Z0SetStsMD(cCodigo, cCodVend)
                MsgInfo("Enviado. Status agora 1 (Model).")
                Return .T.
            Else
                MsgAlert("Envio OK, mas falha ao atualizar status.")
            EndIf
        EndIf
    Else
        MsgAlert("Falha no envio. Verifique log. Resp parcial: "+Left(cResp,120))
    EndIf

Return .F.

//-----------------------------------------------
// Atualiza status via RLock 
//-----------------------------------------------
Static Function Z0SetStsRL()
    Local cAlias := "SZ0"

    If Select(cAlias) == 0
        Return .F.
    EndIf

    DbSelectArea(cAlias)

   
    If (cAlias)->( RLock() )
        (cAlias)->Z0_STATUS := ST_EM_APROVACAO
        (cAlias)->( dbCommit() )
        (cAlias)->( dbUnlock() )
        Return .T.
    EndIf

Return .F.

//-----------------------------------------------
// Fallback via Model MVC
//-----------------------------------------------
Static Function Z0SetStsMD(cCodigo, cCodVend)
    Local oModel := FWLoadModel("MVC001")
    Local oSect, cKey

    If oModel == NIL
        Return .F.
    EndIf

    cKey := xFilial("SZ0") + PadR(cCodigo,6) + PadR(cCodVend,6) // 

    If ! FWFindKey(oModel,"SZ0MASTER",cKey)
        Return .F.
    EndIf

    oModel:SetOperation(4)
    oSect := oModel:GetModel("SZ0MASTER")
    oSect:SetValue("Z0_STATUS", ST_EM_APROVACAO)

    If oModel:CommitData()
        Return .T.
    EndIf
Return .F.

