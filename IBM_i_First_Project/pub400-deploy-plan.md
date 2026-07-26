# PUB400.COM Deployment Plan — IBM_i_First_Project

## Overview

Upload all source members of `IBM_i_First_Project` from the local Git repository
to the PUB400.COM shared IBM i server (user **RAIPX6**, library **RAIPX61**),
compile them in the correct dependency order, and launch the interactive
`STATEMAIN` program to verify the windowed subfile works end-to-end.

A fallback mock-data path is included to verify the screen independently of
whether outbound HTTPS (port 443) is available on PUB400.COM.

**Tool used for upload:** VS Code with the "Code for IBM i" extension.

---

## Scope

| In scope | Out of scope |
|---|---|
| Update CL to use RAIPX61 library | Git branching / CI pipeline |
| Upload 7 source members via VS Code | Creating a new PUB400 account |
| Compile all objects on PUB400 | Permanent production deployment |
| Run STATEMAIN and verify subfile UI | Modifying the REST API or JSON parser |
| Fallback mock-data compile/test path | Automated test framework |

---

## Sub-Tasks

---

### Sub-Task 1 — Update CL Source for RAIPX61 Library

**Status:** `[x] done`

**Intent:**
The CL compile wrapper `STATECL.CLP` currently defaults to `MYLIB`.
PUB400 users cannot create arbitrary libraries — they must use their assigned
library (`RAIPX61`). Change the `DCL &LIB` default value so the program works
without manual intervention.

**Expected Outcomes:**
- `STATECL.CLP` has `VALUE('RAIPX61')` where it previously said `VALUE('MYLIB')`.
- `README.md` reflects the library name change.
- Change is committed to GitHub before upload.

**Todo List:**
1. In `QCLSRC/STATECL.CLP`, change the `DCL VAR(&LIB)` line:
   - From: `VALUE('MYLIB')`
   - To:   `VALUE('RAIPX61')`
2. In `IBM_i_First_Project/README.md`, replace every occurrence of `MYLIB`
   with `RAIPX61` in compile command examples.
3. `git add`, `git commit -m "config: set PUB400 library to RAIPX61"`, `git push`.

**Relevant Context:**
- File: `IBM_i_First_Project/QCLSRC/STATECL.CLP` — line 21
- File: `IBM_i_First_Project/README.md` — compile step examples

---

### Sub-Task 2 — Create a Mock-Data Fallback Module (STATEMOCK)

**Status:** `[x] done`

**Intent:**
PUB400.COM may block outbound HTTPS from RPG programs. To verify that the
subfile display, PgUp/PgDn scrolling, and error message path all work
independently of network access, create a lightweight RPGLE module
`STATEMOCK` that provides a `GetStates` procedure returning hard-coded state
data for "India" (10 entries) without making any HTTP call. This lets us
validate the entire UI/subfile flow before dealing with network access.

**Expected Outcomes:**
- New file `QRPGLESRC/STATEMOCK.RPGLE` exists with a `GetStates` procedure
  that matches the exact signature used by `STATEMAIN`.
- A second CL member `MOCKCL.CLP` compiles `STATEMOCK` instead of `CTRYSVC`
  and binds it into `STATEMAIN_M` (a mock-test variant of the program).
- Both files are committed to GitHub.

**Todo List:**
1. Create `IBM_i_First_Project/QRPGLESRC/STATEMOCK.RPGLE`:
   - `**FREE`, `NoMain`, `DftActGrp(*No)`, `ActGrp('MAINGRP')`
   - Implements `GetStates` with identical prototype to `CTRYSVC`
   - Hard-codes 10 Indian state names into `pStates` array
   - Sets `pCount = 10`, `pErrMsg = *Blanks`
2. Create `IBM_i_First_Project/QCLSRC/MOCKCL.CLP`:
   - Reuses the same STATELIST display file and STATEMAIN module already compiled.
   - Compiles `STATEMOCK` module (CRTRPGMOD).
   - Creates `STATEMAIN_M` program binding `STATEMOCK` + `STATEMAIN` modules
     (no HTTPSVCLIB binding directory needed).
   - Calls `STATEMAIN_M` to launch the mock-backed screen.
3. `git add`, `git commit -m "test: add mock-data fallback for PUB400 HTTPS testing"`, `git push`.

**Relevant Context:**
- `GetStates` prototype in `QRPGLESRC/CTRYSVC.RPGLE` lines 36–43 — must match exactly
- `STATEMAIN.RPGLE` calls `GetStates` at line 109 and expects the same `StateEntry` data structure

---

### Sub-Task 3 — Configure VS Code "Code for IBM i" Connection to PUB400

