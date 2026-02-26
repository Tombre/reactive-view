# Configuration

ReactiveView has Ruby runtime config and frontend build config.

## Ruby config (`config/initializers/reactive_view.rb`)

```ruby
ReactiveView.configure do |config|
  config.daemon_host = "localhost"
  config.daemon_port = 3001
  config.daemon_timeout = 30

  config.auto_start_daemon = Rails.env.development?
  config.external_daemon = Rails.env.production?

  config.daemon_max_restarts = 5
  config.daemon_restart_window = 60
  config.daemon_health_check_interval = 5
  config.daemon_health_check_ttl = 2

  config.pages_path = "app/pages"
  config.working_directory = ".reactive_view"
  config.validate_responses = true
  config.rails_base_url = nil
end
```

## Frontend config (`reactive_view.config.ts`)

```ts
import { defineConfig } from "@reactive-view/core/config";

export default defineConfig({
  vitePlugins: [],
  vite: {},
  reactiveView: { debug: false },
});
```

## Common plugin setup

Tailwind v4:

```ts
import { defineConfig } from "@reactive-view/core/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  vitePlugins: [tailwindcss()],
});
```

See [Ruby Configuration Reference](../../reference/ruby/configuration.md) and [Config API Reference](../../reference/typescript/config-api.md).
