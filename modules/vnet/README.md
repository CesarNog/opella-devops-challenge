# Azure VNET Module

Reusable Terraform module for provisioning an Azure Virtual Network with subnets, Network Security Groups, and optional DDoS protection.

## Features

- Configurable address space and DNS servers
- Dynamic subnet creation with per-subnet NSG rules
- Service endpoint support per subnet
- Subnet delegation support (e.g., for App Service, Container Instances)
- Optional DDoS Protection Plan
- Consistent tagging across all resources

## Documentation

This README is auto-generated using [terraform-docs](https://terraform-docs.io/).
Run `make docs` or `terraform-docs markdown table modules/vnet --output-file README.md --output-mode inject` to regenerate.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
