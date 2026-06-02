#Include "Protheus.ch"
#Include "FwMVCDef.ch"

#Define ST_NOVO          "0"
#Define ST_EM_APROVACAO  "1"
#Define ST_APROVADO      "2"
#Define ST_REPROVADO     "3"


Static cOldCodigo   := ""
Static cOldDescri   := ""
Static cOldCodVend  := ""
Static cOldNomeVend := ""


User Function SZ0MODEL()
    Local aParam := PARAMIXB
    Local xRet   := .T.
    Local oObj, cIdPonto, nOp, oSect
    Local aOld := {}, aNew := {}

    If Empty(aParam)
        Return xRet
    EndIf

    oObj     := aParam[1]
    cIdPonto := aParam[2]

    If ValType(oObj) <> "O"
        Return xRet
    EndIf

    nOp   := oObj:GetOperation()   // 3 Inclui / 4 Altera / 5 Exclui
    oSect := oObj:GetModel("SZ0MASTER")
    If ValType(oSect) <> "O"
        ConOut("SZ0MODEL: Sessao SZ0MASTER nao encontrada.")
        Return xRet
    EndIf

    
    If cIdPonto == "MODELCOMMITNTTS" .And. nOp == 3
        If Empty(AllTrim(oSect:GetValue("Z0_STATUS")))
            oSect:SetValue("Z0_STATUS", ST_NOVO)
        EndIf
        aNew := U_Z0_BUILDARR( ;
                 oSect:GetValue("Z0_CODIGO"), ;
                 oSect:GetValue("Z0_DESCRI"), ;
                 oSect:GetValue("Z0_CODVEN") )
        U_Z0_ENRICHVEND(@aNew)
        U_Z0_SENDMAIL("INC", {}, aNew)
        Return xRet
    EndIf

    
    If cIdPonto == "MODELPRECOMMITNTTS" .And. nOp == 4
        Z0_CaptureOld()
        Return xRet
    EndIf

    
    If cIdPonto == "MODELCOMMITNTTS" .And. nOp == 4
        aOld := U_Z0_BUILDARR(cOldCodigo, cOldDescri, cOldCodVend)
        U_Z0_SETVAR(aOld,"Z0_NOMEVEN", cOldNomeVend)

        aNew := U_Z0_BUILDARR( ;
                  oSect:GetValue("Z0_CODIGO"), ;
                  oSect:GetValue("Z0_DESCRI"), ;
                  oSect:GetValue("Z0_CODVEN") )
        U_Z0_ENRICHVEND(@aNew)

        U_Z0_SENDMAIL("ALT", aOld, aNew)

        // Limpa snapshot
        cOldCodigo   := ""
        cOldDescri   := ""
        cOldCodVend  := ""
        cOldNomeVend := ""
        Return xRet
    EndIf

Return xRet

/* ===================== CAPTURA DOS VALORES ANTIGOS ================== */
Static Function Z0_CaptureOld()
    Local aArea := FWGetArea()
    DbSelectArea("SZ0")
    cOldCodigo   := SZ0->Z0_CODIGO
    cOldDescri   := SZ0->Z0_DESCRI
    cOldCodVend  := SZ0->Z0_CODVEN
    cOldNomeVend := Z0_VendName(cOldCodVend)
    FWRestArea(aArea)
Return

/* ===================== NOME DO VENDEDOR ================== */
Static Function Z0_VendName(cCodVend)
    Local aArea, cNome := ""
    If Empty(cCodVend)
        Return "Vendedor nao informado"
    EndIf
    aArea := FWGetArea()
    DbSelectArea("SA3")
    If DbSeek(xFilial("SA3")+cCodVend)
        cNome := SA3->A3_NOME
    Else
        cNome := "Vendedor nao encontrado"
    EndIf
    FWRestArea(aArea)
Return cNome

/* ===================== BUILD / ENRICH / GET / SET ================== */
User Function Z0_BUILDARR(cCodigo, cDescri, cCodVend)
    Local a := {}
    AAdd(a, {"Z0_CODIGO", cCodigo})
    AAdd(a, {"Z0_DESCRI", cDescri})
    AAdd(a, {"Z0_CODVEN", cCodVend})
Return a

User Function Z0_ENRICHVEND(aArr)
    Local cCodVend := U_Z0_GETVAL(aArr,"Z0_CODVEN")
    Local cNomeVend := Z0_VendName(cCodVend)
    U_Z0_SETVAR(aArr,"Z0_NOMEVEN", cNomeVend)
Return

User Function Z0_GETVAL(aArr,cCampo)
    Local n
    For n := 1 To Len(aArr)
        If aArr[n][1] == cCampo
            Return aArr[n][2]
        EndIf
    Next
Return ""

