#Include "Protheus.ch"
#Include "FwMVCDef.ch"

// ========================
// FUNÇÃO DE ENVIO DE E-MAIL VIA PE
// ========================

User Function SZ0MODEL()
    Local aParam   := PARAMIXB
    Local xRet     := .T.
    Local oObj, cIdPonto, nOp
    Local cDescri, cCodVend, cCodigo
    Local cHTML
    Local cNomeVend

    If aParam <> NIL
        oObj     := aParam[1]              // objeto do Model
        cIdPonto := aParam[2]              // identificador do evento
        nOp      := oObj:GetOperation()    // 3 = Incluir, 4 = Alterar, 5 = Excluir

        // Depois de gravar, fora da transação, e somente na inclusão:
        If cIdPonto == "MODELCOMMITNTTS" .and. nOp == 3    

            // Define o status inicial como "0 - Novo"
            If Empty(Z0_STATUS)
            Z0_STATUS := "0"
            EndIf

            // Captura os campos do registro incluído
            //cStatus   := (Z0_STATUS)
            cDescri   := (Z0_DESCRI)
            cCodVend  := (Z0_CODVEN)
            cCodigo   := (Z0_CODIGO)
            cCodVend  := (cCodVend)

            // Captura o Status
            
            //cStatusDesc := StatusDesc(cStatus)

            // Chame aqui a função desejada
            //VisualizaOpcoesStatus()

            DbSelectArea("SA3")
            If DbSeek(xFilial("SA3") + cCodVend)
                cNomeVend := SA3->A3_NOME
            Else
                cNomeVend := "Vendedor não encontrado"
            EndIf

            // Monta corpo HTML do e-mail
            cHTML := ;
            '<html>' + ;
            '<head>' + ;
            '  <style type="text/css">' + ;
            '    body { font-family: Arial, Helvetica, sans-serif; background-color: #f6f6f6; margin:0; padding:0; }' + ;
            '    .container { background: #fff; max-width: 600px; margin: 40px auto; border-radius: 8px; box-shadow: 0 2px 8px #e0e0e0; padding: 32px; }' + ;
            '    h2 { color: #004080; padding: 24px; text-align: center; }' + ;
            '    .info { font-size: 16px; margin-bottom: 18px; }' + ;
            '    .label { color: #555; font-weight: bold; }' + ;
            '    .value { color: #222; }' + ;
            '    .footer { margin-top: 32px; font-size: 14px; color: #888; }' + ;
            '    .signature { margin-top: 16px; font-size: 15px; color: #004080; font-weight: bold; }' + ;
            '    .logo { display: block; margin: 0 auto 24px auto; max-width: 180px; }' + ;
            '  </style>' + ;
            '</head>' + ;
            '<body>' + ;
            '  <div class="container">' + ;
            '    <img src="https://korustec.com.br/korus-logo-header.webp" alt="Logo da Empresa" class="logo">' + ;
            '    <h2>Aviso: Novo registro incluído na Carteira</h2>' + ;
            '    <div class="info"><span class="label">Código:</span> <span class="value">' + cCodigo + '</span></div>' + ;
            '    <div class="info"><span class="label">Descrição:</span> <span class="value">' + cDescri + '</span></div>' + ;
            '    <div class="info"><span class="label">Código do Vendedor:</span> <span class="value">' + cCodVend + '</span></div>' + ;
            '    <div class="info"><span class="label">Nome do Vendedor:</span> <span class="value">' + cNomeVend + '</span></div>' + ;
            '    <hr style="margin:24px 0;border:0;border-top:1px solid #eee;">' + ;
            '    <div class="info">Este é um <strong>e-mail automático</strong> gerado pelo <span style="color:#c00;">ERP Protheus</span>.</div>' + ;
            '    <div class="footer">' + ;
            '      Atenciosamente,<br>' + ;
            '      <span class="signature">Equipe de Suporte</span><br>' + ;
            '      <span>Data: <em>' + dToC(Date()) + '</em> às <em>' + Time() + '</em></span>' + ;
            '    </div>' + ;
            '  </div>' + ;
            '</body>' + ;
            '</html>'

        
            // Chama função de envio
            fEnvia("caio.silva@korusconsultoria.com.br", "Novo Registro Incluído", cHTML, {}, .T., .T.)
            FWAlertInfo("Registro Incluído e enviado pro E-Mail.", "Sucesso")
        EndIf

        If cIdPonto == "MODELCOMMITNTTS" .and. nOp == 5
            // Captura os campos do registro excluído
            cDescri   := (Z0_DESCRI)
            cCodVend  := (Z0_CODVEN)
            cCodigo   := (Z0_CODIGO)
            cCodVend  := (cCodVend)
            DbSelectArea("SA3")
            If DbSeek(xFilial("SA3") + cCodVend)
                cNomeVend := SA3->A3_NOME
            Else
                cNomeVend := "Vendedor não encontrado"
            EndIf

            // Monta corpo HTML do e-mail para exclusão
            cHTML := ;
            '<html>' + ;
            '<head>' + ;
            '  <style type="text/css">' + ;
            '    body { font-family: Arial, Helvetica, sans-serif; background-color: #f6f6f6; margin:0; padding:0; }' + ;
            '    .container { background: #fff; max-width: 600px; margin: 40px auto; border-radius: 8px; box-shadow: 0 2px 8px #e0e0e0; padding: 32px; }' + ;
            '    h2 { color: #c00; padding: 24px; text-align: center; }' + ;
            '    .info { font-size: 16px; margin-bottom: 18px; }' + ;
            '    .label { color: #555; font-weight: bold; }' + ;
            '    .value { color: #222; }' + ;
            '    .footer { margin-top: 32px; font-size: 14px; color: #888; }' + ;
            '    .signature { margin-top: 16px; font-size: 15px; color: #c00; font-weight: bold; }' + ;
            '    .logo { display: block; margin: 0 auto 24px auto; max-width: 180px; }' + ;
            '  </style>' + ;
            '</head>' + ;
            '<body>' + ;
            '  <div class="container">' + ;
            '    <img src="https://korustec.com.br/korus-logo-header.webp" alt="Logo da Empresa" class="logo">' + ;
            '    <h2>Aviso: Registro excluído da Carteira</h2>' + ;
            '    <div class="info"><span class="label">Código:</span> <span class="value">' + cCodigo + '</span></div>' + ;
            '    <div class="info"><span class="label">Descrição:</span> <span class="value">' + cDescri + '</span></div>' + ;
            '    <div class="info"><span class="label">Código do Vendedor:</span> <span class="value">' + cCodVend + '</span></div>' + ;
            '    <div class="info"><span class="label">Nome do Vendedor:</span> <span class="value">' + cNomeVend + '</span></div>' + ;
            '    <hr style="margin:24px 0;border:0;border-top:1px solid #eee;">' + ;
            '    <div class="info">Este é um <strong>e-mail automático</strong> gerado pelo <span style="color:#c00;">ERP Protheus</span>.</div>' + ;
            '    <div class="footer">' + ;
            '      Atenciosamente,<br>' + ;
            '      <span class="signature">Equipe de Suporte</span><br>' + ;
            '      <span>Data: <em>' + dToC(Date()) + '</em> às <em>' + Time() + '</em></span>' + ;
            '    </div>' + ;
            '  </div>' + ;
            '</body>' + ;
            '</html>'

            // Chama função de envio
            fEnvia("caio.silva@korusconsultoria.com.br", "Registro Excluído", cHTML, {}, .T., .T.)
            FWAlertInfo("Registro Excluído e enviado pro E-Mail.", "Sucesso")
        EndIf

        Static cDescriAnt    := (Z0_DESCRI)
        Static cCodVendAnt   := ""
        Static cNomeVendAnt  := ""
        // Evento PRECOMMIT: captura os valores antes da alteração
        If cIdPonto == "MODELPRECOMMITNTTS" .and. nOp == 4
            cCodigo := (Z0_CODIGO)
            DbSelectArea("SZ0")
            If DbSeek(xFilial("SZ0") + cCodigo)
                cDescriAnt  :=  SZ0->Z0_DESCRI
                cCodVendAnt :=  SZ0->Z0_CODVEN
            Else
                cDescriAnt  :=  ""
                cCodVendAnt :=  ""
                cNomeVendAnt:=  ""
            EndIf
        EndIf

        If cIdPonto == "MODELCOMMITNTTS" .and. nOp == 4
            cDescriNovo  := (Z0_DESCRI)
            cCodVendNovo := (Z0_CODVEN)
            cCodigo      := (Z0_CODIGO)
            cCodVendNovo := (cCodVendNovo)
            DbSelectArea("SA3")
            If DbSeek(xFilial("SA3") + cCodVendAnt)
                cNomeVendAnt := SA3->A3_NOME
            Else
                cNomeVendAnt := "Vendedor não encontrado"
            EndIf
            If DbSeek(xFilial("SA3") + cCodVendNovo)
                cNomeVendNovo := SA3->A3_NOME
            Else
                cNomeVendNovo := "Vendedor não encontrado"
            EndIf


            // Monta corpo HTML do e-mail detalhando alterações
            cHTML := ;
            '<html>' + ;
            '<head>' + ;
            '  <style type="text/css">' + ;
            '    body { font-family: Arial, Helvetica, sans-serif; background-color: #f6f6f6; margin:0; padding:0; }' + ;
            '    .container { background: #fff; max-width: 600px; margin: 40px auto; border-radius: 8px; box-shadow: 0 2px 8px #e0e0e0; padding: 32px; }' + ;
            '    h2 { color: #007b00; padding: 24px; text-align: center; }' + ;
            '    .info { font-size: 16px; margin-bottom: 18px; }' + ;
            '    .label { color: #555; font-weight: bold; }' + ;
            '    .value { color: #222; }' + ;
            '    .changed { background: #ffe9e9; color: #c00; padding: 2px 6px; border-radius: 4px; }' + ;
            '    .footer { margin-top: 32px; font-size: 14px; color: #888; }' + ;
            '    .signature { margin-top: 16px; font-size: 15px; color: #007b00; font-weight: bold; }' + ;
            '    .logo { display: block; margin: 0 auto 24px auto; max-width: 180px; }' + ;
            '  </style>' + ;
            '</head>' + ;
            '<body>' + ;
            '  <div class="container">' + ;
            '    <img src="https://korustec.com.br/korus-logo-header.webp" alt="Logo da Empresa" class="logo">' + ;
            '    <h2>Aviso: Registro alterado na Carteira</h2>' + ;
            '    <div class="info"><span class="label">Código:</span> <span class="value">' + cCodigo + '</span></div>' + ;
            '    <div class="info"><span class="label">Descrição:</span> <span class="value">' + cDescriAnt + '</span> &rarr; <span class="value changed">' + cDescriNovo + '</span></div>' + ;
            '    <div class="info"><span class="label">Código do Vendedor:</span> <span class="value">' + cCodVendAnt + '</span> &rarr; <span class="value changed">' + cCodVendNovo + '</span></div>' + ;
            '    <div class="info"><span class="label">Nome do Vendedor:</span> <span class="value">' + cNomeVendAnt + '</span> &rarr; <span class="value changed">' + cNomeVendNovo + '</span></div>' + ;
            '    <hr style="margin:24px 0;border:0;border-top:1px solid #eee;">' + ;
            '    <div class="info">Este é um <strong>e-mail automático</strong> gerado pelo <span style="color:#c00;">ERP Protheus</span>.</div>' + ;
            '    <div class="footer">' + ;
            '      Atenciosamente,<br>' + ;
            '      <span class="signature">Equipe de Suporte</span><br>' + ;
            '      <span>Data: <em>' + dToC(Date()) + '</em> às <em>' + Time() + '</em></span>' + ;
            '    </div>' + ;
            '  </div>' + ;
            '</body>' + ;
            '</html>'

            // Chama função de envio
            fEnvia("caio.silva@korusconsultoria.com.br", "Registro Alterado", cHTML, {}, .T., .T.)
            FWAlertInfo("Registro Alterado e enviado pro E-Mail.", "Sucesso")
        EndIf
    EndIf
