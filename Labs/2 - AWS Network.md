# AWS Network

## Prérequis

Vous avez reçu par mail un couple key_id/access_key.
Créez le dossier `.aws` dans votre home.
Créez le fichier `credentials` dans le dossier `.aws`, avec le contenu suivant :

```bash
[default]
aws_access_key_id = <votre key_id>
aws_secret_access_key = <votre access_key>
```

## Création du second lab

Retournez dans votre dossier `terraform-labs-{{identifiant}}`.
Créer le dossier `lab2` et y entrer.

## Provider AWS

Créer le fichier `00-provider.tf` avec le contenu suivant :
```hcl
provider "aws" {
    region = "eu-west-3"
}
```

## Description

L'objectif de ce lab est de créer un début de projet en utilisant Terraform and nous allons le faire sur Amazon Web Services (AWS).

La documentation des resources et datas du provider AWS est disponible [ici](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

Nous allons utiliser un projet déjà créé, et nous allons utiliser la région de Paris `eu-west-3`.

Durant ce lab, nous allons étudier le fonctionnement de ressources Terraform, des workspaces Terraform, ainsi que de quelques ressources AWS.

Nous allons créer 2 environements :

1 environement de développement (DEV) avec :
* 1 Sous-réseau (subnet) avec un block CIDR `10.0.X.0/24`
* 1 Machine Virtuelle (VM)

1 environement de production (PRD) avec :
* 1 Sous-réseau avec un block CIDR `10.0.Y.0/24`
* 1 VM

Toutes vos ressources **doivent** être nommées `{{identifiant}}_{{environement}}_{{type de ressource}}`, en majuscules.  
Par exemple : `TDUPONT_DEV_SUBNET_A`.

## Créer votre infrastructure

### On commence par la DEV
#### Création du Workspace Terraform

Comme nous avons 2 environements, qui ne sont pas différents d'un point de vue technique, nous allons utiliser les Workspaces Terraform.

```bash
terraform workspace new DEV
terraform workspace list
```

#### Définition des variables

Créer le fichier `01-variables.tf` avec le contenu suivant :
```hcl
variable "identifiant" {
  description = "Votre identifiant"
  default     = "{{identifiant}}"
}
```

Ensuite, nous avons 2 environements, donc différents espaces réseau (block CIDR). Nous allons utiliser les variables locales pour gérer cette différence.

Ajoutez ce code à la suite du fichier `01-variables.tf` :

```hcl
locals {
  address_spaces = {
    DEV = "10.0.X.0/24"
  }
  address_space = local.address_spaces[terraform.workspace]
}
```

:warning: Rappel : une variable locale peut être calculée (être calculée avec une fonction d'une autre variable locale, ou ressource, ou variable, ...) alors qu'une variable a une valeur fixe.

#### Configuration du réseau

Créer le fichier `04-network.tf` avec le contenu suivant :

```hcl
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["VPC"]
  }
}

resource "aws_subnet" "this" {
  vpc_id            = data.aws_vpc.this.id
  cidr_block        = local.address_space
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = upper("${var.identifiant}_${terraform.workspace}_SUBNET") }
}
```

Nous allons ici utiliser la valeur de `terraform.workspace` pour connaître nous Workspace courant.

Nous ne pouvons pas créer un VPC par personne car AWS limite le nombre d'entre-eux. Nous allons utiliser une data pour récupérer un VPC existant.  
De plus, le sous réseau dépend du VPC, donc nous faisons référence à celui-ci en utilisant un mapping de ressource : `data.aws_vpc.this.id`.

Pour plus d'information concernant les attributs disponible pour les différentes ressources utilisées (par exemple l'id du vpc), vous pouvez lire la [documentation associée](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc).


#### Machines virtuelles

Etant donné qu'une VM dans le cloud est déclarée avec plusieurs ressources, décrivons-les toutes.

##### Récupération des Availability Zones

Ajoutez dans le fichier `01-variables.tf` :

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

Cela va permettre de récupérer les zones disponibles dans notre région.

Tout ce qui suit (sections Disques et Instance) doit être ajouté dans un fichier `05-vm.tf`

##### Disque

```hcl
resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = 10

  tags = { Name = upper("${var.identifiant}_${terraform.workspace}_EBS_VOLUME") }
}
```

##### Instance

```hcl
data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners      = ["amazon"]

 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_instance" "vm" {
  ami               = data.aws_ami.amazon-linux-2.id
  subnet_id         = aws_subnet.this.id
  availability_zone = data.aws_availability_zones.available.names[0]
  instance_type     = "t3.micro"

  tags = { Name = upper("${var.identifiant}_${terraform.workspace}_VM") }
}
```

##### Attachement du disque

```hcl
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebs_volume.id
  instance_id = aws_instance.vm.id
}
```

## Création de la DEV

Comme nous l'avons vu dans le lab 1, nous allons utiliser les commandes suivantes :
```bash
terraform init
terraform plan -out {{identifiant}}.tfplan
terraform apply {{identifiant}}.tfplan
```

:exclamation: Gardez en tête que l'étape `plan` permet de **vérifier** ce que l'on souhaite appliquer, avant de le faire.

### Vérification sur la console

Allez sur la console AWS de notre projet : [console](https://920373009484.signin.aws.amazon.com/console).

Connectez-vous avez votre adresse mail et votre mot de passe reçu par mail.  
Lors de votre première connexion, vous serez invité à en changer.

Une fois connecté, allez dans le menu principal, sélectionnez EC2, et vérifier que votre VM est bien présente.

## Modifier votre infrastructure

### Allez, on ajoute la PRD

Pour tester la puissance de Terraform, et pour vous faire créer une vrai projet d'entreprise, nous allons créer l'environement de production.

#### Ajout des valeurs pour cet environement

Éditer le fichier `01-variables.tf` pour ajouter les lignes associées à l'environement de PRD :

Ce contenu :

```hcl
locals {
  address_spaces = {
    DEV = "10.0.X.0/24"
  }
  address_space = local.address_spaces[terraform.workspace]
}
```

Devient donc :

```hcl
locals {
  address_spaces = {
    DEV = "10.0.X.0/24"
    PRD = "10.0.Y.0/24"
  }
  address_space = local.address_spaces[terraform.workspace]
}
```

## Création de la PRD

Nous devons d'abord créer le Workspace Terraform PRD

```bash
terraform workspace new PRD
terraform workspace list
```

Et ensuite, comme d'habitude...
```bash
terraform init
terraform plan -out {{identifiant}}.tfplan
terraform apply {{identifiant}}.tfplan
```

### Vérification sur la console

Retournez sur la console AWS et vérifiez que votre VM de production est bien là.

## Destruction

Lancez la commande sur chaque Workspace :

```bash
terraform destroy
```

PS : pour changer d'environement, utilisez `terraform workspace select {{env}}`

:warning: Si vous ne supprimez pas vos VMs, vous serez pénaliser de 2 points sur votre note finale.
