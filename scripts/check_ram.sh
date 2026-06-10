#!/usr/bin/env bash
# check_ram.sh
# Checks RAM usage on Windows via PowerShell (Git Bash / native bash).
# Exits 0 if usage >= threshold (high usage / alert).
# Exits 1 if usage <  threshold (normal).
# Exits 2 on error.
#
# Usage: ./check_ram.sh [threshold_percent]
#   threshold_percent  Integer 0-100. Default: 80

THRESHOLD=${1:-80}

# Validate threshold
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || (( THRESHOLD < 0 || THRESHOLD > 100 )); then
    echo "ERROR: Threshold must be an integer between 0 and 100." >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Locate powershell.exe using known absolute paths (PATH may be stripped)
# ---------------------------------------------------------------------------
PS_EXE=""
for candidate in \
    "/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" \
    "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
do
    if [[ -x "$candidate" ]]; then
        PS_EXE="$candidate"
        break
    fi
done

# Last-resort: try PATH
if [[ -z "$PS_EXE" ]] && command -v powershell.exe &>/dev/null; then
    PS_EXE="powershell.exe"
fi

if [[ -z "$PS_EXE" ]]; then
    echo "ERROR: powershell.exe not found. Cannot read RAM statistics." >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Query RAM via PowerShell
# ---------------------------------------------------------------------------
PS_OUTPUT=$("$PS_EXE" -NoProfile -NonInteractive -Command "
    \$os    = Get-CimInstance Win32_OperatingSystem
    \$total = \$os.TotalVisibleMemorySize
    \$free  = \$os.FreePhysicalMemory
    \$used  = \$total - \$free
    \$pct   = [math]::Round((\$used / \$total) * 100, 2)
    Write-Output \"\$used \$total \$pct\"
" 2>/dev/null | tr -d '\r')

read -r USED TOTAL PCT <<< "$PS_OUTPUT"

if [[ -z "$USED" || -z "$TOTAL" || -z "$PCT" ]]; then
    echo "ERROR: Failed to read RAM statistics." >&2
    exit 2
fi

# Human-readable MB
USED_MB=$(awk  "BEGIN{printf \"%.1f\", $USED/1024}")
TOTAL_MB=$(awk "BEGIN{printf \"%.1f\", $TOTAL/1024}")

echo "----------------------------------------"
echo "  RAM Usage Check"
echo "  Used      : ${USED_MB} MB"
echo "  Total     : ${TOTAL_MB} MB"
echo "  Usage     : ${PCT}%"
echo "  Threshold : ${THRESHOLD}%"
echo "----------------------------------------"

OVER=$(awk "BEGIN{print ($PCT >= $THRESHOLD) ? 1 : 0}")

if [[ "$OVER" -eq 1 ]]; then
    echo "STATUS: HIGH — RAM usage (${PCT}%) is at or above threshold (${THRESHOLD}%)."
    exit 0
else
    echo "STATUS: NORMAL — RAM usage (${PCT}%) is below threshold (${THRESHOLD}%)."
    exit 1
fi