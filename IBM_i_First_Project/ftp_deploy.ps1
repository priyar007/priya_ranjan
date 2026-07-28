# =============================================================================
# Script  : ftp_deploy.ps1
# Purpose : Upload IBM i project source members to PUB400.COM (RAIPX61 lib)
#           using FTP ASCII mode, which automatically converts UTF-8/ASCII
#           to EBCDIC CCSID 37 on the IBM i side.
#
# Usage   : .\ftp_deploy.ps1
#           (run from the workspace root: priya_ranjan\)
#
# FTP ASCII mode is the key: it triggers IBM i's built-in ASCII->EBCDIC
# conversion so all special characters ( / [ ] { } " - etc.) are mapped
# correctly to their EBCDIC equivalents without any manual hex encoding.
# =============================================================================

# ---------------------------------------------------------------------------
# CONNECTION SETTINGS — update password before running
# ---------------------------------------------------------------------------
$FTP_HOST = "pub400.com"
$FTP_USER = "RAIPX6"
$FTP_PASS = "YOUR_PASSWORD_HERE"      # <-- replace with your PUB400 password
$LIB      = "RAIPX61"

# ---------------------------------------------------------------------------
# Source files to upload
# Format: @{ Local = "relative\path\file.EXT"; RemoteLib = "LIB"; RemoteFile = "SRCPF"; RemoteMbr = "MEMBER"; Type = "SRCTYPE" }
# ---------------------------------------------------------------------------
$uploads = @(
    @{ Local="IBM_i_First_Project\QRPGLESRC\HTTPSVCPGM.SQLRPGLE"; RemoteFile="QRPGLESRC"; RemoteMbr="HTTPSVCPGM"; Type="SQLRPGLE" },
    @{ Local="IBM_i_First_Project\QRPGLESRC\HTTPSVC.H";            RemoteFile="QRPGLESRC"; RemoteMbr="HTTPSVC";    Type="RPGLEINC" },
    @{ Local="IBM_i_First_Project\QRPGLESRC\CTRYSVC.RPGLE";        RemoteFile="QRPGLESRC"; RemoteMbr="CTRYSVC";    Type="RPGLE"    },
    @{ Local="IBM_i_First_Project\QRPGLESRC\STATEMAIN.RPGLE";      RemoteFile="QRPGLESRC"; RemoteMbr="STATEMAIN";  Type="RPGLE"    },
    @{ Local="IBM_i_First_Project\QRPGLESRC\STATEMOCK.RPGLE";      RemoteFile="QRPGLESRC"; RemoteMbr="STATEMOCK";  Type="RPGLE"    },
    @{ Local="IBM_i_First_Project\QDDSSRC\STATELIST.DSPF";         RemoteFile="QDDSSRC";   RemoteMbr="STATELIST";  Type="DSPF"     },
    @{ Local="IBM_i_First_Project\QCLSRC\STATECL.CLP";             RemoteFile="QCLSRC";    RemoteMbr="STATECL";    Type="CLP"      },
    @{ Local="IBM_i_First_Project\QCLSRC\IFSCL.CLP";               RemoteFile="QCLSRC";    RemoteMbr="IFSCL";      Type="CLP"      },
    @{ Local="IBM_i_First_Project\QCLSRC\MOCKCL.CLP";              RemoteFile="QCLSRC";    RemoteMbr="MOCKCL";     Type="CLP"      },
    @{ Local="IBM_i_First_Project\QCLSRC\IFSMOCKCL.CLP";           RemoteFile="QCLSRC";    RemoteMbr="IFSMOCKCL";  Type="CLP"      }
)

# ---------------------------------------------------------------------------
# Build the FTP command script
# ---------------------------------------------------------------------------
$ftpScript = @"
open $FTP_HOST
$FTP_USER
$FTP_PASS
ascii
"@

foreach ($f in $uploads) {
    # IBM i FTP target path for a source member:
    #   /QSYS.LIB/<LIB>.LIB/<SRCPF>.FILE/<MEMBER>.MBR
    $remotePath = "/QSYS.LIB/$LIB.LIB/$($f.RemoteFile).FILE/$($f.RemoteMbr).MBR"
    $ftpScript += "`nput `"$($f.Local)`" `"$remotePath`""
}

$ftpScript += "`nquit`n"

# ---------------------------------------------------------------------------
# Write the FTP script to a temp file and execute
# ---------------------------------------------------------------------------
$scriptPath = "$env:TEMP\ibmi_ftp_deploy.txt"
$ftpScript | Set-Content -Path $scriptPath -Encoding ASCII

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  IBM i FTP Deploy to $FTP_HOST" -ForegroundColor Cyan
Write-Host "  Library : $LIB" -ForegroundColor Cyan
Write-Host "  Mode    : ASCII (auto EBCDIC convert)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Uploading $($uploads.Count) source members..." -ForegroundColor Yellow
Write-Host ""

ftp -n -s:$scriptPath

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "All files uploaded successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step - compile on IBM i:" -ForegroundColor Cyan
    Write-Host "  CALL PGM(RAIPX61/STATECL)" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "FTP completed with errors. Check output above." -ForegroundColor Red
}

# Clean up temp script
Remove-Item $scriptPath -ErrorAction SilentlyContinue
