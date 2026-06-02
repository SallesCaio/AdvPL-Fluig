#Include "Protheus.ch"
#Include "TopConn.ch"

User Function ZRSC001()
    Local aArea  := FWGetArea()
    Local aPergs := {}
    Local oReport

    // Parametros usados para filtrar a consulta da SC1
    aAdd(aPergs, {1, "Filial De",   Space(TamSX3("C1_FILIAL")[1]),       "", ".T.", "SM0", ".T.", 80, .F.})
    aAdd(aPergs, {1, "Filial Ate",  Replicate("Z", TamSX3("C1_FILIAL")[1]), "", ".T.", "SM0", ".T.", 80, .T.})
    aAdd(aPergs, {1, "Emissao De",  dDataBase, "", ".T.", "", ".T.", 80, .F.})
    aAdd(aPergs, {1, "Emissao Ate", dDataBase, "", ".T.", "", ".T.", 80, .T.})

    // Abre tela de parametros antes de montar o relatorio
    If ParamBox(aPergs, "Relatorio de Solicitacoes de Compra")
        oReport := fReportDef()
        oReport:PrintDialog()
    EndIf

    // Restaura a area original da rotina chamadora
    FWRestArea(aArea)

Return

Static Function fReportDef()
    Local oReport
    Local oSection
    Local oSectionCab

    // Cria o objeto principal do TReport
    oReport := TReport():New( ;
        "ZRSC001", ;
        "RELATORIO GERENCIAL DE SOLICITACOES DE COMPRA", ;
        , ;
        {|oReport| fRepPrint(oReport)} )

    // Configuracoes visuais do relatorio
    oReport:SetLandscape()
    oReport:SetLineHeight(32)
    oReport:lParamPage := .T.
    oReport:SetTotalInLine(.F.)


    // =====================================================
    // SECTION CABECALHO
    // =====================================================
    oSectionCab := TRSection():New( ;
        oReport, ;
        "CABECALHO", ;
        {} )

    oSectionCab:SetTotalInLine(.F.)

    // =====================================================
    // CAMPOS HEADER GERENCIAL
    // =====================================================

    // Empresa
    TRCell():New( ;
        oSectionCab, ;
        "EMPRESA", ;
        "QRY_CAB", ;
        "Empresa", ;
        "@!", ;
        45 )

    // Filial
    TRCell():New( ;
        oSectionCab, ;
        "FILIAL", ;
        "QRY_CAB", ;
        "Filial", ;
        "@!", ;
        20 )

    // Periodo
    TRCell():New( ;
        oSectionCab, ;
        "PERIODO", ;
        "QRY_CAB", ;
        "Periodo", ;
        "@!", ;
        35 )

    // Usuario
    TRCell():New( ;
        oSectionCab, ;
        "USUARIO", ;
        "QRY_CAB", ;
        "Usuario", ;
        "@!", ;
        20 )

    // =====================================================
    // SECTION PRINCIPAL
    // =====================================================
    oSection := TRSection():New( ;
        oReport, ;
        "SOLICITACOES DE COMPRA", ;
        {"QRY_SC"} )

    oSection:SetTotalInLine(.F.)


    // =====================================================
    // COLUNAS PRINCIPAIS RELATORIO
    // Estrutura reduzida para melhorar leitura
    // =====================================================

    // Numero da solicitacao
    TRCell():New(oSection, ;
        "C1_NUM", ;
        "QRY_SC", ;
        "SC", ;
        "@!", 10)

    // Data emissao
    TRCell():New(oSection, ;
        "C1_EMISSAO", ;
        "QRY_SC", ;
        "Emissao", ;
        "@D", 12)

    // Status
    TRCell():New(oSection, ;
        "STATUS", ;
        "QRY_SC", ;
        "Status", ;
        "@!", 14)

    // Solicitante
    TRCell():New(oSection, ;
        "C1_SOLICIT", ;
        "QRY_SC", ;
        "Solicitante", ;
        "@!", 20)

    // Fornecedor
    TRCell():New(oSection, ;
        "A2_NOME", ;
        "QRY_SC", ;
        "Fornecedor", ;
        "@!", 35)

    // Produto
    TRCell():New(oSection, ;
        "C1_PRODUTO", ;
        "QRY_SC", ;
        "Produto", ;
        "@!", 15)

    // Descricao produto
    TRCell():New(oSection, ;
        "C1_DESCRI", ;
        "QRY_SC", ;
        "Descricao Produto", ;
        "@!", 50)

    // Quantidade
    TRCell():New(oSection, ;
        "C1_QUANT", ;
        "QRY_SC", ;
        "Quantidade", ;
        "@E 999,999.99", 12)

    // Centro de custo
    TRCell():New(oSection, ;
        "DESC_CC", ;
        "QRY_SC", ;
        "Centro de Custo", ;
        "@!", 30)

    //Permite criar blocos visuais por SC.
    //TRBreak():New(oSection, ;
    //oSection:Cell("C1_NUM"), ;
    //.T.)
    // Totaliza a quantidade de linhas impressas
    /*TRFunction():New(oSection:Cell("C1_NUM"), , "COUNT", , , "@E 999,999", , .F.)*/