**Status:** `[ ] pending`

**Intent:**  
Set up the VS Code extension so it can connect to PUB400.COM with the RAIPX6
credentials and browse/upload to the RAIPX61 library source physical files.

**Expected Outcomes:**
- VS Code "Code for IBM i" extension is installed.
- A connection named "PUB400" (host: `pub400.com`, user: `RAIPX6`) is created
  and shows a green "connected" status.
- The RAIPX61 library is visible in the "Object Browser" panel.

**Todo List:**
1. Open VS Code → Extensions (`Ctrl+Shift+X`) → search **"Code for IBM i"**
   (publisher: Halcyon Tech) → Install.
2. Open the IBM i side-bar (rocket icon on the left).
3. Click **"Connect to an IBM i"** → fill in:
   - **Host:** `pub400.com`
   - **User:** `RAIPX6`
   - **Password:** *(your PUB400 password)*
   - **Port:** `22` (SSH)
4. After connection, open **"Object Browser"** → click **"+"** →
   add filter: Library = `RAIPX61`, Object type = `*ALL`.
5. Confirm RAIPX61 appears in the browser tree.

**Relevant Context:**
- Extension marketplace ID: `halcyontechltd.code-for-ibmi`
- PUB400 SSH port is 22 (standard)
- PUB400 does NOT support password-less SSH by default — plain password auth is used

---

### Sub-Task 4 — Create Source Physical Files on PUB400

**Status:** `[ ] pending`

**Intent:**  
Before members can be uploaded, the source physical files (`QRPGLESRC`,
`QDDSSRC`, `QCLSRC`, `QSRVSRC`) must exist in the RAIPX61 library on the
server. The CL wrapper creates them automatically, but we need at least
`QCLSRC` to exist before we can upload and compile the CL itself.
Use VS Code's IBM i terminal (5250 emulator or PASE shell) to run the
`CRTSRCPF` commands.

**Expected Outcomes:**
- Four source physical files exist in RAIPX61:
  `RAIPX61/QRPGLESRC`, `RAIPX61/QDDSSRC`, `RAIPX61/QCLSRC`, `RAIPX61/QSRVSRC`
- All visible in the Object Browser under RAIPX61.

**Todo List:**
1. In VS Code, open the IBM i terminal: Command Palette (`Ctrl+Shift+P`) →
   **"IBM i: Open IBM i Shell (5250)"** or **"IBM i: Launch Terminal"**.
2. Run the following four commands (one at a time):
   ```
   CRTSRCPF FILE(RAIPX61/QRPGLESRC) RCDLEN(112) TEXT('RPG Source')
   CRTSRCPF FILE(RAIPX61/QDDSSRC)   RCDLEN(92)  TEXT('DDS Source')
   CRTSRCPF FILE(RAIPX61/QCLSRC)    RCDLEN(92)  TEXT('CL Source')
   CRTSRCPF FILE(RAIPX61/QSRVSRC)   RCDLEN(92)  TEXT('Service Pgm Binder Source')
   ```
3. Confirm each file was created: `WRKOBJ OBJ(RAIPX61/*ALL) OBJTYPE(*FILE)`

**Relevant Context:**
- `RCDLEN(112)` is required for RPGLE (80 cols source + 12 seq/date overhead)
- `RCDLEN(92)` covers DDS and CL (80 cols + 12 overhead)
- MONMSG in the CL handles duplicate creation errors — but the SPF must exist
  before the upload step

---

### Sub-Task 5 — Upload All Source Members via VS Code

**Status:** `[ ] pending`

**Intent:**  
Transfer every local source file from the Git workspace into the correct
source physical file and member on PUB400.COM using the "Code for IBM i"
extension's deploy / member-save feature.

**Expected Outcomes:**
- 7 source members exist on PUB400:

| SPF | Member | Type |
|---|---|---|
| RAIPX61/QRPGLESRC | HTTPSVC | RPGLE |
| RAIPX61/QRPGLESRC | HTTPSVC (header) | RPGLEINC |
| RAIPX61/QRPGLESRC | CTRYSVC | RPGLE |
| RAIPX61/QRPGLESRC | STATEMOCK | RPGLE |
| RAIPX61/QRPGLESRC | STATEMAIN | RPGLE |
| RAIPX61/QDDSSRC | STATELIST | DSPF |
| RAIPX61/QCLSRC | STATECL | CLP |
| RAIPX61/QCLSRC | MOCKCL | CLP |
| RAIPX61/QSRVSRC | HTTPSVCBND | BND |

**Todo List:**
1. In VS Code, open the file `QRPGLESRC/HTTPSVC.RPGLE`.
2. Right-click in the editor → **"Upload Member"** (or use Command Palette →
   **"IBM i: Upload Member to IBM i"**).
