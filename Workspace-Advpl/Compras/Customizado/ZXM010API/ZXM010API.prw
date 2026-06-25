/*/{Protheus.doc} ZXM010API
Integracao API Rest - ZXM010 Fase 2
ViaCEP + Mercado Livre
@type Function
@author Caio Salles
@since 2026-06-23
@version 1.0
/*/

#Include "Protheus.ch"

// ============================================================
// VIACEP - Consulta CEP (API publica, sem autenticacao)
// ============================================================

/*/{Protheus.doc} ZXMLCepConsulta
Consulta CEP na API ViaCEP
@param cCep - CEP a consultar (somente numeros)
@return oJson - Objeto JSON com dados do endereco
@type Static Function
/*/
Static Function ZXMLCepConsulta(cCep)
    Local cUrl     := "https://viacep.com.br/ws/" + cCep + "/json/"
    Local cResp    := ""
    Local oJson    := Nil
    Local aHeaders := {}

    AAdd(aHeaders, "User-Agent: Protheus")
    AAdd(aHeaders, "Accept: application/json")

    cResp := HttpGet(cUrl, , aHeaders)

    If !Empty(cResp)
        oJson := JsonObject():New()
        If oJson:FromJson(cResp) != 0
            oJson := Nil
        EndIf
    EndIf

Return oJson

/*/{Protheus.doc} ZXMLCepPreenche
Preenche endereco via CEP na tabela ZXM
@param cCep - CEP informado
@param cEndereco - Variavel para receber o endereco completo
@return lRet - .T. se conseguiu preencher
@type Static Function
/*/
Static Function ZXMLCepPreenche(cCep, cEndereco)
    Local oJson := ZXMLCepConsulta(cCep)
    Local lRet  := .F.

    If oJson != Nil .And. oJson:HasProperty("logradouro")
        cEndereco := ""
        cEndereco += oJson:GetJsonString("logradouro")
        cEndereco += ", " + oJson:GetJsonString("bairro")
        cEndereco += " - " + oJson:GetJsonString("localidade")
        cEndereco += "/" + oJson:GetJsonString("uf")
        lRet := .T.
    EndIf

Return lRet

// ============================================================
// MERCADO LIVRE - OAuth2 + Busca de Produtos
// ============================================================

Static cML_ClientId     := ""
Static cML_ClientSecret := ""
Static cML_AccessToken  := ""
Static cML_ExpiresAt    := 0

/*/{Protheus.doc} ZXMLMLAuth
Autenticacao OAuth2 Mercado Livre
@return lRet - .T. se autenticou com sucesso
@type Static Function
/*/
Static Function ZXMLMLAuth()
    Local cUrl     := "https://api.mercadolibre.com/oauth/token"
    Local cBody    := "grant_type=client_credentials&client_id=" + cML_ClientId + "&client_secret=" + cML_ClientSecret
    Local cResp    := ""
    Local oJson    := Nil
    Local aHeaders := {}

    AAdd(aHeaders, "Content-Type: application/x-www-form-urlencoded")
    AAdd(aHeaders, "Accept: application/json")

    cResp := HttpPost(cUrl, cBody, , aHeaders)

    If !Empty(cResp)
        oJson := JsonObject():New()
        If oJson:FromJson(cResp) == 0
            cML_AccessToken := oJson:GetJsonString("access_token")
            cML_ExpiresAt    := Seconds() + oJson:GetJsonInteger("expires_in")
        EndIf
    EndIf

Return !Empty(cML_AccessToken)

/*/{Protheus.doc} ZXMLMLBusca
Busca produtos no Mercado Livre
@param cQuery - Termo de busca
@return aItens - Array com resultados
@type Static Function
/*/
Static Function ZXMLMLBusca(cQuery)
    Local cUrl     := "https://api.mercadolibre.com/sites/MLB/search?q=" + cQuery
    Local cResp    := ""
    Local oJson    := Nil
    Local aItens   := {}
    Local aResults := {}
    Local nX       := 0
    Local aHeaders := {}

    AAdd(aHeaders, "Authorization: Bearer " + cML_AccessToken)
    AAdd(aHeaders, "Accept: application/json")

    cResp := HttpGet(cUrl, , aHeaders)

    If !Empty(cResp)
        oJson := JsonObject():New()
        If oJson:FromJson(cResp) == 0
            If oJson:HasProperty("results")
                aResults := oJson:GetJsonArray("results")
                For nX := 1 To Len(aResults)
                    AAdd(aItens, {;
                        aResults[nX]:GetJsonString("id"),;
                        aResults[nX]:GetJsonString("title"),;
                        aResults[nX]:GetJsonNumber("price"),;
                        aResults[nX]:GetJsonString("currency_id");
                    })
                Next
            EndIf
        EndIf
    EndIf

Return aItens

/*/{Protheus.doc} ZXMLMLCotacao
Obtem cotacao de um item especifico do ML
@param cItemId - ID do item no Mercado Livre
@return nPreco - Preco do item (0 se nao encontrado)
@type Static Function
/*/
Static Function ZXMLMLCotacao(cItemId)
    Local cUrl     := "https://api.mercadolibre.com/items/" + cItemId
    Local cResp    := ""
    Local oJson    := Nil
    Local nPreco   := 0
    Local aHeaders := {}

    AAdd(aHeaders, "Authorization: Bearer " + cML_AccessToken)
    AAdd(aHeaders, "Accept: application/json")

    cResp := HttpGet(cUrl, , aHeaders)

    If !Empty(cResp)
        oJson := JsonObject():New()
        If oJson:FromJson(cResp) == 0
            nPreco := oJson:GetJsonNumber("price")
        EndIf
    EndIf

Return nPreco

/*/{Protheus.doc} ZXMLMLPreench
Preenche valor da solicitacao com cotacao ML
@param cCodProd - Codigo do produto ML
@param nValor   - Variavel para receber o valor
@return lRet - .T. se conseguiu obter cotacao
@type Static Function
/*/
Static Function ZXMLMLPreench(cCodProd, nValor)
    Local lRet := .F.

    If Empty(cML_AccessToken) .Or. Seconds() > cML_ExpiresAt
        ZXMLMLAuth()
    EndIf

    If !Empty(cML_AccessToken)
        nValor := ZXMLMLCotacao(cCodProd)
        lRet   := nValor > 0
    EndIf

Return lRet

// ============================================================
// WRAPPER PARA USO NO ZXM010
// ============================================================

/*/{Protheus.doc} ZXM010APILoad
Carrega API e retorna dados para formulario
@param cAcao    - "CEP" ou "ML"
@param cParam   - Parametro (CEP ou ID do produto)
@param xRetorno - Retorno da consulta
@return lRet - .T. se sucesso
@type User Function
/*/
User Function ZXM010APILoad(cAcao, cParam, xRetorno)
    Local lRet := .F.

    Do Case
    Case cAcao == "CEP"
        xRetorno := ZXMLCepConsulta(cParam)
        lRet     := xRetorno != Nil
    Case cAcao == "ML"
        xRetorno := ZXMLMLCotacao(cParam)
        lRet     := xRetorno > 0
    EndCase

Return lRet
