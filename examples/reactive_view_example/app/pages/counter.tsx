import { createSignal, createEffect, onCleanup } from "solid-js";
import { A } from "@solidjs/router";

export default function CounterPage() {
  const [count, setCount] = createSignal(0);
  const [autoIncrement, setAutoIncrement] = createSignal(false);

  // Demo of SolidJS effects
  createEffect(() => {
    if (autoIncrement()) {
      const interval = setInterval(() => {
        setCount(c => c + 1);
      }, 1000);

      onCleanup(() => clearInterval(interval));
    }
  });

  return (
    <div style={{ "font-family": "system-ui, sans-serif", padding: "40px", "max-width": "800px", margin: "0 auto" }}>
      <nav style={{ 
        background: "#f3f4f6", 
        padding: "16px", 
        "border-radius": "8px", 
        "margin-bottom": "20px" 
      }}>
        <A href="/" style={{ "margin-right": "16px" }}>Home</A>
        <A href="/about" style={{ "margin-right": "16px" }}>About</A>
        <A href="/users" style={{ "margin-right": "16px" }}>Users</A>
        <A href="/counter" style={{ "font-weight": "bold" }}>Counter</A>
      </nav>

      <h1>Reactive Counter Demo</h1>
      
      <p>
        This page demonstrates SolidJS reactivity with signals and effects.
        The counter state is managed entirely on the client side.
      </p>

      <div style={{ 
        background: "#fef3c7", 
        padding: "30px", 
        "border-radius": "12px", 
        "text-align": "center",
        "margin": "30px 0"
      }}>
        <div style={{ "font-size": "64px", "font-weight": "bold", color: "#92400e" }}>
          {count()}
        </div>
        <p style={{ color: "#78716c", margin: "10px 0 0 0" }}>Current Count</p>
      </div>

      <div style={{ "display": "flex", gap: "10px", "justify-content": "center", "flex-wrap": "wrap" }}>
        <button 
          onClick={() => setCount(c => c - 1)}
          style={{
            background: "#ef4444",
            color: "white",
            border: "none",
            padding: "12px 24px",
            "border-radius": "6px",
            cursor: "pointer",
            "font-size": "16px"
          }}
        >
          - Decrement
        </button>
        
        <button 
          onClick={() => setCount(0)}
          style={{
            background: "#6b7280",
            color: "white",
            border: "none",
            padding: "12px 24px",
            "border-radius": "6px",
            cursor: "pointer",
            "font-size": "16px"
          }}
        >
          Reset
        </button>
        
        <button 
          onClick={() => setCount(c => c + 1)}
          style={{
            background: "#22c55e",
            color: "white",
            border: "none",
            padding: "12px 24px",
            "border-radius": "6px",
            cursor: "pointer",
            "font-size": "16px"
          }}
        >
          + Increment
        </button>
      </div>

      <div style={{ 
        "margin-top": "30px",
        "padding": "20px",
        background: autoIncrement() ? "#dcfce7" : "#f3f4f6",
        "border-radius": "8px",
        "text-align": "center"
      }}>
        <label style={{ cursor: "pointer", "user-select": "none" }}>
          <input 
            type="checkbox" 
            checked={autoIncrement()}
            onChange={(e) => setAutoIncrement(e.target.checked)}
            style={{ "margin-right": "8px" }}
          />
          Auto-increment every second (using SolidJS effects)
        </label>
      </div>

      <div style={{ "margin-top": "30px", color: "#666" }}>
        <h3>How This Works</h3>
        <pre style={{ 
          background: "#1f2937", 
          color: "#e5e7eb", 
          padding: "16px", 
          "border-radius": "8px",
          overflow: "auto"
        }}>
{`const [count, setCount] = createSignal(0);
const [autoIncrement, setAutoIncrement] = createSignal(false);

createEffect(() => {
  if (autoIncrement()) {
    const interval = setInterval(() => {
      setCount(c => c + 1);
    }, 1000);
    onCleanup(() => clearInterval(interval));
  }
});`}
        </pre>
      </div>
    </div>
  );
}
