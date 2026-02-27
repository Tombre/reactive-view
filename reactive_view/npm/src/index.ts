// @reactive-view/core
// TypeScript library for ReactiveView - SolidJS components with Rails backends
//
// This package re-exports the SolidJS and SolidJS Router APIs so that user-facing
// page components can import everything from a single package:
//
//   import { createSignal, Show, A, useLoaderData } from "@reactive-view/core";
//
// Direct imports from "solid-js" and "@solidjs/router" still work, but using
// "@reactive-view/core" is the recommended convention for ReactiveView projects.

// ============================================================================
// SolidJS Core — Reactivity Primitives
// ============================================================================

export {
  // Signals & state
  createSignal,
  createEffect,
  createMemo,
  createResource,
  createRoot,
  createRenderEffect,
  createComputed,
  createDeferred,
  createSelector,

  // Batching & escape hatches
  batch,
  untrack,
  on,

  // Lifecycle
  onMount,
  onCleanup,

  // Ownership
  getOwner,
  runWithOwner,

  // Props helpers
  mergeProps,
  splitProps,
  children,

  // Lazy loading
  lazy,

  // Observable interop
  observable,
  from,

  // Context
  createContext,
  useContext,

  // Control-flow components
  Show,
  For,
  Switch,
  Match,
  Index,
  Suspense,
  SuspenseList,
  ErrorBoundary,

} from "solid-js";

// SolidJS Core — Types
export type {
  Component,
  ParentComponent,
  ParentProps,
  FlowComponent,
  FlowProps,
  VoidComponent,
  VoidProps,
  Accessor,
  Setter,
  Signal,
  Resource,
  JSX,
  Owner,
  Context,
} from "solid-js";

// ============================================================================
// SolidJS Web — SSR Utilities
// ============================================================================

export { isServer, Dynamic, Portal } from "solid-js/web";

// ============================================================================
// SolidJS Router — Navigation & Routing
// ============================================================================

export {
  // Link component
  A,
  Navigate,

  // Navigation hooks
  useNavigate,
  useLocation,
  useParams,
  useSearchParams,
  useMatch,
  useIsRouting,
  useBeforeLeave,

  // Route data
  createAsync,
  query,
  cache,
} from "@solidjs/router";

export type { AccessorWithLatest } from "@solidjs/router";

// ============================================================================
// ReactiveView — Loader Data
// ============================================================================

export { useLoaderData, createLoaderQuery } from "./loader.js";

// ============================================================================
// ReactiveView — Mutations
// ============================================================================

export {
  createMutation,
  createJsonMutation,
  useAction,
  useSubmission,
  useSubmissions,
} from "./mutation.js";
export type { MutationResult } from "./mutation.js";

// ============================================================================
// ReactiveView — Streaming
// ============================================================================

export {
  createStream,
  useStreamData,
} from "./stream.js";
export type {
  StreamState,
  StreamChunk,
  StreamOptions,
  StreamStatus,
  UseStreamDataOptions,
  StreamDataState,
} from "./stream.js";
export { StreamIncompleteError } from "./stream.js";

// ============================================================================
// ReactiveView — CSRF Utilities
// ============================================================================

export { getCSRFToken, getCSRFParam } from "./csrf.js";

// ============================================================================
// ReactiveView — Type Exports for Loader Data
// ============================================================================

export type { LoaderDataMap, LoaderData, HasLoaderData } from "./types/index.js";

// Note: The Vite plugin is exported from a separate entry point to avoid SSR issues.
// Import it from "@reactive-view/core/vite-plugin" instead of "@reactive-view/core".
// Example: import { reactiveViewPlugin } from "@reactive-view/core/vite-plugin";
