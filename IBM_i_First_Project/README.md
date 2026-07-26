# IBM_i_First_Project

> **IBM i · RPGLE ILE Free-Format · HTTPS Web Services · Interactive Subfile**

A fully interactive IBM i program that:
1. Prompts for a **country name**
2. Calls a **public REST API** over HTTPS (`countriesnow.space`)
3. Parses the JSON response in pure RPGLE (no Java, no Node.js)
4. Displays a scrollable **windowed subfile** (Page Up / Page Down) listing every state/region
5. Shows a friendly **"Server could not be reached"** message when the web service is unavailable

---

## Project Structure

```
IBM_i_First_Project/
├── QRPGLESRC/
│   ├── HTTPSVC.RPGLE     ← HTTPS utility service module  (HTTP_Get procedure)
│   ├── HTTPSVC.H         ← Prototype /COPY header for HTTPSVC
│   ├── CTRYSVC.RPGLE     ← Country/State service module  (GetStates procedure)
│   └── STATEMAIN.RPGLE   ← Main ILE RPG program (interactive + subfile)
├── QDDSSRC/
│   └── STATELIST.DSPF    ← Display File: prompt screen + windowed subfile
├── QCLSRC/
│   └── STATECL.CLP       ← CL program: compiles everything & runs STATEMAIN
├── QSRVSRC/
│   └── HTTPSVCBND.BND    ← Binding directory source for HTTPSVC service program
├── QBNDDIR/              ← (empty; binding directory created at runtime by CL)
└── docs/
    └── FLOW.md           ← Data-flow and program design notes
```

---

## Architecture

```
 ┌──────────────┐   country name   ┌──────────────┐  HTTPS GET  ┌─────────────────────┐
 │  STATEMAIN   │ ───────────────► │   CTRYSVC    │ ──────────► │ countriesnow.space  │
 │  (main pgm)  │ ◄─────────────── │  (GetStates) │ ◄────────── │  /api/v0.1/         │
 │              │  state array     └──────────────┘  JSON body  │  countries/states   │
 │  STATELIST   │                        │                       └─────────────────────┘
 │  (DSPF/SFL)  │                        │ calls
 └──────────────┘               ┌────────▼───────┐
                                │   HTTPSVC      │
                                │  (HTTP_Get)    │
                                │  service pgm   │
                                └────────────────┘
```

---

## REST API Used

| Field          | Value                                                          |
|----------------|----------------------------------------------------------------|
| **Base URL**   | `https://countriesnow.space/api/v0.1/countries/states`        |
| **Method**     | GET  (query param `?country=<name>`)                          |
| **Auth**       | None — free, no API key required                              |
| **Response**   | JSON `{ "error": false, "data": { "states": [...] } }`        |
| **Error case** | HTTP ≠ 200 or network timeout → `pErrMsg` populated           |

---

## Prerequisites

| Requirement              | Version / Detail                                   |
|--------------------------|----------------------------------------------------|
| IBM i OS                 | 7.3 or later (7.4 / 7.5 recommended)              |
| RPGLE compiler           | V7R3 or later                                      |
| `QHTTPAPI` licensed pgm  | HTTP API (`QHttpGetClob`)  — part of IBM HTTP API  |
| Internet connectivity    | Port 443 outbound allowed from IBM i               |
| `QC2LE` binding dir      | Ships with OS, no install needed                   |

---

## Local Compile & Run (Step-by-Step)

### Option A — Use the CL Wrapper (recommended)

```
1. Upload all source members to your IBM i using RDi, VS Code + IBM i extension,
   or FTP:
      PUT QRPGLESRC/HTTPSVC.RPGLE   → MYLIB/QRPGLESRC member HTTPSVC  type RPGLE
      PUT QRPGLESRC/HTTPSVC.H       → MYLIB/QRPGLESRC member HTTPSVC  type RPGLEINC
      PUT QRPGLESRC/CTRYSVC.RPGLE   → MYLIB/QRPGLESRC member CTRYSVC  type RPGLE
      PUT QRPGLESRC/STATEMAIN.RPGLE → MYLIB/QRPGLESRC member STATEMAIN type RPGLE
      PUT QDDSSRC/STATELIST.DSPF    → MYLIB/QDDSSRC   member STATELIST type DSPF
      PUT QCLSRC/STATECL.CLP        → MYLIB/QCLSRC    member STATECL   type CLP
      PUT QSRVSRC/HTTPSVCBND.BND    → MYLIB/QSRVSRC   member HTTPSVCBND type BND

2. Compile the CL wrapper:
      CRTCLPGM PGM(MYLIB/STATECL) SRCFILE(MYLIB/QCLSRC) SRCMBR(STATECL)

3. Run it (compiles all objects then launches STATEMAIN):
      CALL PGM(MYLIB/STATECL)
```

