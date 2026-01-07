# Daemon Startup Modes

**Status:** Not Started  
**Priority:** Low  
**Category:** Developer Experience

## Context

ReactiveView currently supports two ways to run the SolidStart daemon:

1. **Procfile-based** (current default): Run `bin/dev` which uses foreman to start both Rails and SolidStart as separate processes
2. **Rails-managed**: Rails can spawn and manage the daemon via the `Daemon` class when `auto_start_daemon` is enabled

Different developers have different preferences and deployment scenarios:

- **Everyday users** want simplicity: `bin/rails server` should just work
- **Advanced users** may want to run SolidStart separately for debugging, or on a different machine
- **Production deployments** may run the daemon on dedicated servers

## Overview

Make daemon startup mode explicitly configurable with sensible defaults, so:

- New users get a seamless single-command experience
- Advanced users can easily opt into manual daemon management
- The configuration is clear and well-documented

## Acceptance Criteria

- [ ] Clear configuration option for daemon startup mode
- [ ] Default mode works out of the box for new projects
- [ ] Advanced mode allows full control over daemon lifecycle
- [ ] `bin/dev` Procfile approach remains supported
- [ ] Documentation explains tradeoffs of each mode
- [ ] Generator creates appropriate files based on chosen mode

## Tasks

- [ ] Add `daemon_mode` configuration option with values: `:auto`, `:manual`, `:procfile`
- [ ] Update install generator to ask about preferred mode
- [ ] Generate appropriate startup files based on mode:
  - `:auto` - No Procfile, Rails manages daemon
  - `:manual` - Generate Procfile but don't auto-start
  - `:procfile` - Current behavior (default for now)
- [ ] Update `bin/dev` template to support different modes
- [ ] Add `bin/rails reactive_view:daemon:start` and `:stop` commands for manual mode
- [ ] Improve daemon output visibility when Rails-managed (optional log tailing)
- [ ] Document each mode in README with pros/cons
- [ ] Add configuration example in initializer template

## Technical Notes

### Proposed Configuration

```ruby
# config/initializers/reactive_view.rb
ReactiveView.configure do |config|
  # Daemon startup mode:
  # - :procfile - Use Procfile.dev with foreman (default, recommended)
  # - :auto - Rails automatically starts/stops daemon
  # - :manual - User manages daemon separately
  config.daemon_mode = :procfile
  
  # For :manual mode, specify where the daemon is running
  config.daemon_host = 'localhost'
  config.daemon_port = 3001
end
```

### Mode Behaviors

| Mode | `bin/rails server` | `bin/dev` | Daemon Output |
|------|-------------------|-----------|---------------|
| `:procfile` | Rails only (no HMR) | Rails + SolidStart | Visible in terminal |
| `:auto` | Rails + auto-daemon | N/A | In `daemon.log` |
| `:manual` | Rails only | Rails only | Wherever user runs it |

### Considerations

- `:procfile` should remain the default as it provides the best visibility during development
- `:auto` mode needs robust process cleanup on Rails exit
- `:manual` mode is already supported via `external_daemon: true` config
- Consider adding a daemon health indicator to Rails console/logs

## Related Files

- `reactive_view/lib/reactive_view/configuration.rb`
- `reactive_view/lib/reactive_view/daemon.rb`
- `reactive_view/lib/reactive_view/engine.rb`
- `reactive_view/lib/generators/reactive_view/install_generator.rb`
- `reactive_view/lib/generators/reactive_view/templates/Procfile.dev`
