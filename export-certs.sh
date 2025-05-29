#!/bin/bash

CERT_DIR="host-certs"

# Clean and recreate cert directory
rm -rf "$CERT_DIR/*.crt"

OS_TYPE="$(uname -s)"

if [[ "$OS_TYPE" == "Linux" ]]; then
    echo "Detected Linux. Exporting certificates..."
    cp /etc/ssl/certs/*.pem "$CERT_DIR/" 2>/dev/null
    cp /usr/share/ca-certificates/*/*.crt "$CERT_DIR/" 2>/dev/null
elif [[ "$OS_TYPE" == "MINGW"* || "$OS_TYPE" == "CYGWIN"* || "$OS_TYPE" == "MSYS"* ]]; then
    echo "Detected Windows. Running PowerShell script to export certificates..."
    read -r -d '' PS_SCRIPT <<'EOF'
    $certs = Get-ChildItem -Path Cert:\LocalMachine\Root
    $exportPath = "$PSScriptRoot\host-certs"

    if (-Not (Test-Path $exportPath)) {
        New-Item -ItemType Directory -Path $exportPath | Out-Null
    }

    foreach ($cert in $certs) {
        $pem = "-----BEGIN CERTIFICATE-----`n" + [Convert]::ToBase64String($cert.RawData, 'InsertLineBreaks') + "`n-----END CERTIFICATE-----"
        $fileName = "$exportPath\$($cert.Thumbprint).crt"
        Set-Content -Path $fileName -Value $pem
    }
EOF
    echo "$PS_SCRIPT" > collect-certs.ps1
    powershell.exe -ExecutionPolicy Bypass -File collect-certs.ps1
    rm collect-certs.ps1
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "Detected MacOS. Exporting certificates..."
    c=0
    security find-certificate -a -p | \
    awk -v dir="$CERT_DIR" '
        /BEGIN CERTIFICATE/ {c++ ; out=sprintf("%s/cert%d.crt", dir, c)}
        {if(out) print > out}'
else
    echo "Unsupported OS: $OS_TYPE"
    exit 1
fi

echo "Certificates exported to $CERT_DIR"
