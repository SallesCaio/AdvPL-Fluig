/*/{Protheus.doc} ZXM010
Central de Solicitacao Tecnica de Compras - v2.1
@type  Function
@author Caio Salles
@since 2026-06-17
@version 2.1
/*/

#Include "Protheus.ch"
#Include "FwMVCDef.ch"

#Define ST_NOVO         "0"
#Define ST_ANALISE      "1"
#Define ST_APROVADO     "2"
#Define ST_REPROVADO    "3"

Static cTitulo := "Central Solicitacao Tecnica"

//-------------------------------------------------------------------
// Ponto de entrada principal - Controller MVC
//-------------------------------------------------------------------
User Function ZXM010()

    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("ZXM")
    oBrowse:SetDescription(cTitulo)

    // Legendas de status
    oBrowse:AddLegend("ZXM_STATUS == '0'", "GRAY"  , "Novo")
    oBrowse:AddLegend("ZXM_STATUS == '1'", "YELLOW", "Em Analise")
    oBrowse:AddLegend("ZXM_STATUS == '2'", "GREEN" , "Aprovado")
    oBrowse:AddLegend("ZXM_STATUS == '3'", "RED"   , "Reprovado")

    oBrowse:Activate()

Return

//-------------------------------------------------------------------
// MenuDef - Define operacoes disponiveis
//-------------------------------------------------------------------
Static Function MenuDef()

    Local aRot := {}

    ADD OPTION aRot Title "Visualizar" Action "VIEWDEF.ZXM010" OPERATION 2 ACCESS 0
    ADD OPTION aRot Title "Incluir"    Action "VIEWDEF.ZXM010" OPERATION 3 ACCESS 0
    ADD OPTION aRot Title "Alterar"    Action "VIEWDEF.ZXM010" OPERATION 4 ACCESS 0
    ADD OPTION aRot Title "Excluir"    Action "VIEWDEF.ZXM010" OPERATION 5 ACCESS 0
    ADD OPTION aRot Title "Legenda"    Action "u_ZXMLEG"       OPERATION 6 ACCESS 0

Return aRot

//-------------------------------------------------------------------
// ModelDef - Estrutura de dados, validacoes e regras
//-------------------------------------------------------------------
Static Function ModelDef()

    Local oStru := FWFormStruct(1, "ZXM")
    Local oMod  := MPFormModel():New("ZXMMODEL", {|oModel| ZXM010PRE(oModel)}, {|oModel| ZXM010POS(oModel)})

    // Adiciona campos da tabela
    oMod:AddFields("ZXMMASTER", , oStru)

    // PK obrigatoria (Release 12.1+)
    oMod:SetPrimaryKey({"ZXM_FILIAL", "ZXM_COD"})

    // Descricoes
    oMod:SetDescription("Modelo de Dados " + cTitulo)
    oMod:GetModel("ZXMMASTER"):SetDescription("Dados da Solicitacao")

    // Campos obrigatorios via FormStruct
    oStru:SetProperty("ZXM_DESC"  , MODEL_FIELD_OBRIGAT, .T.)
    oStru:SetProperty("ZXM_TIPO"  , MODEL_FIELD_OBRIGAT, .T.)
    oStru:SetProperty("ZXM_FORNEC", MODEL_FIELD_OBRIGAT, .T.)
    oStru:SetProperty("ZXM_LOJA"  , MODEL_FIELD_OBRIGAT, .T.)
    oStru:SetProperty("ZXM_URGEN" , MODEL_FIELD_OBRIGAT, .T.)

Return oMod

//-------------------------------------------------------------------
// ViewDef - Layout da tela com abas
//-------------------------------------------------------------------
Static Function ViewDef()

    Local oMod  := FWLoadModel("ZXM010")
    Local oStru := FWFormStruct(2, "ZXM")
    Local oView := FWFormView():New()

    oView:SetModel(oMod)

    // Duas abas: Cabecalho (60%) e Detalhes (40%)
    oView:CreateHorizontalBox("CABEC", 60)
    oView:CreateHorizontalBox("DETA", 40)

    oView:AddField("VIEW_ZXM", oStru, "ZXMMASTER")

    oView:SetOwnerView("VIEW_ZXM", "CABEC")

    // Titulo da secao
    oView:EnableTitleView("VIEW_ZXM", "Dados da Solicitacao Tecnica")

    // Forca fechamento da janela na confirmacao
    oView:SetCloseOnOk({||.T.})

Return oView

