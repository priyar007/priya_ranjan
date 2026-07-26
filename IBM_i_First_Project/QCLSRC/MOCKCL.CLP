/*                                                                    */
/* Program  : MOCKCL                                                  */
/* Language : ILE CL                                                  */
/* Purpose  : Compile the mock-data variant of States Viewer and run  */
/*            it. Uses STATEMOCK instead of CTRYSVC.                  */
/*            No HTTPS or network access needed.                      */
/*                                                                    */
/* Pre-requisites (must already be compiled by STATECL or IFSCL):    */
/*   - RAIPX61/STATELIST  (*FILE DSPF)                                */
/*   - RAIPX61/STATEMAIN  (*MODULE)                                   */
/*                                                                    */
/* Usage  : CALL PGM(RAIPX61/MOCKCL)                                 */
/* Server : PUB400.COM   User: RAIPX6   Library: RAIPX61             */
/*                                                                    */
/* Mock test cases:                                                   */
/*   Country: India  - 25 hard-coded states, 3 pages                 */
/*   Country: ERROR  - Server could not be reached message           */
/*   Country: ZZZZZ  - Country not found message                     */
/*   F3              - exits program cleanly                         */
/*                                                                    */
PGM

    DCL VAR(&LIB) TYPE(*CHAR) LEN(10) VALUE('RAIPX61')

    /* Step 0: Add library to list */
    ADDLIBLE LIB(&LIB) POSITION(*FIRST)
    MONMSG MSGID(CPF2103)

    /* Step 1: Compile STATEMOCK module                              */
    /* Drop-in replacement for CTRYSVC - returns hard-coded data     */
    CRTRPGMOD MODULE(&LIB/STATEMOCK)                                 +
              SRCFILE(&LIB/QRPGLESRC) SRCMBR(STATEMOCK)             +
              DFTACTGRP(*NO) ACTGRP(QILE)                            +
              TEXT('Mock Country/State module - no HTTP')
    MONMSG MSGID(CPF0000)

    /* Step 2: Create STATEMAIN_M - binds STATEMOCK + STATEMAIN      */
    /* No HTTPSVCLIB binding directory needed (no HTTP calls)         */
    /* STATEMAIN module must already exist                            */
    CRTPGM PGM(&LIB/STATEMAIN_M)                                     +
           MODULE(&LIB/STATEMOCK &LIB/STATEMAIN)                     +
           BNDDIR(QC2LE)                                              +
           ACTGRP(QILE)                                               +
           TEXT('States Viewer - Mock Test Program')
    MONMSG MSGID(CPF0000)

    /* Step 3: Launch the mock-backed program */
    CALL PGM(&LIB/STATEMAIN_M)

ENDPGM
