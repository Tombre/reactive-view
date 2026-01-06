# Production Asset Pipeline Integration

**Status:** Not Started  
**Priority:** High  
**Category:** Deployment

## Context

ReactiveView uses SolidStart (via Vinxi) for server-side rendering and client-side interactivity. During development, Vite serves assets directly with hot module replacement. However, for production deployment, the build output needs to integrate with Rails' asset pipeline or be deployed to a CDN.

Currently, there is no documented or automated process for:

1. Building production-ready assets from SolidStart
2. Integrating those assets with Rails' asset fingerprinting
3. Serving assets from a CDN in production
4. Managing cache invalidation across deployments

This gap makes production deployment of ReactiveView applications manual and error-prone.

## Overview

Implement a production asset pipeline that:

- Compiles SolidStart/Vite assets for production use
- Integrates with Rails' asset pipeline or provides CDN deployment support
- Handles asset fingerprinting for cache busting
- Provides clear configuration for different deployment environments
- Offers rake tasks for build automation in CI/CD pipelines

**Development Flow (current):**
```
Vite Dev Server → HMR → Browser
```

**Production Flow (to implement):**
```
Vite Build → Fingerprinted Assets → Rails Public / CDN → Browser
```

## Acceptance Criteria

- [ ] Production build generates optimized, minified JavaScript and CSS
- [ ] Assets are fingerprinted with content hashes for cache busting
- [ ] Rake task exists for building production assets (`rake reactive_view:build`)
- [ ] Build output integrates with Rails public directory or asset pipeline
- [ ] CDN support with configurable asset host
- [ ] Source maps are optionally generated for production debugging
- [ ] Environment-specific configuration (development, staging, production)
- [ ] Build process is documented for CI/CD integration
- [ ] Example application demonstrates production build
- [ ] Asset manifest is generated for Rails to reference correct fingerprinted files

## Tasks

- [ ] Document the production build process for SolidStart/Vinxi
- [ ] Create rake task `reactive_view:build` for production compilation
- [ ] Configure Vite/Vinxi for production builds with proper output paths
- [ ] Implement asset fingerprinting that works with Rails conventions
- [ ] Add asset manifest generation for mapping logical names to fingerprinted files
- [ ] Update `Renderer` to use fingerprinted asset paths in production
- [ ] Add CDN support with `asset_host` configuration option
- [ ] Create environment-specific build configurations
- [ ] Add `reactive_view:clean` task for removing build artifacts
- [ ] Update Procfile for production (no dev server, use prebuilt assets)
- [ ] Add build step to example application's deployment process
- [ ] Document CI/CD integration patterns
- [ ] Test build output in production-like environment

## Technical Notes

### Build Output Structure

```
public/
  reactive_view/
    assets/
      entry-client-[hash].js
      entry-client-[hash].css
      chunks/
        [name]-[hash].js
    manifest.json
```

### Manifest Format

```json
{
  "entry-client.js": "entry-client-a1b2c3d4.js",
  "entry-client.css": "entry-client-e5f6g7h8.css"
}
```

### Configuration Options

```ruby
ReactiveView.configure do |config|
  config.asset_host = ENV["CDN_URL"]
  config.build_output_path = Rails.root.join("public", "reactive_view")
  config.source_maps = Rails.env.staging?
end
```

### Rake Task Integration

```bash
# Build for production
bundle exec rake reactive_view:build

# Clean build artifacts
bundle exec rake reactive_view:clean

# Build and precompile together
bundle exec rake assets:precompile reactive_view:build
```

## Related Files

- `reactive_view/lib/tasks/reactive_view.rake`
- `reactive_view/lib/reactive_view/configuration.rb`
- `reactive_view/lib/reactive_view/renderer.rb`
- `reactive_view/template/app.config.ts`
- `reactive_view/template/package.json`
