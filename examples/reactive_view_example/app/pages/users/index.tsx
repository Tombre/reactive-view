import { For, Suspense } from "solid-js";
import { A } from "@solidjs/router";
import { useLoaderData } from "#loaders/users/index";
import MainLayout from "../components/MainLayout";

export default function UsersIndexPage() {
  const data = useLoaderData();

  return (
    <MainLayout title="All Users">
      <p class="text-gray-700 mb-6">
        This page demonstrates loading data from a Rails loader. The user data
        comes from <code class="bg-gray-100 px-2 py-1 rounded text-sm">app/pages/users/index.loader.rb</code>.
      </p>

      <Suspense fallback={<div class="text-gray-500">Loading users...</div>}>
        <div class="mt-5">
          <p class="text-gray-600 mb-4">
            Showing {data()?.users?.length || 0} of {data()?.total || 0} users
          </p>

          <div class="grid gap-3 mt-4">
            <For each={data()?.users || []}>
              {(user) => (
                <A
                  href={`/users/${user.id}`}
                  class="block bg-white border border-gray-200 p-4 rounded-lg hover:shadow-md transition-shadow no-underline text-inherit"
                >
                  <div class="font-semibold text-gray-900">
                    {user.name}
                  </div>
                  <div class="text-gray-600 text-sm">
                    {user.email}
                  </div>
                </A>
              )}
            </For>
          </div>
        </div>
      </Suspense>

      <div class="mt-8 bg-gray-50 border border-gray-200 p-4 rounded-lg">
        <h3 class="text-lg font-semibold text-gray-900 mb-3">Loader Code</h3>
        <pre class="bg-gray-800 text-gray-100 p-3 rounded text-xs overflow-auto">
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
    </MainLayout>
  );
}
