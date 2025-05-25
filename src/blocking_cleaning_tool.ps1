<#
.SYNOPSIS
    Script d’administration pour sécuriser les accès et nettoyer l’environnement
.DESCRIPTION
    Ce script permet de :
    - Restreindre l’accès aux outils système sauf pour les informaticiens
    - Tester les accès manuellement
    - Nettoyer tout ou partie de la configuration selon les paramètres fournis
.PARAMETER clear_all
    Supprime tous les utilisateurs, groupes, et ressources
.PARAMETER clear_users
    Supprime uniquement les utilisateurs du JSON
.PARAMETER clear_groups
    Supprime uniquement les groupes du JSON
.PARAMETER clear_res
    Supprime uniquement les ressources (D:\Hopital, etc.)
#>

param (
    [switch]$clear_all,
    [switch]$clear_users,
    [switch]$clear_groups,
    [switch]$clear_res
)

# CONFIGURATION
$systemTools = @(
    "$env:SystemRoot\System32\cmd.exe",
    "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe",
    "$env:SystemRoot\System32\control.exe"
)

$restrictedGroups = @("G_Medecins", "G_Infirmiers", "G_RH", "G_Comptables", "G_Direction", "G_Communication")

function Restrict-SystemTools {
    foreach ($tool in $systemTools) {
        if (Test-Path $tool) {
            $acl = Get-Acl $tool
            foreach ($group in $restrictedGroups) {
                Write-Output "Restriction de $tool pour $group"
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:COMPUTERNAME\$group", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Deny")
                $acl.AddAccessRule($rule)
            }
            Set-Acl $tool $acl
        }
    }
}

function Clear-Users {
    $users = (Get-Content "./data/utilisateurs.json" | ConvertFrom-Json).profils | ForEach-Object { $_.utilisateurs } | Select-Object -ExpandProperty nom
    foreach ($user in $users) {
        if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) {
            Write-Output "Suppression de l'utilisateur : $user"
            Remove-LocalUser -Name $user
        }
    }
}

function Clear-Groups {
    $groups = (Get-Content "../data/groupes.json" | ConvertFrom-Json).groupes | Select-Object -ExpandProperty nom
    foreach ($group in $groups) {
        if (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue) {
            Write-Output "Suppression du groupe : $group"
            Remove-LocalGroup -Name $group
        }
    }
}

function Clear-Resources {
    $resPath = "D:\Hopital"
    if (Test-Path $resPath) {
        Write-Output "Suppression du répertoire $resPath"
        Remove-Item -Path $resPath -Recurse -Force
    }
}

# === EXECUTION SELON LES PARAMÈTRES ===

if ($clear_all) {
    Clear-Users
    Clear-Groups
    Clear-Resources
}
elseif ($clear_users) { Clear-Users }
elseif ($clear_groups) { Clear-Groups }
elseif ($clear_res) { Clear-Resources }
else {
    Write-Output "==> Application des restrictions outils systèmes"
    Restrict-SystemTools

    Write-Output "`n==> Étape suivante : réalisez les tests manuels de connexion"
    Write-Output "Utilisez runas ou ouvrez des sessions Windows pour vérifier :"
    Write-Output "- L'accès ou non à PowerShell, CMD, control.exe"
    Write-Output "- L'accès lecture/écriture aux dossiers selon le rôle"
}