3. Fill in the upload dialog:
   - Library: `RAIPX61`
   - Source File: `QRPGLESRC`
   - Member: `HTTPSVC`
   - Type: `RPGLE`
4. Repeat for each file in the table above — match member name and type exactly.
5. For `HTTPSVC.H`: member name = `HTTPSVC`, source file = `QRPGLESRC`, type = `RPGLEINC`.
   *(Note: The `/COPY QRPGLESRC,HTTPSVC.H` directive in CTRYSVC references this member.)*
6. After all uploads, use **Object Browser** → expand each SPF → verify all
   members are listed.

**Relevant Context:**
- "Code for IBM i" stores the last-used connection/library per workspace —
  set it once and subsequent uploads reuse it.
- Member type controls syntax highlighting on the server; it does NOT affect compilation.
- The `/COPY` statement in `CTRYSVC.RPGLE` line 20 is: `/COPY QRPGLESRC,HTTPSVC.H` —
  the header member must be named `HTTPSVC` with type `RPGLEINC` (or the extension
  `.H` must be stripped and stored as member `HTTPSVC`).

---

### Sub-Task 6 — Compile All Objects (Live HTTPS Path)

**Status:** `[ ] pending`

**Intent:**  
Compile all IBM i objects on PUB400.COM by running the CL wrapper `STATECL`
which executes the full compile chain in the correct dependency order.

**Expected Outcomes:**
- All 8 IBM i objects exist in RAIPX61:
  `STATELIST` (*FILE DSPF), `HTTPSVC` (*MODULE), `HTTPSVCLIB` (*SRVPGM),
  `HTTPSVCLIB` (*BNDDIR), `CTRYSVC` (*MODULE), `STATEMAIN` (*PGM)
- No compilation errors (only warnings are acceptable).
- `STATEMAIN` is callable.

**Todo List:**
1. Open the IBM i terminal in VS Code.
2. First compile the CL wrapper itself:
   ```
   CRTCLPGM PGM(RAIPX61/STATECL) SRCFILE(RAIPX61/QCLSRC) SRCMBR(STATECL)
   ```
3. Run the CL wrapper to compile everything and launch:
   ```
   CALL PGM(RAIPX61/STATECL)
   ```
4. If any compile step fails, check the joblog:
   ```
   DSPJOBLOG OUTPUT(*PRINT)
   ```
   or use VS Code IBM i extension → **"IBM i: Show Job Log"**.
5. Verify all objects: `WRKOBJ OBJ(RAIPX61/*ALL) OBJTYPE(*ALL)`

**Relevant Context:**
- `STATECL.CLP` uses `MONMSG MSGID(CPF0000)` on each compile step — errors are
  suppressed but the joblog captures them. Check the joblog if objects are missing.
- `QHTTPAPI` binding directory must be present on PUB400; it ships with IBM i OS
  7.3+ but confirm with `CHKOBJ OBJ(QHTTPAPI) OBJTYPE(*BNDDIR)` if HTTPSVC fails.
- `CRTSRVPGM` in the CL references `BNDDIR(&LIB/HTTPSVCBND)` — this is a source-based
  export list, which requires the BND member to be uploaded to QSRVSRC first.

---

### Sub-Task 7 — Test Live HTTPS Path (States Viewer Screen)

**Status:** `[ ] pending`

**Intent:**  
Interactively run `STATEMAIN` on PUB400.COM, enter a country name, and verify
the windowed subfile displays with PgUp/PgDn scrolling. Confirm the
"server could not be reached" message appears if the HTTPS call fails.

**Expected Outcomes:**
- Prompt screen appears asking for a country name.
- Entering "India" produces a windowed subfile listing Indian states/regions.
- Page Down scrolls to more states; Page Up returns; "More..." indicator appears.
- F3 exits cleanly.
- If HTTPS is blocked, the error message `"Server could not be reached. Try after some time..."` appears on line 24 in red.

**Todo List:**
1. In the IBM i terminal, run:
   ```
   CALL PGM(RAIPX61/STATEMAIN)
   ```
   (or it auto-runs at the end of `STATECL`)
2. At the prompt screen, type `India` and press Enter.
3. Observe:
   - **HTTPS works:** windowed subfile opens with Indian states listed.
   - **HTTPS blocked:** red error message on line 24; note the exact message text.
4. If HTTPS works: press Page Down, verify "More..." disappears on the last page.
   Press F12 to close window. Press F3 to exit.
5. If HTTPS is blocked: proceed to Sub-Task 8 (mock-data test).
6. Try a second country (e.g. `Australia`) to confirm re-use works.
7. Try an invalid name (e.g. `ZZZZZ`) to confirm "Country not found" error handling.

