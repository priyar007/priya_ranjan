**FREE
// =============================================================================
// Module  : HTTPSVC
// Type    : SQLRPGLE  (ILE RPG with embedded SQL)
// Purpose : HTTP GET utility - uses DB2 for i SQL function
//           SYSTOOLS.HTTPGETCLOB() to perform HTTPS GET requests.
//
//           No licensed product required - SYSTOOLS is part of the
//           IBM i base OS (5770-SS1) on V7R3 and later.
//           No binding directory needed beyond QC2LE (SQL runtime).
//
// Compile : CRTSQLRPGI OBJ(RAIPX61/HTTPSVCPGM) SRCFILE(RAIPX61/QRPGLESRC)
//                      SRCMBR(HTTPSVCPGM) OBJTYPE(*MODULE)
//                      COMMIT(*NONE) CLOSQLCSR(*ENDMOD)
//
// Service : Bound into RAIPX61/HTTPSVCPGM via CRTSRVPGM BNDDIR(QC2LE)
// =============================================================================

Ctl-Opt NoMain;

// ---------------------------------------------------------------------------
// Exported prototype (matches HTTPSVC.H - no change to callers)
// ---------------------------------------------------------------------------
Dcl-Pr HTTP_Get ExtProc('HTTP_Get');
  pUrl      Varchar(1024) Const;
  pResponse Varchar(32740);
  pErrMsg   Varchar(256);
End-Pr;

// ---------------------------------------------------------------------------
// Procedure: HTTP_Get
//   pUrl      - full HTTPS URL to GET
//   pResponse - response body returned to caller (up to 65 KB)
//   pErrMsg   - blank on success; populated on any error
//
// Uses: SYSTOOLS.HTTPGETCLOB(url, httpHeader)
//   - url        : the target URL (Varchar)
//   - httpHeader : NULL = no custom headers (Accept: application/json added)
//   - Returns    : CLOB with the full response body
// ---------------------------------------------------------------------------
Dcl-Proc HTTP_Get Export;
  Dcl-Pi *N;
    pUrl      Varchar(1024) Const;
    pResponse Varchar(32740);
    pErrMsg   Varchar(256);
  End-Pi;

  // SQLERRMC is injected by the SQL precompiler into the global SQLCA DS.
  // It holds the first 70 chars of the error message token - no need for
  // a separate GET DIAGNOSTICS call.
  Dcl-S  httpResult  Varchar(32740)  Inz(*Blanks);
  Dcl-S  errTok      Char(70)        Inz(*Blanks);

  pResponse = *Blanks;
  pErrMsg   = *Blanks;

  // -------------------------------------------------------------------------
  // SYSTOOLS.HTTPGETCLOB(url, httpHeader)
  //   CLOB result assigned directly to VARCHAR(32740) host variable via INTO.
  //   Second param NULL = use system default HTTP headers.
  // -------------------------------------------------------------------------
  Exec SQL
    SELECT SYSTOOLS.HTTPGETCLOB(
             CAST(:pUrl AS VARCHAR(1024)),
             CAST(NULL AS CLOB)
           )
    INTO :httpResult
    FROM SYSIBM.SYSDUMMY1;

  If SQLCODE = 0;
    pResponse = httpResult;
  ElseIf SQLCODE = 100;
    pErrMsg = 'No data returned. Try after some time...';
  Else;
    // Use SQLERRMC from SQLCA (injected by SQL precompiler) for error detail.
    errTok = %TrimR(SQLERRMC);
    If errTok <> *Blanks;
      pErrMsg = %SubSt(errTok : 1 : %Min(%Len(%TrimR(errTok)) : 256));
    Else;
      pErrMsg = 'Server could not be reached. Try after some time...';
    EndIf;
  EndIf;

  Return;
End-Proc;
