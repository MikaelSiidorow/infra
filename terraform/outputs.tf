output "ipv4_address" {
  description = "Public IPv4 address"
  value       = hcloud_server.coolify_server.ipv4_address
}

output "server_id" {
  value = hcloud_server.coolify_server.id
}

output "ssh_host" {
  value = "root@${hcloud_server.coolify_server.ipv4_address}"
}
