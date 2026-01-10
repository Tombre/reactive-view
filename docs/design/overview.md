# ReactiveView

ReactiveView is a Ruby on Rails "view framework" gem for creating modern reactive frontends for your Rails application. ReactiveView esentially replaces the view layer of your rails applciation. You can think of it like a rendering engine, a router, and a data loader all in one.

You can use ReactiveView to build your frontend with tsx components (Typescript + SolidJs), with all data, auth, buisness logic still handled by Rails!

ReactiveView Supports:

- SSR with reactive state based interactivity
- Typesafety between Rails data and your frontend
- Directory based routing

Basically you get a frontend dev experience similar to using React[^1], with none of the maintinence overhead, and the power of a Rails backend.

[^1]: It actually uses SolidJs

## Motivation

There has been an explosion of "frontend first" JS frameworks (NextJs, Remix, SolidStart, Qwikm, etc etc) that have made it easier than ever to build highly reactive frontends in javascript (or rather - Typescript). These frameworks do incredible things, like only loading the most minimal javascript needed for a particluar page, building things in small reusable blocks (components), and letting you build highly reactive and stateful UI that was always so difficult with vanilla javascript.

In comparison, Rails has historically lagged behind the curve when it comes to frontend tooling. Instead, it opted for a simpler frontend development experience to reduce the complexity (and mental fatigue) that comes with maintaining many of those frontend frameworks - at the expense of not having some of those increadible modern frontend tools available to you.

> Rails **does** have some very novel (and awesome) frontend solutions, such as Turbo and Stimulus - offering a HTML over the wire strategy for building frontends. These tools have their tradeoffs; such as letting you write most of your code in a ruby context (nice!) but still having some js or performing in page updates via network requests (not always great!)

What Rails does GREAT though - is backend stuff. Nothing out there compares when it comes to easily building data models and buisness logic.

Wouldn't it be great if we could have the best of both worlds - using rails for what it's GREAT at (backend), and using a js framework for it's great at (frontend) but not in way that required a lot of effort to maintain two seperate services (e.g. frontend and API). Where we get all the benefits of a Rails framework with the modern frontend tooling that makes working with js frameworks a dream - without the pain of maintaing them.

This is what ReactiveView aims to achieve.

## Concepts

In ReactiveView, instead of using Rails controllers which render views, you build your frontends with `tsx` components in the Rails `app/pages` directory. ReactiveView uses SolidJs to render the tsx components, so you can use any SolidJs tool/abstraction (signals, effects, etc) to build your frontend and make it stateful and reactive.

Importing SolidJs primitives can be done from the ReactiveView namespace, e.g:

```tsx
import { createSignal } from "reactiveview/solidjs";
```

The `app/pages` directory also works like a directory based router (similar to frameworks such as Nextjs, Remix, or SolidStart), allowing you to build your frontend via the file system. No need to create a view, a controller to render the view, and a route to register the controller. The `app/pages` directory lets you configure this implicitly.

### Routing

Any `.tsx` files in the `app/pages` directory creates a new frontend page route at the corresponding directory path. Folders and jsx files can tyou `[param]` pattern to determine params for example:

- `app/pages/users/[id]/edit.tsx` would route as `myapp.com/users/1/edit`
- `app/pages/users/[id]/index.tsx` would route as `myapp.com/users/1`

#### Nested layouts

If you want to create nested layouts you can create a file with the same name as a route folder.

```
|-- app/pages/
    |-- blog.tsx                 // layout file
    |-- blog/
        |-- article-1.tsx        // example.com/blog/article-1
        |-- article-2.tsx        // example.com/blog/article-2
```

In this case, the blog.tsx file will act as a layout for the articles in the blog folder. You can reference the child's content by using props.children in the layout.

```tsx
// routes/blog.tsx
import { RouteSectionProps } from "reactiveview/solidjs/router";

export default function BlogLayout(props: RouteSectionProps) {
  return <div>{props.children}</div>;
}
```

> Routing works the exact same way as the `SolidStart` framework. In fact it uses SolidStard behind the scenes. You can use all the same primitives and route patterns and as SolidStart does for directory routes.

### Loading Data

When you need to load, mutate data, or do auth, you do it via a "Loader" which sits in a `{{route-name}}.loader.rb` file (where the `{{route-name}})` corresponds to the name of the tsx component).

Loaders are special Rails controllers with a `load` method that your tsx components talk to so that they can load data. Loaders work seamlessly with your page components to make interacting with data easy.

For example:

```rb
# app/pages/users/[id].loader.rb
class Users::IdLoader < ReactiveView::Loader
  # Provide the typescript definition
  shape :load do
    param :name, ReactiveView::Types::String
    param :id, ReactiveView::Types::Integer
  end

  # respond with the data
  def load
    { name: user.name, id: user.id }
  end

  private

  def user
    @user ||= User.find(params[:id])
  end
end
```

The loader recieves the parameters of the request like any regular rails controller. And allows you to return some data. For type safety you can also call a `shape` method that allows you to configure a response type structure. This is automatically inferred on the frontend:

```tsx
// app/pages/users/[id].tsx
import { useLoaderData } from "reactiveview";

export default function Page() {
  // `user` will automatically be typed to the `shape` definition we setup in the loader
  const user = useLoaderData();

  return (
    <div>
      User {user().id} {user().name}
    </div>
  );
}
```

