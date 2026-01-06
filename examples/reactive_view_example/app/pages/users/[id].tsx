import { Suspense, Show } from "solid-js";
import { A, useParams } from "@solidjs/router";
import { useLoaderData } from "~/lib/reactive-view";

interface User {
  id: number;
  name: string;
  email: string;
  created_at: string;
}

interface LoaderData {
  user: User;
}

export default function UserShowPage() {
  const params = useParams();
  const data = useLoaderData<LoaderData>();

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
        <A href="/counter">Counter</A>
      </nav>

      <A href="/users" style={{ color: "#3b82f6", "text-decoration": "none" }}>
        ← Back to Users
      </A>

      <Suspense fallback={<div style={{ "margin-top": "20px" }}>Loading user...</div>}>
        <Show when={data()?.user} fallback={<div>User not found</div>}>
          {(user) => (
            <div style={{ "margin-top": "20px" }}>
              <h1>{user().name}</h1>
              
              <div style={{ 
                background: "#fff",
                border: "1px solid #e5e7eb",
                padding: "24px",
                "border-radius": "12px",
                "margin-top": "16px"
              }}>
                <div style={{ "margin-bottom": "16px" }}>
                  <label style={{ 
                    display: "block", 
                    color: "#6b7280", 
                    "font-size": "14px",
                    "margin-bottom": "4px"
                  }}>
                    ID
                  </label>
                  <div style={{ "font-weight": "500" }}>{user().id}</div>
                </div>

                <div style={{ "margin-bottom": "16px" }}>
                  <label style={{ 
                    display: "block", 
                    color: "#6b7280", 
                    "font-size": "14px",
                    "margin-bottom": "4px"
                  }}>
                    Email
                  </label>
                  <div style={{ "font-weight": "500" }}>{user().email}</div>
                </div>

                <div>
                  <label style={{ 
                    display: "block", 
                    color: "#6b7280", 
                    "font-size": "14px",
                    "margin-bottom": "4px"
                  }}>
                    Member Since
                  </label>
                  <div style={{ "font-weight": "500" }}>
                    {new Date(user().created_at).toLocaleDateString()}
                  </div>
                </div>
              </div>

              <div style={{ 
                "margin-top": "24px",
                padding: "16px",
                background: "#eff6ff",
                "border-radius": "8px"
              }}>
                <h3 style={{ margin: "0 0 8px 0", color: "#1e40af" }}>Dynamic Route</h3>
                <p style={{ margin: 0, color: "#3730a3" }}>
                  This page uses a dynamic route segment: <code>[id]</code>
                  <br />
                  Current ID from URL: <strong>{params.id}</strong>
                </p>
              </div>
            </div>
          )}
        </Show>
      </Suspense>
    </div>
  );
}
