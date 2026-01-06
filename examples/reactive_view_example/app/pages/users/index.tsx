import { For, Suspense } from "solid-js";
import { A } from "@solidjs/router";
import { useLoaderData } from "#loaders/users/index";

export default function UsersIndexPage() {
  const data = useLoaderData();

  return (
    <div
      style={{
        "font-family": "system-ui, sans-serif",
        padding: "40px",
        "max-width": "800px",
        margin: "0 auto",
      }}
    >
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
        <A
          href="/users"
          style={{ "margin-right": "16px", "font-weight": "bold" }}
        >
          Users
        </A>
        <A href="/counter">Counter</A>
      </nav>

      <h1>Users</h1>

      <p>
        This page demonstrates loading data from a Rails loader. The user data
        comes from <code>app/pages/users/index.loader.rb</code>.
      </p>

      <Suspense fallback={<div>Loading users...</div>}>
        <div style={{ "margin-top": "20px" }}>
          <p style={{ color: "#666" }}>
            Showing {data()?.users?.length || 0} of {data()?.total || 0} users
          </p>

          <div
            style={{
              display: "grid",
              gap: "12px",
              "margin-top": "16px",
            }}
          >
            <For each={data()?.users || []}>
              {(user) => (
                <A
                  href={`/users/${user.id}`}
                  style={{
                    display: "block",
                    background: "#fff",
                    border: "1px solid #e5e7eb",
                    padding: "16px",
                    "border-radius": "8px",
                    "text-decoration": "none",
                    color: "inherit",
                    transition: "box-shadow 0.2s",
                  }}
                >
                  <div style={{ "font-weight": "bold", color: "#1f2937" }}>
                    {user.name}
                  </div>
                  <div style={{ color: "#6b7280", "font-size": "14px" }}>
                    {user.email}
                  </div>
                </A>
              )}
            </For>
          </div>
        </div>
      </Suspense>

      <div
        style={{
          "margin-top": "30px",
          background: "#f9fafb",
          padding: "16px",
          "border-radius": "8px",
        }}
      >
        <h3>Loader Code</h3>
        <pre
          style={{
            background: "#1f2937",
            color: "#e5e7eb",
            padding: "12px",
            "border-radius": "6px",
            overflow: "auto",
            "font-size": "13px",
          }}
        >
          {`class Pages::Users::IndexLoader < ReactiveView::Loader
  loader_sig do
    param :users, ReactiveView::Types::Array[
      ReactiveView::Types::Hash.schema(
        id: ReactiveView::Types::Integer,
        name: ReactiveView::Types::String,
        email: ReactiveView::Types::String
      )
    ]
    param :total, ReactiveView::Types::Integer
  end

  def load
    { users: User.all.map { ... }, total: User.count }
  end
end`}
        </pre>
      </div>
    </div>
  );
}
