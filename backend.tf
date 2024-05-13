 terraform {
   backend "s3" {
     bucket = "nodar-terraform6"
     key    = "terraform.tfstate"
     region = "us-east-1"
   }
 }
