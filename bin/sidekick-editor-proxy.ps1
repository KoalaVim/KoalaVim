# $EDITOR proxy: open $args[0] in the host Neovim ($env:NVIM) and block until the buffer closes.
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$File
)

$ErrorActionPreference = 'Stop'

if (-not $env:NVIM) {
    [Console]::Error.WriteLine('sidekick-editor-proxy: NVIM is empty; cannot reach the host Neovim')
    exit 1
}

$signalFile = Join-Path ([System.IO.Path]::GetTempPath()) "sidekick-editor-proxy.$PID.$([System.IO.Path]::GetRandomFileName())"

try {
    # Vim single-quoted string: only ' is special, doubled to ''
    $vimFile   = "'" + ($File       -replace "'", "''") + "'"
    $vimSignal = "'" + ($signalFile -replace "'", "''") + "'"

    $expr = "v:lua.require('KoalaVim.utils.ai.general').open_editor_file($vimFile, $vimSignal)"

    $out = & nvim --server $env:NVIM --remote-expr $expr 2>&1
    if ($LASTEXITCODE -ne 0) {
        [Console]::Error.WriteLine("sidekick-editor-proxy: nvim --remote-expr failed (NVIM=$($env:NVIM)): $out")
        exit 1
    }

    while (-not (Test-Path -LiteralPath $signalFile)) {
        Start-Sleep -Milliseconds 100
    }
} finally {
    if (Test-Path -LiteralPath $signalFile) {
        Remove-Item -LiteralPath $signalFile -Force -ErrorAction SilentlyContinue
    }
}

exit 0
