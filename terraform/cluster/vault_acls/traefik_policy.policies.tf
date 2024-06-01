vault policy write traefik-policy - <<EOF
path "pki/issue/traefik" {
  capabilities = ["create", "update"]
}
EOF

vault write auth/approle/role/traefik-role \
    token_policies="traefik-policy" \
    token_ttl=24h \
    token_max_ttl=48h
