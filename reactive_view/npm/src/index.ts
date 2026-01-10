// @reactive-view/core
// TypeScript library for ReactiveView - SolidJS components with Rails backends

// Core hook for loading data from Rails loaders
export { useLoaderData, createLoaderQuery } from "./loader.js";

// Mutation support - actions, forms, and submission tracking
export {
  createMutation,
  createJsonMutation,
  useAction,
  useSubmission,
  useSubmissions,
} from "./mutation.js";
export type { MutationResult } from "./mutation.js";

// CSRF token utilities
export { getCSRFToken, getCSRFParam } from "./csrf.js";

// Type exports for loader data
export type { LoaderDataMap, LoaderData, HasLoaderData } from "./types/index.js";

// Note: The Vite plugin is exported from a separate entry point to avoid SSR issues.
// Import it from "@reactive-view/core/vite-plugin" instead of "@reactive-view/core".
// Example: import { reactiveViewPlugin } from "@reactive-view/core/vite-plugin";
