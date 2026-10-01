/*/ 
ZUpXml - Enviar Xml ao Monitor
Caio Salles - Korus Consultoria
@since 24/09/2026
@release 2510
/*/

#Include "TOTVS.CH"

User Function ZUPXML()
    Local cArquivo := ""
    Local cPasta   := ""
    Local cNome    := ""
    Local cDestino := ""
    Local cErro    := ""


    Local lCopia := .F.

    cPasta := GetMV("MV_NGINN")

    If Empty(cPasta)
        FWAlertError("O parametro MV_NGINN nao esta configurado.", "Enviar XML")
        Return
    Endif

    cArquivo := cGetFile(;
        "Arquivo XML (*.xml)|*.xml",;
        "Selecionar XML",;
        1,;
        "",;
        .T.,;
        GETF_LOCALHARD,;
        .F.,;
    .T. )

    If Empty(cArquivo)
        Return
    Endif

    If Lower(Right(cArquivo, 4)) <> ".xml"
        FWAlertError(;
        "Selecione somente arquivos XML.",;
        "Enviar XML")
        Return
    Endif

    cNome := fNomeArquivo(cArquivo)

    cDestino := cPasta

    If Right(cDestino, 1) <> "\" .And. Right(cDestino, 1) <> "/"
        cDestino += "\"
    Endif

    cDestino += cNome

    If File(cDestino, 0, .F.)
        FWAlertError(;
        "Ja existe um arquivo com este nome na pasta destino." + CRLF + ;
        "Arquivo: " + cNome, ;
        "Enviar XML")
        Return
    Endif  

    lCopia := CpyT2S(cArquivo, cPasta, .T., .F.)

    If !lCopia 
        FWAlertError(;
            "Falhar ao copiar XML." + CRLF + ;
            "Erro: "+ cValToChar(FError()), ;
            "Enviar XML")
        Return
    EndIf
    

    If !fValidaNFe(cDestino, @cErro)
        FErase(cDestino)

        FWAlertError(;
            "O arquivo nao e uma NF-e compativel com este processo." + CRLF + ;
            cErro + CRLF + ;
            "O arquivo nao foi mantido na pasta INN.",;
            "Enviar XML")
        Return
    Endif

    // Funções de leitura e processamento para o monitor.
    COLAUTOREAD()
    SCHEDCOMCOL()

    FWAlertInfo(;
        "XML enviado com sucesso. Verifique o monitor." + CRLF +;
        "Arquivo:" + cNome, ;
        "Enviar XML";
    )



Return 

Static Function fNomeArquivo(cArquivo)
    Local nPosBarra  := 0
    Local nPosBarra2 := 0
    Local nPos       := 0

    nPosBarra   := Rat("\", cArquivo)
    nPosBarra2  := Rat("/", cArquivo)
    nPos        := Max(nPosBarra,nPosBarra2)

Return SubStr(cArquivo, nPos + 1)


Static Function fValidaNFe(cArquivo, cErro)

    Local cRaiz := ""
    Local cXML  := ""

    cErro := ""
    cXML := MemoRead(cArquivo)

    If Empty(cXML)
        cErro := "Nao foi possivel ler o conteudo do arquivo"
        Return .F.
    Endif

    cRaiz := fTagRaiz(cXML)

    If Empty(cRaiz)
        cErro := "Nao foi possivel identificar a tag raiz do XML."
        Return .F.
    Endif
    
    If cRaiz == "NFEPROC"
        If !("<NFe" $ cXML)
            cErro := "A estrutura nfeProc nao possui o nó NFe"
            Return .F.
        Endif
    ElseIf cRaiz <> "NFE"
        cErro := "Tipo de documento identificado: " + ;
            cRaiz + ". Esperado: NF-e."
        Return .F.
    Endif

    if !("<infNFe" $ cXML)
        cErro := "A estrutura NFe nao possui o nó nfNFe"
        Return .F.
    Endif

Return .T.

Static Function fTagRaiz(cXML)
    Local c     := AllTrim(cXML)
    Local nFim  := 0
    Local nAbr  := 0
    Local nTag  := 0

    If Left(c, 5) == "<?xml"
        nFim := At("?>", c)
        If nFim > 0
            c := AllTrim(SubStr(c, nFim + 2))
        Endif
    Endif

    nAbr := At("<", c)
    If nAbr == 0
        Return ""
    Endif

    c := SubStr(c, nAbr + 1)

    nFim := At(">", c)
    If nFim == 0
        Return ""
    Endif

    c := SubStr(c, 1, nFim - 1)

    nTag := At(" ", c)
    If nTag > 0
        c := SubStr(c, 1, nTag - 1)
    Endif

Return Upper(AllTrim(c))
