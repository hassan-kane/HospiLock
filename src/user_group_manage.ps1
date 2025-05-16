param (
    [string]$GroupesJSON = ".\groupes.json",
    [string]$UtilisateursJSON = ".\utilisateurs.json"
)

# Charger les fichiers JSON
$groupesData = Get-Content $GroupesJSON | ConvertFrom-Json
$utilisateursData = Get-Content $UtilisateursJSON | ConvertFrom-Json

# Création des groupes 
foreach ($groupe in $groupesData.groupes) {
    if (-not (Get-LocalGroup -Name $groupe.nom -ErrorAction SilentlyContinue)) {
        New-LocalGroup -Name $groupe.nom
        Write-Output "Groupe créé : $($groupe.nom)"
    } else {
        Write-Output "Groupe déjà existant : $($groupe.nom)"
    }
}

# Création des utilisateurs et affectation aux groupes
foreach ($profil in $utilisateursData.profils) {
    $groupeNom = "G_$($profil.profil)"

    foreach ($utilisateur in $profil.utilisateurs) {
        $username = $utilisateur.nom
        $password = ConvertTo-SecureString $utilisateur.defaultMotDePasse -AsPlainText -Force

        if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $username -FullName $utilisateur.prenom -Password $password
            Write-Output "Utilisateur créé : $username"
        } else {
            Write-Output "Utilisateur déjà existant : $username"
        }

        Add-LocalGroupMember -Group $groupeNom -Member $username
        Write-Output "$username ajouté au groupe $groupeNom"
    }
}
