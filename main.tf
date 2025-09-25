#########################################
# Netzwerk: Privat
#########################################
resource "openstack_networking_network_v2" "private_net" {
  name           = "private-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "private_subnet" {
  name            = "private-subnet"
  network_id      = openstack_networking_network_v2.private_net.id
  cidr            = "192.168.100.0/24"
  ip_version      = 4
  gateway_ip      = "192.168.100.1"
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
}


data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

#########################################
# Router zu External Network
#########################################
resource "openstack_networking_router_v2" "router" {
  name                = "router-to-external"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.private_subnet.id
}

#########################################
# Security Group für SSH
#########################################
resource "openstack_networking_secgroup_v2" "ssh" {
  name        = "ssh-access"
  description = "Allow SSH from everywhere"
}

resource "openstack_networking_secgroup_rule_v2" "ssh_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp_in" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.ssh.id
}


resource "openstack_networking_port_v2" "vm_port" {
  name       = "${var.instance_name}-port"
  network_id = openstack_networking_network_v2.private_net.id
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.private_subnet.id
  }
  security_group_ids = [openstack_networking_secgroup_v2.ssh.id]
}



#########################################
# Instanz mit Cloud-Init
#########################################
resource "openstack_compute_instance_v2" "vm" {
  name        = var.instance_name
  image_name  = var.image_name
  flavor_name = var.flavor_name

  network {
    uuid = openstack_networking_network_v2.private_net.id
    port = openstack_networking_port_v2.vm_port.id
  }

  security_groups = [openstack_networking_secgroup_v2.ssh.name]

  user_data = <<-EOF
      #cloud-config
      hostname: cloudconfig-vm
      timezone: Europe/Berlin
      ssh_pwauth: true

      users:
        - name: guido
          groups: sudo
          shell: /bin/bash
          sudo: ["ALL=(ALL) NOPASSWD:ALL"]
          ssh_authorized_keys:
            - ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmEcAQjJBDBZ3AYNPF926esUmn6UgALv6HpI+Ods3qB5S4O0rDz78v8f02gUwzc6j9Gb6of+XXHdH1pXD7XFBFiMMBRpFQUFFIyjFQpMD+C8+ceqYh6MkqBDOoYz9peWWkVkguaRgku3ndGw2ClbmxSVt8hmwl8JJexb9j1F6A17o6e5w9MmPdN5Cs6fLOWeYsRFFWn40FLvYdR9xMp5K+IX4lPvq8UXhtfexHCLIqmoizseugc1M/rieABcxdkQQIciVXgGFJrOXDNQhJBTDkCsDc3eg5asU6Hjv3iCHgsjH3sKaDPZ/ren350/j8TwDpbODB8ffFjZuVXBSN054jQ== guido@laptop
            - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdvkju829nUBJ9hCpSTinSg4NbVBTjP78HHPxefYAWb guido@ub2

    #   chpasswd:
    #     list: |
    #       guido:MeinSicheresPasswort
    #     expire: False
      package_update: true
      package_upgrade: true 
      packages:
        - nginx
        - git
        - curl
      power_state:
        mode: reboot
        message: "Rebooting after upgrade"
        timeout: 60
        condition: True
      write_files:
        - path: /etc/motd
          content: |
            Welcome to your Terraform Cloud-Init VM!
          owner: root:root
          permissions: '0644'

    #   runcmd:
    #     - systemctl enable nginx
    #     - systemctl start nginx
    #     - mkdir -p /opt/myapp
    #     - echo "Hello World" > /opt/myapp/hello.txt

      final_message: "Cloud-Init setup completed!"
    EOF
}

#########################################
# Floating IP
#########################################
resource "openstack_networking_floatingip_v2" "fip" {
  pool = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.fip.address
  port_id     = openstack_networking_port_v2.vm_port.id

  depends_on = [
    openstack_networking_router_interface_v2.router_interface
  ]
}

#########################################
# Outputs
#########################################
output "internal_ip" {
  value = openstack_compute_instance_v2.vm.network[0].fixed_ip_v4
}

output "floating_ip" {
  value = openstack_networking_floatingip_v2.fip.address
}
