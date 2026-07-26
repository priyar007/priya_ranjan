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
      PUT QRPGLESRC/HTTPSVC.RPGLE   → RAIPX61/QRPGLESRC member HTTPSVC  type RPGLE
      PUT QRPGLESRC/HTTPSVC.H       → RAIPX61/QRPGLESRC member HTTPSVC  type RPGLEINC
      PUT QRPGLESRC/CTRYSVC.RPGLE   → RAIPX61/QRPGLESRC member CTRYSVC  type RPGLE
      PUT QRPGLESRC/STATEMAIN.RPGLE → RAIPX61/QRPGLESRC member STATEMAIN type RPGLE
      PUT QDDSSRC/STATELIST.DSPF    → RAIPX61/QDDSSRC   member STATELIST type DSPF
      PUT QCLSRC/STATECL.CLP        → RAIPX61/QCLSRC    member STATECL   type CLP
      PUT QSRVSRC/HTTPSVCBND.BND    → RAIPX61/QSRVSRC   member HTTPSVCBND type BND

2. Compile the CL wrapper:
      CRTCLPGM PGM(RAIPX61/STATECL) SRCFILE(RAIPX61/QCLSRC) SRCMBR(STATECL)

3. Run it (compiles all objects then launches STATEMAIN):
      CALL PGM(RAIPX61/STATECL)
```

### Option B — Manual compile order

```cl
/* 1. Display File */
CRTDSPF FILE(RAIPX61/STATELIST) SRCFILE(RAIPX61/QDDSSRC) SRCMBR(STATELIST)

/* 2. HTTP utility module */
CRTRPGMOD MODULE(RAIPX61/HTTPSVC) SRCFILE(RAIPX61/QRPGLESRC) SRCMBR(HTTPSVC) +
           DFTACTGRP(*NO) ACTGRP(QILE)

/* 3. Service program */
CRTSRVPGM SRVPGM(RAIPX61/HTTPSVCLIB) MODULE(RAIPX61/HTTPSVC)  +
          SRCFILE(RAIPX61/QSRVSRC) SRCMBR(HTTPSVCBND) EXPORT(*ALL)

/* 4. Binding directory */
CRTBNDDIR BNDDIR(RAIPX61/HTTPSVCLIB)
ADDBNDDIRE BNDDIR(RAIPX61/HTTPSVCLIB) OBJ((*LIBL/HTTPSVCLIB *SRVPGM))

/* 5. Country service module */
CRTRPGMOD MODULE(RAIPX61/CTRYSVC) SRCFILE(RAIPX61/QRPGLESRC) SRCMBR(CTRYSVC) +
           DFTACTGRP(*NO) ACTGRP(QILE)

/* 6. Main program (binds CTRYSVC + HTTPSVCLIB) */
CRTPGM PGM(RAIPX61/STATEMAIN)  +
       MODULE(RAIPX61/CTRYSVC RAIPX61/STATEMAIN) +
       BNDDIR(RAIPX61/HTTPSVCLIB QC2LE)

/* 7. Run */
CALL PGM(RAIPX61/STATEMAIN)
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


---

## PUB400.COM Deployment (User: RAIPX6 / Library: RAIPX61)

### Step 1 — Connect VS Code to PUB400

1. Install the **Code for IBM i** extension (`halcyontechltd.code-for-ibmi`) in VS Code.
2. Open the IBM i sidebar (rocket icon) → **"Connect to an IBM i"**:
   - Host: `pub400.com` · User: `RAIPX6` · Port: `22` (SSH)
3. In **Object Browser** add filter: Library = `RAIPX61`, Type = `*ALL`.

### Step 2 — Create Source Physical Files on PUB400

Run these 4 commands in the VS Code IBM i terminal (`Ctrl+Shift+P` → **IBM i: Launch Terminal**):

```
CRTSRCPF FILE(RAIPX61/QRPGLESRC) RCDLEN(112) TEXT('RPG Source')
CRTSRCPF FILE(RAIPX61/QDDSSRC)   RCDLEN(92)  TEXT('DDS Source')
CRTSRCPF FILE(RAIPX61/QCLSRC)    RCDLEN(92)  TEXT('CL Source')
CRTSRCPF FILE(RAIPX61/QSRVSRC)   RCDLEN(92)  TEXT('Service Pgm Binder Source')
```

### Step 3 — Upload Source Members

Use **"Upload Member"** (right-click in editor) or the VS Code member deploy feature:

| Local File | Library/SPF | Member | Type |
|---|---|---|---|
| `QRPGLESRC/HTTPSVC.RPGLE` | `RAIPX61/QRPGLESRC` | `HTTPSVC` | `RPGLE` |
| `QRPGLESRC/HTTPSVC.H` | `RAIPX61/QRPGLESRC` | `HTTPSVC` | `RPGLEINC` |
| `QRPGLESRC/CTRYSVC.RPGLE` | `RAIPX61/QRPGLESRC` | `CTRYSVC` | `RPGLE` |
| `QRPGLESRC/STATEMOCK.RPGLE` | `RAIPX61/QRPGLESRC` | `STATEMOCK` | `RPGLE` |
| `QRPGLESRC/STATEMAIN.RPGLE` | `RAIPX61/QRPGLESRC` | `STATEMAIN` | `RPGLE` |
| `QDDSSRC/STATELIST.DSPF` | `RAIPX61/QDDSSRC` | `STATELIST` | `DSPF` |
| `QCLSRC/STATECL.CLP` | `RAIPX61/QCLSRC` | `STATECL` | `CLP` |
| `QCLSRC/MOCKCL.CLP` | `RAIPX61/QCLSRC` | `MOCKCL` | `CLP` |
| `QSRVSRC/HTTPSVCBND.BND` | `RAIPX61/QSRVSRC` | `HTTPSVCBND` | `BND` |

### Step 4 — Compile

```
CRTCLPGM PGM(RAIPX61/STATECL) SRCFILE(RAIPX61/QCLSRC) SRCMBR(STATECL)
CALL PGM(RAIPX61/STATECL)
```

### Step 5 — Test Live (HTTPS)

```
CALL PGM(RAIPX61/STATEMAIN)
```
Type `India` at the prompt → windowed subfile with Indian states appears.
If HTTPS is blocked → red message `"Server could not be reached. Try after some time..."`

### Step 6 — Test Mock (No Network Needed)

```
CRTCLPGM PGM(RAIPX61/MOCKCL) SRCFILE(RAIPX61/QCLSRC) SRCMBR(MOCKCL)
CALL PGM(RAIPX61/MOCKCL)
```
Type `India` → 10 hard-coded states shown — proves subfile UI works without HTTPS.

---


## Author

**Priya Ranjan** — IBM i Developer  
Repository: `RAIPX6_GIT / priya_ranjan`
