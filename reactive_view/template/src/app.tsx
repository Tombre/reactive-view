import { Router } from "@solidjs/router";
import { FileRoutes } from "@solidjs/start/router";
import { Suspense } from "solid-js";
import { RequestTokenProvider } from "~/lib/reactive-view";

export default function App() {
  return (
    <Router
      root={(props) => (
        <RequestTokenProvider>
          <Suspense fallback={<div>Loading...</div>}>
            {props.children}
          </Suspense>
        </RequestTokenProvider>
      )}
    >
      <FileRoutes />
    </Router>
  );
}
