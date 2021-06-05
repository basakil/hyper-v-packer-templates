
variable "box_out_dir" {
  type    = string
  default = "./dist/"
}

variable "cpu" {
  type    = string
  default = "2"
}

variable "disk_size" {
  type    = string
  default = "200000"
}

variable "hyperv_switchname" {
  type    = string
  default = "${env("hyperv_switchname")}"
}

variable "initrd" {
  type    = string
  default = "/install/initrd.gz"
}

variable "iso_checksum_type" {
  type    = string
  default = "sha256"
}

variable "iso_checksum_string" {
  type    = string
  default = "sha256:f11bda2f2caed8f420802b59f382c25160b114ccc665dbac9c5046e7fceaced2"
  # default = "http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04.1/release/SHA256SUMS"
}

variable "iso_url" {
  type    = string
  default = "http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04.1/release/ubuntu-20.04.1-legacy-server-amd64.iso"
}

variable "keyboard_layout" {
  type    = string
  default = "USA"
}

variable "keyboard_variant" {
  type    = string
  default = "us"
}

variable "locale" {
  type    = string
  default = "en_US.UTF-8"
}

variable "output_directory" {
  type    = string
  default = "./output-ubuntu-20.04/"
}

variable "output_name" {
  type    = string
  default = "ubuntu-focal"
}

variable "password" {
  type    = string
  default = "vagrant"
}

variable "ram_size" {
  type    = string
  default = "2048"
}

variable "username" {
  type    = string
  default = "vagrant"
}

variable "vm_name" {
  type    = string
  default = "ubuntu-focal"
}

variable "vmlinuz" {
  type    = string
  default = "/install/vmlinuz"
}

source "hyperv-iso" "hviso" {
  boot_command         = ["<esc><wait5>", "linux ${var.vmlinuz} ", "auto ", "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ", "debian-installer=${var.locale} ", "locale=${var.locale} ", "hostname={{ .Name }} ", "fb=false ", "debconf/frontend=noninteractive ", "passwd/user-fullname=${var.username} ", "passwd/username=${var.username} ", "passwd/user-password=${var.password} ", "passwd/user-password-again=${var.password} ", "console-setup/ask_detect=false ", "keymap=${var.keyboard_variant} ", "kbd-chooser/method=${var.keyboard_variant} ", "keyboard-configuration/layout=${var.keyboard_layout} ", "keyboard-configuration/variant=${var.keyboard_layout} ", "tasksel=ubuntu-desktop ", "<enter>", "initrd ${var.initrd}<enter>", "boot<enter>"]
  boot_wait            = "0s"
  communicator         = "ssh"
  cpus                 = "${var.cpu}"
  disk_size            = "${var.disk_size}"
  enable_secure_boot   = false
  generation           = 2
  guest_additions_mode = "disable"
  http_directory       = "preseed"
  iso_checksum         = "${var.iso_checksum_string}"
  iso_url              = "${var.iso_url}"
  memory               = "${var.ram_size}"
  output_directory     = "${var.output_directory}"
  shutdown_command     = "echo '${var.username}' | sudo -S -E shutdown -P now"
  ssh_password         = "${var.password}"
  ssh_timeout          = "4h"
  ssh_username         = "${var.username}"
  switch_name          = "${var.hyperv_switchname}"
  vm_name              = "${var.vm_name}"
}

source "virtualbox-iso" "vbiso" {
  boot_command     = ["<enter><wait><f6><esc><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>", "${var.vmlinuz} noapic", "auto ", "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ", "debian-installer=${var.locale} ", "locale=${var.locale} ", "hostname={{ .Name }} ", "fb=false ", "debconf/frontend=noninteractive ", "passwd/user-fullname=${var.username} ", "passwd/username=${var.username} ", "passwd/user-password=${var.password} ", "passwd/user-password-again=${var.password} ", "console-setup/ask_detect=false ", "keymap=${var.keyboard_variant} ", "kbd-chooser/method=${var.keyboard_variant} ", "keyboard-configuration/layout=${var.keyboard_layout} ", "keyboard-configuration/variant=${var.keyboard_layout} ", "tasksel=ubuntu-desktop ", "initrd=${var.initrd}<enter>"]
  boot_wait        = "5s"
  communicator     = "ssh"
  cpus             = "${var.cpu}"
  disk_size        = "${var.disk_size}"
  guest_os_type    = "Ubuntu_64"
  http_directory   = "preseed"
  iso_checksum     = "${var.iso_checksum_string}"
  iso_url          = "${var.iso_url}"
  memory           = "${var.ram_size}"
  output_directory = "${var.output_directory}"
  shutdown_command = "echo '${var.username}' | sudo -S -E shutdown -P now"
  shutdown_timeout = "10m"
  ssh_password     = "${var.password}"
  ssh_timeout      = "4h"
  ssh_username     = "${var.username}"
  vboxmanage       = [["modifyvm", "{{ .Name }}", "--graphicscontroller", "vboxsvga"], ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"], ["modifyvm", "{{ .Name }}", "--vram", "128"], ["modifyvm", "{{ .Name }}", "--clipboard", "bidirectional"], ["modifyvm", "{{ .Name }}", "--draganddrop", "bidirectional"], ["modifyvm", "{{ .Name }}", "--usb", "on"], ["modifyvm", "{{ .Name }}", "--monitorcount", "1"]]
  vm_name          = "${var.vm_name}"
}

build {
  sources = ["source.hyperv-iso.hviso", "source.virtualbox-iso.vbiso"]

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{ .Vars }} sudo -S -E bash {{ .Path }}"
    only            = ["virtualbox-iso"]
    scripts         = ["./scripts/virtualbox.sh"]
  }

  provisioner "shell" {
    environment_vars  = ["SSH_USERNAME=${var.username}", "LOCALE=${var.locale}"]
    execute_command   = "echo '${var.password}' | {{ .Vars }} sudo -S -E bash {{ .Path }}"
    expect_disconnect = true
    scripts           = ["./scripts/update.sh", "./scripts/vagrant.sh", "./scripts/disable-daily-update.sh", "./scripts/ansible.sh"]
  }

  provisioner "shell" {
    environment_vars  = ["LOCALE=${var.locale}"]
    execute_command   = "echo '${var.password}' | {{ .Vars }} sudo -S -E bash {{ .Path }}"
    expect_disconnect = true
    script            = "./scripts/fix-locale.sh"
  }

  provisioner "shell" {
    execute_command = "echo '${var.password}' | {{ .Vars }} sudo -S -E bash {{ .Path }}"
    pause_before    = "10s"
    script          = "./scripts/cleanup.sh"
  }

  post-processor "vagrant" {
    keep_input_artifact = true
    output              = "./${var.box_out_dir}/<no value>-${var.output_name}.box"
  }
}
