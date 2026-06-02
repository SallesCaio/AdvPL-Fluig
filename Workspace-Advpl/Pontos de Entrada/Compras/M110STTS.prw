#Include "Protheus.ch"
#Include "TopConn.ch"

User Function M110STTS()
    Local lRet := .T.

    If ParamIxb[2] <> 3
        lRet := U_SCENVFLU(ParamIxb[1])
    ElseIf ParamIxb[2] == 3
        lRet := .T.
    EndIf

Return lRet
