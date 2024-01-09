# Hello World

## Installer Terraform

* Télécharger Terraform en suivant les instructions sur le [site Terraform](https://developer.hashicorp.com/terraform/install#Linux).

* Lancer la commande `terraform --version` pour vérifier l'installation

```bash
$ terraform --version
Terraform v1.6.6
on linux_amd64
```

## Créer votre premier fichier Terraform

Créer un dossier pour les labs nommé `terraform-labs-{{identifiant}}` et y entrer.
Créer un dossier nommé `lab1` et y entrer.
Par exemple, Thomas Dupont lancera les commandes :

```bash
mkdir terraform-labs-tdupont
cd terraform-labs-tdupont
mkdir lab1
cd lab1
```

### Variables

Créer le fichier `01-variables.tf` avec le contenu suivant :
```hcl
variable "identifiant" {
  description = "Votre identifiant"
}
```

### Outputs

Créer un fichier `10-outputs.tf` avec le contenu suivant :
```hcl
output "hello" {
  value = "Hello ${var.identifiant} !!"
}
```

## Lancer Terraform

### Init

`terraform init`

### Plan

`terraform plan -out {{identifiant}}.tfplan`

Terraform vous demande alors de remplir la variable `identifiant`.

### Appliquer le plan

Après avoir vérifié que le plan correspond à ce qu'on souhaite, on peut l'appliquer avec `terraform apply {{identifiant}}.tfplan`

Vous devriez obtenir un résultat comme celui-ci :

```bash
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

hello = "Hello tdupont !!"
``` 

## Améliorer les variables

Modifier le fichier `01-variables.tf` avec le contenu suivant :

```hcl
variable "identifiant" {
  description = "Votre identifiant"
  default     = "inconnu"
}
```

## Lancer Terraform

Utiliser les mêmes commandes que lors de l'étape précédente pour effectuer un plan et un apply.

Vous devriez obtenir ce résultat :

```bash
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

hello = "Hello inconnu !!"
```

A cause de la valeur par défaut, aucune valeur pour la variable `identifiant` n'est demandée.

## Écraser la valeur par défaut

Il y a plusieurs manières de surcharger une valeur par défaut.

La plus simple est de créer une variable d'environement :

```bash
export TF_VAR_identifiant="{{identifiant}}"
```

## Lancer Terraform

Toujours avec les mêmes commandes :

You should see as output like this:
```bash
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

hello = "Hello tdupont !!"
```

Pour tout savoir sur les variables, consultez la [documentation officielle](https://www.terraform.io/docs/language/values/variables.html#declaring-an-input-variable).

Par exemple, l'attribut `sensitive` permet d'éviter de voir des mots de passe en clair dans les plans.
