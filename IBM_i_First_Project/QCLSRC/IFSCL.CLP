/*                                                                    */
/* Program  : IFSCL                                                   */
/* Language : ILE CL                                                  */
/* Purpose  : Compile all IBM_i_First_Project objects from IFS and    */
/*            launch the interactive STATEMAIN program.               */
/*                                                                    */
/* IFS directory layout expected under:                               */
/*   /home/RAIPX6/IBM_i_First_Project/                                */
/*     QRPGLESRC/HTTPSVC.RPGLE                                        */
/*     QRPGLESRC/HTTPSVC.H                                            */
/*     QRPGLESRC/CTRYSVC.RPGLE                                        */
/*     QRPGLESRC/STATEMAIN.RPGLE                                      */
/*     QDDSSRC/STATELIST.DSPF                                         */
/*     QCLSRC/IFSCL.CLP                                               */
/*     QSRVSRC/HTTPSVCBND.BND                                         */
/*                                                                    */
/* Bootstrap compile (run once from IBM i command line):              */
/*   CRTBNDCL PGM(RAIPX61/IFSCL)                                      */
/*     SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QCLSRC/IFSCL.CLP')  */
/*                                                                    */
/* Then run:                                                          */
/*   CALL PGM(RAIPX61/IFSCL)                                          */
/*                                                                    */
/* Server: PUB400.COM   User: RAIPX6   Library: RAIPX61              */
/*                                                                    */
PGM

    DCL VAR(&LIB) TYPE(*CHAR) LEN(10) VALUE('RAIPX61')

    /* Step 0: Add library to list */
    ADDLIBLE LIB(&LIB) POSITION(*FIRST)
    MONMSG MSGID(CPF2103)

    /* Step 1: Compile Display File from IFS */
    CRTDSPF FILE(&LIB/STATELIST)                                     +
            SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QDDSSRC/STATELIST.DSPF') +
            TEXT('State List - Windowed Subfile')
    MONMSG MSGID(CPF0000)

    /* Step 2: Compile HTTPSVC module from IFS */
    CRTRPGMOD MODULE(&LIB/HTTPSVC)                                   +
              SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QRPGLESRC/HTTPSVC.RPGLE') +
              DFTACTGRP(*NO) ACTGRP(QILE)                            +
              TEXT('HTTP GET utility module')
    MONMSG MSGID(CPF0000)

    /* Step 3: Create service program HTTPSVCLIB from HTTPSVC module */
    CRTSRVPGM SRVPGM(&LIB/HTTPSVCLIB)                               +
              MODULE(&LIB/HTTPSVC)                                   +
              SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QSRVSRC/HTTPSVCBND.BND') +
              EXPORT(*SRCFILE)                                        +
              ACTGRP(*CALLER)                                         +
              TEXT('HTTP Service Program')
    MONMSG MSGID(CPF0000)

    /* Step 4: Create binding directory and add the service program */
    CRTBNDDIR BNDDIR(&LIB/HTTPSVCLIB)
    MONMSG MSGID(CPF0000)
    ADDBNDDIRE BNDDIR(&LIB/HTTPSVCLIB)                               +
               OBJ((*LIBL/HTTPSVCLIB *SRVPGM))
    MONMSG MSGID(CPF0000)

    /* Step 5: Compile CTRYSVC module from IFS                       */
    /* /COPY in CTRYSVC.RPGLE uses: './QRPGLESRC/HTTPSVC.H'          */
    /* Compiler resolves that path relative to the SRCSTMF directory  */
    CRTRPGMOD MODULE(&LIB/CTRYSVC)                                   +
              SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QRPGLESRC/CTRYSVC.RPGLE') +
              DFTACTGRP(*NO) ACTGRP(QILE)                            +
              TEXT('Country / State service module')
    MONMSG MSGID(CPF0000)

    /* Step 6: Compile STATEMAIN module from IFS */
    CRTRPGMOD MODULE(&LIB/STATEMAIN)                                 +
              SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QRPGLESRC/STATEMAIN.RPGLE') +
              DFTACTGRP(*NO) ACTGRP(QILE)                            +
              TEXT('States Viewer main module')
    MONMSG MSGID(CPF0000)

    /* Step 7: Bind CTRYSVC + STATEMAIN modules into STATEMAIN program */
    CRTPGM PGM(&LIB/STATEMAIN)                                       +
           MODULE(&LIB/CTRYSVC &LIB/STATEMAIN)                       +
           BNDDIR(&LIB/HTTPSVCLIB QC2LE)                             +
           ACTGRP(QILE)                                              +
           TEXT('States Viewer - Main Program')
    MONMSG MSGID(CPF0000)

    /* Step 8: Launch the program */
    CALL PGM(&LIB/STATEMAIN)

ENDPGM
