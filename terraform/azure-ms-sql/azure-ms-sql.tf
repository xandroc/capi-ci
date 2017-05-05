variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "resource_group" {}
variable "db_name" {}
variable "db_admin_user" {}
variable "db_admin_password" {}

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
    name = "${var.db_name}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    location = "West US"
    version = "12.0"
    administrator_login = "${var.db_admin_user}"
    administrator_login_password = "${var.db_admin_password}"

    tags {
        environment = "CAPI-CI"
    }
}

resource "azurerm_sql_database" "test" {
    name = "${var.db_name}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    location = "West US"
    server_name = "${azurerm_sql_server.test.name}"

    tags {
        environment = "CAPI-CI"
    }
}

resource "azurerm_sql_firewall_rule" "test" {
    name = "${var.db_name}"
    resource_group_name = "${azurerm_resource_group.test.name}"
    server_name = "${azurerm_sql_server.test.name}"
    start_ip_address = "0.0.0.0"
    end_ip_address = "255.255.255.255"
}

output "db_name" {
    value = "${var.db_name}"
}

output "db_address" {
    sensitive = true
    value = "${azurerm_sql_database.test.name}.database.windows.net"
}
output "db_admin_user" {
    sensitive = true
    value = "${var.db_admin_user}"
}
output "db_admin_password" {
    sensitive = true
    value = "${var.db_admin_password}"
}
