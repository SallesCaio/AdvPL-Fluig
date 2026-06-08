#Include "Protheus.ch"
#Include "FwMVCDef.ch"


#Define ST_NOVO         "0"
#Define ST_ANALISE      "1"
#Define ST_APROVADO     "2"
#Define ST_REPROVADO    "3"

Static cTitulo := ;
    "Central Solicitação Técnica"

//---------------------------------------------------
// Central Solicitação Técnica
//---------------------------------------------------
User Function ZXM010()

    Local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias("ZXM")
    oBrowse:SetDescription(cTitulo)

    // Legendas
    oBrowse:AddLegend(;
        "ZXM_STATUS=='1'",;
        "YELLOW",;
        "Em Analise" )

    oBrowse:AddLegend(;
        "ZXM_STATUS=='2'",;
        "GREEN",;
        "Aprovado" )

    oBrowse:AddLegend(;
        "ZXM_STATUS=='3'",;
        "RED",;
        "Reprovado" )

    oBrowse:Activate()

Return

//---------------------------------------------------
// Model
//---------------------------------------------------
Static Function ModelDef()

    Local oStru := ;
        FWFormStruct(1,"ZXM")

    Local oMod := ;
        MPFormModel():New("ZXMMODEL")

    // Campos obrigatórios
    oStru:SetProperty(;
        "ZXM_TIPO",;
        MODEL_FIELD_OBRIGAT,;
        .T. )

    oStru:SetProperty(;
        "ZXM_CATEG",;
        MODEL_FIELD_OBRIGAT,;
        .T. )

    oStru:SetProperty(;
        "ZXM_DESC",;
        MODEL_FIELD_OBRIGAT,;
        .T. )

    oStru:SetProperty(;
        "ZXM_FORNEC",;
        MODEL_FIELD_OBRIGAT,;
        .T. )

    // Campos da tabela
    oMod:AddFields(;
        "ZXMMASTER",;
        NIL,;
        oStru )

    // PK obrigatória da release
    oMod:SetPrimaryKey({;
        "ZXM_FILIAL",;
        "ZXM_COD" ;
    })

Return oMod

//---------------------------------------------------
// View
//---------------------------------------------------
Static Function ViewDef()

    Local oMod := ;
        FWLoadModel("ZXM010")

    Local oStru := ;
        FWFormStruct(2,"ZXM")

    Local oView := ;
        FWFormView():New()

    oView:SetModel(oMod)

    // Campos da tela
    oView:AddField(;
        "VIEW_ZXM",;
        oStru,;
        "ZXMMASTER" )

    // Layout simples
    oView:CreateHorizontalBox(;
        "TELA",100 )

    oView:SetOwnerView(;
        "VIEW_ZXM",;
        "TELA" )

Return oView

//---------------------------------------------------
// Menu MVC
//---------------------------------------------------
Static Function MenuDef()

    Local aRot := {}

    ADD OPTION aRot ;
        TITLE "Incluir" ;
        ACTION "VIEWDEF.ZXM010" ;
        OPERATION 3 ACCESS 0

    ADD OPTION aRot ;
        TITLE "Alterar" ;
        ACTION "VIEWDEF.ZXM010" ;
        OPERATION 4 ACCESS 0

    ADD OPTION aRot ;
        TITLE "Visualizar" ;
        ACTION "VIEWDEF.ZXM010" ;
        OPERATION 2 ACCESS 0

Return aRot
