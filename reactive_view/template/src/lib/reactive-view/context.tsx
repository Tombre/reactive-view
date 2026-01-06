import { createContext, useContext, ParentComponent } from "solid-js";
import { isServer } from "solid-js/web";
import { useSearchParams } from "@solidjs/router";

// Context for the request token passed from Rails
const RequestTokenContext = createContext<string | undefined>();

/**
 * Provider that extracts and provides the request token from the URL
 * The token is passed by Rails when requesting a render from SolidStart
 */
export const RequestTokenProvider: ParentComponent = (props) => {
  // On the server during SSR, the token comes from the render request
  // On the client, we might need it for client-side navigation data fetching
  const [searchParams] = useSearchParams();
  
  // The token is typically passed as a query parameter during SSR
  // For client-side navigation, we'll make new requests to Rails
  const token = isServer 
    ? (globalThis as any).__REACTIVE_VIEW_TOKEN__ 
    : searchParams._rv_token;

  return (
    <RequestTokenContext.Provider value={token}>
      {props.children}
    </RequestTokenContext.Provider>
  );
};

/**
 * Hook to get the current request token
 */
export function useRequestToken(): string | undefined {
  return useContext(RequestTokenContext);
}
