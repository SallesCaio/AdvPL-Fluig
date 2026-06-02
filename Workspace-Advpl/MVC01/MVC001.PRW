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

    oBrowse:AddLegend("Z0_STATUS=='"+ST_NOVO+"'", "WHITE", "NOVO")
    oBrowse:AddLegend("Z0_STATUS=='"+ST_EM_APROVACAO+"'", "YELLOW", "EM APROVACAO")
    oBrowse:AddLegend("Z0_STATUS=='"+ST_APROVADO+"'", "GREEN", "APROVADO")
    oBrowse:AddLegend("Z0_STATUS=='"+ST_REPROVADO+"'", "RED", "NAO APROVADO")


    oBrowse:Activate()
Return

Static Function ModelDef()
    Local oStru := FwFormStruct(1,"SZ0")
    Local oMod  := MPFormModel():New("SZ0MODEL")

    oMod:AddFields("SZ0MASTER", , oStru)

    oMod:SetPre("SZ0MASTER", {|oModel| Z0_PRE(oModel)})

    oMod:SetPost("SZ0MASTER", {|oModel| Z0_POS(oModel)})
    
    
    oMod:SetDescription("Modelo de Dados de Carteira")
    
    oMod:GetModel("SZ0MASTER"):SetDescription("Dados de Carteira")
Return oMod

Static Function ViewDef()
    Local oMod  := FWLoadModel("MVC001")
    Local oStr2 := FwFormStruct(2,"SZ0")
    Local oView := FWFormView():New()

    oView:SetModel(oMod)
    
    oView:CreateHorizontalBox("CABEC",30)
    oView:CreateHorizontalBox("CTRL",30)
    oView:CreateHorizontalBox("INFO",30)

    oView:SetOwnerView("VIEW_SZ0","CABEC")

/*
    oView:AddField("VIEW_SZ0", oStr2, "SZ0MASTER")
    oView:CreateHorizontalBox("TELA",100)

    oView:SetOwnerView("VIEW_SZ0","TELA")
*/
Return oView

Static Function MenuDef()
    Local aRot := {}
    ADD OPTION aRot Title "Incluir"               Action "VIEWDEF.MVC001" OPERATION 3 ACCESS 0
    ADD OPTION aRot Title "Alterar"               Action "VIEWDEF.MVC001" OPERATION 4 ACCESS 0
    ADD OPTION aRot Title "Visualizar"            Action "VIEWDEF.MVC001" OPERATION 2 ACCESS 0
    ADD OPTION aRot Title "Excluir"               Action "U_Z0EXC"        OPERATION 5 ACCESS 0
    ADD OPTION aRot Title "Solicitar aprovacao"   Action "U_ENVIAFLUIG"   OPERATION 0 ACCESS 0
Return aRot


Static Function Z0_PRE(oModel)

    Local oSect := oModel:GetModel("SZ0MASTER")
    Local cCodigo := AllTrim(oSect:GetValue("Z0_CODIGO"))
    Local cVend    := Alltrim(oSect:GetValue("Z0_CODVEN"))
    Local nOp := oModel:GetOperation()

    IF Empty(cCodigo)
        FWAlertError("C�digo da carteira � obrigat�rio.")
        Return .F.
    ENDIF

    IF Z0_EXISTE(cCodigo, cVend)
        FWAlertError("Carteira j� cadastrada para este vendedor")
        Return .F.
    ENDIF

    IF !Z0_VENDOK(cVend)
        FWAlertError("Vendedor invalido")
        Return .F.
    ENDIF

    IF oSect:GetValue("Z0_STATUS") == ST_APROVADO
        FWAlertError("Registro aprovado nao pode ser alterado.")
        Return .F.
    ENDIF

    If nOp == 3 .Or. nOp == 4
        If Empty( AllTrim( oSect:GetValue("Z0_TIPO") ) )
            FWAlertError("Tipo da carteira e obrigatorio.")
            Return .F.
        EndIf

        If Empty( AllTrim( oSect:GetValue("Z0_SEGMENTO") ) )
            FWAlertError("Segmento e obrigatorio.")
            Return .F.
        EndIf

        If Val( oSect:GetValue("Z0_LIMCRED") ) <= 0
            FWAlertError("Limite de credito deve ser maior que zero.")
            Return .F.
        EndIf
    EndIf

Return .T.

Static Function Z0_POS(oModel)
    Local oSect := oModel:GetModel("SZ0MASTER")

    If oModel:GetOperation() == 3
        If Empty( oSect:GetValue("Z0_STATUS") )
            oSect:SetValue("Z0_STATUS", ST_NOVO)
        EndIf
        oSect:SetValue("Z0_DTCAD", Date())
        oSect:SetValue("Z0_USRCAD", UsrRetName())
    EndIf

RETURN .T.


