**FREE
// =============================================================================
// Program : STATEMAIN
// Purpose : Main interactive program.
//           1. Shows PROMPTRCD \Z user enters a country name.
//           2. Calls GetStates (CTRYSVC) via HTTPS.
//           3. Loads state names into windowed subfile STATELIST.
//           4. Displays subfile with PgUp/PgDn scrolling.
//           5. On network error shows  "Server could not be reached..."
//           6. F3 / F12 to exit at any time.
//
// Compile : CRTBNDRPG PGM(MYLIB/STATEMAIN) SRCFILE(MYLIB/QRPGLESRC)
//           SRCMBR(STATEMAIN) DFTACTGRP(*NO) ACTGRP(QILE)
//           BNDDIR(HTTPSVCLIB)
// =============================================================================

Ctl-Opt BndDir('QC2LE':'HTTPBNDDIR')
        Option(*SrcStmt : *NoDebugIO);

// ---------------------------------------------------------------------------
// Display file
// ---------------------------------------------------------------------------
Dcl-F STATELIST WorkStn UsrOpn IndDs(Ind) sfile(SFLRCD : SFLRCDNBR) ;

// ---------------------------------------------------------------------------
// Indicator data structure (maps *IN indicators to named booleans)
// ---------------------------------------------------------------------------
Dcl-Ds Ind ;
  ExitKey    Ind Pos(3);    // CA03 F3
  CancelKey  Ind Pos(12);   // CA12 F12
  SflDsp     Ind Pos(31);   // Subfile display  indicator
  SflDspCtl  Ind Pos(32);   // Subfile ctl display indicator
  SflClr     Ind Pos(33);   // Subfile clear indicator
  SflEnd     Ind Pos(34);   // SFL end indicator
End-Ds;

// ---------------------------------------------------------------------------
// Bind CTRYSVC prototype
// ---------------------------------------------------------------------------
Dcl-C  MAX_STATES  200;

Dcl-Ds StateEntry  Qualified Template;
  StateName  Varchar(80);
End-Ds;

Dcl-Pr GetStates   ExtProc('GetStates');
  pCountry    Varchar(80)  Const;
  pStates     LikeDs(StateEntry) Dim(MAX_STATES);
  pCount      Int(10);
  pErrMsg     Varchar(256);
End-Pr;

// ---------------------------------------------------------------------------
// Working variables
// ---------------------------------------------------------------------------
Dcl-Ds States       LikeDs(StateEntry) Dim(MAX_STATES);
Dcl-S  stateCount   Int(10)    Inz(0);
Dcl-S  wsErrMsg     Varchar(256);
Dcl-S  countryName  Varchar(80);
Dcl-S  rrn          Int(10)    Inz(0);
Dcl-S  i            Int(10)    Inz(0);
Dcl-S  topRrn       Int(10)    Inz(1);

// ---------------------------------------------------------------------------
// DSPF field variables (matching DSPF field names)
// ---------------------------------------------------------------------------
Dcl-S  CTRYINPUT    Char(30);
Dcl-S  CTRYNAME     Char(30);
Dcl-S  STATENAME    Char(40);
Dcl-S  SFLRRN       Packed(4:0);
Dcl-S  SFLRCDNBR    Packed(4:0) Inz(1);
Dcl-S  MSGLINE      Char(79);

// ===========================================================================
// MAIN LINE
// ===========================================================================

Open  STATELIST;

// ---- Prompt loop -----------------------------------------------------------
DoU ExitKey Or CancelKey;

  // Clear prompt fields
  CTRYINPUT = *Blanks;
  MSGLINE   = *Blanks;
  ExitKey   = *Off;
  CancelKey = *Off;

  Write PROMPTRCD;
  Exfmt PROMPTRCD;

  If ExitKey Or CancelKey;
    Leave;
  EndIf;

  countryName = %TrimR(CTRYINPUT);
  If countryName = *Blanks;
    MSGLINE = 'Please enter a country name.';
    Write PROMPTRCD;
    Iter;
  EndIf;

  // ---- Call the web service ------------------------------------------------
  wsErrMsg   = *Blanks;
  stateCount = 0;

  GetStates( countryName : States : stateCount : wsErrMsg );

  // ---- Handle web-service error --------------------------------------------
  If wsErrMsg <> *Blanks;
    // MSGLINE = %Left(%TrimR(wsErrMsg) : 79);
    MSGLINE = %TrimR(wsErrMsg);
    Iter;                          // Loop back to prompt
  EndIf;

  // ---- Load subfile --------------------------------------------------------
  // CTRYNAME   = %Left(%TrimR(countryName) : 30);
  CTRYNAME   = %TrimR(countryName) ;


  // Clear previous subfile contents
  SflDsp    = *Off;
  SflDspCtl = *Off;
  SflClr    = *On;
  Write SFLCTL1;
  SflClr    = *Off;

  For i = 1 to stateCount;
    rrn        = i;
    SFLRRN     = rrn;
    SFLRCDNBR = rrn;
    // STATENAME  = %Left(%TrimR(States(i).StateName) : 40);
    STATENAME  = %TrimR(States(i).StateName);
    Write SFLRCD;
  EndFor;

  // ---- Display subfile in window -------------------------------------------
  SflDsp    = *On;
  SflDspCtl = *On;
  SFLRCDNBR = 1;
  ExitKey   = *Off;
  CancelKey = *Off;

  DoU ExitKey Or CancelKey;
    Exfmt SFLCTL1;
    If ExitKey Or CancelKey;
      Leave;
    EndIf;
  EndDo;

  // After closing the window, loop back to prompt unless F3 pressed
  If ExitKey;
    Leave;
  EndIf;

EndDo;

// ---------------------------------------------------------------------------
Close STATELIST;
*InLR = *On;
Return;
