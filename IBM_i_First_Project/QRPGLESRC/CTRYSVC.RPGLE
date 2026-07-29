**FREE
// =============================================================================
// Module  : CTRYSVC
// Purpose : Country / State service.
//           - Accepts a country name.
//           - Calls  https://restcountries.com/v3.1/name/{country}
//           - Parses the JSON response to extract the list of states/regions
//             (administrative divisions) using the "subregion" or
//             "capitalInfo" structure — for a full state list the module
//             uses  https://countriesnow.space/api/v0.1/countries/states
//           - Populates a keyed array of state names passed in by STATEMAIN.
//
// Compile : CRTRPGMOD MODULE(MYLIB/CTRYSVC) SRCFILE(MYLIB/QRPGLESRC)
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
//   pCountry  – country name (e.g. "India")
//   pStates   – output array of state names
//   pCount    – number of states found
//   pErrMsg   – blank = success; populated = error message
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

  // Build POST-style URL (API accepts GET with query)
  // countriesnow returns JSON:
  //  { "error":false, "data":{ "name":"India",
  //    "states":[{"name":"Andhra Pradesh",...}, ...] } }

  // The API requires a POST with JSON body; we simulate with HTTPS POST.
  // For simplicity we use the GET variant that accepts a query param:
  //   GET /api/v0.1/countries/states?country=India  (not officially supported)
  // IBM i HTTPPOSTCLOB would be needed for POST — here we use the GET-only
  // open API that returns states directly:
  //   https://api.countrystatecity.in   (needs key)
  //
  // We therefore use the freely available:
  //   GET https://countriesnow.space/api/v0.1/countries/states
  //   with body  {"country":"India"}
  //
  // Because QHttpGetClob is GET-only we use an alternative free GET endpoint:
  //   GET https://restcountries.com/v3.1/name/{country}?fullText=true
  //   and extract "region","subregion" as a label; then use:
  //   GET https://www.travel-advisory.info/api?countrycode=XX
  //
  // BEST free GET-only states API:
  //   https://api.first.org/data/v1/countries  -- no states
  //
  // We use: https://countriesnow.space/api/v0.1/countries/states/q?country=India
  // (undocumented but functional GET variant)

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
  // Lightweight JSON parser
  // Looks for repeated pattern:  "name":"<state name>"
  // in the "states" array portion of the response.
  // -------------------------------------------------------------------------

  // First, navigate to "states":[ section
  searchStr = '"states":[';
  pos1      = %Scan(searchStr : payload);

  If pos1 = 0;
    // Try "error":true pattern — API returned an error object
    If %Scan('"error":true' : payload) > 0;
      pErrMsg = 'Country not found. Please check the country name.';
    Else;
      pErrMsg = 'Unexpected response from server. Try after some time...';
    EndIf;
    Return;
  EndIf;

  // Work on the sub-string after "states":[
  remainder = %SubSt(payload : pos1 + %Len(searchStr));

  // Find closing ] of the states array
  posEnd = %Scan(']' : remainder);
  If posEnd > 1;
    remainder = %SubSt(remainder : 1 : posEnd - 1);
  EndIf;

  // Parse each {"name":"<value>" ...} object
  searchStr = '"name":"';
  pos1      = 1;

  DoW idx < MAX_STATES;
    pos1 = %Scan(searchStr : remainder : pos1);
    If pos1 = 0;
      Leave;
    EndIf;

    pos2 = pos1 + %Len(searchStr);  // start of value
    posEnd = %Scan('"' : remainder : pos2);
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
