**FREE
// =============================================================================
// Header / Prototype copy book for HTTPSVC service program
// /COPY this into any module that needs HTTP_Get
// =============================================================================

Dcl-Pr HTTP_Get        ExtProc('HTTP_Get');
  pUrl               Varchar(1024) Const;
  pResponse          Varchar(65535);
  pErrMsg            Varchar(256);
End-Pr;
