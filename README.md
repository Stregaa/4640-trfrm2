# 4640-trfrm2

Adding a load balancer on DigitalOcean with Terraform and implementing variables:  
1. In a new project root directory, create the following directory structure:  
![image](https://user-images.githubusercontent.com/64290337/201251415-728d198d-3caf-465a-9930-65f3925c05e4.png)

2. While in the project root, add a ```.gitignore``` containing the following:  
```
.terraform/
*.tfstate
*.tfstate.backup
.env
do_token
```

3. In ```variables.tf```, add the following variables:  
```
# API token - replace empty string with your DO token
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
```
4. ```In main.tf```, include the following:
```
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "droplet_ssh_key" {
  name = "ATTEMPT1000"
}

data "digitalocean_project" "lab_project" {
  name = "first-project"
}

# Create a new tag
resource "digitalocean_tag" "do_tag" {
  name = "Web"
}

# Create a new vpc
resource "digitalocean_vpc" "web_vpc" {
  name     = "4640labs"
  region   = var.region
}

# Create a new Web Droplet in the sfo3 region
resource "digitalocean_droplet" "web" {
  image  = "rockylinux-9-x64"
  count  = var.droplet_count
  name   = "web-${count.index + 1}"
  tags   = [digitalocean_tag.do_tag.id]
  region = var.region
  size   = "s-1vcpu-512mb-10gb"
  ssh_keys = [data.digitalocean_ssh_key.droplet_ssh_key.id]
  vpc_uuid = digitalocean_vpc.web_vpc.id

  lifecycle {
    create_before_destroy = true
  }

}

# Add new web droplets to existing 4640_labs project
resource "digitalocean_project_resources" "project_attach" {
  project = data.digitalocean_project.lab_project.id
  resources = flatten([
    digitalocean_droplet.web.*.urn
  ])
}

# Create a load balancer
resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-1"
  region = var.region

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_tag = "Web"
  vpc_uuid = digitalocean_vpc.web_vpc.id
}

output "server_ip" {
  value = digitalocean_droplet.web.*.ipv4_address
}
```
Note the variables we used from the ```variables.tf``` file: ```var.<variablename>```  

5. Validate ```main.tf```:  
```terraform validate```
6. Check the terraform plan:  
```terraform plan```
7. Apply terraform and create the resources:  
```terraform apply```  

Setting up Ansible and Nginx:  
1. We will be reusing the ```ansible.cfg``` from the previous lab.  
2. In ```nginx_setup.yml```, include:  
```
---

- name: install and enable nginx
  hosts: webservers
  tasks:
    - name: install nginx
      package:
        name: nginx
        state: present
    - name: enable and start nginx
      service:
        name: nginx
        enabled: yes
        state: started
```
3. While in the /mgmt directory, test the connection to DigitalOcean:  
```ansible-inventory --graph```  
```ansible -m ping -u root webservers```  
```ansible-playbook nginx_setup.yml -u root```
