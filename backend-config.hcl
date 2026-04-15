bucket         = "razyosefterraform"
key            = "terraform/state/production/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "raz-terraform-lock"