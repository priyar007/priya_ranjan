**FREE
// =============================================================================
// Module  : STATEMOCK
// Purpose : Mock implementation of GetStates — returns 25 hard-coded Indian
//           states with ZERO network calls.  Used on PUB400.COM to validate
//           the windowed subfile UI when outbound HTTPS is unavailable.
//
//           Also simulates the error path: if pCountry = 'ERROR' the procedure
//           returns the "server unreachable" message so that error display can
//           be tested without a network failure.
//
//           Drop-in replacement for CTRYSVC — identical GetStates signature.
//
// Compile : CRTRPGMOD MODULE(RAIPX61/STATEMOCK) SRCFILE(RAIPX61/QRPGLESRC)
//           SRCMBR(STATEMOCK) DFTACTGRP(*NO) ACTGRP(QILE)
// =============================================================================

Ctl-Opt NoMain DftActGrp(*No) ActGrp('MAINGRP');

// ---------------------------------------------------------------------------
// Constants & template DS — must exactly match CTRYSVC
// ---------------------------------------------------------------------------
Dcl-C  MAX_STATES  200;

Dcl-Ds StateEntry  Qualified Template;
  StateName  Varchar(80);
End-Ds;

// ---------------------------------------------------------------------------
// Prototype (exported — matches CTRYSVC exactly)
// ---------------------------------------------------------------------------
Dcl-Pr GetStates   ExtProc('GetStates');
  pCountry    Varchar(80)  Const;
  pStates     LikeDs(StateEntry) Dim(MAX_STATES);
  pCount      Int(10);
  pErrMsg     Varchar(256);
End-Pr;

// ---------------------------------------------------------------------------
// Procedure: GetStates (mock)
// ---------------------------------------------------------------------------
Dcl-Proc GetStates Export;
  Dcl-Pi *N;
    pCountry  Varchar(80)  Const;
    pStates   LikeDs(StateEntry) Dim(MAX_STATES);
    pCount    Int(10);
    pErrMsg   Varchar(256);
  End-Pi;

  pCount  = 0;
  pErrMsg = *Blanks;

  // ------------------------------------------------------------------
  // Simulate server-error path: type 'ERROR' as the country name
  // ------------------------------------------------------------------
  If %Upper(%TrimR(pCountry)) = 'ERROR';
    pErrMsg = 'Server could not be reached. Try after some time...';
    Return;
  EndIf;

  // ------------------------------------------------------------------
  // Simulate not-found path
  // ------------------------------------------------------------------
  If %Upper(%TrimR(pCountry)) = 'ZZZZZ';
    pErrMsg = 'Country not found. Please check the country name.';
    Return;
  EndIf;

  // ------------------------------------------------------------------
  // Hard-coded 25 Indian states — enough to demonstrate PgUp/PgDn
  // (subfile page size = 10, so 25 entries gives 3 pages)
  // ------------------------------------------------------------------
  pStates(1).StateName  = 'Andaman and Nicobar Islands';
  pStates(2).StateName  = 'Andhra Pradesh';
  pStates(3).StateName  = 'Arunachal Pradesh';
  pStates(4).StateName  = 'Assam';
  pStates(5).StateName  = 'Bihar';
  pStates(6).StateName  = 'Chandigarh';
  pStates(7).StateName  = 'Chhattisgarh';
  pStates(8).StateName  = 'Dadra and Nagar Haveli';
  pStates(9).StateName  = 'Daman and Diu';
  pStates(10).StateName = 'Delhi (National Capital Territory)';
  pStates(11).StateName = 'Goa';
  pStates(12).StateName = 'Gujarat';
  pStates(13).StateName = 'Haryana';
  pStates(14).StateName = 'Himachal Pradesh';
  pStates(15).StateName = 'Jammu and Kashmir';
  pStates(16).StateName = 'Jharkhand';
  pStates(17).StateName = 'Karnataka';
  pStates(18).StateName = 'Kerala';
  pStates(19).StateName = 'Ladakh';
  pStates(20).StateName = 'Lakshadweep';
  pStates(21).StateName = 'Madhya Pradesh';
  pStates(22).StateName = 'Maharashtra';
  pStates(23).StateName = 'Manipur';
  pStates(24).StateName = 'Meghalaya';
  pStates(25).StateName = 'Mizoram';

  pCount = 25;

  Return;
End-Proc;
