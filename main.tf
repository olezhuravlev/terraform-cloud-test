# Base Terraform definition.
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

# Define provider.
provider "yandex" {
  cloud_id = var.yandex-cloud-id
  zone     = var.yandex-cloud-zone
}

# Create folder.
resource "yandex_resourcemanager_folder" "netology-folder" {
  cloud_id    = var.yandex-cloud-id
  name        = "netology-folder-${terraform.workspace}"
  description = "Netology test folder"
}

# Create service account.
resource "yandex_iam_service_account" "terraform-netology-sa" {
  folder_id   = yandex_resourcemanager_folder.netology-folder.id
  name        = "terraform-netology-sa-${terraform.workspace}"
  description = "Service account to be used by Terraform"
}

# Grant permission "storage.editor" on folder "yandex-folder-id" for service account.
resource "yandex_resourcemanager_folder_iam_member" "terraform-netology-storage-editor" {
  folder_id = yandex_resourcemanager_folder.netology-folder.id
  role      = "admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform-netology-sa.id}"
}

# Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "terraform-sa-static-key" {
  service_account_id = yandex_iam_service_account.terraform-netology-sa.id
  description        = "Static access key for service account"
}

# Use keys to create bucket
resource "yandex_storage_bucket" "netology-bucket" {
  access_key = yandex_iam_service_account_static_access_key.terraform-sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.terraform-sa-static-key.secret_key
  bucket     = "netology-bucket-${terraform.workspace}"
  grant {
    id          = yandex_iam_service_account.terraform-netology-sa.id
    type        = "CanonicalUser"
    permissions = ["READ", "WRITE"]
  }
}

# Network.
resource "yandex_vpc_network" "netology-network" {
  folder_id   = yandex_resourcemanager_folder.netology-folder.id
  name        = "netology-network"
  description = "Netology network"
}

# Subnets of the network.
resource "yandex_vpc_subnet" "netology-subnet" {
  folder_id      = yandex_resourcemanager_folder.netology-folder.id
  name           = "netology-subnet-0"
  description    = "Netology subnet 0"
  v4_cidr_blocks = ["10.100.0.0/24"]
  zone           = var.yandex-cloud-zone
  network_id     = yandex_vpc_network.netology-network.id
}
