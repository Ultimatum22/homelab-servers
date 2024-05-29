namespace "*" {
  policy       = "write"
  capabilities = ["alloc-node-exec"]

  variables {
    path "*" {
      capabilities = ["write", "read", "destroy"]
    }
  }
}

agent {
  policy = "write"
}

operator {
  policy = "write"
}

quota {
  policy = "write"
}

node {
  policy = "write"
}

host_volume "*" {
  policy = "write"
}
