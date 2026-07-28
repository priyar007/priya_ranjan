/*                                                                    */
/* Program  : STATECL                                                 */
/* Language : ILE CL                                                  */
/* Purpose  : Compile all objects for IBM_i_First_Project and run     */
/*            the interactive STATEMAIN program.                      */
/*                                                                    */
/* Steps:                                                             */
/*   1. Use library RAIPX61 (PUB400 assigned library for RAIPX6)     */
/*   2. Create source physical files                                  */
/*   3. Compile HTTPSVC module + service program HTTPSVCLIB           */
/*   4. Compile CTRYSVC module                                        */
/*   5. Compile Display File STATELIST                                */
/*   6. Compile and bind STATEMAIN main program                       */
/*   7. Call STATEMAIN                                                */
/*                                                                    */
/* Usage  : CALL PGM(RAIPX61/STATECL)                                */
/* Server : PUB400.COM   User: RAIPX6   Library: RAIPX61             */
/*                                                                    */
PGM

    DCL VAR(&LIB) TYPE(*CHAR) LEN(10) VALUE('RAIPX61')

    /* Step 0: Add RAIPX61 to library list                           */
    /* CRTLIB is not permitted on PUB400 shared server               */
    ADDLIBLE LIB(&LIB) POSITION(*FIRST)
    MONMSG MSGID(CPF2103)

    /* Step 1: Create source physical files */
    CRTSRCPF FILE(&LIB/QRPGLESRC) RCDLEN(112) TEXT('RPG Source')
    MONMSG MSGID(CPF7302)
    CRTSRCPF FILE(&LIB/QDDSSRC)   RCDLEN(92)  TEXT('DDS Source')
    MONMSG MSGID(CPF7302)
    CRTSRCPF FILE(&LIB/QCLSRC)    RCDLEN(92)  TEXT('CL Source')
    MONMSG MSGID(CPF7302)

    /* Step 2: Compile Display File */
    CRTDSPF FILE(&LIB/STATELIST)                                     +
            SRCFILE(&LIB/QDDSSRC) SRCMBR(STATELIST)                 +
            TEXT('State List - Windowed Subfile')
    MONMSG MSGID(CPF0000)

    /* Step 3: Compile HTTPSVC SQLRPGLE module                        */
    /* CRTSQLRPGI compiles embedded SQL + RPG into a *MODULE          */
    /* SYSTOOLS.HTTPGETCLOB() needs no extra binding directory        */
    CRTSQLRPGI OBJ(&LIB/HTTPSVCPGM)                                 +
               SRCFILE(&LIB/QRPGLESRC) SRCMBR(HTTPSVCPGM)          +
               OBJTYPE(*MODULE)                                       +
               COMMIT(*NONE) CLOSQLCSR(*ENDMOD)                      +
               TEXT('HTTP GET utility module')
    MONMSG MSGID(CPF0000)

    /* Step 4: Create HTTPSVCPGM service program                      */
    /* SQL runtime is part of QC2LE - no extra BNDDIR needed          */
    CRTSRVPGM SRVPGM(&LIB/HTTPSVCPGM)                               +
              MODULE(&LIB/HTTPSVCPGM)                                +
              EXPORT(*ALL)                                            +
              BNDDIR(QC2LE)                                           +
              ACTGRP(*CALLER)                                         +
              TEXT('HTTP Service Program')
    MONMSG MSGID(CPF0000)

    /* Step 5: Create binding directory and add service program */
    CRTBNDDIR BNDDIR(&LIB/HTTPSVCPGM)
    MONMSG MSGID(CPF0000)
    ADDBNDDIRE BNDDIR(&LIB/HTTPSVCPGM)                               +
               OBJ((*LIBL/HTTPSVCPGM *SRVPGM))
    MONMSG MSGID(CPF0000)

    /* Step 6: Compile CTRYSVC module                                 */
    /* CRTRPGMOD does not accept DFTACTGRP/ACTGRP                     */
    CRTRPGMOD MODULE(&LIB/CTRYSVC)                                   +
              SRCFILE(&LIB/QRPGLESRC) SRCMBR(CTRYSVC)               +
              TEXT('Country / State service module')
    MONMSG MSGID(CPF0000)

    /* Step 7: Compile STATEMAIN module                               */
    /* CRTRPGMOD does not accept DFTACTGRP/ACTGRP                     */
    CRTRPGMOD MODULE(&LIB/STATEMAIN)                                  +
              SRCFILE(&LIB/QRPGLESRC) SRCMBR(STATEMAIN)             +
              TEXT('States Viewer main module')
    MONMSG MSGID(CPF0000)

    /* Step 8: Bind CTRYSVC + STATEMAIN into main program             */
    /* ACTGRP and BNDDIR go here on CRTPGM, not on CRTRPGMOD          */
    CRTPGM PGM(&LIB/STATEMAIN)                                       +
           MODULE(&LIB/CTRYSVC &LIB/STATEMAIN)                       +
           BNDDIR(&LIB/HTTPSVCPGM QC2LE)                             +
           ACTGRP(QILE)                                               +
           TEXT('States Viewer - Main Program')
    MONMSG MSGID(CPF0000)

    /* Step 9: Launch the program */
    CALL PGM(&LIB/STATEMAIN)

ENDPGM
