packer {
  required_plugins {
    azure = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# Auth to Azure
variable "clientid" {
}
variable "clientsecret" {
}
variable "subscriptionid" {
}
variable "tenantid" {
}

# general vars
variable "location" {
  default = "West Europe"
}
variable "vm_sku"{
}

# existing VNet
variable "virtual_network_resource_group_name" {
}
variable "virtual_network_name" {
}
variable "virtual_network_subnet_name" {
}
variable "private_virtual_network_with_public_ip" {
}

# Target for managed image
variable "managed_image_resource_group_name"{
}
variable "managed_image_name_prefix" {
}


locals { 
  timestamp = regex_replace(timestamp(), "[- TZ:]", "") 
}

//AZ
source "azure-arm" "azurevm" {
  client_id = var.clientid
  client_secret = var.clientsecret
  subscription_id = var.subscriptionid
  tenant_id = var.tenantid

  virtual_network_resource_group_name = var.virtual_network_resource_group_name
  virtual_network_name = var.virtual_network_name
  virtual_network_subnet_name = var.virtual_network_subnet_name
  private_virtual_network_with_public_ip = var.private_virtual_network_with_public_ip

  managed_image_resource_group_name = var.managed_image_resource_group_name
  managed_image_name = "${var.managed_image_name_prefix}_${local.timestamp}"

  build_resource_group_name = var.managed_image_resource_group_name

  os_type = "Linux"
  image_publisher = "Canonical"
  image_offer = "0001-com-ubuntu-server-jammy"
  image_sku = "22_04-lts-gen2"
  location = var.location
  vm_size = var.vm_sku

  azure_tags = {
    source = "PackerBuilder"
    timestamp = local.timestamp
  }
}

build {
  sources = ["sources.azure-arm.azurevm"]

  provisioner "shell" {
    script = "install.sh"
    execute_command  = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
  }

  #https://developer.hashicorp.com/packer/plugins/builders/azure/arm#linux
  provisioner "shell" {
    inline = [
      "sleep 30",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    execute_command  = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline_shebang = "/bin/sh -x"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

}


