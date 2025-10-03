#Include "protheus.ch"

/*
    Wrapper e utilidades para SZ0
    Ajustado para garantir envio de e-mail na exclusão mesmo após retorno à versão v6 do SZ0ACTION.
    Convenção atual assumida:
       - Declarações das User Functions sem U_
       - Chamadas usando U_<Nome>
    O código abaixo trata três cenários de implementação de envio:
       A) U_Z0_BUILDARR / U_Z0_ENRICHVEND / U_Z0_SENDMAIL
       B) Apenas U_Z0_SENDMAIL (aceita array simples aOld)
       C) Apenas U_Z0_MAILSEND (envio SMTP direto) -> gera HTML de exclusão aqui
*/

/* ====================== CONSTANTES DE STATUS ====================== */
#Define ST_NOVO          "0"
#Define ST_EM_APROVACAO  "1"
#Define ST_APROVADO      "2"
#Define ST_REPROVADO     "3"

/* ====================== GET / SET STATUS ========================= */
User Function Z0_GETST()
    Local cAlias := "SZ0"
    If Select(cAlias) == 0
        Return ""
    EndIf
    DbSelectArea(cAlias)
Return AllTrim((cAlias)->Z0_STATUS)

User Function Z0_SETSTS(cNovo)
    Local cAlias := "SZ0"
    If Empty(cNovo) ; Return .F. ; EndIf
    If Select(cAlias) == 0 ; Return .F. ; EndIf
    DbSelectArea(cAlias)
    If (cAlias)->( RLock() )
        (cAlias)->Z0_STATUS := cNovo
        (cAlias)->( DbCommit() )
        (cAlias)->( DbUnlock() )
        Return .T.
    EndIf
Return .F.

/* ====================== VALID ========================= */
User Function Z0_VAL()
    Local cAlias := "SZ0"
    If Select(cAlias) == 0
        Return .T.
    EndIf
    DbSelectArea(cAlias)
    If (cAlias)->Z0_STATUS == ST_EM_APROVACAO
        FWAlertError("Alteracao bloqueada. Registro em aprovacao (status = 1).")
        Return .F.
    EndIf
Return .T.

/* ====================== EXCLUSÃO ========================= */
User Function Z0EXC()
    Local cAlias    := "SZ0"
    Local cCod      := ""
    Local cDescri   := ""
    Local cCodVend  := ""
    Local cNomeVend := ""
    Local aOld      := {}
    Local lSent     := .F.

    // 1. Verificações básicas
    If Select(cAlias) == 0
        FWAlertError("Alias SZ0 não selecionado.")
        Return
    EndIf
    DbSelectArea(cAlias)

    If (cAlias)->( RecNo() ) <= 0
        FWAlertError("Nenhum registro selecionado.")
        Return
    EndIf

    If (cAlias)->Z0_STATUS == ST_EM_APROVACAO
        FWAlertError("Exclusao bloqueada. Registro em aprovacao (status = 1).")
        Return
    EndIf

    // 2. Captura dados
    cCod      := AllTrim((cAlias)->Z0_CODIGO)
    cDescri   := AllTrim((cAlias)->Z0_DESCRI)
    cCodVend  := AllTrim((cAlias)->Z0_CODVEN)

    // Nome do vendedor (reaproveita lógica da action via enrich)
    aOld := U_Z0_BUILDARR(cCod, cDescri, cCodVend)
    U_Z0_ENRICHVEND(@aOld)

    // 3. Confirmação
    If ! MsgYesNo("Confirma exclusao da carteira " + cCod + " ?")
        Return
    EndIf

    // 4. Envia e-mail (antes ou depois da exclusão – aqui ANTES; se quiser depois, mova bloco)
    lSent := U_Z0_SENDMAIL("DEL", aOld, {})
    If ! lSent
        If ! MsgYesNo("Falha ao enviar e-mail de exclusao. Prosseguir mesmo assim?")
            Return
        EndIf
    Else
        FWAlertInfo("E-mail de exclusao enviado.","Exclusao")
    EndIf

    // 5. Exclusão efetiva
    If (cAlias)->( RLock() )
        (cAlias)->( DbDelete() )
        (cAlias)->( DbCommit() )
        (cAlias)->( DbUnlock() )
        FWAlertInfo("Registro " + cCod + " excluido.")
    Else
        FWAlertError("Nao foi possivel bloquear o registro (RLock).")
    EndIf
Return
