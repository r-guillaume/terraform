# Les modules

## Création du 3ème lab

Retournez dans votre dossier `terraform-labs-{{identifiant}}`.
Créer le dossier `lab3` et y entrer.

## Description

Comme vous avez suivi le lab 2, vous êtes maintenant capables de faire pas mal de choses par vous-même...

Donc dans ce lab, nous allons introduire de nouvelles notions, comme les boucles et les modules.

## Optimisation

Pour créer une VM, nous avons créer ces différentes ressources :
* Une instance
* Un ou plusieurs disques
* Pour chaque disque, un attachement

*Nous le faisons pas dans ce lab, mais pour une VM, il faut souvent créer un record DNS.*

La solution pour optimiser notre déploiement s'appelle le module Terraform.

### Création d'un module local pour créer une VM

L'objectif de cette section du lab est de créer un module et de l'utiliser.

Un module est constitué de `variables` qui sont les attributs d'entrée du module, d'`output` qui sont les sorties, et de `resource` & `data`, qui font partie du code principal du module.

Créer le dossier `modules` et le sous-dossier `vm` :
```bash
mkdir -p modules/vm
cd modules/vm
```

#### Variables

Nous allons créer un input pour le module pour chaque variable qui peut changer lors de la création d'une VM :

* Name
* AZ (availibility zone)
* AMI (image)
* subnet_id (id du sous-réseau)
* workspace (Terraform Workspace)
* Disques
* Identifiant

Créez le fichier `variables.tf`, et ajoutez ce contenu :

```hcl
variable ami {
    description = "L'AMI à utiliser"
}

variable name {
    description = "Nom de la VM"
    type        = string
}

variable az {
    description = "Availibility zone à utiliser"
}

variable subnet_id {
    description = "Sous-réseau à utiliser"
}

variable disks {
    description = "Disques à ajouter à la VM"
    type        = map(any)
    default     = {}
}

variable workspace {
    description = "Terraform workspace"
    type        = string
}

variable identifiant {
    description = "Votre identifiant"
    type        = string
}
```

#### Structure principale du module

Créez un fichier `main.tf` avec le contenu de votre fichier `05-vm.tf` du lab 2.  
Remplacez les variables nécessaires par `var.{{nom de la variable}}`.

L'objectif est également de permettre d'avoir plusieurs VMs par environement, et plusieurs disques par VMs.  
Renseignez-vous sur la ressource for_each...

*Essayez de le faire par vous-même*

Vous devriez obtenir quelque chose comme ça :

For easy stuff
```hcl
resource "aws_instance" "vm" {
  ami               = var.ami
  subnet_id         = var.subnet_id
  availability_zone = var.az
  instance_type     = "t2.micro"

  tags = { Name = upper("${var.identifiant}_${var.workspace}_VM_${var.name}") }
}

resource "aws_ebs_volume" "ebs_volume" {
  for_each          = var.disks
  availability_zone = var.az
  size              = each.value

  tags = { Name = upper("${var.identifiant}_${var.workspace}_EBS_VOLUME_${var.name}") }
}

resource "aws_volume_attachment" "ebs_att" {
  for_each    = var.disks
  device_name = each.key
  volume_id   = aws_ebs_volume.ebs_volume[each.key].id
  instance_id = aws_instance.vm.id
}
```

#### Ouput

Comme vous le savez maintenant, un module est une boîte noire, on ne connaît pas ce qu'il s'y passe, sauf en regardant le code.

Ainsi, nous devons parfois récupérer des informations sur ce qui a été créé, grâce aux outputs.

Il pourraît être intéressant de pouvoir obtenir toutes les informations sur chaque VM.

Créez le fichier `output.tf` et ajoutez-y le code suivant :
```hcl
output instance {
    description = "Les informations de la VM"
    value       = aws_instance.vm
}
```

### Utilisation du module

Retournez dans votre dossier lab3 : `cd ../..`

Vous pouvez maintenant utiliser votre module, pour celà créez le fichier `05-vm.tf` avec un appel à votre module.

Pour ce lab, vous devez créer les choses suivantes.

DEV :
* 1 VM nommée `vm1` avec 2 disques (`/dev/sdb` de 1Go et `/dev/sdc` de 2Go)
* 1 VM nommée `vm2` avec 1 disque (`/dev/sdb` de 3Go)

PRD :
* 1 VM nommée `vm` avec 1 disque (`/dev/sdh` de 5Go)

Pour information, les modules ont un attribut `source` qui permet d'indiquer le chemin du module.  

Petite aide...
```hcl
data "aws_ami" "amazon-linux-2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

locals {
  vms = {
    DEV = {
      "vm1" = {
        disks = {
          "/dev/sdb" = 1
          "/dev/sdc" = 2
        }
      }
      "vm2" = {
        disks = {
          "/dev/sdb" = 3
        }
      }
    }
    PRD = {
      "vm" = {
        disks = {
          "/dev/sdh" = 5
        }
      }
    }
  }
  vm = local.vms[terraform.workspace]
}
```

A vous de jouer !

\
\
\
\
\
\
\
\
\
\
\
Essayez de ne pas regarder la solution... ;)

\
\
\
\
\
\
\
\
\
\
\
Je vous vois :p
\
\
\
\
\
\
\
\
\
\
\
Ok:

La solution ressemble à ça :

```hcl
module "vm" {
  source      = "./modules/vm"
  for_each    = local.vm
  name        = upper(each.key)
  workspace   = terraform.workspace
  identifiant = var.identifiant
  az          = data.aws_availability_zones.available.names[0]
  subnet_id   = aws_subnet.this.id
  ami         = data.aws_ami.amazon-linux-2.id
  disks       = each.value.disks
}
```

## Appliquer l'infrastructure sur les 2 environements

Vous savez le faire, je vous laisse planifier et appliquer les ressources sur AWS.

### Vérification sur la console

Allez sur la console AWS de notre projet : [console](https://389840134943.signin.aws.amazon.com/console).

Une fois connecté, allez dans le menu principal, sélectionnez EC2, et vérifier que votre VM est bien présente.  
Vérifiez également que vos disques sont bien présents.

## Destruction

Lancez la commande sur chaque Workspace :

```bash
terraform apply -destroy
```

PS : pour changer d'environement, utilisez `terraform workspace select {{env}}`

:warning: Si vous ne supprimez pas vos VMs, vous serez pénaliser de 2 points sur votre note finale.
