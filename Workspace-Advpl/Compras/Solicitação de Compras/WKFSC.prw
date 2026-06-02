#Include "Protheus.ch"
#Include "TopConn.ch"

#Define SC_APROV_LIBERADO "L"
#Define SC_APROV_BLOQ     "B"

User Function SCENVFLU(cNumSC)
    Local lRet := .F.

    If Empty(cNumSC)
        Return .F.
    EndIf

    If SCBloq(cNumSC)
        lRet := SCStartFlu(cNumSC)
    EndIf

Return lRet

Static Function SCBloq (cNumSC)
	Local aArea  := GetArea()
	Local cAlias := GetNextAlias()
	Local cQry 	 := ""
	Local lRet   := .F.

	// Localiza todos os itens da solicitacao
	cQry := " SELECT R_E_C_N_O_ RECN "
    cQry += " FROM " + RetSqlName("SC1")
    cQry += " WHERE C1_FILIAL = '" + xFilial("SC1") + "'"
    cQry += " AND C1_NUM = '" + cNumSC + "'"
    cQry += " AND D_E_L_E_T_ = ' '"

	TCQuery cQry New Alias (cAlias)

	While !(cAlias)->(Eof())
		SC1->(DbGoTo((cAlias)->RECN))

		// Bloqueia a SC enquanto aguarda aprovacao
		If RecLock("SC1", .F.)
			SC1->C1_APROV := SC_APROV_BLOQ
			MsUnLock()
			lRet := .T.
		EndIf

		(cAlias)->(DbSkip())
	EndDo

	
	(cAlias)->(DbCloseArea())
	RestArea(aArea)	

Return lRet

Static Function SCStartFlu(cNumSC)
    Local cCardData 	:= ""
    Local cSoapXml  	:= ""
    Local cResp     	:= ""
    Local lRet      	:= .F.
    Local cAliasFornece := "SA2"
    Local cUrlFluig     := "http://fluig.local:8080/webdesk/ECMWorkflowEngineService"
    Local cUser         := "adm"
    Local cPass         := "Korus123"
    Local nCompany      := 2
    Local cProcId       := "ProcessoAprovacao"

    Local cCodigo       := ""
    Local cDescri       := ""
    Local cCodFornece   := ""
    Local cStatusLocal  := ""
    Local cVendNome     := ""
    Local cCardData     := ""
    Local cSoapXml      := ""
    Local aHeaders      := {}
    Local cHeadRet      := ""
    Local nTimeOut      := 120
    Local cResp         := ""
    Local cLogDir       := "\temp\"
    Local lSucesso      := .F.
    Local cComment      := ""

    ConOut("[ENVIAFLUIG] Inicio")

    cCodigo      	:= AllTrim((cAlias)->C1_NUM)
    cDescri      	:= AllTrim((cAlias)->C1_DESCRI)
    cCodFornece     := AllTrim((cAlias)->C1_FORNECE)
    cStatusLocal 	:= AllTrim((cAlias)->C1_XSTATUS)

    DbSelectArea(cCodFornece)
    cForneceNome := AllTrim((cCodFornece)->A2_NOME)

    If Empty(cCodigo) .or. Empty(cDescri) .or. Empty(cCodFornece)
        MsgAlert("Preencha Codigo, Descricao e Fornecedor antes de enviar.")
        Return .F.
    EndIf

    If !( cStatusLocal $ ( ST_NOVO + ST_REPROVADO ) )
        MsgAlert("Este cadastro esta em aprovacao. Aguarde a finalizacao da aprovacao antes de reenviar.")
        Return .F.
    EndIf

    // Alterado: prompt de confirmacao
    If ! MsgYesNo("Solicitar aprovacao da carteira "+cCodigo+"?", "Solicitar aprovacao")
        Return .F.
    EndIf

    ConOut("[ENVIAFLUIG] COD="+cCodigo+" STATUS="+cStatusLocal)

    cCardData := ;
        '<cardData>' + ;
          '<item><item>C1_NUM</item><item>'+cCodigo   +'</item></item>' + ;
          '<item><item>C1_DESCRI</item><item>'+cDescri   +'</item></item>' + ;
          '<item><item>C1_FORNECE</item><item>'+cCodFornece  +'</item></item>' + ;
          '<item><item>C1_XSTATUS</item><item>'+cStatusLocal+'</item></item>' + ;
          '<item><item>A2_NOME</item><item>'+cForneceNome+'</item></item>' + ;
          '<item><item>fluigInstId</item><item></item></item>' + ;
        '</cardData>'

    // Comentario inicial permanece descritivo
    cComment := "Abertura de solicitacao de aprovacao da carteira. " + ;
                      "Codigo "+cCodigo+", Descricao '"+cDescri+"', Vendedor "+cCodFornece+" - "+cVendNome+ ;
                      ". Status inicial=Novo."

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
              '<comments>'+cComment+'</comments>' + ;
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
            FWAlertInfo("Solicitacao enviada para aprovacao. Acompanhe o andamento no Fluig.", "Solicitar aprovacao")
            Return .T.
        Else
            ConOut("[ENVIAFLUIG] RLock falhou. Tentando Model.")
            If Z0SetStsMD(cCodigo, cCodFornece)
                FWAlertInfo("Solicitacao enviada para aprovacao. Acompanhe o andamento no Fluig.", "Solicitar aprovacao")
                Return .T.
            Else
                MsgAlert("Envio OK, mas nao foi possivel atualizar o status local.")
            EndIf
        EndIf
    Else
        MsgAlert("Nao foi possivel enviar a solicitacao. Verifique o log. Resp parcial: "+Left(cResp,120))
    EndIf

Return .F.
    // Monta dados da solicitacao para o processo Fluig
    cCardData := SCMontaCard(cNumSC)

    // Proximo bloco: montar XML startProcess
    // Use o ENVIAFLUIG como base, trocando Z0_* por C1_*
    
Return lRet


Static Function SCMontaCard(cNumSC)
    Local cCard := ""

    // Dados que serao enviados para o formulario do Fluig
    cCard := '<cardData>' + ;
        '<item><item>C1_NUM</item><item>' + AllTrim(cNumSC) + '</item></item>' + ;
        '<item><item>C1_FILIAL</item><item>' + xFilial("SC1") + '</item></item>' + ;
    '</cardData>'

Return cCard
