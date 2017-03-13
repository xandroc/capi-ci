variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "resource_group" {}
variable "name" {}
variable "admin_user" {}
variable "admin_password" {}
variable "trusted_ip" {}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

resource "azurerm_resource_group" "test" {
   name = "${var.resource_group}"
   location = "West US"
}
resource "azurerm_sql_server" "test" {
    name = "${var.name}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    location = "West US"
    version = "12.0"
    administrator_login = "${var.admin_user}"
    administrator_login_password = "${var.admin_password}"

    tags {
        environment = "CAPI-CI"
    }
}

resource "azurerm_sql_database" "test" {
    name = "${var.name}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    location = "West US"
    server_name = "${azurerm_sql_server.test.name}"

    tags {
        environment = "CAPI-CI"
    }
}

resource "azurerm_sql_firewall_rule" "test" {
    name = "${var.name}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    server_name = "${azurerm_sql_server.test.name}"
    start_ip_address = "${var.trusted_ip}"
    end_ip_address = "${var.trusted_ip}"
}

output "db_fqdn" {
    value = "${azurerm_sql_database.test.name}.database.windows.net"
}
output "db_user" {
    sensitive = true
    value = "${var.admin_user}"
}
output "db_password" {
    sensitive = true
    value = "${var.admin_password}"
}
