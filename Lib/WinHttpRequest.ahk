#Requires AutoHotkey v1.1

; Version: 2023.07.05.2
; https://gist.github.com/e6062286ac7f4c35b612d3a53535cc2a
; Usage and examples: https://redd.it/mcjj4s
; Testing: http://httpbin.org/ | http://httpbun.org/ | http://ptsv2.com/

WinHttpRequest(oOptions := "") {
    return new WinHttpRequest(oOptions)
}

class WinHttpRequest extends WinHttpRequest.Functor {

    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

    ;#region: Meta

    __New(oOptions := "") {
        static HTTPREQUEST_PROXYSETTING_DEFAULT := 0, HTTPREQUEST_PROXYSETTING_DIRECT := 1, HTTPREQUEST_PROXYSETTING_PROXY := 2, EnableCertificateRevocationCheck := 18, SslErrorIgnoreFlags := 4, SslErrorFlag_Ignore_All := 13056, SecureProtocols := 9, WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_3 := 8192, WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_2 := 2048, UserAgentString := 0
        if (!IsObject(oOptions)) {
            oOptions := {}
        }
        if (!oOptions.HasKey("Proxy") || !oOptions.Proxy) {
            this.whr.SetProxy(HTTPREQUEST_PROXYSETTING_DEFAULT)
        } else if (oOptions.Proxy = "DIRECT") {
            this.whr.SetProxy(HTTPREQUEST_PROXYSETTING_DIRECT)
        } else {
            this.whr.SetProxy(HTTPREQUEST_PROXYSETTING_PROXY, oOptions.Proxy)
        }
        if (oOptions.HasKey("Revocation")) {
            this.whr.Option[EnableCertificateRevocationCheck] := !!oOptions.Revocation
        } else {
            this.whr.Option[EnableCertificateRevocationCheck] := true
        }
        if (oOptions.HasKey("SslError")) {
            if (oOptions.SslError = false) {
                this.whr.Option[SslErrorIgnoreFlags] := SslErrorFlag_Ignore_All
            }
        }
        if (!oOptions.HasKey("TLS")) {
            this.whr.Option[SecureProtocols] := WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_3 | WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_2
        } else {
            this.whr.Option[SecureProtocols] := oOptions.TLS
        }
        if (oOptions.HasKey("UA")) {
            this.whr.Option[UserAgentString] := oOptions.UA
        }
    }
    ;#endregion

    ;#region: Static

    EncodeUri(sUri) {
        return this._EncodeDecode(sUri, true, false)
    }

    EncodeUriComponent(sComponent) {
        return this._EncodeDecode(sComponent, true, true)
    }

    DecodeUri(sUri) {
        return this._EncodeDecode(sUri, false, false)
    }

    DecodeUriComponent(sComponent) {
        return this._EncodeDecode(sComponent, false, true)
    }

    ObjToQuery(oData) {
        if (!IsObject(oData)) {
            return oData
        }
        out := ""
        for key, val in oData {
            out .= this._EncodeDecode(key, true, true) "="
            out .= this._EncodeDecode(val, true, true) "&"
        }
        return RTrim(out, "&")
    }

    QueryToObj(sData) {
        if (IsObject(sData)) {
            return sData
        }
        sData := LTrim(sData, "?")
        obj := {}
        for _, part in StrSplit(sData, "&") {
            pair := StrSplit(part, "=", "", 2)
            key := this._EncodeDecode(pair[1], false, true)
            val := this._EncodeDecode(pair[2], false, true)
            obj[key] := val
        }
        return obj
    }
    ;#endregion

    ;#region: Public

    Request(sMethod, sUrl, mBody := "", oHeaders := false, oOptions := false) {
        if (this.whr = "") {
            throw Exception("Not initialized.", -1)
        }
        sMethod := Format("{:U}", sMethod) ; CONNECT not supported
        if !(sMethod ~= "^(DELETE|GET|HEAD|OPTIONS|PATCH|POST|PUT|TRACE)$") {
            throw Exception("Invalid HTTP verb.", -1, sMethod)
        }
        if !(sUrl := Trim(sUrl)) {
            throw Exception("Empty URL.", -1)
        }
        if (!IsObject(oHeaders)) {
            oHeaders := {}
        }
        if (!IsObject(oOptions)) {
            oOptions := {}
        }
        if (sMethod = "POST") {
            multi := oOptions.HasKey("Multipart") ? !!oOptions.Multipart : false
            this._Post(mBody, oHeaders, multi)
        } else if (sMethod = "GET" && mBody) {
            sUrl := RTrim(sUrl, "&")
            sUrl .= InStr(sUrl, "?") ? "&" : "?"
            sUrl .= WinHttpRequest.ObjToQuery(mBody)
            mBody := ""
        }
        this.whr.Open(sMethod, sUrl, true)
        for key, val in oHeaders {
            this.whr.SetRequestHeader(key, val)
        }
        this.whr.Send(mBody)
        this.whr.WaitForResponse()
        if (oOptions.HasKey("Save")) {
            target := RegExReplace(oOptions.Save, "^\h*\*\h*", "", forceSave)
            if (this.whr.Status = 200 || forceSave) {
                this._Save(target)
            }
            return this.whr.Status
        }
        out := new WinHttpRequest._Response()
        out.Headers := this._Headers()
        out.Status := this.whr.Status
        out.Text := this._Text(oOptions.HasKey("Encoding") ? oOptions.Encoding : "")
        return out
    }
    ;#endregion

