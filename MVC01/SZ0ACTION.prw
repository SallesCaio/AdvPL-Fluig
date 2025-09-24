#Include "Protheus.ch"
#Include "FwMVCDef.ch"

#Include "Protheus.ch"
#Include "FwMVCDef.ch"

// ========================
// FUNÇÃO DE ENVIO DE E-MAIL VIA PE
// ========================
// Observação importante:
// - NUNCA acesse campos "nus" (Z0_DESCRI, Z0_STATUS, etc.) no contexto WS.
// - SEMPRE use o model recebido (aParam[1]) e a seção 'SZ0MASTER'.
// - Removidas inicializações Static com acesso a campos.
// - FWAlertInfo trocado por ConOut (WS não tem UI).
// - Mantida lógica de e-mail.

User Function SZ0MODEL()
    Local aParam   := PARAMIXB
    Local xRet     := .T.

    Local oObj, cIdPonto, nOp
    Local oSect

    Local cDescri   := ""
    Local cCodVend  := ""
    Local cCodigo   := ""
    Local cHTML     := ""
    Local cNomeVend := ""
    Local aArea     := NIL

    // Valores "anteriores" para comparação em alteração
    Static cDescriAnt   := ""
    Static cCodVendAnt  := ""
    Static cNomeVendAnt := ""

    If aParam == NIL
        Return xRet
    EndIf

    oObj     := aParam[1]              // objeto do Model
    cIdPonto := aParam[2]              // identificador do evento (MODELPRECOMMITNTTS/MODELCOMMITNTTS/etc.)
    If ValType(oObj) <> "O"
        Return xRet
    EndIf

    nOp   := oObj:GetOperation()       // 3 = Incluir, 4 = Alterar, 5 = Excluir
    oSect := oObj:GetModel("SZ0MASTER")
    If ValType(oSect) <> "O"
        ConOut("SZ0MODEL: Seção 'SZ0MASTER' não encontrada no model.")
        Return xRet
    EndIf

    // ------------- INCLUSÃO: pós-commit (fora de transação)
    If cIdPonto == "MODELCOMMITNTTS" .and. nOp == 3

        // Define status inicial, se vazio (pelo Model)
        If Empty(AllTrim(oSect:GetValue("Z0_STATUS")))
            oSect:SetValue("Z0_STATUS", "0")
        EndIf

        // Captura campos do registro incluído pelo Model
        cDescri  := oSect:GetValue("Z0_DESCRI")
        cCodVend := oSect:GetValue("Z0_CODVEN")
        cCodigo  := oSect:GetValue("Z0_CODIGO")

        // Busca nome do vendedor
        Do Case
        Case !Empty(AllTrim(cCodVend))
            aArea := FWGetArea()
            DbSelectArea("SA3")
            If DbSeek(xFilial("SA3") + cCodVend)
                cNomeVend := SA3->A3_NOME
            Else
                cNomeVend := "Vendedor não encontrado"
            EndIf
            FWRestArea(aArea)
        Otherwise
            cNomeVend := "Vendedor não informado"
        EndCase

        // Monta corpo HTML do e-mail
        cHTML := ;
        '<html><head><style type="text/css">' + ;
        'body{font-family:Arial,Helvetica,sans-serif;background:#f6f6f6;margin:0;padding:0}' + ;
        '.container{background:#fff;max-width:600px;margin:40px auto;border-radius:8px;box-shadow:0 2px 8px #e0e0e0;padding:32px}' + ;
        'h2{color:#004080;padding:24px;text-align:center}.info{font-size:16px;margin-bottom:18px}' + ;
        '.label{color:#555;font-weight:bold}.value{color:#222}.footer{margin-top:32px;font-size:14px;color:#888}' + ;
        '.signature{margin-top:16px;font-size:15px;color:#004080;font-weight:bold}.logo{display:block;margin:0 auto 24px;max-width:180px}' + ;
        '</style></head><body><div class="container">' + ;
        '<img src="https://korustec.com.br/korus-logo-header.webp" alt="Logo da Empresa" class="logo">' + ;
        '<h2>Aviso: Novo registro incluído na Carteira</h2>' + ;
        '<div class="info"><span class="label">Código:</span> <span class="value">' + cCodigo  + '</span></div>' + ;
        '<div class="info"><span class="label">Descrição:</span> <span class="value">' + cDescri  + '</span></div>' + ;
        '<div class="info"><span class="label">Código do Vendedor:</span> <span class="value">' + cCodVend + '</span></div>' + ;
        '<div class="info"><span class="label">Nome do Vendedor:</span> <span class="value">' + cNomeVend+ '</span></div>' + ;
        '<hr style="margin:24px 0;border:0;border-top:1px solid #eee;">' + ;
        '<div class="info">Este é um <strong>e-mail automático</strong> gerado pelo <span style="color:#c00;">ERP Protheus</span>.</div>' + ;
        '<div class="footer">Atenciosamente,<br><span class="signature">Equipe de Suporte</span><br>' + ;
        '<span>Data: <em>' + dToC(Date()) + '</em> às <em>' + Time() + '</em></span></div>' + ;
        '</div></body></html>'

        // Envio de e-mail
        fEnvia("caio.silva@korusconsultoria.com.br", "Novo Registro Incluído", cHTML, {}, .T., .T.)
        If fEnvia("caio.silva@korusconsultoria.com.br", "Novo Registro Incluído", cHTML, {}, .T., .T.)
        FWAlertInfo("Registro Incluído e enviado pro E-Mail.", "Sucesso")
        Else
        FWAlertInfo("Registro Incluído, mas houve falha no envio de e-mail.", "Atenção")
        EndIf
        Return xRet
    EndIf

    // ------------- EXCLUSÃO: pós-commit (fora de transação)
    If cIdPonto == "MODELCOMMITNTTS" .and. nOp == 5
        cDescri  := oSect:GetValue("Z0_DESCRI")
        cCodVend := oSect:GetValue("Z0_CODVEN")
        cCodigo  := oSect:GetValue("Z0_CODIGO")

        aArea := FWGetArea()
        DbSelectArea("SA3")
        If DbSeek(xFilial("SA3") + cCodVend)
            cNomeVend := SA3->A3_NOME
        Else
            cNomeVend := "Vendedor não encontrado"
        EndIf
        FWRestArea(aArea)

        cHTML := ;
        '<html><head><style type="text/css">' + ;
        'body{font-family:Arial,Helvetica,sans-serif;background:#f6f6f6;margin:0;padding:0}' + ;
        '.container{background:#fff;max-width:600px;margin:40px auto;border-radius:8px;box-shadow:0 2px 8px #e0e0e0;padding:32px}' + ;
        'h2{color:#c00;padding:24px;text-align:center}.info{font-size:16px;margin-bottom:18px}' + ;
        '.label{color:#555;font-weight:bold}.value{color:#222}.footer{margin-top:32px;font-size:14px;color:#888}' + ;
        '.signature{margin-top:16px;font-size:15px;color:#c00;font-weight:bold}.logo{display:block;margin:0 auto 24px;max-width:180px}' + ;
        '</style></head><body><div class="container">' + ;
        '<img src="https://korustec.com.br/korus-logo-header.webp" alt="Logo da Empresa" class="logo">' + ;
        '<h2>Aviso: Registro excluído da Carteira</h2>' + ;
        '<div class="info"><span class="label">Código:</span> <span class="value">' + cCodigo  + '</span></div>' + ;
        '<div class="info"><span class="label">Descrição:</span> <span class="value">' + cDescri  + '</span></div>' + ;
        '<div class="info"><span class="label">Código do Vendedor:</span> <span class="value">' + cCodVend + '</span></div>' + ;
        '<div class="info"><span class="label">Nome do Vendedor:</span> <span class="value">' + cNomeVend+ '</span></div>' + ;
        '<hr style="margin:24px 0;border:0;border-top:1px solid #eee;">' + ;
        '<div class="info">Este é um <strong>e-mail automático</strong> gerado pelo <span style="color:#c00;">ERP Protheus</span>.</div>' + ;
        '<div class="footer">Atenciosamente,<br><span class="signature">Equipe de Suporte</span><br>' + ;
        '<span>Data: <em>' + dToC(Date()) + '</em> às <em>' + Time() + '</em></span></div>' + ;
        '</div></body></html>'

        fEnvia("caio.silva@korusconsultoria.com.br", "Registro Excluído", cHTML, {}, .T., .T.)
        If fEnvia("caio.silva@korusconsultoria.com.br", "Registro Excluído", cHTML, {}, .T., .T.)
        FWAlertInfo("Registro Excluído e enviado pro E-Mail.", "Sucesso")
        Else
        FWAlertInfo("Registro Excluído, mas houve falha no envio de e-mail.", "Atenção")
        EndIf
        Return xRet
    EndIf

    // ------------- ALTERAÇÃO: pré-commit (captura VALORES ANTIGOS)
    If cIdPonto == "MODELPRECOMMITNTTS" .and. nOp == 4
        cCodigo := oSect:GetValue("Z0_CODIGO")

        aArea := FWGetArea()
        DbSelectArea("SZ0")
        If DbSeek(xFilial("SZ0") + cCodigo)
            cDescriAnt  := SZ0->Z0_DESCRI
            cCodVendAnt := SZ0->Z0_CODVEN
        Else
            cDescriAnt  := ""
            cCodVendAnt := ""
            cNomeVendAnt:= ""
        EndIf
        FWRestArea(aArea)

        Return xRet
    EndIf

    // ------------- ALTERAÇÃO: pós-commit (comparação ANTIGO x NOVO)
    If cIdPonto == "MODELCOMMITNTTS" .and. nOp == 4
        cDescriNovo  := oSect:GetValue("Z0_DESCRI")
        cCodVendNovo := oSect:GetValue("Z0_CODVEN")
        cCodigoNovo  := oSect:GetValue("Z0_CODIGO")

        aArea := FWGetArea()
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
        FWRestArea(aArea)

        cHTML := ;
        '<html><head><style type="text/css">' + ;
        'body{font-family:Arial,Helvetica,sans-serif;background:#f6f6f6;margin:0;padding:0}' + ;
        '.container{background:#fff;max-width:600px;margin:40px auto;border-radius:8px;box-shadow:0 2px 8px #e0e0e0;padding:32px}' + ;
        'h2{color:#007b00;padding:24px;text-align:center}.info{font-size:16px;margin-bottom:18px}' + ;
        '.label{color:#555;font-weight:bold}.value{color:#222}.changed{background:#ffe9e9;color:#c00;padding:2px 6px;border-radius:4px}' + ;
        '.footer{margin-top:32px;font-size:14px;color:#888}.signature{margin-top:16px;font-size:15px;color:#007b00;font-weight:bold}.logo{display:block;margin:0 auto 24px;max-width:180px}' + ;
        '</style></head><body><div class="container">' + ;
        '<img src="https://korustec.com.br/korus-logo-header.webp" alt="Logo da Empresa" class="logo">' + ;
        '<h2>Aviso: Registro alterado na Carteira</h2>' + ;
        '<div class="info"><span class="label">Código:</span> <span class="value">' + cCodigoNovo + '</span></div>' + ;
        '<div class="info"><span class="label">Descrição:</span> <span class="value">' + cDescriAnt + '</span> &rarr; <span class="value changed">' + cDescriNovo + '</span></div>' + ;
        '<div class="info"><span class="label">Código do Vendedor:</span> <span class="value">' + cCodVendAnt + '</span> &rarr; <span class="value changed">' + cCodVendNovo + '</span></div>' + ;
        '<div class="info"><span class="label">Nome do Vendedor:</span> <span class="value">' + cNomeVendAnt + '</span> &rarr; <span class="value changed">' + cNomeVendNovo + '</span></div>' + ;
        '<hr style="margin:24px 0;border:0;border-top:1px solid #eee;">' + ;
        '<div class="info">Este é um <strong>e-mail automático</strong> gerado pelo <span style="color:#c00;">ERP Protheus</span>.</div>' + ;
        '<div class="footer">Atenciosamente,<br><span class="signature">Equipe de Suporte</span><br>' + ;
        '<span>Data: <em>' + dToC(Date()) + '</em> às <em>' + Time() + '</em></span></div>' + ;
        '</div></body></html>'

        fEnvia("caio.silva@korusconsultoria.com.br", "Registro Alterado", cHTML, {}, .T., .T.)
        If fEnvia("caio.silva@korusconsultoria.com.br", "Registro Alterado", cHTML, {}, .T., .T.)
        FWAlertInfo("Registro Alterado e enviado pro E-Mail.", "Sucesso")
        Else
        FWAlertInfo("Registro Alterado, mas houve falha no envio de e-mail.", "Atenção")
        EndIf
        Return xRet
    EndIf

