#Include "Protheus.ch"
#Include "FwMVCDef.ch"



User Function MVC001()

	Local oBrowse	:= FwMBrowse():New()

	oBrowse:setAlias('SZ0')
	oBrowse:setDescription('Cadastro de Carteira de Clientes')

	oBrowse:Activate()

Return

Static Function AfterCreateBrowse(oBrowse)
    oBrowse:AddColumn("Status", {|oRec| StatusDesc(oRec:Z0_STATUS)})
Return


Static Function ModelDef()

	Local oStruSZ0	:= FwFormStruct(1,'SZ0')
	Local oModel	 
	
	oModel	:= MPFormModel():New("SZ0MODEL")
	oModel:AddFields( 'SZ0MASTER', /*cOwner*/, oStruSZ0)
	oModel:SetDescription( 'Modelo de Dados de Carteira' )
	oModel:GetModel( 'SZ0MASTER' ):SetDescription( 'Dados de Carteira' )
	
	

Return oModel


Static Function ViewDef()

    Local oModel	:= FWLoadModel( 'MVC001' )
    Local oStruSZ0	:= FWFormStruct( 2, 'SZ0' )
    Local oView

    oView := FWFormView():New()
    oView:SetModel( oModel )
    oView:AddField( 'VIEW_SZ0', oStruSZ0, 'SZ0MASTER' )

    oView:CreateHorizontalBox( 'TELA' , 100 )
    oView:SetOwnerView( 'VIEW_SZ0', 'TELA' )

Return oView


#Include "Protheus.ch"
#Include "FwMVCDef.ch"

Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina Title 'Incluir'         Action 'VIEWDEF.MVC001' OPERATION 3 ACCESS 0
    ADD OPTION aRotina Title 'Alterar'         Action 'VIEWDEF.MVC001' OPERATION 4 ACCESS 0
    ADD OPTION aRotina Title 'Visualizar'      Action 'VIEWDEF.MVC001' OPERATION 2 ACCESS 0
    ADD OPTION aRotina Title 'Excluir'         Action 'VIEWDEF.MVC001' OPERATION 5 ACCESS 0
    //ADD OPTION aRotina Title 'Imprimir'      Action 'VIEWDEF.MVC001' OPERATION 8 ACCESS 0
    //ADD OPTION aRotina Title 'Copiar'        Action 'VIEWDEF.MVC001' OPERATION 9 ACCESS 0

    // Nova opção custom no menu do browse (sem operação padrão):
    ADD OPTION aRotina Title 'Enviar p/ Fluig' Action 'U_ENVIAFLUIG' OPERATION 0 ACCESS 0

Return aRotina
