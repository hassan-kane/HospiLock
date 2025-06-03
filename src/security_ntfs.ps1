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

    # 🔒 Désactiver héritage et supprimer permissions héritées
    $acl.SetAccessRuleProtection($true, $false)

    # Nettoyer les règles existantes
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

# Application des permissions depuis le JSON
foreach ($item in $permissionsData) {
    Appliquer-Droits -chemin $item.Path -droits $item.Droits
}

# ================================
# Restreindre les outils système
# ================================
$executables = @(
    "$env:windir\System32\cmd.exe",
    "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe",
    "$env:windir\System32\regedit.exe",
    "$env:windir\System32\eventvwr.exe",
    "$env:windir\System32\services.msc",
    "$env:windir\System32\diskmgmt.msc",
    "$env:windir\System32\control.exe"
)

# Groupes NON autorisés à utiliser les outils système
$groupesRestreints = @(
    "G_Medecins", "G_Infirmiers", "G_Communication",
    "G_RH", "G_Comptables", "G_Direction"
)

foreach ($exe in $executables) {
    if (Test-Path $exe) {
        $acl = Get-Acl $exe

        # Supprimer règles conflictuelles existantes
        $acl.Access | Where-Object {
            $_.IdentityReference -match "G_IT|Administrateurs|G_Medecins|G_Infirmiers|G_Communication|G_RH|G_Comptables|G_Direction"
        } | ForEach-Object {
            $acl.RemoveAccessRule($_)
        }

        # Appliquer les refus aux groupes non autorisés
        foreach ($grp in $groupesRestreints) {
            $deny = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $grp, "ReadAndExecute", "None", "None", "Deny"
            )
            $acl.AddAccessRule($deny)
        }

        # Autoriser les informaticiens
        $allowIT = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "G_IT", "FullControl", "None", "None", "Allow"
        )

        # Autoriser les administrateurs
        $allowAdmin = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Administrateurs", "FullControl", "None", "None", "Allow"
        )

        $acl.AddAccessRule($allowIT)
        $acl.AddAccessRule($allowAdmin)

        Set-Acl -Path $exe -AclObject $acl
        Write-Host "🔒 Accès restreint configuré pour : $exe"
    }
}

# Définir le mot de passe du compte Administrateur local
$admin = [ADSI]"WinNT://./Administrateur,User"
$admin.SetPassword("Admin@2025!")
Write-Host "🔐 Mot de passe administrateur local défini."
