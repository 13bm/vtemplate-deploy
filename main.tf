provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.resource_pool_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_virtual_machine" "vm" {
  name             = "${var.vm_name_prefix} - ${var.vm_name}"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder

  num_cpus = var.vm_cpu
  memory   = var.vm_memory
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id = var.network_name
  }

  # No disk block - attempt to use template's disks directly

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = "${var.vm_name_prefix}-${var.vm_name}"
        domain    = var.domain_name
      }
      
      network_interface {}
    }
  }
  
  lifecycle {
    ignore_changes = [
      annotation,
      clone,
      storage_policy_id,
    ]
  }
}

# Variables
variable "vsphere_user" {
  description = "vSphere username"
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "vSphere password"
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "vSphere server address"
  type        = string
}

variable "datacenter_name" {
  description = "Name of the datacenter"
  type        = string
}

variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}

variable "resource_pool_name" {
  description = "Name of the resource pool within the cluster"
  type        = string
}

variable "datastore_name" {
  description = "Name of the datastore"
  type        = string
}

variable "template_name" {
  description = "Name of the VM template"
  type        = string
}

variable "vm_name_prefix" {
  description = "Prefix to append to VM name"
  type        = string
  default     = "tf"
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_folder" {
  description = "Folder to place the VM in"
  type        = string
  default     = "AL"
}

variable "vm_cpu" {
  description = "Number of CPUs for the VM"
  type        = number
  default     = 4
}

variable "vm_memory" {
  description = "Memory in MB for the VM"
  type        = number
  default     = 16384
}

variable "network_name" {
  description = "Port Group"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the VM"
  type        = string
  default     = "local"
}

output "vm_ip_address" {
  value = vsphere_virtual_machine.vm.default_ip_address
}