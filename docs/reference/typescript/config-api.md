# TypeScript: Config API (`@reactive-view/core/config`)

## `defineConfig`

```ts
defineConfig(config?: ReactiveViewConfig): ReactiveViewConfig
```

## `ReactiveViewConfig`

- `vitePlugins?: PluginOption[]`
- `vite?: Record<string, unknown>`
- `reactiveView?: { debug?: boolean; [key: string]: unknown }`

`reactive_view.config.ts` is loaded by `.reactive_view/app.config.ts` and merged into the SolidStart config.
