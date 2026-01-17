# CortexIA Audit Log Design

## Structure
All security-relevant events must be logged in JSON format to standard output (container logs) and optionally to a structured file for collection.

### JSON Schema
```json
{
  "timestamp": "2024-01-20T10:00:00Z",
  "event_id": "uuid-v4",
  "source_service": "cortexia-gateway",
  "event_type": "AUTHZ_DECISION", 
  "actor": {
    "user_id": "bob",
    "ip": "192.168.1.10"
  },
  "resource": {
    "id": "agent-123",
    "type": "agent"
  },
  "action": "execute",
  "decision": "DENY",
  "policy_id": "cortexia.authz",
  "metadata": {
    "reason": "opa_policy_denial"
  }
}
```

## Storage Strategy (Local)
1. **Container Logs:** Use default Docker logging driver (json-file). Promtail/Fluentd can scrape these.
2. **Persistence:** Mount a volume at `/var/log/cortexia/audit.log` for services that support file output.
   - Local Path: `foundation/security/audit/logs/`

## Future (K8s)
- Sidecar (Fluentbit) sending logs to OpenSearch.
