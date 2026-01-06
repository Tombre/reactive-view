# Streaming SSR

**Status:** Not Started  
**Priority:** Medium  
**Category:** Performance

## Context

SolidStart supports streaming server-side rendering, which allows the server to send HTML to the browser progressively as it becomes available. This can significantly improve Time to First Byte (TTFB) and perceived performance, especially when:

1. Some data loads faster than others
2. There are slow database queries or API calls
3. Users are on slow connections

Currently, ReactiveView waits for all loader data to be fetched before sending any HTML to the browser. This means users see nothing until everything is ready, which can feel slow even if the total time is acceptable.

## Overview

Implement streaming SSR support for ReactiveView that:

- Leverages SolidStart's built-in streaming capabilities
- Sends initial HTML shell immediately
- Streams in content as loader data becomes available
- Uses Suspense boundaries to define streaming chunks
- Maintains SEO compatibility with proper meta tag handling

**Current SSR Flow:**
```
Request → Fetch ALL Data → Render ALL HTML → Send Response
TTFB: [=============================]
```

**Streaming SSR Flow:**
```
Request → Send Shell → Stream Content as Ready
TTFB: [==]
Full: [=============================]
```

## Acceptance Criteria

- [ ] Initial HTML shell is sent before all data is loaded
- [ ] Content streams progressively as loader data resolves
- [ ] Suspense boundaries define streaming chunks
- [ ] Fallback UI is shown while streaming (loading skeletons)
- [ ] SEO-critical content (meta tags, titles) is in initial shell
- [ ] Streaming works with Rails-to-SolidStart communication
- [ ] Hydration works correctly with streamed content
- [ ] Error handling works within streamed chunks
- [ ] Performance improvement is measurable (TTFB reduction)
- [ ] Configuration option to enable/disable streaming
- [ ] Documentation explains streaming setup and tradeoffs

## Tasks

- [ ] Investigate SolidStart/Vinxi streaming SSR API
- [ ] Update `Renderer` to support streaming responses
- [ ] Configure Vinxi for streaming output
- [ ] Implement proper response handling for streamed HTML
- [ ] Add Suspense boundaries to example app for streaming
- [ ] Ensure loader data fetching supports streaming (async iteration)
- [ ] Handle meta tags and SEO content in stream head
- [ ] Test hydration with streamed content
- [ ] Test error boundaries within streamed chunks
- [ ] Measure and document TTFB improvements
- [ ] Add configuration option for streaming (`config.streaming_ssr`)
- [ ] Test with artificially slow loaders
- [ ] Test with multiple concurrent slow data sources
- [ ] Document streaming patterns and best practices

## Technical Notes

### SolidStart Streaming

SolidStart uses `renderToStream` from `solid-js/web`:

```typescript
import { renderToStream } from "solid-js/web";

const stream = renderToStream(() => <App />);
```

### Suspense Boundaries for Streaming

```tsx
import { Suspense } from "solid-js";

function UserPage() {
  return (
    <div>
      {/* This renders immediately */}
      <Header />
      
      {/* This streams when data is ready */}
      <Suspense fallback={<UserSkeleton />}>
        <UserDetails />
      </Suspense>
      
      {/* This can stream independently */}
      <Suspense fallback={<PostsSkeleton />}>
        <UserPosts />
      </Suspense>
    </div>
  );
}
```

### Renderer Updates

```ruby
# reactive_view/lib/reactive_view/renderer.rb
class Renderer
  def render_streaming(component_path, props)
    # Return an Enumerator or IO that Rails can stream
    Enumerator.new do |yielder|
      stream = fetch_stream_from_solidstart(component_path, props)
      stream.each_chunk { |chunk| yielder << chunk }
    end
  end
end
```

### Rails Streaming Response

```ruby
# In a controller
def show
  response.headers["Content-Type"] = "text/html"
  response.headers["Transfer-Encoding"] = "chunked"
  
  self.response_body = ReactiveView.render_streaming(
    "pages/users/[id]",
    { user_id: params[:id] }
  )
end
```

### Vinxi Configuration

```typescript
// app.config.ts
export default defineConfig({
  server: {
    preset: "node-server",
    // Enable streaming
    experimental: {
      streaming: true
    }
  }
});
```

### SEO Considerations

Meta tags must be in the initial chunk:

```tsx
function App() {
  return (
    <html>
      <head>
        {/* These are in the initial stream */}
        <title>Page Title</title>
        <meta name="description" content="..." />
      </head>
      <body>
        {/* Content can stream */}
        <Suspense fallback={<Loading />}>
          <Content />
        </Suspense>
      </body>
    </html>
  );
}
```

### Testing with Slow Loaders

```ruby
# For testing streaming behavior
class SlowLoader < ReactiveView::Loader
  def call
    sleep(3)  # Simulate slow database
    { data: "finally loaded" }
  end
end
```

## Related Files

- `reactive_view/lib/reactive_view/renderer.rb`
- `reactive_view/template/src/entry-server.tsx`
- `reactive_view/template/app.config.ts`
- `reactive_view/lib/reactive_view/daemon.rb`
