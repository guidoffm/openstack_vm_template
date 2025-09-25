
variable "image_name" {
  description = "Der Name des OpenStack-Images."
  type        = string  
}

variable "flavor_name" {
  description = "Der Name des OpenStack-Flavors."
  type        = string
}

variable "instance_name" {
  description = "Der Name für die neue Instanz."
  type        = string
}

variable "network_name" { 
  description = "Der Name des OpenStack-Netzwerks."
  type        = string 
}

variable "external_network_name" {
  description = "Der Name des externen Netzwerks für die Floating IP."
  type        = string
  
}