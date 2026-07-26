/* =============================================================================
** Program  : MOCKCL
** Language : CL (Control Language)
** Purpose  : Compile the mock-data variant of the States Viewer and run it.
**            Uses STATEMOCK instead of CTRYSVC — no HTTPS / network needed.
**            Ideal for testing the subfile UI on PUB400.COM before confirming
**            that outbound HTTPS is available.
**
** Pre-requisites (must already be compiled by STATECL):
**   - RAIPX61/STATELIST   (*FILE *DSPF)
**   - RAIPX61/STATEMAIN   (*MODULE)
**
** Creates:
**   - RAIPX61/STATEMOCK   (*MODULE)
**   - RAIPX61/STATEMAIN_M (*PGM)   ← mock variant of main program
**
** Usage    : CRTCLPGM PGM(RAIPX61/MOCKCL) SRCFILE(RAIPX61/QCLSRC) SRCMBR(MOCKCL)
**            CALL PGM(RAIPX61/MOCKCL)
** Server   : PUB400.COM  User: RAIPX6  Library: RAIPX61
** =============================================================================
*/
PGM

    DCL VAR(&LIB) TYPE(*CHAR) LEN(10) VALUE('RAIPX61')

    /* -----------------------------------------------------------------------
    ** Step 0: Add library to list
    ** ----------------------------------------------------------------------- */
    ADDLIBLE LIB(&LIB) POSITION(*FIRST)
    MONMSG  MSGID(CPF2103)

    /* -----------------------------------------------------------------------
    ** Step 1: Compile STATEMOCK module
    **         This is a drop-in replacement for CTRYSVC with identical
    **         GetStates procedure signature but returns hard-coded data.
    ** ----------------------------------------------------------------------- */
    CRTRPGMOD MODULE(&LIB/STATEMOCK)                               +
              SRCFILE(&LIB/QRPGLESRC) SRCMBR(STATEMOCK)           +
              DFTACTGRP(*NO) ACTGRP(QILE)                          +
              TEXT('Mock Country/State module — no HTTP')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 2: Create STATEMAIN_M — binds STATEMOCK + STATEMAIN modules.
    **         No HTTPSVCLIB binding directory needed (mock makes no HTTP calls).
    **         STATEMAIN module must already exist (compiled by STATECL).
    ** ----------------------------------------------------------------------- */
    CRTPGM    PGM(&LIB/STATEMAIN_M)                               +
              MODULE(&LIB/STATEMOCK &LIB/STATEMAIN)               +
              BNDDIR(QC2LE)                                        +
              ACTGRP(QILE)                                         +
              TEXT('States Viewer — Mock Test Program')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 3: Launch the mock-backed program
    **
    ** Test cases:
    **   Country: India  → 25 hard-coded states, 3 pages, PgDn/PgUp works
    **   Country: ERROR  → "Server could not be reached" error message shown
    **   Country: ZZZZZ  → "Country not found" error message shown
    **   F3              → exits program cleanly
    ** ----------------------------------------------------------------------- */
    CALL PGM(&LIB/STATEMAIN_M)

ENDPGM