Return xRet

/*
Static Function SZ0ACTION(oModel, cIdPonto)
    Local oObj := oModel
    Local nOp := oObj:GetOperation()    // 3=Incluir, 4=Alterar, 5=Excluir
    Local cNome, cEmail, cCodigo
    Local cHTML

    // --- Somente após inclusão
    If cIdPonto == "MODELCOMMITNTTS" .And. nOp == 3
        // Captura os campos do registro incluído
        cNome   := oObj:GetField("Z0_CODIGO")   // código da carteira
        cEmail  := oObj:GetField("Z0_DESCRI")   // descrição
        cCodigo := oObj:GetField("Z0_CODVEN")   // código do vendedor

        // Monta corpo HTML do e-mail
        cHTML := "<html><body>" + ;
                 "<h2>Novo registro incluído na Carteira</h2>" + ;
                 "<p><strong>Código:</strong> " + cCodigo + "</p>" + ;
                 "<p><strong>Nome:</strong> " + cNome + "</p>" + ;
                 "<p><strong>Email:</strong> " + cEmail + "</p>" + ;
                 "</body></html>"

        // Chama função de envio
        fEnvia("caio.silva@korusconsultoria.com.br", "Novo Registro Incluído", cHTML, {}, .T., .T.)
    EndIf

Return .T.
*/

