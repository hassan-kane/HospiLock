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
        New-Item -Path $chemin -ItemType Directory | Out-Null
        Write-Host "Dossier créé : $chemin"
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
    Write-Host "Droits appliqués sur : $chemin"
}

foreach ($item in $permissionsData) {
    Appliquer-Droits -chemin $item.Path -droits $item.Droits
}

$executables = @(
    "$env:windir\System32\cmd.exe",
    "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe",
    "$env:windir\System32\control.exe"
)

foreach ($exe in $executables) {
    if (Test-Path $exe) {
        $acl = Get-Acl $exe

        $deny = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users", "ReadAndExecute", "None", "None", "Deny"
        )

        $allow = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "G_IT", "FullControl", "None", "None", "Allow"
        )

        $acl.SetAccessRule($deny)
        $acl.AddAccessRule($allow)
        Set-Acl -Path $exe -AclObject $acl

        Write-Host "Restriction appliquée à : $exe"
    }
}

$admin = [ADSI]"WinNT://./Administrator,User"
$admin.SetPassword("Admin@2025!")
Write-Host "Mot de passe administrateur local défini."