**Relevant Context:**
- PUB400 5250 terminal can be accessed via VS Code IBM i extension's built-in
  emulator or via any TN5250 client (e.g. IBM i Access Client Solutions).
- PgUp/PgDn in the subfile window are driven by `SFLEND(*MORE)` + `SFLPAG(10)` +
  `SFLSIZ(200)` defined in `STATELIST.DSPF`.

---

### Sub-Task 8 — Compile and Test Mock-Data Path (STATEMAIN_M)

**Status:** `[ ] pending`

**Intent:**  
If HTTPS is blocked on PUB400.COM, compile and run `STATEMAIN_M` (the mock
variant) to prove the windowed subfile UI logic works correctly with no network
dependency. This is also useful as a standalone screen regression test.

**Expected Outcomes:**
- `STATEMOCK` module and `STATEMAIN_M` program exist in RAIPX61.
- Running `STATEMAIN_M` shows the same windowed subfile but populated with
  10 hard-coded Indian state names (no HTTP call made).
- PgUp/PgDn, F3, F12 all behave identically to the live path.

**Todo List:**
1. In the IBM i terminal, compile the mock CL wrapper:
   ```
   CRTCLPGM PGM(RAIPX61/MOCKCL) SRCFILE(RAIPX61/QCLSRC) SRCMBR(MOCKCL)
   ```
2. Run it:
   ```
   CALL PGM(RAIPX61/MOCKCL)
   ```
3. At the prompt, type `India` and press Enter.
4. Verify:
   - 10 mock states are shown in the subfile window.
   - PgUp/PgDn works (10 entries fit one page, so "More..." should not appear).
   - F3 exits cleanly.
5. If this works but Sub-Task 7 showed HTTPS blocked, raise a ticket or email
   PUB400 admin to request outbound HTTPS from job `STATEMAIN`.

**Relevant Context:**
- `STATEMOCK.RPGLE` and `MOCKCL.CLP` are created in Sub-Task 2.
- `STATEMAIN_M` reuses the `STATEMAIN` module (already compiled) — only the
  `GetStates` implementation changes.

---

### Sub-Task 9 — Commit Final State to GitHub

**Status:** `[ ] pending`

**Intent:**  
Ensure the final working state — including the library update, the mock module,
and any fixes discovered during testing — is pushed to GitHub as a clean,
deployable snapshot.

**Expected Outcomes:**
- GitHub `master` branch contains all source files with `RAIPX61` as the library.
- Commit message clearly marks the PUB400 deployment milestone.
- `README.md` is updated with the PUB400-specific compile and run instructions.

**Todo List:**
1. Verify `git status` shows no unexpected modified files.
2. If any source was edited during testing (e.g. typo fixes), stage and commit those.
3. Update `IBM_i_First_Project/README.md`:
   - Replace all remaining `MYLIB` references with `RAIPX61`.
   - Add a **"PUB400.COM Deployment"** section with the exact steps used.
   - Note whether HTTPS was available or the mock path was needed.
4. `git add IBM_i_First_Project/`
5. `git commit -m "deploy: PUB400.COM RAIPX61 — compile + test complete"`
6. `git push origin master`

**Relevant Context:**
- Current GitHub remote: `https://github.com/priyar007/priya_ranjan.git`
- Branch: `master`

---

## Dependency Order Summary

```
Sub-Task 1  (update CL library)
     │
Sub-Task 2  (create mock module + CL)
     │
     ├──► Sub-Task 3  (VS Code connection setup)
     │         │
     │    Sub-Task 4  (create SPFs on PUB400)
     │         │
     │    Sub-Task 5  (upload all members)
     │         │
     │    Sub-Task 6  (compile live path)
     │         │
     │    Sub-Task 7  (test live HTTPS)
     │         │
     │         ├── HTTPS works ──► Sub-Task 9 (GitHub commit)
     │         │
     │         └── HTTPS blocked ──► Sub-Task 8 (mock test) ──► Sub-Task 9
     │
     └──► Sub-Tasks 3–5 can begin in parallel with Sub-Task 2
```

---

## Key Reference Values

| Item | Value |
|---|---|
| PUB400 hostname | `pub400.com` |
| SSH port | `22` |
| IBM i user | `RAIPX6` |
| Library | `RAIPX61` |
| Main program | `RAIPX61/STATEMAIN` |
| Mock program | `RAIPX61/STATEMAIN_M` |
| REST API | `https://countriesnow.space/api/v0.1/countries/states` |
| VS Code extension | `halcyontechltd.code-for-ibmi` |
