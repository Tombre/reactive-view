import { createSignal } from "solid-js";
import { A } from "@solidjs/router";

export default function HomePage() {
  const [count, setCount] = createSignal(0);

  return (
    <div
      style={{
        "font-family": "system-ui, sans-serif",
        padding: "40px",
        "max-width": "800px",
        margin: "0 auto",
      }}
    >
      <h1>Welcome to ReactiveView!</h1>

      <p>
        This page is rendered by <strong>SolidJS</strong> with server-side
        rendering, powered by your <strong>Rails</strong> backend.
      </p>

      <nav
        style={{
          background: "#f3f4f6",
          padding: "16px",
          "border-radius": "8px",
          "margin-bottom": "20px",
        }}
      >
        <A href="/" style={{ "margin-right": "16px" }}>
          Home
        </A>
        <A href="/about" style={{ "margin-right": "16px" }}>
          About
        </A>
        <A href="/users" style={{ "margin-right": "16px" }}>
          Users
        </A>
        <A href="/dashboard" style={{ "margin-right": "16px" }}>
          Dashboard
        </A>
        <A href="/counter">Counter</A>
      </nav>

      <div
        style={{
          background: "#f0f9ff",
          padding: "20px",
          "border-radius": "8px",
          "margin-top": "20px",
        }}
      >
        <h3>Interactive Counter (Client-Side State)</h3>
        <p>
          Count: <strong>{count()}</strong>
        </p>
        <button
          onClick={() => setCount((c) => c + 1)}
          style={{
            background: "#3b82f6",
            color: "white",
            border: "none",
            padding: "8px 16px",
            "border-radius": "4px",
            cursor: "pointer",
            "margin-right": "8px",
          }}
        >
          Increment
        </button>
        <button
          onClick={() => setCount(0)}
          style={{
            background: "#6b7280",
            color: "white",
            border: "none",
            padding: "8px 16px",
            "border-radius": "4px",
            cursor: "pointer",
          }}
        >
          Reset
        </button>
      </div>

      <div style={{ "margin-top": "30px", color: "#666" }}>
        <h3>How It Works</h3>
        <ul>
          <li>
            Pages are defined as TSX files in <code>app/pages/</code>
          </li>
          <li>
            Data is loaded via Ruby loaders (<code>*.loader.rb</code>)
          </li>
          <li>Full SSR with hydration for interactivity</li>
          <li>Type-safe communication between Rails and TypeScript</li>
        </ul>
      </div>
    </div>
  );
}
