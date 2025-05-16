<#
.SYNOPSIS
    Script de restriction d’accès aux outils système et de nettoyage d’environnement.
.DESCRIPTION
    - Bloque cmd.exe, powershell.exe, control.exe pour les groupes non autorisés
    - Fournit des options de nettoyage : utilisateurs, groupes, ressources, ou tout
.PARAMETERS
    -clear_all        Supprime utilisateurs, groupes et ressources
    -clear_users      Supprime uniquement les utilisateurs JSON
    -clear_groups     Supprime uniquement les groupes JSON
    -clear_res        Supprime uniquement le dossier D:\Hopital
#>

param (
    [switch]$clear_all,
    [switch]$clear_users,
    [switch]$clear_groups,
    [switch]$clear_res
)

# == CONFIGURATION ==

# Outils à restreindre
$systemTools = @(
    "$env:SystemRoot\System32\cmd.exe",
    "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe",
    "$env:SystemRoot\System32\control.exe"
)

# Groupes qui n'ont PAS le droit d'accès
$restrictedGroups = @("G_Medecins", "G_Infirmiers", "G_RH", "G_Comptables", "G_Direction", "G_Communication")

# == FONCTION : Restriction d'accès NTFS ==
function Restrict-SystemTools {
    foreach ($tool in $systemTools) {
        if (Test-Path $tool) {
            try {
                $acl = Get-Acl $tool
                foreach ($group in $restrictedGroups) {
                    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                        ".\\$group",                         # Groupe local
                        "ReadAndExecute",                   # Droits à refuser
                        "ContainerInherit,ObjectInherit",   # Héritage
                        "None",                             # Inheritance flags
                        "Deny"                              # Type de règle
                    )
                    $acl.AddAccessRule($rule)
                }
                Set-Acl -Path $tool -AclObject $acl
                Write-Output "✅ Restrictions appliquées à : $tool"
            } catch {
                Write-Warning "❌ Erreur lors du traitement de $tool : $_"
            }
        } else {
            Write-Warning "⚠️ Fichier introuvable : $tool"
        }
    }
}

# == FONCTION : Nettoyage des utilisateurs ==
function Clear-Users {
    $users = (Get-Content "./data/utilisateurs.json" | ConvertFrom-Json).profils |
        ForEach-Object { $_.utilisateurs } | Select-Object -ExpandProperty nom

    foreach ($user in $users) {
        if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) {
            Write-Output "🧹 Suppression de l'utilisateur : $user"
            Remove-LocalUser -Name $user
        }
    }
}

# == FONCTION : Nettoyage des groupes ==
function Clear-Groups {
    $groups = (Get-Content "./data/groupes.json" | ConvertFrom-Json).groupes |
        Select-Object -ExpandProperty nom

    foreach ($group in $groups) {
        if (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue) {
            Write-Output "🧹 Suppression du groupe : $group"
            Remove-LocalGroup -Name $group
        }
    }
}

# == FONCTION : Nettoyage des ressources ==
function Clear-Resources {
    $resPath = "D:\Hopital"
    if (Test-Path $resPath) {
        Write-Output "🧹 Suppression de : $resPath"
        Remove-Item -Path $resPath -Recurse -Force
    } else {
        Write-Output "📂 Aucun dossier D:\\Hopital à supprimer"
    }
}

# == ROUTINE PRINCIPALE ==

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
    Write-Output "==> Application des restrictions outils systèmes"
    Restrict-SystemTools

    Write-Output "`n==> Étape suivante : TESTS"
    Write-Output "- Utilise `runas` ou une session utilisateur pour tester l'accès aux outils"
    Write-Output "- Vérifie que seuls les informaticiens ont accès à : PowerShell, CMD, control.exe"
    Write-Output "- Les autres groupes doivent être bloqués"
}
