<#
.SYNOPSIS
    Script de nettoyage basé sur les fichiers JSON du projet.
.DESCRIPTION
    - Supprime les utilisateurs listés dans resources.json et utilisateurs.json
    - Supprime les groupes listés dans groupes.json
    - Supprime les dossiers listés dans permissions.json
    - Vide tous les fichiers JSON utilisés
.PARAMETERS
    -clear_all        Supprime tout : utilisateurs, groupes, ressources
    -clear_users      Supprime uniquement les utilisateurs JSON
    -clear_groups     Supprime uniquement les groupes JSON
    -clear_res        Supprime uniquement les dossiers JSON
#>

param (
    [switch]$clear_all,
    [switch]$clear_users,
    [switch]$clear_groups,
    [switch]$clear_res
)

function Clear-JsonFile {
    param (
        [string]$path,
        [string]$emptyContent
    )
    try {
        Set-Content -Path $path -Value $emptyContent -Encoding UTF8
        Write-Output "✅ JSON vidé avec succès : $path"
    } catch {
        Write-Warning "Impossible de vider le fichier : $path"
    }
}

function Clear-Users {
    $userFiles = @("../data/resources.json", "../data/utilisateurs.json")

    foreach ($file in $userFiles) {
        if (Test-Path $file) {
            try {
                $data = Get-Content $file | ConvertFrom-Json
                foreach ($profil in $data.profils) {
                    foreach ($user in $profil.utilisateurs) {
                        $userName = $user.nom
                        if (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue) {
                            Write-Output "Suppression utilisateur : $userName"
                            Remove-LocalUser -Name $userName
                        }
                    }
                }
                Clear-JsonFile -path $file -emptyContent '{ "profils": [] }'
            } catch {
                Write-Warning "Erreur de traitement du fichier $file : $_"
            }
        } else {
            Write-Warning "Fichier non trouvé : $file"
        }
    }
}

function Clear-Groups {
    $groupFile = "../data/groupes.json"
    if (Test-Path $groupFile) {
        try {
            $groupes = (Get-Content $groupFile | ConvertFrom-Json).groupes
            foreach ($groupe in $groupes) {
                $nom = $groupe.nom
                if (Get-LocalGroup -Name $nom -ErrorAction SilentlyContinue) {
                    Write-Output "Suppression groupe : $nom"
                    Remove-LocalGroup -Name $nom
                }
            }
            Clear-JsonFile -path $groupFile -emptyContent '{ "groupes": [] }'
        } catch {
            Write-Warning "Erreur de traitement du fichier $groupFile : $_"
        }
    } else {
        Write-Warning "Fichier non trouvé : $groupFile"
    }
}

function Clear-Resources {
    $permFile = "../data/permissions.json"
    if (Test-Path $permFile) {
        try {
            $permissions = Get-Content $permFile | ConvertFrom-Json
            foreach ($item in $permissions) {
                $path = $item.Path
                if (Test-Path $path) {
                    Write-Output "Suppression du dossier : $path"
                    Remove-Item -Path $path -Recurse -Force
                }
            }
            Clear-JsonFile -path $permFile -emptyContent '[]'
        } catch {
            Write-Warning "Erreur de traitement du fichier $permFile : $_"
        }
    } else {
        Write-Warning "Fichier non trouvé : $permFile"
    }
}

# == EXECUTION PRINCIPALE ==
if ($clear_all) {
    Clear-Users
    Clear-Groups
    Clear-Resources
}
elseif ($clear_users) {
    Clear-Users
}
elseif ($clear_groups) {
    Clear-Groups
}
elseif ($clear_res) {
    Clear-Resources
}
else {
    Write-Output "Aucun paramètre spécifié. Utilisez -clear_all, -clear_users, -clear_groups ou -clear_res"
}
