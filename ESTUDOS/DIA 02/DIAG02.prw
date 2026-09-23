/*---------------------------------------------------------------------*
 | Projeto: Estudos do Protheus dia 02                                |
 | Protheus: 12.1.2510                                                |
 | Autor: Caio Salles / Korus Consultoria                             |
 | Desc:    |
 *---------------------------------------------------------------------*/
/*
DbSelectArea(cAlias) ? escolhe a �REA de trabalho. S� isso. N�o abre tabela, n�o carrega dado, n�o busca nada.

DbSetOrder(nOrdem) ? define QUAL �ndice est� ativo na �rea. � o "andar" pelo qual o DbSeek vai procurar.

DbSeek(cChave) ? procura cChave no �ndice ativo. Devolve .T. = ACHOU / .F. = N�O achou. 
Posiciona a �rea no registro encontrado. Se n�o achou ? posiciona no mais PR�XIMO. (guarde isso)

xFilial(cAlias) ? devolve a FILIAL corrente como string. Existe porque quase toda chave come�a por filial.

*/
#INCLUDE "protheus.ch"

User Function DESC01(cCod)
    Local cRet   := ""
    Local lAchou := .F.
    Local cDesc  := ""
    
    DbSelectArea("SB1")
    DbSetOrder(1)

    lAchou:= DbSeek(xFilial("SB1") + cCod)

    If !lAchou 
        cRet:= "PRODUTO INEXISTENTE"
        Return cRet
    Endif


    cDesc:= SB1->B1_DESC

Return cDesc 

//CORRE��O (VERS�O DIRETA)

/*

User Function DESC01(cCod)
    Local lAchou := .F.

    DbSelectArea("SB1")
    DbSetOrder(1)

    lAchou:= DbSeek(xFilial("SB1") + cCod)

    If !lAchou
        Return "PRODUTO EXISTENTE"
    Endif

Return SB1->B1_DESC

*/
