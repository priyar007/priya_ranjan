/* =============================================================================
** Program  : IFSMOCKCL
** Language : CL (Control Language)
** Purpose  : Compile the mock-data variant of States Viewer from IFS source
**            and launch STATEMAIN_M (no HTTPS / network needed).
**
**            Pre-requisite: IFSCL must have already run successfully so that
**            STATELIST (*FILE DSPF) and STATEMAIN (*MODULE) exist in RAIPX61.
**
** Compile this CL itself first (one time only):
**   CRTBNDCL PGM(RAIPX61/IFSMOCKCL)                                +
**            SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QCLSRC/IFSMOCKCL.CLP')
**
** Then run:
**   CALL PGM(RAIPX61/IFSMOCKCL)
**
** Mock test cases:
**   Country: India  → 25 hard-coded states, 3 pages
**   Country: ERROR  → "Server could not be reached" message
**   Country: ZZZZZ  → "Country not found" message
**
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
    ** Step 1: Compile STATEMOCK module from IFS
    ** ----------------------------------------------------------------------- */
    CRTRPGMOD MODULE(&LIB/STATEMOCK)                                 +
              SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QRPGLESRC/STATEMOCK.RPGLE') +
              DFTACTGRP(*NO) ACTGRP(QILE)                            +
              TEXT('Mock Country/State module — no HTTP')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 2: Create STATEMAIN_M — binds STATEMOCK + STATEMAIN modules
    **         STATEMAIN module must already exist (compiled by IFSCL)
    ** ----------------------------------------------------------------------- */
    CRTPGM    PGM(&LIB/STATEMAIN_M)                                  +
              MODULE(&LIB/STATEMOCK &LIB/STATEMAIN)                  +
              BNDDIR(QC2LE)                                           +
              ACTGRP(QILE)                                            +
              TEXT('States Viewer — Mock Test Program')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 3: Launch the mock-backed program
    ** ----------------------------------------------------------------------- */
    CALL PGM(&LIB/STATEMAIN_M)

ENDPGM
