# Terraform variables

# API token
variable "do_token" {
  type = string
  default = "dop_v1_197c336ab023534557ec910c54910cff76153a7f6ddac674d3eedb4ccd358178"
}

# set default region to sfo3
variable "region" {
  type = string
  default = "sfo3"
}

# set default droplet count
variable "droplet_count" {
  type = number
  default = 2
}
