/* =============================================================================
** Program  : STATECL
** Language : CL (Control Language)
** Purpose  : Compile all objects for IBM_i_First_Project and run the
**            interactive STATEMAIN program.
**
** Steps:
**   1.  Create the MYLIB library (if needed).
**   2.  Create source physical files.
**   3.  Compile HTTPSVC module and bind into service program HTTPSVCLIB.
**   4.  Compile CTRYSVC module.
**   5.  Compile Display File STATELIST.
**   6.  Compile & bind STATEMAIN main program.
**   7.  Call STATEMAIN.
**
** Usage    : CALL PGM(MYLIB/STATECL)
** =============================================================================
*/
PGM

    DCL VAR(&LIB) TYPE(*CHAR) LEN(10) VALUE('MYLIB')

    /* -----------------------------------------------------------------------
    ** Step 0: Create library if it does not exist
    ** ----------------------------------------------------------------------- */
    CHKOBJ  OBJ(&LIB) OBJTYPE(*LIB)
    MONMSG  MSGID(CPF9801) EXEC(DO)
        CRTLIB  LIB(&LIB) TEXT('IBM i First Project Library')
    ENDDO

    ADDLIBLE LIB(&LIB) POSITION(*FIRST)
    MONMSG  MSGID(CPF2103)        /* Already in library list */

    /* -----------------------------------------------------------------------
    ** Step 1: Create source physical files (10-char record length + 12 seq/date)
    ** ----------------------------------------------------------------------- */
    CRTSRCPF FILE(&LIB/QRPGLESRC) RCDLEN(112)  TEXT('RPG Source')
    MONMSG MSGID(CPF7302)
    CRTSRCPF FILE(&LIB/QDDSSRC)   RCDLEN(92)   TEXT('DDS Source')
    MONMSG MSGID(CPF7302)
    CRTSRCPF FILE(&LIB/QCLSRC)    RCDLEN(92)   TEXT('CL Source')
    MONMSG MSGID(CPF7302)

    /* -----------------------------------------------------------------------
    ** Step 2: Compile Display File
    ** ----------------------------------------------------------------------- */
    CRTDSPF   FILE(&LIB/STATELIST)                                 +
              SRCFILE(&LIB/QDDSSRC) SRCMBR(STATELIST)             +
              TEXT('State List — Windowed Subfile')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 3: Compile HTTPSVC module
    ** ----------------------------------------------------------------------- */
    CRTRPGMOD MODULE(&LIB/HTTPSVC)                                 +
              SRCFILE(&LIB/QRPGLESRC) SRCMBR(HTTPSVC)             +
              DFTACTGRP(*NO) ACTGRP(QILE)                          +
              TEXT('HTTP GET utility module')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 4: Create service program binding directory entry
    ** ----------------------------------------------------------------------- */
    CRTSRVPGM SRVPGM(&LIB/HTTPSVCLIB)                             +
              MODULE(&LIB/HTTPSVC)                                 +
              EXPORT(*ALL)                                          +
              BNDDIR(&LIB/HTTPSVCBND)                              +
              ACTGRP(*CALLER)                                       +
              TEXT('HTTP Service Program')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 5: Create binding directory and add service program
    ** ----------------------------------------------------------------------- */
    CRTBNDDIR BNDDIR(&LIB/HTTPSVCLIB)
    MONMSG MSGID(CPF0000)
    ADDBNDDIRE BNDDIR(&LIB/HTTPSVCLIB)                             +
               OBJ((*LIBL/HTTPSVCLIB *SRVPGM))
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 6: Compile CTRYSVC module
    ** ----------------------------------------------------------------------- */
    CRTRPGMOD MODULE(&LIB/CTRYSVC)                                 +
              SRCFILE(&LIB/QRPGLESRC) SRCMBR(CTRYSVC)             +
              DFTACTGRP(*NO) ACTGRP(QILE)                          +
              TEXT('Country / State service module')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 7: Compile & bind STATEMAIN
    ** ----------------------------------------------------------------------- */
    CRTPGM    PGM(&LIB/STATEMAIN)                                  +
              MODULE(&LIB/CTRYSVC &LIB/STATEMAIN)                  +
              BNDDIR(&LIB/HTTPSVCLIB QC2LE)                        +
              ACTGRP(QILE)                                          +
              TEXT('States Viewer — Main Program')
    MONMSG MSGID(CPF0000)

    /* -----------------------------------------------------------------------
    ** Step 8: Launch the program
    ** ----------------------------------------------------------------------- */
    CALL PGM(&LIB/STATEMAIN)

ENDPGM
