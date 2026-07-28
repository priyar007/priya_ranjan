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

    /* Step 1: Create a temp source physical file for DDS             */
    /* CRTDSPF does not support SRCSTMF - must copy IFS file into a  */
    /* source member first using CPYFRMSTMF then compile from member  */
    CRTSRCPF FILE(&LIB/QDDSSRC) RCDLEN(92) TEXT('DDS Source')
    MONMSG MSGID(CPF7302)

    /* STMFCCSID(*PCASC) = pure 7-bit ASCII - no Unicode chars in source */
    /* DBFCCSID(37)      = EBCDIC US - IBM i native encoding              */
    CPYFRMSTMF FROMSTMF('/home/RAIPX6/IBM_i_First_Project/QDDSSRC/STATELIST.DSPF') +
               TOMBR('/QSYS.LIB/RAIPX61.LIB/QDDSSRC.FILE/STATELIST.MBR') +
               MBROPT(*REPLACE) STMFCCSID(1208) DBFCCSID(37)
    MONMSG MSGID(CPF0000)

    CHGPFM FILE(&LIB/QDDSSRC) MBR(STATELIST) SRCTYPE(DSPF)
    MONMSG MSGID(CPF0000)

    /* Step 2: Compile Display File from source member */
    CRTDSPF FILE(&LIB/STATELIST)                                     +
            SRCFILE(&LIB/QDDSSRC) SRCMBR(STATELIST)                 +
            TEXT('State List - Windowed Subfile')
    MONMSG MSGID(CPF0000)

    /* Step 3: Compile HTTPSVC as SQLRPGLE module from IFS            */
    /* CRTSQLRPGI handles embedded SQL + RPG in one step              */
    /* SYSTOOLS.HTTPGETCLOB() - no extra binding directory required   */
    CRTSQLRPGI OBJ(&LIB/HTTPSVCPGM)                                 +
               SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QRPGLESRC/HTTPSVC.RPGLE') +
               OBJTYPE(*MODULE)                                       +
               COMMIT(*NONE) CLOSQLCSR(*ENDMOD)                      +
               TEXT('HTTP GET utility module')
    MONMSG MSGID(CPF0000)

    /* Step 4: Create service program HTTPSVCPGM from HTTPSVCPGM module */
    /* SQL runtime is part of QC2LE - no extra BNDDIR needed            */
    CRTSRVPGM SRVPGM(&LIB/HTTPSVCPGM)                               +
              MODULE(&LIB/HTTPSVCPGM)                                +
              EXPORT(*ALL)                                            +
              BNDDIR(QC2LE)                                           +
              ACTGRP(*CALLER)                                         +
              TEXT('HTTP Service Program')
    MONMSG MSGID(CPF0000)

    /* Step 5: Create binding directory and add the service program */
    CRTBNDDIR BNDDIR(&LIB/HTTPSVCPGM)
    MONMSG MSGID(CPF0000)
    ADDBNDDIRE BNDDIR(&LIB/HTTPSVCPGM)                               +
               OBJ((*LIBL/HTTPSVCPGM *SRVPGM))
    MONMSG MSGID(CPF0000)

    /* Step 6: Compile CTRYSVC module from IFS                        */
    /* /COPY in CTRYSVC.RPGLE uses: './QRPGLESRC/HTTPSVC.H'           */
    /* Compiler resolves relative to the SRCSTMF parent directory     */
    CRTRPGMOD MODULE(&LIB/CTRYSVC)                                   +
              SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QRPGLESRC/CTRYSVC.RPGLE') +
              TEXT('Country / State service module')
    MONMSG MSGID(CPF0000)

    /* Step 7: Compile STATEMAIN module from IFS */
    CRTRPGMOD MODULE(&LIB/STATEMAIN)                                 +
              SRCSTMF('/home/RAIPX6/IBM_i_First_Project/QRPGLESRC/STATEMAIN.RPGLE') +
              TEXT('States Viewer main module')
    MONMSG MSGID(CPF0000)

    /* Step 8: Bind CTRYSVC + STATEMAIN into final program            */
    /* ACTGRP goes here on CRTPGM not on CRTRPGMOD                    */
    CRTPGM PGM(&LIB/STATEMAIN)                                       +
           MODULE(&LIB/CTRYSVC &LIB/STATEMAIN)                       +
           BNDDIR(&LIB/HTTPSVCPGM QC2LE)                             +
           ACTGRP(QILE)                                               +
           TEXT('States Viewer - Main Program')
    MONMSG MSGID(CPF0000)

    /* Step 9: Launch the program */
    CALL PGM(&LIB/STATEMAIN)

ENDPGM