// ========================
// FUNÇÃO AUXILIAR DE ENVIO DE E-MAIL
// ========================
Static Function fEnvia(cPara, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTLS)
    Local aArea := FWGetArea()
    Local oMsg  := TMailMessage():New()
    Local oSrv  := TMailManager():New()
    Local lRet  := .T.
    Local cLog  := ""
    Local cFrom := AllTrim(GetMV("MV_RELACNT"))
    Local cUser := SubStr(cFrom,1,At('@',cFrom)-1)
    Local cPass := AllTrim(GetMV("MV_RELPSW"))
    Local cSrvFull := AllTrim(GetMV("MV_RELSERV"))
    Local cServer := Iif(':' $ cSrvFull, SubStr(cSrvFull,1,At(':',cSrvFull)-1), cSrvFull)
    Local nPort  := Iif(':' $ cSrvFull, Val(SubStr(cSrvFull,At(':',cSrvFull)+1,Len(cSrvFull))), 587)
    Local nTimeOut := GetMV("MV_RELTIME")
    Local nAtual := 0
    Local nRet := 0

    Default cPara      := ""
    Default cAssunto   := ""
    Default cCorpo     := ""
    Default aAnexos    := {}
    Default lMostraLog := .F.
    Default lUsaTLS    := .F.

    If Empty(cPara) .Or. Empty(cAssunto) .Or. Empty(cCorpo)
        FWRestArea(aArea)
        Return .F.
    EndIf

    // --- Monta mensagem
    oMsg:cFrom    := cFrom
    oMsg:cTo      := cPara
    oMsg:cSubject := cAssunto
    oMsg:cBody    := cCorpo

    // --- Anexa arquivos, se houver
    For nAtual := 1 To Len(aAnexos)
        If File(aAnexos[nAtual])
            nRet := oMsg:AttachFile(aAnexos[nAtual])
            If nRet < 0
                cLog += "002 - Não foi possível anexar o arquivo '"+aAnexos[nAtual]+"'!" + CRLF
            EndIf
        Else
            cLog += "003 - Arquivo '"+aAnexos[nAtual]+"' não encontrado!" + CRLF
        EndIf
    Next

    // --- Configura servidor SMTP
    oSrv := TMailManager():New()
    If lUsaTLS
        oSrv:SetUseTLS(.T.)
    EndIf

    nRet := oSrv:Init("", cServer, cUser, cPass, 0, nPort)
    If nRet == 0
        oSrv:SetSMTPTimeout(nTimeOut)
        If oSrv:SMTPConnect() == 0
            If oSrv:SmtpAuth(cFrom, cPass) == 0
                lRet := (oMsg:Send(oSrv) == 0)
            Else
                lRet := .F.
            EndIf
            oSrv:SMTPDisconnect()
        Else
            lRet := .F.
        EndIf
    Else
        lRet := .F.
    EndIf

    FWRestArea(aArea)
