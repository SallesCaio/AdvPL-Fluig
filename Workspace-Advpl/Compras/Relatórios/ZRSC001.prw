#Include "Protheus.ch"
#Include "TopConn.ch"

User Function ZRSC001()
    Local aArea  := FWGetArea()
    Local aPergs := {}
    Local oReport

    // Parametros usados para filtrar a consulta da SC1.
    aAdd(aPergs, {1, "Filial De",   Space(TamSX3("C1_FILIAL")[1]),          "", ".T.", "SM0", ".T.", 80, .F.})
    aAdd(aPergs, {1, "Filial Ate",  Replicate("Z", TamSX3("C1_FILIAL")[1]), "", ".T.", "SM0", ".T.", 80, .T.})
    aAdd(aPergs, {1, "Emissao De",  dDataBase,                              "", ".T.", "",    ".T.", 80, .F.})
    aAdd(aPergs, {1, "Emissao Ate", dDataBase,                              "", ".T.", "",    ".T.", 80, .T.})

    // Abre tela de parametros antes de montar o relatorio.
    If ParamBox(aPergs, "Relatorio de Solicitacoes de Compra")
        oReport := fReportDef()
        oReport:PrintDialog()
    EndIf

    // Restaura a area original da rotina chamadora.
    FWRestArea(aArea)

Return

Static Function fReportDef()
    Local oReport
    Local oSectionCab
    Local oSection

    // Cria o objeto principal do TReport.
    oReport := TReport():New( ;
        "ZRSC001", ;
        "RELATORIO GERENCIAL DE SOLICITACOES DE COMPRA", ;
        , ;
        {|oReport| fRepPrint(oReport)} )

    // Configuracoes visuais principais do relatorio.
    oReport:SetLandscape()
    oReport:SetLineHeight(52)
    oReport:SetColSpace(2)
    oReport:cFontBody := "Arial"
    oReport:nFontBody := 10
    oReport:lParamPage := .T.
    oReport:SetTotalInLine(.F.)

    // =====================================================
    // SECTION 1 - CABECALHO GERENCIAL
    // Mantem a section separada da grid para evitar sobreposicao.
    // =====================================================
    oSectionCab := TRSection():New( ;
        oReport, ;
        "DADOS DO RELATORIO", ;
        {} )

    oSectionCab:SetTotalInLine(.F.)

    // Empresa do ambiente corrente.
    TRCell():New( ;
        oSectionCab, ;
        "EMPRESA", ;
        "QRY_CAB", ;
        "Empresa", ;
        "@!", ;
        65 )

    // Filial do ambiente corrente.
    TRCell():New( ;
        oSectionCab, ;
        "FILIAL", ;
        "QRY_CAB", ;
        "Filial", ;
        "@!", ;
        25 )

    // Periodo informado no ParamBox.
    TRCell():New( ;
        oSectionCab, ;
        "PERIODO", ;
        "QRY_CAB", ;
        "Periodo", ;
        "@!", ;
        45 )

    // Usuario responsavel pela emissao.
    TRCell():New( ;
        oSectionCab, ;
        "USUARIO", ;
        "QRY_CAB", ;
        "Usuario", ;
        "@!", ;
        25 )

    // =====================================================
    // SECTION 2 - GRID PRINCIPAL
    // =====================================================
    oSection := TRSection():New( ;
        oReport, ;
        "SOLICITACOES DE COMPRA", ;
        {"QRY_SC"} )

    oSection:SetTotalInLine(.F.)

    oSection:SetLineHeight(52)
    oSection:SetLineBreak(.T.)

    // Numero da solicitacao.
    TRCell():New(oSection, ;
        "C1_NUM", ;
        "QRY_SC", ;
        "SC", ;
        "@!", ;
        12)

    // Data de emissao da solicitacao.
    TRCell():New(oSection, ;
        "C1_EMISSAO", ;
        "QRY_SC", ;
        "Emissao", ;
        "@D", ;
        14)

    // Solicitante informado na SC1.
    TRCell():New(oSection, ;
        "C1_SOLICIT", ;
        "QRY_SC", ;
        "Solicitante", ;
        "@!", ;
        14)

    // Nome do fornecedor vinculado a solicitacao.
    TRCell():New(oSection, ;
        "A2_NOME", ;
        "QRY_SC", ;
        "Fornecedor", ;
        "@!", ;
        28)

    // Codigo do produto solicitado.
    TRCell():New(oSection, ;
        "C1_PRODUTO", ;
        "QRY_SC", ;
        "Produto", ;
        "@!", ;
        16)

    // Descricao do produto solicitado.
    TRCell():New(oSection, ;
        "C1_DESCRI", ;
        "QRY_SC", ;
        "Descricao Produto", ;
        "@!", ;
        46)

    // Quantidade solicitada.
    TRCell():New(oSection, ;
        "C1_QUANT", ;
        "QRY_SC", ;
        "Quantidade", ;
        "@E 999,999.99", ;
        12)

    // Pontos de evolucao futura:
    // TRBreak pode ser reativado para agrupar por solicitacao.
    // TRFunction pode ser reativado para totalizar registros impressos.
    fAjustaVisual(oSectionCab, oSection)

