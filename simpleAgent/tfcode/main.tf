terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.64.0"
    }
  }
  backend "azurerm" {} 
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  storage_use_azuread        = true
}

variable "managed_image_id" {
  type = string
}
variable "vm_sku" {
  type = string  
}
variable "virtual_network_resource_group_name" {
  type = string  
}
variable "virtual_network_name" {
  type = string
}
variable "virtual_network_subnet_name" {
  type = string
}


data "azurerm_resource_group" "existing" {
  name = var.virtual_network_resource_group_name
}

data "azurerm_virtual_network" "existing" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_subnet" "existing" {
  name                 = var.virtual_network_subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = data.azurerm_virtual_network.existing.resource_group_name
}

resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine_scale_set" "example" {
  name                = "AzDO-Agent-linux"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = data.azurerm_resource_group.existing.location
  sku                 = var.vm_sku
  instances           = 0

  admin_username = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.sshkey.public_key_openssh
  }

  source_image_id = var.managed_image_id

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "AzDO_Agent_linux"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = data.azurerm_subnet.existing.id
    }
  }

  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}