### Option B — Manual compile order

```cl
/* 1. Display File */
CRTDSPF FILE(MYLIB/STATELIST) SRCFILE(MYLIB/QDDSSRC) SRCMBR(STATELIST)

/* 2. HTTP utility module */
CRTRPGMOD MODULE(MYLIB/HTTPSVC) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(HTTPSVC) +
           DFTACTGRP(*NO) ACTGRP(QILE)

/* 3. Service program */
CRTSRVPGM SRVPGM(MYLIB/HTTPSVCLIB) MODULE(MYLIB/HTTPSVC)  +
          SRCFILE(MYLIB/QSRVSRC) SRCMBR(HTTPSVCBND) EXPORT(*ALL)

/* 4. Binding directory */
CRTBNDDIR BNDDIR(MYLIB/HTTPSVCLIB)
ADDBNDDIRE BNDDIR(MYLIB/HTTPSVCLIB) OBJ((*LIBL/HTTPSVCLIB *SRVPGM))

/* 5. Country service module */
CRTRPGMOD MODULE(MYLIB/CTRYSVC) SRCFILE(MYLIB/QRPGLESRC) SRCMBR(CTRYSVC) +
           DFTACTGRP(*NO) ACTGRP(QILE)

/* 6. Main program (binds CTRYSVC + HTTPSVCLIB) */
CRTPGM PGM(MYLIB/STATEMAIN)  +
       MODULE(MYLIB/CTRYSVC MYLIB/STATEMAIN) +
       BNDDIR(MYLIB/HTTPSVCLIB QC2LE)

/* 7. Run */
CALL PGM(MYLIB/STATEMAIN)
```

---

## User Interface

```
┌────────────────────────────────────────────────────────────────────┐
│ IBM i First Project — State Lister                                 │
│                                                                    │
│ Enter country name and press Enter:  India___________________      │
│                                                                    │
│ F3=Exit                                                            │
└────────────────────────────────────────────────────────────────────┘
```

After Enter:

```
┌──────────────────────────────────────────────────────────────────────┐
│ IBM i — States Viewer                                                │
│ Country : India                                                      │
│ ────────────────────────────────────────────────────────────────     │
│   #   State / Region                                                 │
│ ────────────────────────────────────────────────────────────────     │
│       Andaman and Nicobar Islands                                    │
│       Andhra Pradesh                                                 │
│       Arunachal Pradesh                                              │
│       Assam                                                          │
│       Bihar                                                          │
│       Chandigarh                                                     │
│       Chhattisgarh                                                   │
│       Dadra and Nagar Haveli                                         │
│       Daman and Diu                                                  │
│       Delhi                                                          │
│ ────────────────────────────────────────────────────────────────     │
│ F3=Exit  F12=Cancel  +/-=Scroll                            More...  │
└──────────────────────────────────────────────────────────────────────┘
```

If the web service is unreachable:
```
Server could not be reached. Try after some time...
```

---

## Key Design Decisions

| Decision                        | Reason                                                   |
|---------------------------------|----------------------------------------------------------|
| Pure RPGLE free-format          | Modern IBM i standard; no CLP for logic                  |
| `QHttpGetClob` (IBM HTTP API)   | IBM-supported, no third-party tools needed               |
| Lightweight JSON parser         | No external JSON library needed; scans for `"name":""`   |
| Windowed subfile                | Keeps focus on selected data; does not replace base screen |
| Service program for HTTP        | Reusable across future projects; clean separation         |
| SFLEND(*MORE)                   | Native "More..." indicator, standard IBM i UX            |

---

## Commit to GitHub

```bash
git add IBM_i_First_Project/
git commit -m "feat: IBM_i_First_Project — RPGLE ILE state viewer via HTTPS"
git push origin master
```

---

## Author

**Priya Ranjan** — IBM i Developer  
Repository: `RAIPX6_GIT / priya_ranjan`