Return lRet

Static Function SendWorkflow(cCodigo, cDescri, cCodVend, cNomeVend)
    Local cUrlFluig := "https://lab.fluig.com/webdesk/ECMWorkflowEngineService"
    Local cUser := "academy.aluno"
    Local cPass := "academy.aluno"
    Local cCardData, cSoapXml, cRetorno
    Local lOk := .F.

    // Monta o cardData
    cCardData := ;
        '<cardData>' + ;
            '<item><item>Z0_CODIGO</item><item>' + cCodigo + '</item></item>' + ;
            '<item><item>ZO_DESCRI</item><item>' + cDescri + '</item></item>' + ;
            '<item><item>Z0_CODVEN</item><item>' + cCodVend + '</item></item>' + ;
            '<item><item>Z0_NOMEVEN</item><item>' + cNomeVend + '</item></item>' + ;
        '</cardData>'

    // Monta o SOAP
    cSoapXml := ;
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
        '<comments>Solicitação Protheus</comments>' + ;
        '<userId>' + cUser + '</userId>' + ;
        '<completeTask>true</completeTask>' + ;
        '<attachments/>' + ;
        cCardData + ;
        '<appointment/>' + ;
        '<managerMode>false</managerMode>' + ;
        '</ws:startProcess>' + ;
        '</soapenv:Body>' + ;
        '</soapenv:Envelope>'

    // Chamada SOAP (exemplo usando HttpPost, pode ser WSCALL ou WSCLIENT)
    cRetorno := HttpPost(cUrlFluig, cSoapXml, "text/xml") // Ajuste para sua função de envio SOAP

    // Verifique se cRetorno contém sucesso
    If !Empty(cRetorno) .and. "startProcessResponse" $ cRetorno
        lOk := .T.
    EndIf

