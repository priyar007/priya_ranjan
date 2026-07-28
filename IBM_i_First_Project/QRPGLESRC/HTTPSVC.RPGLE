**FREE
// =============================================================================
// Module  : HTTPSVC
// Purpose : HTTP GET utility - uses PASE curl via system() to fetch a URL.
//           No licensed HTTP product required - works on any IBM i 7.x with
//           PASE installed (standard on PUB400).
//           Only binding directory needed: QC2LE (base OS).
//
// Compile : CRTRPGMOD MODULE(RAIPX61/HTTPSVCPGM)
//           SRCFILE(RAIPX61/QRPGLESRC) SRCMBR(HTTPSVCPGM)
//
// Service : Bound into RAIPX61/HTTPSVCPGM via CRTSRVPGM
// =============================================================================

Ctl-Opt NoMain
        BndDir('QC2LE');

// ---------------------------------------------------------------------------
// C runtime prototypes (from QC2LE)
// ---------------------------------------------------------------------------
Dcl-Pr sys_system   Int(10) ExtProc('system');
  cmd             Pointer Value Options(*String);
End-Pr;

Dcl-Pr sys_fopen    Pointer ExtProc('fopen');
  path            Pointer Value Options(*String);
  mode            Pointer Value Options(*String);
End-Pr;

Dcl-Pr sys_fread    Int(10) ExtProc('fread');
  buf             Pointer Value;
  size            Int(10) Value;
  count           Int(10) Value;
  stream          Pointer Value;
End-Pr;

Dcl-Pr sys_fclose   Int(10) ExtProc('fclose');
  stream          Pointer Value;
End-Pr;

Dcl-Pr sys_remove   Int(10) ExtProc('remove');
  path            Pointer Value Options(*String);
End-Pr;

// ---------------------------------------------------------------------------
// Exported prototype
// ---------------------------------------------------------------------------
Dcl-Pr HTTP_Get     ExtProc('HTTP_Get');
  pUrl            Varchar(1024) Const;
  pResponse       Varchar(65535);
  pErrMsg         Varchar(256);
End-Pr;

// ---------------------------------------------------------------------------
// Procedure: HTTP_Get
//   pUrl      - full HTTPS URL to GET
//   pResponse - response body (up to 65 KB)
//   pErrMsg   - blank on success; error message on failure
// ---------------------------------------------------------------------------
Dcl-Proc HTTP_Get Export;
  Dcl-Pi *N;
    pUrl      Varchar(1024) Const;
    pResponse Varchar(65535);
    pErrMsg   Varchar(256);
  End-Pi;

  // Temp IFS file in /tmp - unique per job using runtime timestamp
  Dcl-C  TMPFILE  '/tmp/httpsvc_out.tmp';

  Dcl-S  cmd        Varchar(2048);
  Dcl-S  rc         Int(10);
  Dcl-S  fp         Pointer;
  Dcl-S  bytesRead  Int(10);
  Dcl-S  buf        Char(65535) Inz(*Blanks);

  pResponse = *Blanks;
  pErrMsg   = *Blanks;

  // Remove any leftover temp file from a previous run
  sys_remove(TMPFILE);

  // Build curl command:
  //   -s  = silent (no progress bar)
  //   -S  = show error if -s is used
  //   -L  = follow redirects
  //   -m 10 = max 10 seconds timeout
  //   -o  = write output to temp file
  cmd = 'QSH CMD(''curl -s -S -L -m 10 ' +
        '-o ' + TMPFILE + ' ' +
        '"' + %TrimR(pUrl) + '"' +
        ''')';

  rc = sys_system(%TrimR(cmd));

  If rc <> 0;
    pErrMsg = 'Server could not be reached. Try after some time...';
    Return;
  EndIf;

  // Read the temp file back
  fp = sys_fopen(TMPFILE : 'rb');
  If fp = *Null;
    pErrMsg = 'Server could not be reached. Try after some time...';
    Return;
  EndIf;

  bytesRead = sys_fread(%Addr(buf) : 1 : %Size(buf) : fp);
  sys_fclose(fp);
  sys_remove(TMPFILE);

  If bytesRead <= 0;
    pErrMsg = 'No data returned. Try after some time...';
    Return;
  EndIf;

  pResponse = %SubSt(buf : 1 : bytesRead);

  Return;
End-Proc;