Return xRet


// ========================
// FUNÇÃO AUXILIAR DE ENVIO DE E-MAIL
// ========================
Static Function fEnvia(cPara, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTLS)
    Local aArea := FWGetArea()
    Local oMsg  := TMailMessage():New()
    Local oSrv  := TMailManager():New()
    Local lRet  := .T.
    Local cFrom := AllTrim(GetMV("MV_RELACNT"))
    Local cUser := SubStr(cFrom,1,At('@',cFrom)-1)
    Local cPass := AllTrim(GetMV("MV_RELPSW"))
    Local cSrvFull := AllTrim(GetMV("MV_RELSERV"))
    Local cServer := Iif(':' $ cSrvFull, SubStr(cSrvFull,1,At(':',cSrvFull)-1), cSrvFull)
    Local nPort  := Iif(':' $ cSrvFull, Val(SubStr(cSrvFull,At(':',cSrvFull)+1)), 587)
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

    oMsg:cFrom    := cFrom
    oMsg:cTo      := cPara
    oMsg:cSubject := cAssunto
    oMsg:cBody    := cCorpo

    For nAtual := 1 To Len(aAnexos)
        If File(aAnexos[nAtual])
            nRet := oMsg:AttachFile(aAnexos[nAtual])
        EndIf
    Next

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

Static Procedure _NotifyInfo(cMsg, cTitle)
   Default cTitle := "Sucesso"
   Begin Sequence
      // Mostra alerta quando houver interface (SmartClient/WebApp)
      FWAlertInfo(cMsg, cTitle)
   Recover
      // Em contexto sem UI (WS), registra no log
      ConOut(cTitle + ": " + cMsg)
   End Sequence
Return




/*




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






*/
 

 
