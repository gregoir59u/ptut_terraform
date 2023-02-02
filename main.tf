terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.11"
    }
  }
}

provider "proxmox" {

  pm_api_url = var.pm_api_url

  ########## PWD AUTH ###########################################
  //pm_user         = var.pm_user
  //pm_password     = var.pm_password
  ###############################################################

  ########## TOKEN AUTH #########################################
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  ###############################################################

  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "proxmox_vm" {
  count       = 1
  name        = "server-prod${count.index + 1}"
  target_node = "proxmox"
  clone       = "debian-cloudinit"
  os_type     = "cloud-init"
  cores       = 2
  sockets     = "1"
  cpu         = "host"
  memory      = 2048
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"
  disk {
    size    = "10G"
    type    = "scsi"
    storage = "local"
  }

  ######### Cloud-init image config #############################
  ipconfig0  = "ip=192.168.1.21${count.index + 1}/24,gw=192.168.1.254"
  sshkeys    = file("/home/alexis/.ssh/id_rsa.pub") //publickey of the local machine
  ciuser     = var.ciuser
  cipassword = var.cipassword
  ###############################################################

  connection {
    type        = "ssh"
    user        = var.user
    password    = var.password
    host        = "192.168.1.21${count.index + 1}"
    private_key = file("/home/alexis/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo apt-get update",
      "sudo curl https://raw.githubusercontent.com/fucks1u/scripts-provisionning/main/install-zabbix.sh | sudo bash"
    ]
  }
}

