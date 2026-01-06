import { A } from "@solidjs/router";

export default function AboutPage() {
  return (
    <div style={{ "font-family": "system-ui, sans-serif", padding: "40px", "max-width": "800px", margin: "0 auto" }}>
      <nav style={{ 
        background: "#f3f4f6", 
        padding: "16px", 
        "border-radius": "8px", 
        "margin-bottom": "20px" 
      }}>
        <A href="/" style={{ "margin-right": "16px" }}>Home</A>
        <A href="/about" style={{ "margin-right": "16px", "font-weight": "bold" }}>About</A>
        <A href="/users" style={{ "margin-right": "16px" }}>Users</A>
        <A href="/counter">Counter</A>
      </nav>

      <h1>About ReactiveView</h1>
      
      <p>
        ReactiveView is a Ruby on Rails "view framework" gem for creating modern 
        reactive frontends for your Rails application.
      </p>

      <h2>Features</h2>
      <ul>
        <li><strong>SSR</strong> - Server-side rendering with SolidJS hydration</li>
        <li><strong>Type Safety</strong> - Automatic TypeScript types from Ruby loaders</li>
        <li><strong>File-based Routing</strong> - SolidStart-style routing from <code>app/pages/</code></li>
        <li><strong>Rails Integration</strong> - Use Rails for auth, models, and business logic</li>
      </ul>

      <h2>Architecture</h2>
      <p>
        ReactiveView works by coordinating between Rails and a SolidStart daemon:
      </p>
      <ol>
        <li>Rails receives the HTTP request</li>
        <li>Your loader runs (auth, data fetching, etc.)</li>
        <li>Rails asks SolidStart to render the page</li>
        <li>SolidStart calls back to Rails for loader data</li>
        <li>Rendered HTML is returned to the client</li>
        <li>SolidJS hydrates for client-side interactivity</li>
      </ol>
    </div>
  );
}
