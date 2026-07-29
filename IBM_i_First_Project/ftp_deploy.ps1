# =============================================================================
# Script  : ftp_deploy.ps1
# Purpose : Upload IBM i project source members to PUB400.COM (RAIPX61 lib)
#           with correct UTF-8 to EBCDIC CCSID 37 conversion.
#
# Strategy (2-step per file):
#   Step 1 - Upload file in BINARY mode to IFS /home/RAIPX6/src/
#            Binary preserves the exact UTF-8 bytes from Windows.
#   Step 2 - Run CPYFRMSTMF on IBM i (via QUOTE RCMD) to copy the IFS file
#            into the source member with STMFCCSID(1208) DBFCCSID(37).
#            IBM i does the full UTF-8->EBCDIC conversion, so ALL characters
#            including [ ] { } " / - em-dash etc. map correctly.
#
# Usage   : .\IBM_i_First_Project\ftp_deploy.ps1
#           (run from workspace root: priya_ranjan\)
# =============================================================================

# ---------------------------------------------------------------------------
# CONNECTION SETTINGS
# ---------------------------------------------------------------------------
$FTP_HOST  = "pub400.com"
$FTP_USER  = "RAIPX6"
$FTP_PASS  = "YOUR_PASSWORD_HERE"     # <-- replace with your PUB400 password
$LIB       = "RAIPX61"
$IFS_DIR   = "/home/RAIPX6/src"      # temp staging folder on IFS

# ---------------------------------------------------------------------------
# Source files to upload
# ---------------------------------------------------------------------------
$uploads = @(
    @{ Local="IBM_i_First_Project\QRPGLESRC\HTTPSVCPGM.SQLRPGLE"; SrcPF="QRPGLESRC"; Mbr="HTTPSVCPGM"; Type="SQLRPGLE" },
    @{ Local="IBM_i_First_Project\QRPGLESRC\HTTPSVC.H";            SrcPF="QRPGLESRC"; Mbr="HTTPSVC";    Type="RPGLEINC" },
    @{ Local="IBM_i_First_Project\QRPGLESRC\CTRYSVC.RPGLE";        SrcPF="QRPGLESRC"; Mbr="CTRYSVC";    Type="RPGLE"    },
    @{ Local="IBM_i_First_Project\QRPGLESRC\STATEMAIN.RPGLE";      SrcPF="QRPGLESRC"; Mbr="STATEMAIN";  Type="RPGLE"    },
    @{ Local="IBM_i_First_Project\QRPGLESRC\STATEMOCK.RPGLE";      SrcPF="QRPGLESRC"; Mbr="STATEMOCK";  Type="RPGLE"    },
    @{ Local="IBM_i_First_Project\QDDSSRC\STATELIST.DSPF";         SrcPF="QDDSSRC";   Mbr="STATELIST";  Type="DSPF"     },
    @{ Local="IBM_i_First_Project\QCLSRC\STATECL.CLP";             SrcPF="QCLSRC";    Mbr="STATECL";    Type="CLP"      },
    @{ Local="IBM_i_First_Project\QCLSRC\IFSCL.CLP";               SrcPF="QCLSRC";    Mbr="IFSCL";      Type="CLP"      },
    @{ Local="IBM_i_First_Project\QCLSRC\MOCKCL.CLP";              SrcPF="QCLSRC";    Mbr="MOCKCL";     Type="CLP"      },
    @{ Local="IBM_i_First_Project\QCLSRC\IFSMOCKCL.CLP";           SrcPF="QCLSRC";    Mbr="IFSMOCKCL";  Type="CLP"      }
)

# ---------------------------------------------------------------------------
# Resolve absolute workspace root from the script location
# ---------------------------------------------------------------------------
$wsRoot = Split-Path -Parent $PSScriptRoot

# ---------------------------------------------------------------------------
# Build FTP script
# ---------------------------------------------------------------------------
$ftpScript  = "open $FTP_HOST`r`n"
$ftpScript += "user $FTP_USER $FTP_PASS`r`n"

# Create the staging folder on IFS (ignore error if it already exists)
$ftpScript += "quote rcmd MKDIR DIR('$IFS_DIR')`r`n"

# ---- Step 1: upload every file in BINARY to IFS ----------------------------
$ftpScript += "binary`r`n"
foreach ($f in $uploads) {
    $localPath  = Join-Path $wsRoot $f.Local
    $ifsPath    = "$IFS_DIR/$($f.Mbr)"
    $ftpScript += "put `"$localPath`" `"$ifsPath`"`r`n"
}

# ---- Step 2: CPYFRMSTMF each IFS file into source member ------------------
# STMFCCSID(1208) = UTF-8  |  DBFCCSID(37) = EBCDIC US
# This is IBM i doing the conversion natively - 100% reliable for all chars.
foreach ($f in $uploads) {
    $ifsPath    = "$IFS_DIR/$($f.Mbr)"
    $mbrPath    = "/QSYS.LIB/$LIB.LIB/$($f.SrcPF).FILE/$($f.Mbr).MBR"
    $cpyCmd     = "CPYFRMSTMF FROMSTMF('$ifsPath') TOMBR('$mbrPath') MBROPT(*REPLACE) STMFCCSID(1208) DBFCCSID(37)"
    $ftpScript += "quote rcmd $cpyCmd`r`n"
}

$ftpScript += "quit`r`n"

# ---------------------------------------------------------------------------
# Write temp FTP script and execute
# ---------------------------------------------------------------------------
$scriptPath = "$env:TEMP\ibmi_ftp_deploy.txt"
[System.IO.File]::WriteAllText($scriptPath, $ftpScript, [System.Text.Encoding]::ASCII)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  IBM i Deploy : $FTP_HOST" -ForegroundColor Cyan
Write-Host "  Library      : $LIB" -ForegroundColor Cyan
Write-Host "  Method       : Binary to IFS + CPYFRMSTMF" -ForegroundColor Cyan
Write-Host "  Encoding     : UTF-8 (1208) -> EBCDIC (37)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Uploading $($uploads.Count) source members..." -ForegroundColor Yellow
Write-Host ""

ftp -n -s:$scriptPath

Write-Host ""
if ($LASTEXITCODE -eq 0) {
    Write-Host "Deploy complete." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step - compile on IBM i:" -ForegroundColor Cyan
    Write-Host "  CALL PGM(RAIPX61/STATECL)" -ForegroundColor White
} else {
    Write-Host "FTP completed with warnings - check output above." -ForegroundColor Yellow
}

Remove-Item $scriptPath -ErrorAction SilentlyContinue