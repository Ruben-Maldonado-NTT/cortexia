package cortexia.authz

default allow = false

# Allow if user is admin
allow if {
    input.user == "admin"
}

# Allow simple read access to everyone logic (example)
allow if {
    input.action == "read"
}
