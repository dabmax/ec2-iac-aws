variable "ton-network-address" {
  default = "172.16.0.0/24"
}

variable "ton-rz" {
  default = "us-east-1"
}

variable "trusted-address" {
  default = ["188.96.33.25/32"]
}

variable "port-https" {
  default = "443"
}

variable "port-ssh" {
  default = "22"
}

variable "instance-group" {
  default = "t2.micro"
}

variable "ssh-key" {
  default = "~/.ssh/id_rsa"
}

variable "install-nginx" {
  default = "nginx.sh"
}