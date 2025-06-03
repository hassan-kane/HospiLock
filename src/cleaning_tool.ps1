<#
.SYNOPSIS
    Script de nettoyage basé uniquement sur les fichiers JSON.
.DESCRIPTION
    - Supprime les utilisateurs listés dans resources.json
    - Supprime les groupes listés dans groupes.json
    - Supprime les répertoires listés dans permissions.json
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


function Clear-Users {
    $resData = Get-Content "./data/resources.json" | ConvertFrom-Json
    foreach ($profil in $resData.profils) {
        foreach ($user in $profil.utilisateurs) {
            $userName = $user.nom
            if (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue) {
                Write-Output "Suppression utilisateur : $userName"
                Remove-LocalUser -Name $userName
            }
        }
    }
}

function Clear-Groups {
    $groupes = (Get-Content "./data/groupes.json" | ConvertFrom-Json).groupes
    foreach ($groupe in $groupes) {
        $nom = $groupe.nom
        if (Get-LocalGroup -Name $nom -ErrorAction SilentlyContinue) {
            Write-Output "Suppression groupe : $nom"
            Remove-LocalGroup -Name $nom
        }
    }
}
function Clear-Resources {
    $structureData = Get-Content "./data/structure_C.json" | ConvertFrom-Json
    $base = $structureData.base
    $structure = $structureData.structure

    foreach ($section in $structure.PSObject.Properties) {
        $sectionName = $section.Name
        $sectionPath = Join-Path $base $sectionName
        if (Test-Path $sectionPath) {
            Write-Output "Suppression du dossier : $sectionPath"
            Remove-Item -Path $sectionPath -Recurse -Force
        } else {
            Write-Output "Dossier introuvable (ignoré) : $sectionPath"
        }
    }
}


# Execution principale
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
