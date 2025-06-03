
param (
    [string]$jsonPath = ".\structure.json"
)

# Charger le JSON
try {
    $jsonContent = Get-Content $jsonPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur de lecture du fichier JSON. Chemin fourni : $jsonPath"
    exit 1
}

$basePath = $jsonContent.base
$structure = $jsonContent.structure

# Créer le dossier racine
if (-not (Test-Path -Path $basePath)) {
    New-Item -Path $basePath -ItemType Directory | Out-Null
    Write-Host "Dossier racine cree : $basePath"
}

# Créer tous les dossiers et fichiers
foreach ($mainFolder in $structure.PSObject.Properties) {
    $mainPath = Join-Path $basePath $mainFolder.Name
    New-Item -Path $mainPath -ItemType Directory -Force | Out-Null
    Write-Host "Cree : $mainPath"

    foreach ($subFolder in $mainFolder.Value.PSObject.Properties) {
        $subPath = Join-Path $mainPath $subFolder.Name
        New-Item -Path $subPath -ItemType Directory -Force | Out-Null
        Write-Host "   Sous-dossier : $subPath"

        foreach ($file in $subFolder.Value) {
            $filePath = Join-Path $subPath $file
            New-Item -Path $filePath -ItemType File -Force | Out-Null
            Write-Host "      Fichier : $filePath"
        }
    }
}

Write-Host ""
Write-Host "Structure creee avec succes."
