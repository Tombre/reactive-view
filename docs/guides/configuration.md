# Configuration Guide

This guide covers how to configure ReactiveView's frontend build system and asset handling.

## Frontend Configuration

ReactiveView allows you to customize the Vite build configuration through a `reactive_view.config.ts` file at your Rails root.

### Creating a Configuration File

When you run `rails reactive_view:install`, a minimal configuration file is created:

```typescript
// reactive_view.config.ts
import { defineConfig } from "@reactive-view/core/config";

export default defineConfig({
  // vitePlugins: [],
  // vite: {},
  // reactiveView: { debug: false },
});
```

### Adding Tailwind CSS

To add Tailwind CSS (or any other Vite plugin):

```typescript
import { defineConfig } from "@reactive-view/core/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  vitePlugins: [tailwindcss()],
});
```

Don't forget to install the Tailwind dependencies:

```bash
npm install -D tailwindcss @tailwindcss/vite
```

### Configuration Options

The `defineConfig` function accepts the following options:

#### `vitePlugins`

An array of Vite plugins to include in the build:

```typescript
import { defineConfig } from "@reactive-view/core/config";
import tailwindcss from "@tailwindcss/vite";
import autoprefixer from "autoprefixer";

export default defineConfig({
  vitePlugins: [
    tailwindcss(),
    // Add more plugins as needed
  ],
});
```

#### `vite`

Additional Vite configuration to merge with the defaults:

```typescript
export default defineConfig({
  vite: {
    build: {
      sourcemap: true,
    },
    define: {
      __APP_VERSION__: JSON.stringify("1.0.0"),
    },
  },
});
```

#### `reactiveView`

ReactiveView plugin options:

```typescript
export default defineConfig({
  reactiveView: {
    debug: true, // Enable verbose logging
  },
});
```

## Asset Management

ReactiveView automatically syncs all files from `app/pages/` to `.reactive_view/src/pages/`, except for `.loader.rb` files.

### Supported Asset Types

Any file type that Vite can handle will work:

- **Styles**: `.css`, `.scss`, `.sass`, `.less`, `.module.css`
- **Images**: `.png`, `.jpg`, `.svg`, `.webp`, `.gif`
- **Fonts**: `.woff`, `.woff2`, `.ttf`, `.otf`
- **Data**: `.json`, `.yaml`
- **Components**: `.tsx`, `.ts`, `.jsx`, `.js`

### Using CSS Files

Create CSS files anywhere in `app/pages/`:

```css
/* app/pages/styles/custom.css */
.my-component {
  background: blue;
}
```

Import them in your TSX files:

```tsx
// app/pages/my-page.tsx
import "./styles/custom.css";

export default function MyPage() {
  return <div class="my-component">Styled!</div>;
}
```

### Using CSS Modules

CSS Modules work out of the box:

```css
/* app/pages/styles/button.module.css */
.primary {
  background: blue;
  color: white;
}
```

```tsx
// app/pages/components/Button.tsx
import styles from "./styles/button.module.css";

export default function Button() {
  return <button class={styles.primary}>Click me</button>;
}
```

### Using SCSS/SASS

Install the SCSS preprocessor:

```bash
npm install -D sass
```

Create SCSS files:

```scss
// app/pages/styles/variables.scss
$primary-color: #3b82f6;

.button {
  background: $primary-color;
}
```

Import in your components:

```tsx
import "./styles/variables.scss";
```

### Using Images

Place images in `app/pages/` and import them:

```tsx
// app/pages/logo.tsx
import logoUrl from "./assets/logo.png";

export default function Logo() {
  return <img src={logoUrl} alt="Logo" />;
}
```

## Rails Configuration

Configure ReactiveView's Ruby settings in your initializer:

```ruby
# config/initializers/reactive_view.rb
ReactiveView.configure do |config|
  # SolidStart daemon settings
  config.daemon_host = "localhost"
  config.daemon_port = 3001
  config.daemon_timeout = 30

  # Auto-start daemon with Rails (development only)
  config.auto_start_daemon = Rails.env.development?

  # External daemon (production - managed separately)
  config.external_daemon = Rails.env.production?

  # Paths
  config.pages_path = "app/pages"
  config.working_directory = ".reactive_view"

  # Validate loader responses in dev/test
  config.validate_responses = true
end
```

## Common Recipes

### Tailwind CSS v4

```bash
npm install -D tailwindcss @tailwindcss/vite
```

```typescript
// reactive_view.config.ts
import { defineConfig } from "@reactive-view/core/config";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  vitePlugins: [tailwindcss()],
});
```

```css
/* app/pages/styles/tailwind.css */
@import "tailwindcss";

@source "../**/*.tsx";
```

### UnoCSS

```bash
npm install -D unocss @unocss/vite
```

```typescript
// reactive_view.config.ts
import { defineConfig } from "@reactive-view/core/config";
import UnoCSS from "@unocss/vite";

export default defineConfig({
  vitePlugins: [UnoCSS()],
});
```

### CSS-in-JS (Vanilla Extract)

```bash
npm install -D @vanilla-extract/css @vanilla-extract/vite-plugin
```

```typescript
// reactive_view.config.ts
import { defineConfig } from "@reactive-view/core/config";
import { vanillaExtractPlugin } from "@vanilla-extract/vite-plugin";

export default defineConfig({
  vitePlugins: [vanillaExtractPlugin()],
});
```

### TypeScript Path Aliases

Add custom path mappings:

```typescript
// reactive_view.config.ts
import { defineConfig } from "@reactive-view/core/config";
import path from "path";

export default defineConfig({
  vite: {
    resolve: {
      alias: {
        "@components": path.resolve(__dirname, "app/pages/components"),
        "@utils": path.resolve(__dirname, "app/pages/utils"),
      },
    },
  },
});
```

Then use in your components:

```tsx
import { Button } from "@components/Button";
import { formatDate } from "@utils/dates";
```

## Troubleshooting

### Configuration not loading

Make sure `reactive_view.config.ts` is at your Rails root (same directory as `Gemfile`).

### Vite plugin errors

Ensure the plugin is installed:

```bash
npm install -D <plugin-name>
```

And properly imported in `reactive_view.config.ts`.

### Asset not found

After adding new assets, run:

```bash
bin/rails reactive_view:sync
```

This ensures all files are copied to `.reactive_view/src/pages/`.

### HMR not working

Restart the ReactiveView daemon:

```bash
bin/rails reactive_view:daemon:stop
bin/rails reactive_view:daemon:start
```

Or use `bin/dev` to restart both Rails and the daemon.
