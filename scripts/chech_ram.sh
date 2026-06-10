#!/usr/bin/env bash
# check_ram.sh
# Checks RAM usage on Windows (Git Bash / WSL).
# Exits 0 if usage >= threshold (high usage / alert).
# Exits 1 if usage < threshold (normal).
#
# Usage: ./check_ram.sh [threshold_percent]
#   threshold_percent  Integer 0-100. Default: 80

THRESHOLD=${1:-80}

# Validate threshold is a number in range
if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || (( THRESHOLD < 0 || THRESHOLD > 100 )); then
    echo "ERROR: Threshold must be an integer between 0 and 100." >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Read memory stats via PowerShell (works in Git Bash and WSL)
# ---------------------------------------------------------------------------
read_ram_windows() {
    powershell.exe -NoProfile -Command "
        \$os = Get-CimInstance Win32_OperatingSystem
        \$total = \$os.TotalVisibleMemorySize
        \$free  = \$os.FreePhysicalMemory
        \$used  = \$total - \$free
        \$pct   = [math]::Round((\$used / \$total) * 100, 2)
        Write-Output \"\$used \$total \$pct\"
    " 2>/dev/null | tr -d '\r'
}

# ---------------------------------------------------------------------------
# Read memory stats via /proc/meminfo (pure WSL / Linux fallback)
# ---------------------------------------------------------------------------
read_ram_proc() {
    local total free buffers cached used pct
    total=$(awk '/^MemTotal:/{print $2}'  /proc/meminfo)
    free=$(awk '/^MemFree:/{print $2}'   /proc/meminfo)
    buffers=$(awk '/^Buffers:/{print $2}' /proc/meminfo)
    cached=$(awk '/^Cached:/{print $2}'  /proc/meminfo)
    used=$(( total - free - buffers - cached ))
    pct=$(awk "BEGIN{printf \"%.2f\", ($used/$total)*100}")
    echo "$used $total $pct"
}

# ---------------------------------------------------------------------------
# Detect environment and read RAM
# ---------------------------------------------------------------------------
if command -v powershell.exe &>/dev/null; then
    # Git Bash on Windows, or WSL with Windows PowerShell accessible
    METHOD="PowerShell"
    read -r USED TOTAL PCT <<< "$(read_ram_windows)"
elif [[ -f /proc/meminfo ]]; then
    # Pure WSL / Linux
    METHOD="/proc/meminfo"
    read -r USED TOTAL PCT <<< "$(read_ram_proc)"
else
    echo "ERROR: Cannot determine RAM usage — neither PowerShell nor /proc/meminfo is available." >&2
    exit 2
fi

# Verify we actually got numbers
if [[ -z "$USED" || -z "$TOTAL" || -z "$PCT" ]]; then
    echo "ERROR: Failed to read RAM statistics." >&2
    exit 2
fi

# Convert kB to MB for human-readable output
USED_MB=$(awk "BEGIN{printf \"%.1f\", $USED/1024}")
TOTAL_MB=$(awk "BEGIN{printf \"%.1f\", $TOTAL/1024}")

echo "----------------------------------------"
echo "  RAM Usage Check"
echo "  Method    : $METHOD"
echo "  Used      : ${USED_MB} MB"
echo "  Total     : ${TOTAL_MB} MB"
echo "  Usage     : ${PCT}%"
echo "  Threshold : ${THRESHOLD}%"
echo "----------------------------------------"

# Compare using awk to handle decimals correctly
OVER=$(awk "BEGIN{print ($PCT >= $THRESHOLD) ? 1 : 0}")

if [[ "$OVER" -eq 1 ]]; then
    echo "STATUS: HIGH — RAM usage (${PCT}%) is at or above threshold (${THRESHOLD}%)."
    exit 0   # >= threshold  →  exit 0
else
    echo "STATUS: NORMAL — RAM usage (${PCT}%) is below threshold (${THRESHOLD}%)."
    exit 1   # < threshold   →  exit 1
fi