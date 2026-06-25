/*/{Protheus.doc} ZXM010
Central de Solicitacao Tecnica de Compras - v3.0 (Modelo 3)
Cabe�alho (ZXM) + Itens (ZXN)
@type  Function
@author Caio Salles
@since 2026-06-17
@version 3.0
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
// ModelDef - Estrutura de dados (Cabe�alho + Itens)
//-------------------------------------------------------------------
Static Function ModelDef()

    // Estruturas
    Local oStruCab := FWFormStruct(1, "ZXM")  // Cabe�alho
    Local oStruIte := FWFormStruct(1, "ZXN")  // Itens
    Local oMod     := MPFormModel():New("ZXMMODEL", {|oMod| ZXM010PRE(oMod)}, {|oMod| ZXM010POS(oMod)})

    // Cabe�alho
    oMod:AddFields("ZXMMASTER", , oStruCab)
    oMod:SetPrimaryKey({"ZXM_FILIAL", "ZXM_COD"})
    oMod:SetDescription("Modelo de Dados " + cTitulo)
    oMod:GetModel("ZXMMASTER"):SetDescription("Dados da Solicitacao")

    // Itens (grid)
    oMod:AddGrid("ZXNDETAIL", "ZXMMASTER", oStruIte)
    oMod:GetModel("ZXNDETAIL"):SetDescription("Itens da Solicitacao")

    // Relacao cabe�alho → itens
    oMod:SetRelation("ZXNDETAIL", {{"ZXN_FILIAL", "xFilial('ZXN')"}, {"ZXN_COD", "ZXM_COD"}}, ZXN->(IndexKey(1)))

    // Obrigatoriedade controlada via SX3 (Obrigat. Usuario)
    // ZXM_DESC, ZXM_TIPO, ZXM_FORNEC, ZXM_LOJA, ZXM_URGEN
    // ZXN_PROD, ZXN_QTD, ZXN_VLUNI

Return oMod

//-------------------------------------------------------------------
// ViewDef - Layout da tela (Cabe�alho + Grid)
//-------------------------------------------------------------------
Static Function ViewDef()

    Local oModel     := FWLoadModel("ZXM010")
    Local oView      := FWFormView():New()

    oView:SetModel(oModel)

    // Filtra campos para cada aba
    Local oStrPrinc  := FWFormStruct(2, "ZXM", {|cCampo| AllTrim(cCampo) $ "ZXM_DESC|ZXM_TIPO|ZXM_FORNEC|ZXM_LOJA|ZXM_URGEN|ZXM_CATEG"})
    Local oStrObs    := FWFormStruct(2, "ZXM", {|cCampo| AllTrim(cCampo) $ "ZXM_OBS|ZXM_DETAL|ZXM_JUST"})
    Local oStrIte    := FWFormStruct(2, "ZXN")

    // Remove pastas padrão
    oStrPrinc:SetNoFolder()
    oStrObs:SetNoFolder()

    // Remove campos auto-preenchidos do grid
    oStrIte:RemoveField("ZXN_FILIAL")
    oStrIte:RemoveField("ZXN_COD")

    // Cabeçalho com abas (35%)
    oView:AddField("VIEW_ZXM", oStrPrinc, "ZXMMASTER")
    oView:AddField("VIEW_OBS", oStrObs, "ZXMMASTER")

    oView:CreateHorizontalBox("CABEC", 35)

    // Folder de abas dentro do cabeçalho
    oView:CreateFolder("ABAS_CABEC", "CABEC")
    oView:AddSheet("ABAS_CABEC", "SHEET_DADOS", "Dados Principais")
    oView:AddSheet("ABAS_CABEC", "SHEET_OBS", "Obs / Desc Tecnica")

    // Boxes de cada sheet
    oView:CreateHorizontalBox("BOX_DADOS", 100, , , "ABAS_CABEC", "SHEET_DADOS")
    oView:CreateHorizontalBox("BOX_OBS", 100, , , "ABAS_CABEC", "SHEET_OBS")

    // Itens grid (65%)
    oView:CreateHorizontalBox("ITENS", 65)
    oView:AddGrid("VIEW_ITENS", oStrIte, "ZXNDETAIL")

    // Liga views às boxes
    oView:SetOwnerView("VIEW_ZXM", "BOX_DADOS")
    oView:SetOwnerView("VIEW_OBS", "BOX_OBS")
    oView:SetOwnerView("VIEW_ITENS", "ITENS")

    oView:SetCloseOnOk({||.T.})

Return oView

//-------------------------------------------------------------------
// ZXM010PRE - Validacao PRE-gatilho
//-------------------------------------------------------------------
Static Function ZXM010PRE(oModel)

    Local nTotIte := 0
    Local nX := 0
    Local oCab   := oModel:GetModel("ZXMMASTER")
    Local oIte   := oModel:GetModel("ZXNDETAIL")
    Local nOp    := oModel:GetOperation()
    Local cFornec:= AllTrim(oCab:GetValue("ZXM_FORNEC"))
    Local cLoja  := AllTrim(oCab:GetValue("ZXM_LOJA"))
    Local cStatus:= oCab:GetValue("ZXM_STATUS")

    // Regra: Aprovado nao pode editar
    If nOp == 4 .And. cStatus == ST_APROVADO
        FWAlertError("Solicitacao APROVADA nao pode ser alterada.", "Bloqueio")
        Return .F.
    EndIf

    // Regra: Reprovado nao pode editar
    If nOp == 4 .And. cStatus == ST_REPROVADO
        FWAlertError("Solicitacao REPROVADA nao pode ser alterada. Crie uma nova.", "Bloqueio")
        Return .F.
    EndIf

    // Valida fornecedor existe (Inclusao e Alteracao)
    If nOp == 3 .Or. nOp == 4
        If !Empty(cFornec) .And. !ZXM010VFORN(cFornec, cLoja)
            FWAlertError("Fornecedor " + cFornec + "/" + cLoja + " nao cadastrado.", "Validacao")
            Return .F.
        EndIf
    EndIf

    // Valida se tem itens (Inclusao e Alteracao)
    If nOp == 3 .Or. nOp == 4
        nTotIte := 0
        For nX := 1 To oIte:Length()
            If !oIte:IsDeleted(nX)
                nTotIte++
            EndIf
        Next
        If nTotIte == 0
            FWAlertError("Informe pelo menos 1 item na solicitacao.", "Validacao")
            Return .F.
        EndIf
    EndIf

    // Valida exclusao: so Novo ou Reprovado
    If nOp == 5
        If !(cStatus $ "0/3")
            FWAlertError("So e possivel excluir solicitacoes NOVAS ou REPROVADAS.", "Bloqueio")
            Return .F.
        EndIf
    EndIf

Return .T.

//-------------------------------------------------------------------
// ZXM010POS - Pos-gatilho (auto-preenche auditoria)
//-------------------------------------------------------------------
Static Function ZXM010POS(oModel)

    Local oCab := oModel:GetModel("ZXMMASTER")
    Local nOp  := oModel:GetOperation()

    If nOp == 3
        If Empty(oCab:GetValue("ZXM_STATUS"))
            oCab:SetValue("ZXM_STATUS", ST_NOVO)
        EndIf
        oCab:SetValue("ZXM_DTAB", Date())
        oCab:SetValue("ZXM_USR", __cUserID)
    EndIf

Return .T.

//-------------------------------------------------------------------
// ZXM010VFORN - Valida se fornecedor existe na SA2
//-------------------------------------------------------------------
Static Function ZXM010VFORN(cCodForn, cLojaForn)

    Local lRet  := .F.
    Local aArea := FWGetArea()

    DbSelectArea("SA2")
    SA2->(DbSetOrder(1))
    If SA2->(DbSeek(xFilial("SA2") + cCodForn + cLojaForn))
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