Return oReport

Static Function fDadosEmpresa()

    Local aDados := {}

    // =====================================================
    // ABRE EMPRESA CORRENTE DO AMBIENTE
    // =====================================================
    OpenSM0()

    // Nome empresa
    aAdd(aDados, AllTrim(SM0->M0_NOME))

    // Nome filial
    aAdd(aDados, AllTrim(SM0->M0_FILIAL))

    // CNPJ empresa
    aAdd(aDados, AllTrim(SM0->M0_CGC))

    // Endereco empresa
    aAdd(aDados, AllTrim(SM0->M0_ENDCOB))

Return aDados

Static Function fCabecRel(oReport)

    Local aEmpresa
    Local cNomEmpresa
    Local cFilEmpresa
    Local cCnpjEmp
    Local cEndEmpresa
    Local cPeriodo
    Local cUsuario

    aEmpresa := fDadosEmpresa()

    cNomEmpresa := aEmpresa[1]
    cFilEmpresa := aEmpresa[2]
    cCnpjEmp    := aEmpresa[3]
    cEndEmpresa := aEmpresa[4]

    cPeriodo := DTOC(MV_PAR03) + ;
        " ate " + ;
        DTOC(MV_PAR04)

    cUsuario := AllTrim(__cUserID)

    // =====================================================
    // BLOCO SUPERIOR
    // =====================================================

    oReport:Say(120,010, ;
        "RELATORIO GERENCIAL DE SOLICITACOES DE COMPRA")

    oReport:Line(115,005,115,285)

    // =====================================================
    // BLOCO ESQUERDO
    // =====================================================
    oReport:Say(135,010, ;
        "Empresa: " + cNomEmpresa)

    oReport:Say(145,010, ;
        "Filial: " + cFilEmpresa)

    oReport:Say(155,010, ;
        "CNPJ: " + cCnpjEmp)

    oReport:Say(165,010, ;
        "Endereco: " + cEndEmpresa)

    // =====================================================
    // BLOCO DIREITO
    // =====================================================
    oReport:Say(135,180, ;
        "Emitido: " + DTOC(Date()))

    oReport:Say(145,180, ;
        "Usuario: " + cUsuario)

    oReport:Say(155,180, ;
        "Periodo:")

    oReport:Say(165,180, ;
        cPeriodo)

    // =====================================================
    // LINHA FINAL
    // =====================================================
    oReport:Line(175,005,175,285)

Return

