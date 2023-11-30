terraform {
  required_providers {
    vultr = {
      source  = "vultr/vultr"
    }
  }
}

provider "vultr" {
  api_key = "SILLVA2A6J3F6S4SKKSNXAPFNZFMWNFF2MRA"
}

# Déclarez le groupe de pare-feu
resource "vultr_firewall_group" "my_firewallgroup" {
  description = "base firewall"
}

# Déclarez la règle du pare-feu
resource "vultr_firewall_rule" "my_firewallrule" {
  firewall_group_id = vultr_firewall_group.my_firewallgroup.id
  protocol          = "tcp"
  ip_type           = "v4"
  subnet            = "0.0.0.0"
  subnet_size       = 0
  port              = "80"
  notes             = "my firewall rule"
}

# Déclarez le script de démarrage pour l'installation de WordPress
resource "vultr_startup_script" "wordpress_script" {
  name   = "install_wordpress"
  script = filebase64("wordpress_script.sh")
}

# Déclarez l'instance Vultr en utilisant les ressources précédemment définies
resource "vultr_instance" "example" {
  label             = "julienfvm"
  plan              = "vc2-1c-1gb"
  region            = "fra"
  os_id             = 1743
  script_id         = vultr_startup_script.wordpress_script.id
  firewall_group_id = vultr_firewall_group.my_firewallgroup.id
}

# Déclarez la ressource Docker MySQL
resource "docker_container" "mysql" {
  name  = "mysql_container"
  image = "mysql:latest"
  ports {
    internal = 3306
    external = 3306
  }
  env = [
    "MYSQL_ROOT_PASSWORD=my-secret-pw",
    "MYSQL_DATABASE=wordpress",
    "MYSQL_USER=wordpress",
    "MYSQL_PASSWORD=wordpresspassword",
  ]
  restart = "always"
}

# Déclarez la ressource Docker WordPress
resource "docker_container" "wordpress" {
  name  = "wordpress_container"
  image = "wordpress:latest"
  ports {
    internal = 80
    external = 8080
  }
  links = [docker_container.mysql.name]
  env = [
    "WORDPRESS_DB_HOST=mysql_container",
    "WORDPRESS_DB_USER=wordpress",
    "WORDPRESS_DB_PASSWORD=wordpresspassword",
    "WORDPRESS_DB_NAME=wordpress",
  ]
  restart = "always"
}

output "instance_ip" {
  value = vultr_instance.example.main_ip
}
