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

    oBrowse:AddLegend("Z0_STATUS=='1'", "YELLOW", "Em aprovacao")
    oBrowse:AddLegend("Z0_STATUS=='2'", "GREEN",  "Aprovado")
    oBrowse:AddLegend("Z0_STATUS=='3'", "RED",    "Nao aprovado")


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
    ADD OPTION aRot Title "Incluir"               Action "VIEWDEF.MVC001" OPERATION 3 ACCESS 0
    ADD OPTION aRot Title "Alterar"               Action "VIEWDEF.MVC001" OPERATION 4 ACCESS 0
    ADD OPTION aRot Title "Visualizar"            Action "VIEWDEF.MVC001" OPERATION 2 ACCESS 0
    ADD OPTION aRot Title "Excluir"               Action "U_Z0EXC"        OPERATION 5 ACCESS 0
    ADD OPTION aRot Title "Solicitar aprovacao"   Action "U_ENVIAFLUIG"   OPERATION 0 ACCESS 0
Return aRot
