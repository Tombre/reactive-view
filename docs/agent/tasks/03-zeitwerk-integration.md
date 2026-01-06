# Improved Zeitwerk Integration

**Status:** Not Started  
**Priority:** High  
**Category:** Developer Experience

## Context

Rails uses Zeitwerk for autoloading Ruby files. Zeitwerk expects conventional file naming that maps directly to constant names (e.g., `user.rb` → `User`, `users/show_loader.rb` → `Users::ShowLoader`).

ReactiveView uses SolidStart-style file naming with bracket notation for dynamic segments (e.g., `[id].loader.rb`, `[...slug].loader.rb`). This naming convention doesn't match Zeitwerk's expectations, so the current implementation manually requires loader files via `LoaderRegistry.load_all`.

This causes several issues:

1. No automatic reloading when loader files change in development
2. Files must be manually required at boot time
3. Inconsistent with Rails conventions developers expect
4. Potential issues with eager loading in production

## Overview

Improve the loader file loading mechanism to work better with Rails' autoloading infrastructure. The solution should:

- Support the `[param].loader.rb` naming convention (or a compatible alternative)
- Enable automatic reloading in development
- Work correctly with eager loading in production
- Maintain the visual association between pages and loaders

**Current State:**
```
app/pages/users/[id].loader.rb  →  Manually required, no reload
```

**Target State:**
```
app/pages/users/[id].loader.rb  →  Autoloaded, reloads on change
```

## Acceptance Criteria

- [ ] Loader files are automatically loaded without manual `require` calls
- [ ] Changes to loader files trigger automatic reload in development
- [ ] Eager loading works correctly in production
- [ ] The file naming convention is documented and consistent
- [ ] Class naming convention is clear and predictable
- [ ] No performance regression from the current implementation
- [ ] Works with `rails console` and other Rails tooling
- [ ] Error messages are helpful when loader classes can't be found

## Tasks

- [ ] Research Zeitwerk inflector API for custom file-to-constant mapping
- [ ] Prototype inflector-based approach for bracket notation
- [ ] Prototype alternative: conventional naming with mapping file
- [ ] Prototype alternative: symlinks to conventionally-named files
- [ ] Evaluate each approach for DX, performance, and maintenance
- [ ] Implement chosen approach
- [ ] Update `LoaderRegistry` to work with new loading mechanism
- [ ] Ensure hot reloading works correctly in development
- [ ] Test eager loading in production mode
- [ ] Update documentation with file naming conventions
- [ ] Add tests for loader loading and reloading

## Technical Options

### Option 1: Custom Zeitwerk Inflector

Create a custom inflector that handles bracket notation:

```ruby
# lib/reactive_view/zeitwerk_inflector.rb
class ReactiveViewInflector < Zeitwerk::Inflector
  def camelize(basename, abspath)
    if basename.match?(/\[.*\]/)
      # [id] → Id, [...slug] → Slug
      basename.gsub(/\[\.\.\.?(.*?)\]/, '\1').camelize
    else
      super
    end
  end
end
```

**Pros:** Maintains design doc naming convention  
**Cons:** Complex, may have edge cases

### Option 2: Conventional Naming with Mapping

Use standard Rails naming, maintain a mapping for routing:

```
app/pages/users/id.loader.rb      →  Users::IdLoader
app/pages/users/id.tsx            →  Route: /users/:id
```

**Pros:** Works with Zeitwerk out of the box  
**Cons:** Loses visual association between TSX and loader files

### Option 3: Separate Loaders Directory

Move loaders to a conventional location:

```
app/loaders/pages/users/id_loader.rb  →  Pages::Users::IdLoader
app/pages/users/[id].tsx              →  Route: /users/:id
```

**Pros:** Clear separation, standard Rails conventions  
**Cons:** Loaders are far from their pages

### Option 4: Hybrid with File Watcher

Keep current naming, add file watcher for development reloading:

```ruby
# In development, watch for changes and re-require
Listen.to(pages_path, only: /\.loader\.rb$/) do |modified, added, removed|
  (modified + added).each { |f| load f }
end
```

**Pros:** Maintains design doc naming, works today  
**Cons:** Doesn't integrate with Zeitwerk, manual loading

## Recommendation

Start with **Option 4 (Hybrid)** as a quick win for development reloading, then pursue **Option 1 (Custom Inflector)** for full Zeitwerk integration.

## Related Files

- `reactive_view/lib/reactive_view/loader_registry.rb`
- `reactive_view/lib/reactive_view/engine.rb`
- `reactive_view/lib/reactive_view/file_sync.rb`
