# Ruby: Configuration

Source: `ReactiveView::Configuration`.

## Attributes

- `daemon_host` (String, default `"localhost"`)
- `daemon_port` (Integer, default `3001`, must be positive)
- `daemon_timeout` (Integer seconds, default `30`)
- `auto_start_daemon` (Boolean, default `true`)
- `external_daemon` (Boolean, default `false`)
- `daemon_max_restarts` (Integer, default `5`)
- `daemon_restart_window` (Integer seconds, default `60`)
- `daemon_health_check_interval` (Integer seconds, default `5`)
- `daemon_health_check_ttl` (Integer seconds, default `2`)
- `pages_path` (String, default `"app/pages"`)
- `working_directory` (String, default `".reactive_view"`)
- `validate_responses` (Boolean, default `true`)
- `rails_base_url` (String or nil, default `nil`)

## Helpers

- `should_auto_start_daemon?`
- `should_validate_responses?`
- `daemon_url`
- `pages_absolute_path`
- `working_directory_absolute_path`

## Configure block

```ruby
ReactiveView.configure do |config|
  config.daemon_port = 3001
end
```
