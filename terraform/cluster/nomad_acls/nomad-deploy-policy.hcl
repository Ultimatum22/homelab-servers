namespace "*" {
  policy       = "read"
  capabilities = ["submit-job", "dispatch-job", "read-logs"]
}

node {
  policy = "read"
}

agent {
  policy = "read"
}

host_volume "docker-sock-ro" {
  policy = "read" # read = read-only, write = read/write, deny to deny
}
