#Include "Protheus.ch"
#Include "FwMVCDef.ch"

#Define ST_NOVO          "0"
#Define ST_EM_APROVACAO  "1"
#Define ST_APROVADO      "2"
#Define ST_REPROVADO     "3"

User Function MVC001()
    Local oBrowse := FwMBrowse():New()
    oBrowse:setAlias("SZ0")
    oBrowse:setDescription("Cadastro de Carteira de Clientes")
    oBrowse:Activate()
Return

Static Function ModelDef()
    Local oStru := FwFormStruct(1,"SZ0")
    Local oMod  := MPFormModel():New("SZ0MODEL")
    oMod:AddFields("SZ0MASTER", , oStru)
    oMod:SetDescription("Modelo de Dados de Carteira")
    oMod:GetModel("SZ0MASTER"):SetDescription("Dados de Carteira")
Return oMod

Static Function ViewDef()
    Local oMod  := FWLoadModel("MVC001")
    Local oStr2 := FwFormStruct(2,"SZ0")
    Local oView := FWFormView():New()
    oView:SetModel(oMod)
    oView:AddField("VIEW_SZ0", oStr2, "SZ0MASTER")
    oView:CreateHorizontalBox("TELA",100)
    oView:SetOwnerView("VIEW_SZ0","TELA")
Return oView

Static Function MenuDef()
    Local aRot := {}
    ADD OPTION aRot Title "Incluir"         Action "VIEWDEF.MVC001" OPERATION 3 ACCESS 0
    ADD OPTION aRot Title "Alterar"         Action "VIEWDEF.MVC001" OPERATION 4 ACCESS 0
    ADD OPTION aRot Title "Visualizar"      Action "VIEWDEF.MVC001" OPERATION 2 ACCESS 0
    ADD OPTION aRot Title "Excluir"         Action "U_Z0EXC"        OPERATION 5 ACCESS 0
    ADD OPTION aRot Title "Enviar p/ Fluig" Action "U_ENVIAFLUIG"   OPERATION 0 ACCESS 0
Return aRot

/*
Static Function MenuDef()
    Local aRot := {}
    ADD OPTION aRot Title "Incluir"         Action "VIEWDEF.MVC001"  OPERATION 3 ACCESS 0
    ADD OPTION aRot Title "Alterar"         Action "U_Z0ALT"         OPERATION 4 ACCESS 0
    ADD OPTION aRot Title "Visualizar"      Action "VIEWDEF.MVC001"  OPERATION 2 ACCESS 0
    ADD OPTION aRot Title "Excluir"         Action "U_Z0EXC"         OPERATION 5 ACCESS 0
    ADD OPTION aRot Title "Enviar p/ Fluig" Action "U_ENVIAFLUIG"    OPERATION 0 ACCESS 0



Return aRot

User Function OpenOp(nOp)
    Local cAlias := "SZ0"
    Local oModel, oView, oStru, cKey

    If Select(cAlias) == 0
        FWAlertError("Alias SZ0 não selecionado.")
        Return
    EndIf
    DbSelectArea(cAlias)

    // Monta chave primária (AJUSTE os PadR conforme tamanho real dos campos)
    cKey := xFilial(cAlias) + ;
            PadR((cAlias)->Z0_CODIGO, 6) + ;
            PadR((cAlias)->Z0_CODVEN , 6)

    oModel := FWLoadModel("MVC001")

    If oModel == NIL
        FWAlertError("FWLoadModel('MVC001') retornou NIL.")
        Return
    EndIf

    // Localiza registro dentro do model
    If Type("FWFindKey") == "UI"
        If ! FWFindKey(oModel,"SZ0MASTER", cKey)
            FWAlertError("Registro não encontrado no Model (chave: "+cKey+").")
            Return
        EndIf
    Else
        FWAlertError("FWFindKey indisponível neste patch. Considere usar gatilhos (triggers).")
        Return
    EndIf

    oModel:SetOperation(nOp)

    // Se FWLoadView existir, use-o (monta tudo corretamente)
    If Type("FWLoadView") == "UI"
        oView := FWLoadView("MVC001")
        oView:SetModel(oModel)
        oView:Activate()
        Return
    EndIf

    // Fallback manual (caso FWLoadView não exista)
    oStru := FwFormStruct(2,"SZ0")
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SZ0", oStru, "SZ0MASTER")
    oView:CreateHorizontalBox("TELA",100)
    oView:SetOwnerView("VIEW_SZ0","TELA")
    oView:Activate()
Return
*/
