# Multi-Server Deployment

**Status:** Not Started  
**Priority:** Low  
**Category:** Deployment

## Context

The current ReactiveView architecture assumes the SolidStart daemon runs on the same server as the Rails application. While this is simple and works well for many deployments, larger applications may benefit from:

1. Running SolidStart on dedicated rendering servers for better resource isolation
2. Scaling rendering servers independently from Rails application servers
3. Deploying to containerized environments where each service runs separately
4. Using serverless or edge rendering for SolidStart

This task addresses the architectural changes needed to support these deployment patterns while maintaining security and performance.

## Overview

Enable ReactiveView to support multi-server deployment where:

- Rails and SolidStart can run on separate servers/containers
- Communication happens over the network rather than localhost
- Multiple SolidStart instances can be load balanced
- Health checks ensure rendering service availability
- Authentication secures inter-service communication

**Single-Server Deployment (current):**
```
[Server]
├── Rails App
└── SolidStart Daemon (localhost:3001)
```

**Multi-Server Deployment (target):**
```
[Rails Servers]          [Rendering Servers]
├── Rails App 1  ───────► SolidStart 1
├── Rails App 2  ───────► SolidStart 2
└── Rails App 3  ───────► SolidStart 3 (load balanced)
```

## Acceptance Criteria

- [ ] SolidStart daemon can run on a different host than Rails
- [ ] Configuration supports remote daemon URL
- [ ] Multiple daemon instances can be load balanced
- [ ] Health check endpoint exists for daemon instances
- [ ] Inter-service authentication prevents unauthorized access
- [ ] Connection pooling optimizes network usage
- [ ] Timeouts and retries handle network failures gracefully
- [ ] Documentation covers common deployment patterns
- [ ] Docker Compose example for multi-container setup
- [ ] Kubernetes deployment example
- [ ] Performance is acceptable over network (latency considerations)

## Tasks

- [ ] Document supported deployment patterns (single-server, multi-server, containerized)
- [ ] Update configuration to support remote daemon URLs
- [ ] Implement connection pooling for remote daemon connections
- [ ] Add timeout and retry logic for network requests
- [ ] Create health check endpoint in SolidStart daemon (`/health`)
- [ ] Implement load balancing support (multiple daemon URLs)
- [ ] Add inter-service authentication (shared secret or JWT)
- [ ] Create Docker Compose example with separate services
- [ ] Create Kubernetes deployment manifests
- [ ] Add circuit breaker pattern for daemon failures
- [ ] Implement failover to degraded rendering (Rails-only fallback)
- [ ] Add metrics/logging for inter-service communication
- [ ] Test latency impact of network communication
- [ ] Document security considerations for multi-server setup

## Technical Notes

### Configuration for Remote Daemon

```ruby
# config/initializers/reactive_view.rb
ReactiveView.configure do |config|
  # Single remote daemon
  config.daemon_url = ENV["SOLIDSTART_URL"] || "http://localhost:3001"
  
  # Multiple daemons with load balancing
  config.daemon_urls = [
    "http://render-1.internal:3001",
    "http://render-2.internal:3001",
    "http://render-3.internal:3001"
  ]
  config.load_balancing = :round_robin  # or :random, :least_connections
  
  # Connection settings
  config.daemon_timeout = 30.seconds
  config.daemon_retries = 3
  config.connection_pool_size = 10
  
  # Authentication
  config.daemon_auth_token = ENV["REACTIVE_VIEW_AUTH_TOKEN"]
end
```

### Health Check Endpoint

```typescript
// In SolidStart daemon
export function GET() {
  return new Response(JSON.stringify({
    status: "healthy",
    version: "1.0.0",
    uptime: process.uptime()
  }), {
    headers: { "Content-Type": "application/json" }
  });
}
```

### Inter-Service Authentication

```ruby
# Rails side - add auth header
class Renderer
  def render(path, props)
    http.post(daemon_url, {
      headers: {
        "Authorization" => "Bearer #{config.daemon_auth_token}",
        "X-Request-ID" => request_id
      },
      body: { path: path, props: props }
    })
  end
end
```

```typescript
// SolidStart side - verify auth
function authMiddleware(request: Request) {
  const token = request.headers.get("Authorization")?.replace("Bearer ", "");
  if (token !== process.env.AUTH_TOKEN) {
    return new Response("Unauthorized", { status: 401 });
  }
}
```

### Docker Compose Example

```yaml
version: "3.8"
services:
  rails:
    build: .
    environment:
      - SOLIDSTART_URL=http://solidstart:3001
      - REACTIVE_VIEW_AUTH_TOKEN=secret
    depends_on:
      - solidstart
      - postgres
  
  solidstart:
    build:
      context: .
      dockerfile: Dockerfile.solidstart
    environment:
      - AUTH_TOKEN=secret
      - RAILS_URL=http://rails:3000
    ports:
      - "3001:3001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
  
  postgres:
    image: postgres:15
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: solidstart-renderer
spec:
  replicas: 3
  selector:
    matchLabels:
      app: solidstart-renderer
  template:
    spec:
      containers:
      - name: solidstart
        image: myapp/solidstart:latest
        ports:
        - containerPort: 3001
        env:
        - name: AUTH_TOKEN
          valueFrom:
            secretKeyRef:
              name: reactive-view-secrets
              key: auth-token
        readinessProbe:
          httpGet:
            path: /health
            port: 3001
        livenessProbe:
          httpGet:
            path: /health
            port: 3001
---
apiVersion: v1
kind: Service
metadata:
  name: solidstart-renderer
spec:
  selector:
    app: solidstart-renderer
  ports:
  - port: 3001
    targetPort: 3001
```

### Circuit Breaker Pattern

```ruby
class DaemonConnection
  include CircuitBreaker
  
  circuit_breaker :render,
    failure_threshold: 5,
    recovery_timeout: 30.seconds,
    fallback: -> { render_fallback_html }
  
  def render(path, props)
    # Normal rendering logic
  end
  
  def render_fallback_html
    # Return minimal HTML with client-side only rendering
    "<div id='root'>Loading...</div><script src='/client.js'></script>"
  end
end
```

### Security Considerations

1. **Network isolation:** Use private networks between services
2. **TLS:** Enable HTTPS for inter-service communication in production
3. **Token rotation:** Implement token rotation strategy
4. **Rate limiting:** Protect daemon from abuse
5. **Request validation:** Validate all incoming render requests

## Related Files

- `reactive_view/lib/reactive_view/daemon.rb`
- `reactive_view/lib/reactive_view/renderer.rb`
- `reactive_view/lib/reactive_view/configuration.rb`
- `reactive_view/template/src/routes/api/render.ts`