    ;#region: Private

    static _doc := ""

    _EncodeDecode(Text, bEncode, bComponent) {
        if (this._doc = "") {
            this._doc := ComObjCreate("HTMLFile")
            this._doc.write("<meta http-equiv='X-UA-Compatible' content='IE=Edge'>")
        }
        action := (bEncode ? "en" : "de") "codeURI" (bComponent ? "Component" : "")
        return ObjBindMethod(this._doc.parentWindow, action).Call(Text)
    }

    _Headers() {
        headers := this.whr.GetAllResponseHeaders()
        headers := RTrim(headers, "`r`n")
        out := {}
        for _, line in StrSplit(headers, "`n", "`r") {
            pair := StrSplit(line, ":", " ", 2)
            out[pair[1]] := pair[2]
        }
        return out
    }

    _Mime(Extension) {
        if (WinHttpRequest.MIME.HasKey(Extension)) {
            return WinHttpRequest.MIME[Extension]
        }
        return "application/octet-stream"
    }

    _MultiPart(ByRef Body) {
        static LMEM_ZEROINIT := 64, EOL := "`r`n"
        this._memLen := 0
        this._memPtr := DllCall("LocalAlloc", "UInt", LMEM_ZEROINIT, "UInt", 1)
        boundary := "----------WinHttpRequest-" A_NowUTC A_MSec
        for field, value in Body {
            this._MultiPartAdd(boundary, EOL, field, value)
        }
        this._MultipartStr("--" boundary "--" EOL)
        Body := ComObjArray(0x11, this._memLen)
        pvData := NumGet(ComObjValue(Body) + 8 + A_PtrSize, "Ptr")
        DllCall("RtlMoveMemory", "Ptr", pvData, "Ptr", this._memPtr, "UInt", this._memLen)
        DllCall("LocalFree", "Ptr", this._memPtr)
        return boundary
    }

    _MultiPartAdd(Boundary, EOL, Field, Value) {
        if (!IsObject(Value)) {
            str := "--" Boundary
            str .= EOL
            str .= "Content-Disposition: form-data; name=""" Field """"
            str .= EOL
            str .= EOL
            str .= Value
            str .= EOL
            this._MultipartStr(str)
            return
        }
        for _, path in Value {
            SplitPath path, filename, , ext
            str := "--" Boundary
            str .= EOL
            str .= "Content-Disposition: form-data; name=""" Field """; filename=""" filename """"
            str .= EOL
            str .= "Content-Type: " this._Mime(ext)
            str .= EOL
            str .= EOL
            this._MultipartStr(str)
            this._MultipartFile(path)
            this._MultipartStr(EOL)
        }
    }

    _MultipartFile(Path) {
        static LHND := 66
        try {
            oFile := FileOpen(Path, 0x0)
        } catch {
            throw Exception("Couldn't open file for reading.", -1, Path)
        }
        this._memLen += oFile.Length
        this._memPtr := DllCall("LocalReAlloc", "Ptr", this._memPtr, "UInt", this._memLen, "UInt", LHND)
        oFile.RawRead(this._memPtr + this._memLen - oFile.length, oFile.length)
    }

    _MultipartStr(Text) {
        static LHND := 66
        size := StrPut(Text, "UTF-8") - 1
        this._memLen += size
        this._memPtr := DllCall("LocalReAlloc", "Ptr", this._memPtr, "UInt", this._memLen, "UInt", LHND)
        StrPut(Text, this._memPtr + this._memLen - size, size, "UTF-8")
    }

    _Post(ByRef Body, ByRef Headers, bMultipart) {
        isMultipart := 0
        for _, value in Body {
            isMultipart += !!IsObject(value)
        }
        if (isMultipart || bMultipart) {
            Body := WinHttpRequest.QueryToObj(Body)
            boundary := this._MultiPart(Body)
            Headers["Content-Type"] := "multipart/form-data; boundary=""" boundary """"
        } else {
            Body := WinHttpRequest.ObjToQuery(Body)
            if (!Headers.HasKey("Content-Type")) {
                Headers["Content-Type"] := "application/x-www-form-urlencoded"
            }
        }
    }

    _Save(Path) {
        arr := this.whr.ResponseBody
        pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize, "Ptr")
        length := arr.MaxIndex() + 1
        FileOpen(Path, 0x1).RawWrite(pData + 0, length)
    }

    _Text(Encoding) {
        response := ""
        try response := this.whr.ResponseText
        if (response = "" || Encoding != "") {
            try {
                arr := this.whr.ResponseBody
                pData := NumGet(ComObjValue(arr) + 8 + A_PtrSize, "Ptr")
                length := arr.MaxIndex() + 1
                response := StrGet(pData, length, Encoding)
            }
        }
        return response
    }

    class Functor {

        __Call(Method, Parameters*) {
            return this.Request(Method, Parameters*)
        }

    }

    class _Response {

        Json {
            get {
                method := Json.HasKey("parse") ? "parse" : "Load"
                oJson := ObjBindMethod(Json, method, this.Text).Call()
                ObjRawSet(this, "Json", oJson)
                return oJson
            }
        }

    }

    ;#endregion

    class MIME {
        static 7z := "application/x-7z-compressed"
        static gif := "image/gif"
        static jpg := "image/jpeg"
        static json := "application/json"
        static png := "image/png"
        static zip := "application/zip"
    }

}