Here the component calls `useLoaderData` which fetches the data in a typesafe way. Since the route and loader are named the same, it knows which loader to use for which component. In the background, this data is preloaded from the loader when the route is hit - allowing for smooth SSR.

Loaders also are responsible for any auth or "pre-work" needed to be done to the request. Loaders are called when the route is hit on the rails side, before the content is rendered. This lets you do any normal rails controller things such as checking auth, setting cookies, logs, etc etc. For example, if you want to check auth - use a loader with a before_action that authorizes the request.

> Behind the scenes, a basic loader class is actually called for every route. When you need to provide data to your page component, you add your own which implements the `load` method.

## How it works behind the scenes

ReactiveView works with two main components:

- **A Rails Engine** for drawring the rails routes and handling requests.
- **A SolidStart** server daemon (booted up alongside Rails) compiled in the background, that is responsible for rendering the html

In ReactiveView, The Rails engine handles the initial requests. When it comes time to render the html, the engine reaches out to the SolidStart server and requests the html content. This content is rendered with SSR, and sent back to the Rails engine, which then sends it back to the client!

The Rails Engine component also handles data loading and mutation requests coming from the resulting SolidStart server or the resulting js bundle. Everytime it see's a `x.loader.rb` controller, it will setup an additional api route that allows data to be fetched for the SolidStart process. The SolidStart server is automatically setup with server actions that fetch this data, treating the Rails Engine kind like an API.

In this design, it's best to think of SolidStart as a "rendering process" and not of an application server. While it uses HTML the webserver mechanism to deliver content, it's not facing the public internet. Instead Rails is asking it "Render the HTML content (server side rendered ) for this route and give it to me" and SolidStart gives it back to Rails, which then delivers it back to the client, along with the references to the assets and js bundles it compiled earlier.

> In the future ReactiveView could be configured to put SolidStart **in front** of the Rails application, allowing developers to have SolidStart work as the frontend - taking requests from the internet, and Rails be the "backend of the fronted" - working as an API only application. For now though, having Rails serve the request and SolidStart be the rendering process allows incremental adoption for people who have existing normal Rails routes.

## The Rails Engine

The ReactiveView Rails Engine's job is to take requests from the client, and then coordinate with the SolidStart daemon.

All routes are handled by a default base `ReactiveView::Loader` controller. The controller accepts the request, and then (via a `ReactiveView::Renderer` service) makes a request to the SolidStart server daemon for the html content of the page. The SolidStart server daemon will make requests back to Rails application for any data it needs to render the page (using the loaders you have written). The HTML response is sent back to the client. In this way, the controllers act as a kind of application level proxy for the page contents.

```rb
# A simplified example
class ReactiveView::Loader < ActionController::Base
  # Add the `load` method to enable loading data from this controller. If this method exists, the engine
  # sets up an additional route that can be queried by the SolidStart daemon for data.
  # def load
  # end

  # The route action
  def call
    content = renderer.call(request.fullpath)
    render html: content.html_safe
  end

  private

  # The `Renderer` class is responsible for making calls to the SolidStart daemon and returning errors if it's
  # not available or doesn't respond in a timely manner.
  def renderer
    @renderer ||= ReactiveView::Renderer.new
  end
end
```

Because the loaders are the things that accept all the requests in the first place, developers can override them and add more things (e.g. like auth):

```rb
# app/pages/users/[id].loader.rb
class Users::IdLoader < ReactiveView::Loader
  before_action :authenticate_user!

  shape :load do
    param :name, ReactiveView::Types::String
    param :id, ReactiveView::Types::Integer
  end

  def load
    { name: user.name, id: user.id }
  end

  private

  def authenticate_user!
    redirect_to admin_sign_in_path unless user == current_user && user_signed_in?
  end

  def user
    @user ||= User.find(params[:id])
  end
end
```

In the above example, the `before_action` would first redirect the client before the renderer was even accessed.

In Rails development environement, a service will monitor for changes in `app/pages` loaders and page components, and use the directory structure to draw the routes on the rails side as the files are changed. The service will also copy `.tsx` files across to the `SolidStart` working directory for the server deamon to recompile itself.

## SolidStart Server Dameon

The SolidStart server dameon is the JS/Typescript web server responsible for rendering pages as requested by the Rails Engine controllers.

When you add a `.tsx` file to `app/pages` - a process copies the file over to a `.reactive_view` directory which contains the SolidStart application. The application is kept running and monitored by the a Rails service. It is run in development mode if Rails is also in development or test mode. When deploying to production, the application is compiled and built so that rails (or a server in front of rails like nginx - or a cdn - or whatever) can also proxy across assets (images and js for example).

When a Rails loader controller calls the `ReactiveView::Renderer` service, it makes a request to this dameon for the html content. Some of these pages make API calls back to the Rails application via loaders (described above).

This mechanism means you get to write your components and pages inside the Rails application directory - and have the Typescript SolidStart project compiled for you - all while being perfectly typesafe.

### Why a SolidStart HTTP server?

- Because the mechanisms for routing, data fetching, etc etc is already build and can be handled by SolidStart
- Because it allows the deamon to respond to multiple requests at once
- Because in the future we may want to allow putting the daemon on a different server or deployed by a provider (and http is great way to enable communication like that).
- Because in the future we may want to allow having the SolidStart server _in front_ of the Rails server, so SolidStart responds to requests directly, and Rails just acts as an API only server.
