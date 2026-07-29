/*                                                                    */
/* Program  : STARTUP                                                 */
/* Language : ILE CL                                                  */
/* Purpose  : User profile startup program for RAIPX6 on PUB400.COM  */
/*            Runs automatically on every login - restores library    */
/*            list and current library that are lost on logoff.       */
/*                                                                    */
/* Compile  : CRTBNDCL PGM(RAIPX61/STARTUP)                          */
/*                      SRCFILE(RAIPX61/QCLSRC) SRCMBR(STARTUP)      */
/*                                                                    */
/* Activate : Run once to wire to your user profile:                  */
/*   CHGUSRPRF USRPRF(RAIPX6)                                        */
/*             INLPGM(RAIPX61/STARTUP)                                */
/*             CURLIB(RAIPX61)                                        */
/*             INLLIBL(QTEMP RAIPX61 RAIPX62 RAIPX6B QGPL)           */
/*                                                                    */
PGM

    /* Set current library */
    CHGCURLIB CURLIB(RAIPX61)
    MONMSG MSGID(CPF0000)

    /* Build library list */
    ADDLIBLE LIB(RAIPX61)  POSITION(*FIRST)
    MONMSG MSGID(CPF2103)

    ADDLIBLE LIB(RAIPX62)  POSITION(*AFTER RAIPX61)
    MONMSG MSGID(CPF2103)

    ADDLIBLE LIB(RAIPX6B)  POSITION(*AFTER RAIPX62)
    MONMSG MSGID(CPF2103)

    /* Set job CCSID */
    CHGJOB CCSID(37)
    MONMSG MSGID(CPF0000)

ENDPGM