Return oReport

Static Function fAjustaVisual(oSectionCab, oSection)

    // Ajusta alinhamentos do cabecalho gerencial para leitura em bloco.
    oSectionCab:Cell("EMPRESA"):SetHeaderAlign("LEFT")
    oSectionCab:Cell("FILIAL"):SetHeaderAlign("CENTER")
    oSectionCab:Cell("PERIODO"):SetHeaderAlign("CENTER")
    oSectionCab:Cell("USUARIO"):SetHeaderAlign("CENTER")

    oSectionCab:Cell("EMPRESA"):SetAlign("LEFT")
    oSectionCab:Cell("FILIAL"):SetAlign("CENTER")
    oSectionCab:Cell("PERIODO"):SetAlign("CENTER")
    oSectionCab:Cell("USUARIO"):SetAlign("CENTER")

    // Ajusta alinhamentos da grid principal.
    oSection:Cell("C1_NUM"):SetHeaderAlign("CENTER")
    oSection:Cell("C1_EMISSAO"):SetHeaderAlign("CENTER")
    oSection:Cell("C1_SOLICIT"):SetHeaderAlign("CENTER")
    oSection:Cell("A2_NOME"):SetHeaderAlign("CENTER")
    oSection:Cell("C1_PRODUTO"):SetHeaderAlign("CENTER")
    oSection:Cell("C1_DESCRI"):SetHeaderAlign("CENTER")
    oSection:Cell("C1_QUANT"):SetHeaderAlign("CENTER")

    oSection:Cell("C1_NUM"):SetAlign("CENTER")
    oSection:Cell("C1_EMISSAO"):SetAlign("CENTER")
    oSection:Cell("C1_PRODUTO"):SetAlign("CENTER")
    oSection:Cell("C1_QUANT"):SetAlign("RIGHT")


Return