Return lOk

/*
Static Function AfterCreateBrowse(oBrowse)
    oBrowse:AddColumn("Status", {|oRec| StatusDesc(oRec:Z0_STATUS)})
Return
*/

/*
Static Function VisualizaOpcoesStatus()
    Local cCampo := PadR("Z0_STATUS", 10)
    Local aExeX3Arr := X3CboxToArray(cCampo)
    Local cConteudo := ""
    Local nI

    For nI := 1 To Len(aExeX3Arr)
        cConteudo += aExeX3Arr[nI][1] + " - " + aExeX3Arr[nI][2] + CRLF
    Next

    FWAlertInfo("Opções do Status:\n" + cConteudo, "Visualização ComboBox")
Return
*/

/*
Static Function StatusDesc(cStatus)
    Local cCampo := "Z0_STATUS"
    Local cDescricao := X3Combo(cCampo, cStatus)
    If Empty(cDescricao)
        cDescricao := "Status desconhecido"
    EndIf
Return cDescricao
*/

/*
Static Function StatusDesc(cStatus)
    Local aStatus := { ;
        { "0", "Novo" }, ;
        { "1", "Em aprovação" }, ;
        { "2", "Aprovado" }, ;
        { "3", "Não Aprovado" }, ;
        { "4", "Corrigir" }, ;
        { "5", "Erro Integração" } ;
    }
    Local cDesc := ""
    Local nIdx

    For nIdx := 1 To Len(aStatus)
        If aStatus[nIdx][1] == AllTrim(cStatus)
            cDesc := aStatus[nIdx][2] // Só a descrição!
            Exit
        EndIf
    Next

    If Empty(cDesc)
        cDesc := "Status desconhecido"
    EndIf

Return cDesc

/*
User Function X3CBoxArr()
    Local aArea      := FWGetArea()
    Local cCampo     := ""
    Local aExeX3Arr  := {}
 
    //Exemplo 1, combo box com opções comuns
    cCampo     := PadR("Z0_STATUS", 10)
    aExeX3Arr  := X3CboxToArray(cCampo)
    FWAlertInfo("O conteúdo do combo é: " + ArrayToStr(aExeX3Arr), "Teste 1 X3CBox, TkSX3Box e X3CboxToArray")

        FWRestArea(aArea)
Return
*/
 

 
