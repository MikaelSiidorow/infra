# K3s server outputs
output "k3s_ipv4_address" {
  description = "K3s server public IPv4 address"
  value       = hcloud_server.k3s_server.ipv4_address
}

output "k3s_server_id" {
  value = hcloud_server.k3s_server.id
}

output "k3s_ssh_host" {
  value = "root@${hcloud_server.k3s_server.ipv4_address}"
}