Static Function fRepPrint(oReport)
    Local aArea       := FWGetArea()
    Local oSectionCab := oReport:Section(1)
    Local oSection    := oReport:Section(2)

    Local cQryCab     := ""
    Local cQry        := ""

    Local nAtual      := 0
    Local nTotal      := 0

    Local aEmpresa
    Local cNomEmpresa
    Local cFilEmpresa
    Local cPeriodo
    Local cUsuario

    // =====================================================
    // MONTA QUERY PRINCIPAL - GRID SC1
    // Busca dados da SC, fornecedor e centro de custo.
    // =====================================================
    cQry += " SELECT " + CRLF
    cQry += "     SC1.C1_FILIAL, " + CRLF
    cQry += "     SC1.C1_NUM, " + CRLF
    cQry += "     SC1.C1_ITEM, " + CRLF
    cQry += "     SC1.C1_EMISSAO, " + CRLF
    cQry += "     SC1.C1_PRODUTO, " + CRLF
    cQry += "     SC1.C1_DESCRI, " + CRLF
    cQry += "     SC1.C1_QUANT, " + CRLF
    cQry += "     SC1.C1_CC, " + CRLF
    cQry += "     SC1.C1_SOLICIT, " + CRLF
    cQry += "     SC1.C1_APROV, " + CRLF
    cQry += "     SA2.A2_COD, " + CRLF
    cQry += "     SA2.A2_NOME, " + CRLF
    cQry += "     SA2.A2_CGC, " + CRLF
    cQry += "     CTT.CTT_DESC01 AS DESC_CC, " + CRLF
    cQry += "     CASE SC1.C1_APROV " + CRLF
    cQry += "         WHEN 'L' THEN 'Liberado' " + CRLF
    cQry += "         WHEN 'B' THEN 'Bloqueado' " + CRLF
    cQry += "         ELSE 'Pendente' " + CRLF
    cQry += "     END STATUS " + CRLF
    cQry += " FROM " + RetSqlName("SC1") + " SC1 " + CRLF
    cQry += " LEFT JOIN " + RetSqlName("SA2") + " SA2 " + CRLF
    cQry += "     ON SA2.A2_COD = SC1.C1_FORNECE " + CRLF
    cQry += "     AND SA2.A2_LOJA = SC1.C1_LOJA " + CRLF
    cQry += "     AND SA2.D_E_L_E_T_ = ' ' " + CRLF
    cQry += " LEFT JOIN " + RetSqlName("CTT") + " CTT " + CRLF
    cQry += "     ON CTT.CTT_CUSTO = SC1.C1_CC " + CRLF
    cQry += "     AND CTT.CTT_FILIAL = SC1.C1_FILIAL " + CRLF
    cQry += "     AND CTT.D_E_L_E_T_ = ' ' " + CRLF
    cQry += " WHERE SC1.C1_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' " + CRLF
    cQry += "   AND SC1.C1_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' " + CRLF
    cQry += "   AND SC1.D_E_L_E_T_ = ' ' " + CRLF
    cQry += " ORDER BY SC1.C1_NUM, SC1.C1_ITEM " + CRLF

    // =====================================================
    // MONTA QUERY DO CABECALHO
    // Usa a SM0 como tabela de apoio porque o PlsQuery precisa de FROM.
    // =====================================================
    aEmpresa := fDadosEmpresa()

    cNomEmpresa := aEmpresa[1]
    cFilEmpresa := aEmpresa[2]
    cPeriodo    := DTOC(MV_PAR03) + " ate " + DTOC(MV_PAR04)
    cUsuario    := AllTrim(__cUserID)

    cQryCab += " SELECT TOP 1 " + CRLF
    // Protege literais do cabecalho contra aspas simples vindas da SM0 ou usuario.
    cQryCab += "     '" + fSqlText(cNomEmpresa) + "' AS EMPRESA, " + CRLF
    cQryCab += "     '" + fSqlText(cFilEmpresa) + "' AS FILIAL, " + CRLF
    cQryCab += "     '" + fSqlText(cPeriodo) + "' AS PERIODO, " + CRLF
    cQryCab += "     '" + fSqlText(cUsuario) + "' AS USUARIO " + CRLF
    cQryCab += " FROM " + RetSqlName("SM0") + " SM0 " + CRLF

    // Executa os aliases usados pelas duas sections.
    PlsQuery(cQryCab, "QRY_CAB")
    PlsQuery(cQry,    "QRY_SC")

    // Ajusta tipo do campo data para impressao correta no TReport.
    TCSetField("QRY_SC", "C1_EMISSAO", "D")

    DbSelectArea("QRY_SC")

    // Conta total de registros para barra de progresso.
    Count To nTotal
    oReport:SetMeter(nTotal)

    // =====================================================
    // IMPRIME SECTION 1 - CABECALHO GERENCIAL
    // =====================================================
    DbSelectArea("QRY_CAB")
    QRY_CAB->(DbGoTop())

    oSectionCab:Init()
    oSectionCab:PrintLine()
    oSectionCab:Finish()

    // =====================================================
    // IMPRIME SECTION 2 - GRID PRINCIPAL
    // =====================================================
    DbSelectArea("QRY_SC")
    QRY_SC->(DbGoTop())

    oSection:Init()

    While !QRY_SC->(Eof())
        nAtual++

        // Atualiza mensagem de progresso da impressao.
        oReport:SetMsgPrint( ;
            "Imprimindo registro " + ;
            cValToChar(nAtual) + ;
            " de " + ;
            cValToChar(nTotal))

        oReport:IncMeter()

        // Imprime a linha atual da grid.
        oSection:PrintLine()

        QRY_SC->(DbSkip())
    EndDo

    // Finaliza a section principal.
    oSection:Finish()

    // Fecha aliases temporarios usados pelo relatorio.
    QRY_SC->(DbCloseArea())
    QRY_CAB->(DbCloseArea())

    // Restaura a area original da rotina chamadora.
    FWRestArea(aArea)

