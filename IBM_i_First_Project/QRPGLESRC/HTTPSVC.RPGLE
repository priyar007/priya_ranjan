**FREE
// =============================================================================
// Module  : HTTPSVC
// Purpose : HTTP/HTTPS utility service — wraps IBM i HTTP API (HTTPGETCLOB /
//           QHttpGet) to perform a simple GET request and return the raw body.
//           Used by CTRYSVC to call the REST Countries API.
//
// Compile : CRTRPGMOD MODULE(MYLIB/HTTPSVC) SRCFILE(MYLIB/QRPGLESRC)
//           SRCMBR(HTTPSVC) DFTACTGRP(*NO) ACTGRP(QILE)
//
// Service : Bound into MYLIB/HTTPSVCLIB via CRTSRVPGM
// =============================================================================

Ctl-Opt NoMain DftActGrp(*No) ActGrp('HTTPSVCGRP')
        BndDir('QC2LE':'QHTTPAPI');

// ---------------------------------------------------------------------------
// Prototype — exported so CTRYSVC can /COPY this header
// ---------------------------------------------------------------------------
Dcl-Pr HTTP_Get        ExtProc('HTTP_Get');
  pUrl               Varchar(1024) Const;
  pResponse          Varchar(65535);
  pErrMsg            Varchar(256);
End-Pr;

// ---------------------------------------------------------------------------
// IBM i HTTPS (QHttpGet) prototype
// ---------------------------------------------------------------------------
Dcl-Pr QHttpGet       ExtProc('QHttpGetClob');
  url                Pointer Value;
  urlLen             Int(10) Value;
  responseOut        Pointer Value;
  responseLen        Int(10) Value;
  responseLenActual  Int(10);
  httpStatusCode     Int(10);
  errorCode          Char(16);
End-Pr;

// ---------------------------------------------------------------------------
// Public procedure: HTTP_Get
//   pUrl      – full HTTPS URL to GET
//   pResponse – response body returned to caller (up to 65 KB)
//   pErrMsg   – blank on success; populated on failure
// ---------------------------------------------------------------------------
Dcl-Proc HTTP_Get Export;
  Dcl-Pi *N;
    pUrl      Varchar(1024) Const;
    pResponse Varchar(65535);
    pErrMsg   Varchar(256);
  End-Pi;

  Dcl-S  responseBuffer Char(65535)    Inz(*Blanks);
  Dcl-S  urlPtr         Pointer;
  Dcl-S  respPtr        Pointer;
  Dcl-S  urlBuf         Varchar(1024);
  Dcl-S  actualLen      Int(10)        Inz(0);
  Dcl-S  httpStatus     Int(10)        Inz(0);
  Dcl-S  errCode        Char(16)       Inz(*Blanks);

  pResponse = *Blanks;
  pErrMsg   = *Blanks;
  urlBuf    = pUrl;

  urlPtr  = %Addr(urlBuf);
  respPtr = %Addr(responseBuffer);

  // Call IBM i QHttpGetClob
  QHttpGet( urlPtr : %Len(%Trim(urlBuf)) :
            respPtr : %Size(responseBuffer) :
            actualLen : httpStatus : errCode );

  // Evaluate result
  If httpStatus = 200 And actualLen > 0;
    pResponse = %SubSt(responseBuffer : 1 : actualLen);
  ElseIf httpStatus = 0;
    // Network error / host unreachable
    pErrMsg = 'Server could not be reached. Try after some time...';
  Else;
    pErrMsg = 'HTTP Error ' + %Char(httpStatus)
            + '. Try after some time...';
  EndIf;

  Return;
End-Proc;
