**FREE
// =============================================================================
// Module  : CTRYSVC
// Purpose : Country / State service.
//           - Accepts a country name.
//           - Calls the countriesnow.space states API (GET variant)
//           - Parses the JSON response to extract state names
//           - Populates an array of state names passed in by STATEMAIN.
//
// Compile : CRTRPGMOD MODULE(RAIPX61/CTRYSVC) SRCFILE(RAIPX61/QRPGLESRC)
//           SRCMBR(CTRYSVC) DFTACTGRP(*NO) ACTGRP(QILE)
// =============================================================================

Ctl-Opt NoMain BndDir('QC2LE':'HTTPBNDDIR');

/COPY QRPGLESRC,HTTPSVC

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
Dcl-C  MAX_STATES    200;
Dcl-C  API_BASE      'https://countriesnow.space/api/v0.1/countries/states';

// ---------------------------------------------------------------------------
// Single-character hex constants - avoids EBCDIC/ASCII transfer corruption.
// When a UTF-8 source file is uploaded to IBM i without CCSID conversion,
// these characters map to wrong code points in EBCDIC CCSID 37:
//
//   Character  ASCII  EBCDIC(37)   RPG hex literal
//   "          x22    x7F          x'7F'
//   [          x5B    xAD          x'AD'
//   ]          x5D    xBD          x'BD'
//   {          x7B    xC0          x'C0'
//
// Using x'...' constants makes the value CCSID-independent.
// ---------------------------------------------------------------------------
Dcl-C  DQ   x'7F';
Dcl-C  LBR  x'AD';
Dcl-C  RBR  x'BD';
Dcl-C  LBC  x'C0';

// ---------------------------------------------------------------------------
// Exported data structures
// ---------------------------------------------------------------------------
Dcl-Ds StateEntry  Qualified Template;
  StateName  Varchar(80);
End-Ds;

// ---------------------------------------------------------------------------
// Prototype
// ---------------------------------------------------------------------------
Dcl-Pr GetStates   ExtProc('GetStates');
  pCountry    Varchar(80)  Const;
  pStates     LikeDs(StateEntry) Dim(MAX_STATES);
  pCount      Int(10);
  pErrMsg     Varchar(256);
End-Pr;

// ---------------------------------------------------------------------------
// Procedure: GetStates
//   pCountry  - country name (e.g. India)
//   pStates   - output array of state names
//   pCount    - number of states found
//   pErrMsg   - blank = success; populated = error message
// ---------------------------------------------------------------------------
Dcl-Proc GetStates Export;
  Dcl-Pi *N;
    pCountry  Varchar(80)  Const;
    pStates   LikeDs(StateEntry) Dim(MAX_STATES);
    pCount    Int(10);
    pErrMsg   Varchar(256);
  End-Pi;

  Dcl-S  url         Varchar(1024);
  Dcl-S  payload     Varchar(65535);
  Dcl-S  errHttp     Varchar(256);
  Dcl-S  searchStr   Varchar(80);
  Dcl-S  remainder   Varchar(65535);
  Dcl-S  token       Varchar(80);
  Dcl-S  pos1        Int(10)  Inz(0);
  Dcl-S  pos2        Int(10)  Inz(0);
  Dcl-S  posEnd      Int(10)  Inz(0);
  Dcl-S  idx         Int(10)  Inz(0);

  pCount  = 0;
  pErrMsg = *Blanks;

  // Build GET URL:
  // https://countriesnow.space/api/v0.1/countries/states/q?country=India
  url = API_BASE + '/q?country=' + %TrimR(pCountry);

  HTTP_Get( url : payload : errHttp );

  If errHttp <> *Blanks;
    pErrMsg = errHttp;
    Return;
  EndIf;

  If payload = *Blanks;
    pErrMsg = 'No data returned. Try after some time...';
    Return;
  EndIf;

  // -------------------------------------------------------------------------
  // Lightweight JSON parser.
  // Uses hex constants for " [ ] to survive EBCDIC/ASCII transfer.
  //
  // Target JSON shape:
  //   {"error":false,"data":{"name":"India","states":[{"name":"Goa",...}]}}
  //
  // Step 1 - find  "states":[
  // Step 2 - inside that array find each  "name":"<value>"
  // -------------------------------------------------------------------------

  // searchStr = "states":[
  searchStr = DQ + 'states' + DQ + ':' + LBR;
  pos1      = %Scan(searchStr : payload);

  If pos1 = 0;
    // Check for "error":true
    If %Scan(DQ + 'error' + DQ + ':true' : payload) > 0;
      pErrMsg = 'Country not found. Please check the country name.';
    Else;
      pErrMsg = 'Unexpected response from server. Try after some time...';
    EndIf;
    Return;
  EndIf;

  // Isolate the content after "states":[
  remainder = %SubSt(payload : pos1 + %Len(searchStr));

  // Trim at the closing ] of the states array
  posEnd = %Scan(RBR : remainder);
  If posEnd > 1;
    remainder = %SubSt(remainder : 1 : posEnd - 1);
  EndIf;

  // Parse each "name":"<value>" pair
  // searchStr = "name":"
  searchStr = DQ + 'name' + DQ + ':' + DQ;
  pos1      = 1;

  DoW idx < MAX_STATES;
    pos1 = %Scan(searchStr : remainder : pos1);
    If pos1 = 0;
      Leave;
    EndIf;

    pos2   = pos1 + %Len(searchStr);   // first char of value
    posEnd = %Scan(DQ : remainder : pos2);
    If posEnd = 0;
      Leave;
    EndIf;

    token = %SubSt(remainder : pos2 : posEnd - pos2);
    token = %TrimR(token);

    If token <> *Blanks And token <> 'null';
      idx += 1;
      pStates(idx).StateName = token;
    EndIf;

    pos1 = posEnd + 1;
  EndDo;

  pCount = idx;

  If pCount = 0;
    pErrMsg = 'No states found for country: ' + %TrimR(pCountry);
  EndIf;

  Return;
End-Proc;
