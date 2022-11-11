# Terraform variables

# API token
variable "do_token" {
  type = string
  default = ""
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
