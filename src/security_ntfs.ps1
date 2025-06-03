# 1. Droits NTFS classiques

$regles = @(
    @{ dossier = "C:\Hopital\Patients"; groupe = "G_Medecins"; droits = "ReadAndExecute" },
    @{ dossier = "C:\Hopital\RH"; groupe = "G_RH"; droits = "Modify" },
    @{ dossier = "C:\Hopital\Finance"; groupe = "G_Comptables"; droits = "Modify" },
    @{ dossier = "C:\Hopital\Communication"; groupe = "G_Communication"; droits = "ReadAndExecute" },
    @{ dossier = "C:\Hopital\Direction"; groupe = "G_Direction"; droits = "FullControl" },
    @{ dossier = "C:\Hopital\Soins"; groupe = "G_Infirmiers"; droits = "Modify" },
    @{ dossier = "C:\Hopital\Outils_IT"; groupe = "G_IT"; droits = "FullControl" }
)

foreach ($regle in $regles) {
    if (Test-Path $regle.dossier) {
        $acl = Get-Acl $regle.dossier
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $regle.groupe,
            $regle.droits,
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl -Path $regle.dossier -AclObject $acl
        Write-Output " Droits '$($regle.droits)' appliqués à $($regle.groupe) sur $($regle.dossier)"
    }
}


# 2. Cas croisés – accès spécifiques ciblés


# 2.1 RH (rh1) peut lire un fichier dans Direction
$file = "C:\Hopital\Direction\Docs\strategie_2025.docx"
if (Test-Path $file) {
    $acl = Get-Acl $file
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("rh1", "Read", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $file $acl
    Write-Output "Accès READ accordé à rh1 sur $file"
}

# 2.2 G_Medecins peut lire un fichier dans Communication
$file = "C:\Hopital\Communication\Campagnes\campagne_printemps.docx"
if (Test-Path $file) {
    $acl = Get-Acl $file
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("G_Medecins", "ReadAndExecute", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $file $acl
    Write-Output " Accès READ accordé à G_Medecins sur $file"
}

# 2.3 IT (info1) peut modifier le dossier Evaluations RH
$dossier = "C:\Hopital\RH\Evaluations"
if (Test-Path $dossier) {
    $acl = Get-Acl $dossier
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("info1", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $dossier $acl
    Write-Output "Accès MODIFY accordé à info1 sur $dossier"
}


# 3. Blocage des outils système sensibles

$executables = @(
    "C:\Windows\System32\cmd.exe",
    "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
    "C:\Windows\System32\regedit.exe",
    "C:\Windows\System32\eventvwr.exe",
    "C:\Windows\System32\services.msc"
)

foreach ($exe in $executables) {
    if (Test-Path $exe) {
        icacls $exe /inheritance:r /remove:g "Users" "Authenticated Users" "Everyone" > $null
        icacls $exe /grant:r "Administrateurs":RX > $null
        icacls $exe /grant:r "G_IT":RX > $null
        Write-Output " Outil restreint à Admins et G_IT : $exe"
    } else {
        Write-Output " Non trouvé : $exe"
    }
}
