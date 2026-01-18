package mcp.rbac

import rego.v1

# Default deny
default allow = false

# User roles (mocked or from headers)
user_roles := {
    "admin": ["read_tools", "call_tools", "read_resources"],
    "viewer": ["read_tools", "read_resources"]
}

# Allow if user is admin
allow if {
    input.user == "admin"
}

# Allow reading tools if user has the permission
allow if {
    input.action == "read_tools"
    permission_allowed(input.role, "read_tools")
}

# Allow calling specific tools (could be more granular)
allow if {
    input.action == "call_tools"
    permission_allowed(input.role, "call_tools")
}

permission_allowed(role, permission) if {
    some r
    r == role
    some p
    p == user_roles[r][_]
    p == permission
}
