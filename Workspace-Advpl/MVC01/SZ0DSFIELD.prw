#Include "protheus.ch"

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
        // Mensagem generica, sem expor codigo
        FWAlertError("Alteracao bloqueada. Este cadastro esta em aprovacao. Aguarde a finalizacao.")
        Return .F.
    EndIf
Return .T.

/* ====================== EXCLUSÃO ========================= */
User Function Z0EXC()
    Local cAlias    := "SZ0"
    Local cCod      := ""
    Local cDescri   := ""
    Local cCodVend  := ""
    Local aOld      := {}
    Local lSent     := .F.

    If Select(cAlias) == 0
        FWAlertError("Alias SZ0 nao selecionado.")
        Return
    EndIf
    DbSelectArea(cAlias)

    If (cAlias)->( RecNo() ) <= 0
        FWAlertError("Nenhum registro selecionado.")
        Return
    EndIf

    If (cAlias)->Z0_STATUS == ST_EM_APROVACAO
        // Mensagem generica, sem expor codigo
        FWAlertError("Exclusao bloqueada. Este cadastro esta em aprovacao. Tente novamente apos a finalizacao.")
        Return
    EndIf

    // Dados
    cCod      := AllTrim((cAlias)->Z0_CODIGO)
    cDescri   := AllTrim((cAlias)->Z0_DESCRI)
    cCodVend  := AllTrim((cAlias)->Z0_CODVEN)

    aOld := U_Z0_BUILDARR(cCod, cDescri, cCodVend)
    U_Z0_ENRICHVEND(@aOld)

    // Confirmacao
    If ! MsgYesNo("Confirma excluir a carteira "+cCod+" - "+cDescri+"?", "Exclusao de Carteira")
        Return
    EndIf

    // E-mail (antes da exclusao)
    lSent := U_Z0_SENDMAIL("DEL", aOld, {})
    If ! lSent
        If ! MsgYesNo("Nao foi possivel enviar o e-mail de exclusao agora. Deseja prosseguir mesmo assim?")
            Return
        EndIf
    Else
        FWAlertInfo("E-mail de exclusao enviado.", "Exclusao")
    EndIf

    // Exclusao efetiva
    If (cAlias)->( RLock() )
        (cAlias)->( DbDelete() )
        (cAlias)->( DbCommit() )
        (cAlias)->( DbUnlock() )
        FWAlertInfo("Registro "+cCod+" excluido.", "Exclusao")
    Else
        FWAlertError("Nao foi possivel bloquear o registro para exclusao (RLock).")
    EndIf
Return
