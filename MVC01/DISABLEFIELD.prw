#Include "protheus.ch"
#Include "FwMVCDef.ch"
//--------------------------------------------------
//02/10/2025 18:07 Operation ALterar/Excluir em Status != 1 , Correção imediata -
//--------------------------------------------------
#Define ST_EM_APROVACAO "1"

User Function Z0_GETST()
    Local cAlias := "SZ0"
    If Select(cAlias) == 0
        Return ""
    EndIf
    DbSelectArea(cAlias)
Return AllTrim((cAlias)->Z0_STATUS)

Static Function __CanEdit()
    Return ( U_Z0_GETST() != ST_EM_APROVACAO )

//--------------------------------------------------
// Alterar
//--------------------------------------------------
User Function Z0ALT()
    If ! __CanEdit()
        FWAlertError("Alteração bloqueada. Status 'Em Aprovação'.")
        Return
    EndIf
    __OpenOp(4)
Return

//--------------------------------------------------
// Excluir
//--------------------------------------------------
User Function Z0EXC()
    If ! __CanEdit()
        FWAlertError("Exclusão bloqueada. Status 'Em Aprovação'.")
        Return
    EndIf
    __OpenOp(5)
Return


Static Function __OpenOp(nOp)
    Local cAlias := "SZ0"
    Local oModel
    Local oView
    Local oStru


    If Select(cAlias) == 0
        FWAlertError("Alias SZ0 não selecionado.")
        Return
    EndIf
    DbSelectArea(cAlias)

    oModel := FWLoadModel("MVC001")
    If oModel == NIL
        FWAlertError("FWLoadModel('MVC001') retornou NIL.")
        Return
    EndIf

    oModel:SetOperation(nOp)



    oModel:Load()

    oStru := FwFormStruct(2,"SZ0")
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_SZ0", oStru, "SZ0MASTER")
    oView:CreateHorizontalBox("TELA",100)
    oView:SetOwnerView("VIEW_SZ0","TELA")


    oView:Activate()

Return
