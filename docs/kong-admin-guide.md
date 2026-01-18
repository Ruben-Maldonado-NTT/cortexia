# Kong Admin API Guide

## Overview
Kong Gateway provides a powerful Admin API on port `8001` for managing services, routes, plugins, and more.

Since Konga UI has compatibility issues with Postgres 16, we recommend using one of these alternatives:

## Option 1: Kong Admin API (REST)

### List all services
```bash
curl http://localhost:8001/services
```

### List all routes
```bash
curl http://localhost:8001/routes
```

### Create a new service
```bash
curl -X POST http://localhost:8001/services \
  -d "name=my-service" \
  -d "url=http://my-backend:8080"
```

### Create a route for the service
```bash
curl -X POST http://localhost:8001/services/my-service/routes \
  -d "name=my-route" \
  -d "paths[]=/my-api"
```

### Add rate limiting plugin
```bash
curl -X POST http://localhost:8001/services/my-service/plugins \
  -d "name=rate-limiting" \
  -d "config.minute=100"
```

### Delete a route
```bash
curl -X DELETE http://localhost:8001/routes/{route-id}
```

## Option 2: Use Insomnia or Postman

### Insomnia (Recommended)
1. Download: https://insomnia.rest/
2. Import OpenAPI spec from Kong: `http://localhost:8001/`
3. Visual interface for all API operations

### Postman
1. Download: https://www.postman.com/
2. Create new request to `http://localhost:8001`
3. Use Collections for organizing requests

## Option 3: kong CLI (inside container)

```bash
# List services
docker exec cortexia-kong kong-health
docker exec cortexia-kong kong config db_export

# Reload Kong configuration
docker exec cortexia-kong kong reload
```

## Common Tasks

### View current configuration
```bash
curl http://localhost:8001/ | jq
```

### Check Kong health
```bash
curl http://localhost:8001/status
```

### Verify a service is working
```bash
# Via Kong Proxy
curl http://localhost:8000/api/agents/health
```

## API Documentation
- Full API docs: https://docs.konghq.com/gateway/latest/admin-api/
- Interactive API: `http://localhost:8001/`

## Future: Konga Alternative
Once Konga is updated to support Postgres 16, we can re-enable it. 
Alternatively, consider:
- **kong-dashboard**: Lightweight alternative (unmaintained)
- **Konga Community Fork**: Watch for Postgres 16 support
- **Kong Enterprise**: Official UI (paid)

---

**Note**: Our platform already has Kong routes configured via `scripts/configure-kong.sh`.
Run that script to recreate routes if needed.
