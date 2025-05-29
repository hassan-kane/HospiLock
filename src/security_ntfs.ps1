param (
    [string]$PermissionsJSON = ".\permissions.json"
)

if (-not (Test-Path $PermissionsJSON)) {
    Write-Error "Fichier JSON introuvable : $PermissionsJSON"
    exit
}

$permissionsData = Get-Content $PermissionsJSON | ConvertFrom-Json

function Appliquer-Droits {
    param (
        [string]$chemin,
        [array]$droits
    )

    if (!(Test-Path $chemin)) {
        Write-Warning "⚠️ Le chemin '$chemin' n'existe pas. Aucune permission appliquée."
        return
    }

    $acl = Get-Acl $chemin
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

    foreach ($droit in $droits) {
        $groupe = $droit.Groupe
        $permission = $droit.Permission

        try {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $groupe, $permission, "ContainerInherit,ObjectInherit", "None", "Allow"
            )
            $acl.AddAccessRule($rule)
        } catch {
            Write-Warning "Erreur lors de l'ajout des droits pour $groupe sur $chemin avec '$permission'"
        }
    }

    Set-Acl -Path $chemin -AclObject $acl
    Write-Host "✅ Droits appliqués sur : $chemin"
}

foreach ($item in $permissionsData) {
    Appliquer-Droits -chemin $item.Path -droits $item.Droits
}

# Restreindre les exécutables système sauf pour G_IT
$executables = @(
    "$env:windir\System32\cmd.exe",
    "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe",
    "$env:windir\System32\control.exe"
)

foreach ($exe in $executables) {
    if (Test-Path $exe) {
        $acl = Get-Acl $exe

        $deny = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Utilisateurs", "ReadAndExecute", "None", "None", "Deny"
        )

        $allow = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "G_IT", "FullControl", "None", "None", "Allow"
        )

        $acl.SetAccessRule($deny)
        $acl.AddAccessRule($allow)
        Set-Acl -Path $exe -AclObject $acl

        Write-Host "🔒 Restriction appliquée à : $exe"
    }
}

# Définir le mot de passe de l’administrateur
$admin = [ADSI]"WinNT://./Administrateur,User"
$admin.SetPassword("Admin@2025!")
Write-Host "🔐 Mot de passe administrateur local défini."