User Function Z0_SETVAR(aArr,cCampo,xValor)
    Local n
    For n := 1 To Len(aArr)
        If aArr[n][1] == cCampo
            aArr[n][2] := xValor
            Return
        EndIf
    Next
    AAdd(aArr,{cCampo,xValor})
Return

/* ===================== ENVIO (ALTO NÍVEL) ================== */
User Function Z0_SENDMAIL(cTipo, aOld, aNew)
    Local cAssunto, cHtml
    Local lOk := .F.

    Do Case
    Case cTipo == "INC" ; cAssunto := "Novo Registro - Carteira"
    Case cTipo == "ALT" ; cAssunto := "Registro Alterado - Carteira"
    Case cTipo == "DEL" ; cAssunto := "Registro Excluido - Carteira"
    Otherwise            ; cAssunto := "Evento Carteira"
    EndCase

    cHtml := U_Z0_HTML(cTipo, aOld, aNew)
    If ! Empty(cHtml)
        lOk := U_Z0_MAILSEND("caio.silva@korusconsultoria.com.br", ;
                              cAssunto, cHtml, {}, .F., .T.)
    EndIf
Return lOk

/* ===================== HTML ================== */
User Function Z0_HTML(cTipo, aOld, aNew)
    Local cColorTit, cColorNew, cColorOld
    Local cCOld := U_Z0_GETVAL(aOld,"Z0_CODIGO")
    Local cDOld := U_Z0_GETVAL(aOld,"Z0_DESCRI")
    Local cVOld := U_Z0_GETVAL(aOld,"Z0_CODVEN")
    Local cNOld := U_Z0_GETVAL(aOld,"Z0_NOMEVEN")

    Local cCNew := U_Z0_GETVAL(aNew,"Z0_CODIGO")
    Local cDNew := U_Z0_GETVAL(aNew,"Z0_DESCRI")
    Local cVNew := U_Z0_GETVAL(aNew,"Z0_CODVEN")
    Local cNNew := U_Z0_GETVAL(aNew,"Z0_NOMEVEN")

    Local cTitulo, cBody := ""

    Do Case
    Case cTipo == "INC"
        cColorTit := "#004080"
    Case cTipo == "ALT"
        cColorTit := "#007b00"
    Case cTipo == "DEL"
        cColorTit := "#c00000"
    Otherwise
        cColorTit := "#004080"
    EndCase
    cColorNew := "#c00"
    cColorOld := "#555"

    Do Case
    Case cTipo == "INC"
        cTitulo := "Aviso: Novo registro incluido na Carteira"
        cBody += Z0_Line("Codigo:", cCNew)
        cBody += Z0_Line("Descricao:", cDNew)
        cBody += Z0_Line("Codigo do Vendedor:", cVNew)
        cBody += Z0_Line("Nome do Vendedor:", cNNew)

    Case cTipo == "DEL"
        cTitulo := "Aviso: Registro excluido da Carteira"
        cBody += Z0_Line("Codigo:", cCOld)
        cBody += Z0_Line("Descricao:", cDOld)
        cBody += Z0_Line("Codigo do Vendedor:", cVOld)
        cBody += Z0_Line("Nome do Vendedor:", cNOld)

    Case cTipo == "ALT"
        cTitulo := "Aviso: Registro alterado na Carteira"
        cBody += Z0_Diff("Codigo:", cCOld, cCNew, .F.)
        cBody += Z0_Diff("Descricao:", cDOld, cDNew)
        cBody += Z0_Diff("Codigo do Vendedor:", cVOld, cVNew)
        cBody += Z0_Diff("Nome do Vendedor:", cNOld, cNNew)

    Otherwise
        cTitulo := "Evento Carteira"
        cBody   += Z0_Line("Codigo:", cCNew)
    EndCase

Return ;
    '<html><head><style>' + ;
    'body{font-family:Arial,Helvetica,sans-serif;background:#f6f6f6;margin:0;padding:0}' + ;
    '.container{background:#fff;max-width:640px;margin:40px auto;border-radius:8px;box-shadow:0 2px 8px #dadada;padding:36px}' + ;
    'h2{margin:0 0 28px 0;text-align:center;font-weight:600;color:' + cColorTit + '}' + ;
    '.row{font-size:15px;margin:10px 0}' + ;
    '.lbl{color:#004080;font-weight:bold;display:inline-block;min-width:160px}' + ;
    '.val{color:#222;font-weight:600}' + ;
    '.old{background:#fafafa;color:' + cColorOld + ';padding:2px 6px;border:1px solid #ccc;border-radius:4px}' + ;
    '.new{background:#ffe4e4;color:' + cColorNew + ';padding:2px 6px;border:1px solid #f5b5b5;border-radius:4px}' + ;
    'hr{margin:30px 0;border:0;border-top:1px solid #e1e1e1}' + ;
    '.footer{font-size:13px;color:#666;line-height:1.5}' + ;
    '.signature{margin-top:16px;font-size:14px;font-weight:bold;color:#004080}' + ;
    '.logo{display:block;margin:0 auto 18px;max-width:170px}' + ;
    '</style></head><body><div class="container">' + ;
    '<img class="logo" src="https://korustec.com.br/korus-logo-header.webp">' + ;
    '<h2>'+cTitulo+'</h2>' + ;
    cBody + ;
    '<hr>' + ;
    '<div class="footer">Este e um <strong>e-mail automatico</strong> gerado pelo <span style="color:#c00;">ERP Protheus</span>.' + ;
    '<div class="signature">Equipe de Suporte</div>' + ;
    'Data: <em>'+dToC(Date())+'</em> as <em>'+Time()+'</em></div>' + ;
    '</div></body></html>'