Return

Static Function fDadosEmpresa()
    Local aArea  := FWGetArea()
    Local aDados := {}

    // Abre a empresa corrente do ambiente.
    OpenSM0()

    // Dados institucionais usados no cabecalho do relatorio.
    aAdd(aDados, AllTrim(SM0->M0_NOME))
    aAdd(aDados, AllTrim(SM0->M0_FILIAL))
    aAdd(aDados, AllTrim(SM0->M0_CGC))
    aAdd(aDados, AllTrim(SM0->M0_ENDCOB))

    // Restaura a area ativa para nao interferir nos aliases do relatorio.
    FWRestArea(aArea)

Return aDados

Static Function fSqlText(cTexto)

    // Escapa aspas simples para uso seguro em literais SQL montados no PlsQuery.
    cTexto := StrTran(AllTrim(cValToChar(cTexto)), "'", "''")

Return cTexto

Static Function fCabecRel(oReport)
    Local aEmpresa
    Local cNomEmpresa
    Local cFilEmpresa
    Local cCnpjEmp
    Local cEndEmpresa
    Local cPeriodo
    Local cUsuario

    // Rotina legado mantida apenas como referencia para evolucao visual.
    // Nao chamar junto com a Section(1), pois pode sobrepor a grid.
    aEmpresa := fDadosEmpresa()

    cNomEmpresa := aEmpresa[1]
    cFilEmpresa := aEmpresa[2]
    cCnpjEmp    := aEmpresa[3]
    cEndEmpresa := aEmpresa[4]
    cPeriodo    := DTOC(MV_PAR03) + " ate " + DTOC(MV_PAR04)
    cUsuario    := AllTrim(__cUserID)

    // Bloco superior do cabecalho manual.
    oReport:Say(120, 010, "RELATORIO GERENCIAL DE SOLICITACOES DE COMPRA")
    oReport:Line(115, 005, 115, 285)

    // Bloco esquerdo com dados da empresa.
    oReport:Say(135, 010, "Empresa: " + cNomEmpresa)
    oReport:Say(145, 010, "Filial: " + cFilEmpresa)
    oReport:Say(155, 010, "CNPJ: " + cCnpjEmp)
    oReport:Say(165, 010, "Endereco: " + cEndEmpresa)

    // Bloco direito com dados da emissao.
    oReport:Say(135, 180, "Emitido: " + DTOC(Date()))
    oReport:Say(145, 180, "Usuario: " + cUsuario)
    oReport:Say(155, 180, "Periodo:")
    oReport:Say(165, 180, cPeriodo)

    // Linha final do cabecalho manual.
    oReport:Line(175, 005, 175, 285)

Return
