terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.3.0"
    }
  }
}

provider "openstack" {
  # Umgebungsvariablen wie OS_AUTH_URL, OS_USERNAME, OS_PASSWORD, etc. werden automatisch ausgelesen.
  # Dies ist der einfachste Weg, sich bei MicroStack zu authentifizieren.
  insecure    = true
}