Static Function fRepPrint(oReport)
    Local aArea    := FWGetArea()
    Local cQry     := ""
    Local oSectionCab := oReport:Section(1)
    Local oSection    := oReport:Section(2)
    Local nAtual   := 0
    Local nTotal   := 0
    Local aEmpresa
    Local cNomEmpresa
    Local cFilEmpresa
    Local cPeriodo
    Local cUsuario
    Local cQryCab := ""



    // Monta consulta principal do relatorio
    // Busca dados da SC, fornecedor e centro de custo
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

    // Dados fornecedor
    cQry += "     SA2.A2_COD, " + CRLF
    cQry += "     SA2.A2_NOME, " + CRLF
    cQry += "     SA2.A2_CGC, " + CRLF

    // Centro de custo
    cQry += "     CTT.CTT_DESC01 AS DESC_CC, " + CRLF

    // Traducao status tecnico
    cQry += "     CASE SC1.C1_APROV " + CRLF
    cQry += "         WHEN 'L' THEN 'Liberado' " + CRLF
    cQry += "         WHEN 'B' THEN 'Bloqueado' " + CRLF
    cQry += "         WHEN 'R' THEN 'Rejeitado' " + CRLF
    cQry += "         ELSE 'Pendente' " + CRLF
    cQry += "     END STATUS " + CRLF

    // Tabela principal
    cQry += " FROM " + RetSqlName("SC1") + " SC1 " + CRLF

    // Join fornecedor
    cQry += " LEFT JOIN " + RetSqlName("SA2") + " SA2 " + CRLF
    cQry += "     ON SA2.A2_COD = SC1.C1_FORNECE " + CRLF
    cQry += "     AND SA2.A2_LOJA = SC1.C1_LOJA " + CRLF
    cQry += "     AND SA2.D_E_L_E_T_ = ' ' " + CRLF

    // Join centro custo
    cQry += " LEFT JOIN " + RetSqlName("CTT") + " CTT " + CRLF
    cQry += "     ON CTT.CTT_CUSTO = SC1.C1_CC " + CRLF
    cQry += "     AND CTT.CTT_FILIAL = SC1.C1_FILIAL " + CRLF
    cQry += "     AND CTT.D_E_L_E_T_ = ' ' " + CRLF

    // Filtros ParamBox
    cQry += " WHERE SC1.C1_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' " + CRLF
    cQry += "   AND SC1.C1_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' " + CRLF
    cQry += "   AND SC1.D_E_L_E_T_ = ' ' " + CRLF

    // Ordenacao impressao
    cQry += " ORDER BY SC1.C1_NUM, SC1.C1_ITEM " + CRLF

    // =====================================================
    // MONTA DADOS CABECALHO
    // =====================================================
    aEmpresa := fDadosEmpresa()

    cNomEmpresa := aEmpresa[1]
    cFilEmpresa := aEmpresa[2]

    cPeriodo := DTOC(MV_PAR03) + ;
        " ate " + ;
        DTOC(MV_PAR04)

    cUsuario := AllTrim(__cUserID)

    // =====================================================
    // QUERY HEADER
    // =====================================================
    cQryCab += " SELECT TOP 1 " + CRLF
    cQryCab += " '" + cNomEmpresa + "' AS EMPRESA, " + CRLF
    cQryCab += " '" + cFilEmpresa + "' AS FILIAL, " + CRLF
    cQryCab += " '" + cPeriodo + "' AS PERIODO, " + CRLF
    cQryCab += " '" + cUsuario + "' AS USUARIO " + CRLF
    cQryCab += " FROM " + RetSqlName("SM0") + " SM0 " + CRLF

    PlsQuery(cQryCab, "QRY_CAB")


    // Executa query e cria alias temporario do relatorio
    PlsQuery(cQry, "QRY_SC")
    DbSelectArea("QRY_SC")

    // Ajusta tipo do campo data
    // Necessario para impressao correta no TReport
    TCSetField("QRY_SC", "C1_EMISSAO", "D")

    // Conta total de registros para barra de progresso
    Count To nTotal
    oReport:SetMeter(nTotal)

    // =====================================================
    // IMPRIME CABECALHO GERENCIAL
    // =====================================================
    DbSelectArea("QRY_CAB")
    QRY_CAB->(DbGoTop())

    oSectionCab:Init()
    oSectionCab:PrintLine()
    oSectionCab:Finish()

    // =====================================================
    // Inicializa grid principal
    // =====================================================
    oSection:Init()

    // Cabeçalho
    //fCabecRel(oReport)

    QRY_SC->(DbGoTop())


    While !QRY_SC->(Eof())

        nAtual++

        // Atualiza mensagem progresso
        oReport:SetMsgPrint( ;
            "Imprimindo registro " + ;
            cValToChar(nAtual) + ;
            " de " + ;
            cValToChar(nTotal))

        oReport:IncMeter()

        // Imprime linha atual
        oSection:PrintLine()

        QRY_SC->(DbSkip())

    EndDo



    // Finaliza impressao da secao
    oSection:Finish()

    // Fecha alias temporario
    QRY_SC->(DbCloseArea())

    // Restaura area original da rotina
    FWRestArea(aArea)

Return