//-------------------------------------------------------------------
// ZXM010PRE - Validacao PRE-gatilho (antes de gravar)
// Retorna .T. se valido, .F. se reprovado
//-------------------------------------------------------------------
Static Function ZXM010PRE(oModel)

    Local oSect   := oModel:GetModel("ZXMMASTER")
    Local nOp     := oModel:GetOperation()
    Local cDesc   := AllTrim(oSect:GetValue("ZXM_DESC"))
    Local cTipo   := AllTrim(oSect:GetValue("ZXM_TIPO"))
    Local cFornec := AllTrim(oSect:GetValue("ZXM_FORNEC"))
    Local cLoja   := AllTrim(oSect:GetValue("ZXM_LOJA"))
    Local cUrgen  := AllTrim(oSect:GetValue("ZXM_URGEN"))
    Local cStatus := oSect:GetValue("ZXM_STATUS")

    //--------------------------------------------------
    // Regra: Aprovado nao pode ser alterado
    //--------------------------------------------------
    If nOp == 4 .And. cStatus == ST_APROVADO
        FWAlertError("Solicitacao APROVADA nao pode ser alterada.", "Bloqueio")
        Return .F.
    EndIf

    //--------------------------------------------------
    // Regra: Reprovado nao pode ser alterado (reabrir = novo)
    //--------------------------------------------------
    If nOp == 4 .And. cStatus == ST_REPROVADO
        FWAlertError("Solicitacao REPROVADA nao pode ser alterada. Crie uma nova.", "Bloqueio")
        Return .F.
    EndIf

    //--------------------------------------------------
    // Valida campos obrigatorios (Inclusao e Alteracao)
    //--------------------------------------------------
    If nOp == 3 .Or. nOp == 4

        If Empty(cDesc)
            FWAlertError("Descricao e obrigatoria.", "Validacao")
            Return .F.
        EndIf

        If Empty(cTipo)
            FWAlertError("Tipo da solicitacao e obrigatorio.", "Validacao")
            Return .F.
        EndIf

        If Empty(cFornec)
            FWAlertError("Fornecedor e obrigatorio.", "Validacao")
            Return .F.
        EndIf

        If Empty(cLoja)
            FWAlertError("Loja do fornecedor e obrigatoria.", "Validacao")
            Return .F.
        EndIf

        If Empty(cUrgen)
            FWAlertError("Urgencia e obrigatoria.", "Validacao")
            Return .F.
        EndIf

        //--------------------------------------------------
        // Valida fornecedor existe (SA1)
        //--------------------------------------------------
        If !ZXM010VFORN(cFornec, cLoja)
            FWAlertError("Fornecedor " + cFornec + "/" + cLoja + " nao cadastrado.", "Validacao")
            Return .F.
        EndIf

        //--------------------------------------------------
        // Valida urgencia valida
        //--------------------------------------------------
        If !(cUrgen $ "B/M/A")
            FWAlertError("Urgencia invalida. Use B (Baixa), M (Media) ou A (Alta).", "Validacao")
            Return .F.
        EndIf

    EndIf

    //--------------------------------------------------
    // Valida exclusao: so Novo ou Reprovado
    //--------------------------------------------------
    If nOp == 5
        If !(cStatus $ "0/3")
            FWAlertError("So e possivel excluir solicitacoes NOVAS ou REPROVADAS.", "Bloqueio")
            Return .F.
        EndIf
    EndIf

Return .T.

//-------------------------------------------------------------------
// ZXM010POS - Pos-gatilho (apos gravacao confirmada)
// Auto-preenche campos de auditororia
//-------------------------------------------------------------------
Static Function ZXM010POS(oModel)

    Local oSect := oModel:GetModel("ZXMMASTER")
    Local nOp   := oModel:GetOperation()

    If nOp == 3
        // Inclusao: seta status inicial e data de cadastro
        If Empty(oSect:GetValue("ZXM_STATUS"))
            oSect:SetValue("ZXM_STATUS", ST_NOVO)
        EndIf
        oSect:SetValue("ZXM_DTAB", Date())
        oSect:SetValue("ZXM_USR", __cUserID)
    EndIf

Return .T.

//-------------------------------------------------------------------
// ZXM010VFORN - Valida se fornecedor existe na SA1
//-------------------------------------------------------------------
Static Function ZXM010VFORN(cCodForn, cLojaForn)

    Local lRet   := .F.
    Local aArea  := FWGetArea()

    DbSelectArea("SA1")
    If DbSeek(xFilial("SA1") + cCodForn + cLojaForn)
        lRet := .T.
    EndIf

    FWRestArea(aArea)

Return lRet

//-------------------------------------------------------------------
// ZXMLEG - Legenda da rotina
//-------------------------------------------------------------------
User Function ZXMLEG()

    Local aLegenda := {}

    AADD(aLegenda, {"BR_CINZA"   , "Novo"})
    AADD(aLegenda, {"BR_AMARELO" , "Em Analise"})
    AADD(aLegenda, {"BR_VERDE"   , "Aprovado"})
    AADD(aLegenda, {"BR_VERMELHO", "Reprovado"})

    BrwLegenda(cTitulo, "Status", aLegenda)

Return