/* ===================== HELPERS (STATIC) ================== */
Static Function Z0_Line(cLabel,cVal)
Return '<div class="row"><span class="lbl">'+cLabel+'</span><span class="val">'+ ;
       Iif(Empty(cVal),"-",cVal) + '</span></div>'

Static Function Z0_Diff(cLabel,cOld,cNew,lAlwaysShowOld)
    Local cRet := '<div class="row"><span class="lbl">'+cLabel+'</span>'
    Default lAlwaysShowOld := .T.
    If cOld == cNew .And. ! lAlwaysShowOld
        cRet += '<span class="val">'+Iif(Empty(cNew),"-",cNew)+'</span></div>'
    Else
        cRet += '<span class="old">'+Iif(Empty(cOld),"-",cOld)+'</span> &rarr; ' + ;
                '<span class="new">'+Iif(Empty(cNew),"-",cNew)+'</span></div>'
    EndIf
Return cRet

/* ===================== ENVIO SMTP ================== */
    User Function Z0_MAILSEND(cPara, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTLS)
        Local aArea := FWGetArea()
        Local oMsg  := TMailMessage():New()
        Local oSrv  := TMailManager():New()
        Local lRet  := .T.
        Local cFrom := AllTrim(GetMV("MV_RELACNT"))
        Local cUser := Iif("@"$cFrom, SubStr(cFrom,1,At('@',cFrom)-1), cFrom)
        Local cPass := AllTrim(GetMV("MV_RELPSW"))
        Local cSrvFull := AllTrim(GetMV("MV_RELSERV"))
        Local cServer := Iif(':' $ cSrvFull, SubStr(cSrvFull,1,At(':',cSrvFull)-1), cSrvFull)
        Local nPort  := Iif(':' $ cSrvFull, Val(SubStr(cSrvFull,At(':',cSrvFull)+1)), 587)
        Local nTimeOut := GetMV("MV_RELTIME")
        Local nAt, nRet

        Default cPara      := ""
        Default cAssunto   := ""
        Default cCorpo     := ""
        Default aAnexos    := {}
        Default lMostraLog := .F.
        Default lUsaTLS    := .T.

        If Empty(cPara) .Or. Empty(cAssunto) .Or. Empty(cCorpo)
            FWRestArea(aArea)
            Return .F.
        EndIf

        oMsg:cFrom    := cFrom
        oMsg:cTo      := cPara
        oMsg:cSubject := cAssunto
        oMsg:cBody    := cCorpo

        For nAt := 1 To Len(aAnexos)
            If File(aAnexos[nAt])
                oMsg:AttachFile(aAnexos[nAt])
            EndIf
        Next

        If lUsaTLS
            oSrv:SetUseTLS(.T.)
        EndIf

        nRet := oSrv:Init("", cServer, cUser, cPass, 0, nPort)
        If nRet == 0
            oSrv:SetSMTPTimeout(nTimeOut)
            If oSrv:SMTPConnect() == 0
                If oSrv:SMTPAuth(cFrom, cPass) == 0 .Or. oSrv:SmtpAuth(cFrom, cPass) == 0  // compat builds
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
/*
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

    Static cDescriAnt   := ""
    Static cCodVendAnt  := ""
    Static cNomeVendAnt := ""

    If aParam == NIL
        Return xRet
    EndIf

    oObj     := aParam[1]             
    cIdPonto := aParam[2]              
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


        If Empty(AllTrim(oSect:GetValue("Z0_STATUS")))
            oSect:SetValue("Z0_STATUS", "0")
        EndIf

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
        FWAlertInfo("Registro Incluído e enviado pro E-Mail.", "Sucesso")
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
        FWAlertInfo("Registro Excluído e enviado pro E-Mail.", "Sucesso")
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
        FWAlertInfo("Registro Alterado e enviado pro E-Mail.", "Sucesso")
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

*/


