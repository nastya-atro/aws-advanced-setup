terraform {
  backend "s3" {
    bucket         = "chevoska-terraform-state-bucket-12345" 
    key            = "check-locations-platform/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
} 