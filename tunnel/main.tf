resource "random_id" "tunnel_secret" {
  byte_length = 35
}

variable tunnelName {
  description = "Tunnel Name"
  type        = string
}

variable hostPath {
  description = "Host Path"
  type        = string
}

variable zone {
  description = "Cloudflare Zone"
  type        = string
}

variable servicePath {
  description = "service Path"
  type        = string
}

variable appPort {
  description = "appPort"
  type        = string
}  

resource "cloudflare_tunnel" "this" {
  account_id = var.accountID
  name       = var.tunnelName
  secret     = random_id.tunnel_secret.b64_std
  config_src = "cloudflare"
}

resource "cloudflare_tunnel_config" "config" {
  account_id = var.accountID
  tunnel_id  = cloudflare_tunnel.this.id

  config {
    warp_routing {
      enabled = true
    }
    ingress_rule {
      service = "http://${var.servicePath}:${var.appPort}"
    }
  }
}

data "cloudflare_zones" "zones" {
  filter {
    name        = var.zone
    lookup_type = "exact"
    status      = "active"
  }
}

locals {
  cloudflare_zone_id = lookup(element(data.cloudflare_zones.zones.zones, 0), "id")
}

resource "cloudflare_record" "app_path" {
  zone_id = local.cloudflare_zone_id
  name    = "${var.hostPath}.${var.zone}"
  value   = "${cloudflare_tunnel.this.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

output "tunnel_token" {
  value = cloudflare_tunnel.this.tunnel_token
  sensitive = true
}

output "tunnel_id" {
  value = cloudflare_tunnel.this.id
}