/*---------------------------------------------------------------------*
 | Projeto: Estudos do Protheus dia 01                                |
 | Protheus: 12.1.2510                                                |
 | Autor: Caio Salles / Korus Consultoria                             |
 | Desc:    |
 *---------------------------------------------------------------------*/
/*
DbSelectArea(cAlias) ? escolhe a ÁREA de trabalho. Só isso. Não abre tabela, não carrega dado, não busca nada.

DbSetOrder(nOrdem) ? define QUAL índice está ativo na área. É o "andar" pelo qual o DbSeek vai procurar.

DbSeek(cChave) ? procura cChave no índice ativo. Devolve .T. = ACHOU / .F. = NÃO achou. 
Posiciona a área no registro encontrado. Se não achou ? posiciona no mais PRÓXIMO. (guarde isso)

xFilial(cAlias) ? devolve a FILIAL corrente como string. Existe porque quase toda chave começa por filial.

*/
#INCLUDE "protheus.ch"

/*User Function DIAG02()
    Local cRet := ""

    DbSelectArea("SB1")
    DbSetOrder(1)

    If DbSeek(xFilial("SB1")+ cCod)
     cRet := SB1->B1_DESC
    Endif

Return cRet
*/
User Function DIAG01(cProd, cForn)
    Local cRet   := ""
    Local lAchou := .F.

    DbSelectArea("SB1")
    DbSetOrder(1)

    lAchou := DbSeek(xFilial("SB1") + cProd)

    If !lAchou 
        cRet := "PRODUTO INEXISTENTE"
        Return cRet
    Endif

    DbSelectArea("SA2")
    DbSetOrder(1)

    lAchou := DbSeek(xFilial("SA2")+ cForn)

    If !lAchou
        cRet := "FORNECEDOR INEXISTENTE"
        Return cRet
    Endif

    cRet := "OK"

Return cRet
        

    