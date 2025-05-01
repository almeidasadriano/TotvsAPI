#Include "TOTVS.ch"    
#include "Topconn.ch"  
#include "RESTFUL.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"   
#INCLUDE "Fileio.ch"
#INCLUDE "totvs.ch"


#DEFINE LOG_DIRECTORY               "\log_integ"

//+------------------------------------------------------------------------------------------------------------------+
//| Programa | API_Protheus | Autor | Adriano Almeida | Data | 10.04.2025 | 
//+------------------------------------------------------------------------------------------------------------------+
//| Descr. | API REST Para Inclusão de Pré-NF | 
//| 
//+------------------------------------------------------------------------------------------------------------------+
//| Uso | Integração 
//+------------------------------------------------------------------------------------------------------------------+

WSRESTFUL APIEPICURE DESCRIPTION "API REST Protheus" SECURITY 'MATA140' FORMAT APPLICATION_JSON 
    WSDATA RequestNumber As Character
    
    WSMETHOD POST IncluirPreNF DESCRIPTION "API utilizada pra incluir Pré-Nota" WSSYNTAX "/Incluir/prenf" PRODUCES APPLICATION_JSON

ENDWSRESTFUL



WSMETHOD POST IncluirPreNF WSRECEIVE WSRESTFUL APIEPICURE
    Local lRet  := .T.
    Local aArea :=GetArea()
    Local aCabec
    Local dData
    Local aItens
    Local aLinha

    Local oJson
    Local oItems

    Local cJson := Self:GetContent()
    Local cError

    Local nX
    Local nY

    Private lMsErroAuto := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.
    Private cChaveSF1       := ""


    //Se não existir o diretório de logs dentro da Protheus Data, será criado
    IF .NOT. ExistDir(LOG_DIRECTORY)
        MakeDir(LOG_DIRETCTORY)
    EndIF  

     //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)


     //Se tiver algum erro no Parse, encerra a execução
    IF .NOT. Empty(cError)
        SetRestFault(500,'Parser Json Error')
        lRet    := .F.
    Else

        PREPARE ENVIRONMENT EMPRESA '01' FILIAL oJson:GetJsonObject('Filial') 


         //Se encontrar o Fornecedor existente conforme dados do JSON
        DbSelectArea('SA2')
            SA2->(dbSetOrder(1))
            IF (SA2->(dbSeek(FWxFilial("SA2")+PadR(oJson:GetJsonObject('Fornecedor'),TamSX3("A2_COD")[1])+PadR(oJson:GetJsonObject('Loja'),TamSX3("A2_LOJA")[1]))))
                aCabec  := {}
                aItens  := {}

  
                cChaveSF1 := FWxFilial("SF1") +;
                             PadR(AllTrim(oJson:GetJsonObject('Doc')), TamSX3("F1_DOC")[1]) +;
                             PadR(AllTrim(oJson:GetJsonObject('Serie')), TamSX3("F1_SERIE")[1]) +;
                             PadR(AllTrim(oJson:GetJsonObject('Fornecedor')), TamSX3("F1_FORNECE")[1]) +; 
                             PadR(AllTrim(oJson:GetJsonObject('Loja')), TamSX3("F1_LOJA")[1])+;
                             PadR(AllTrim(oJson:GetJsonObject('Tipo')), TamSX3("F1_TIPO")[1])
                
                //Se conseguir posicionar na nota, retorna que já existe
                If SF1->(MsSeek(cChaveSF1))

                    SetRestFault(500,EncodeUTF8("- NF já existe na base, chave de pesquisa: " + cChaveSF1 + CRLF))
                    lRet := .F.
                ELSE

                       //2. Altera as variáveis públicas
                    cEmpAnt := "01"
                    cFilAnt := oJson:GetJsonObject('Filial')
                    cNumEmp := cEmpAnt + cFilAnt

                    //Converte Data
                    dData := SToD(oJson:GetJsonObject('Emissao'))

                    //Posições do Cabeçalho (SF1)
                    aAdd(aCabec,{"F1_FILIAL",    AllTrim(oJson:GetJsonObject('Filial')),         NIL})
                    aAdd(aCabec,{"F1_TIPO",      AllTrim(oJson:GetJsonObject('Tipo')),           NIL})
                    aAdd(aCabec,{"F1_FORMUL",    AllTrim(oJson:GetJsonObject('Formul')),         NIL})
                    aAdd(aCabec,{"F1_DOC",       AllTrim(oJson:GetJsonObject('Doc')),            NIL})
                    aAdd(aCabec,{"F1_SERIE",     AllTrim(oJson:GetJsonObject('Serie')),          NIL})
                    aAdd(aCabec,{"F1_EMISSAO",   dData,                                          NIL})
                    aAdd(aCabec,{"F1_FORNECE",   AllTrim(oJson:GetJsonObject('Fornecedor')),     NIL})
                    aAdd(aCabec,{"F1_LOJA",      AllTrim(oJson:GetJsonObject('Loja')),           NIL})
                    aAdd(aCabec,{"F1_ESPECIE",   AllTrim(oJson:GetJsonObject('Especie')),        NIL})
                    aAdd(aCabec,{"F1_COND",      AllTrim(oJson:GetJsonObject('CondPagto')),      NIL})

                
                    //Busca os itens no JSON, percorre eles e adiciona no array da SD1
                    oItems  := oJson:GetJsonObject('Items')
            
                    For nX  := 1 To Len (oItems)
                        aLinha  := {}
                        aAdd(aLinha,{"D1_FILIAL",   cFilAnt,                                                                          NIL})
                        aAdd(aLinha,{"D1_ITEM",     AllTrim(oItems[nX]:GetJsonObject('Item')),                                        NIL})
                        aAdd(aLinha,{"D1_COD",      AllTrim(oItems[nX]:GetJsonObject('Codigo')),                                      NIL})
                        aAdd(aLinha,{"D1_CC",       AllTrim(oItems[nX]:GetJsonObject('CentroCusto')),                                 NIL})
                        aAdd(aLinha,{"D1_CONTA",    AllTrim(oItems[nX]:GetJsonObject('Conta')),                                       NIL})
                        aAdd(aLinha,{"D1_LOCAL",    AllTrim(oItems[nX]:GetJsonObject('Local')),                                       NIL})              
                        aAdd(aLinha,{"D1_QUANT",    oItems[nX]:GetJsonObject('Quantidade'),                                           NIL})
                        aAdd(aLinha,{"D1_VUNIT",    oItems[nX]:GetJsonObject('Value'),                                                NIL})
                        aAdd(aLinha,{"D1_TOTAL",    oItems[nX]:GetJsonObject('Quantidade') * oItems[nX]:GetJsonObject('Value'),       Nil} )
                        aAdd(aLinha,{"D1_TES",      AllTrim(oItems[nX]:GetJsonObject('TES')),                                         NIL})
                        aAdd(aItens,aLinha)
                    Next nX

                    //Chama a inclusão automática de pré-nota de entrada
                    MSExecAuto({|x, y, z| MATA140(x, y, z)}, aCabec, aItens, 3)

                    //Se houve erro, gera um arquivo de log dentro do diretório da protheus data
                    IF lMsErroAuto
                        cArqLog := oJson:GetJsonObject('Fornecedor')+oJson:GetJsonObject('Loja')+"-"+ StrTran(Time(), ':', '-')+".log"
                        aLogAuto    := {}
                        aLogAuto    := GetAutoGrLog()
                        For nY := 1 To Len(aLogAuto)
                            cErro += aLogAuto[nY] + CRLF
                        Next nY
                        MemoWrite(LOG_DIRECTORY + cArqLog,cErro)
                        SetRestFault(500, cErro)
                        lRet    := .F.
                    ELSE
                        cJsonRet    := '{"Pré-Nota gerada com sucesso":"'+SF1->F1_DOC+'"}'
                        Self:SetResponse(cJsonRet)
                    EndIF
                
                EndIF

            ELSE
                SetRestFault(500,EncodeUTF8(oJson:GetJsonObject('Fornecedor') + ",fornecedor não encontrado"))
                lRet := .F.
            EndIF
    EndIf
    
    RestArea(aArea)
    FreeObj(oJson)
    
    RESET ENVIRONMENT 
Return(lRet)
