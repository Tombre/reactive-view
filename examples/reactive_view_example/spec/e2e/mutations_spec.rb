require_relative 'e2e_helper'

RSpec.describe 'ReactiveView mutations', type: :e2e do
  it 'renders generated mutation controls on the dynamic user route' do
    with_page do |page|
      page.goto("#{e2e_base_url}/users")
      page.wait_for_selector('text=All Users')
      page.click("a:has-text('Alice Johnson')")
      page.wait_for_selector('text=Dynamic Route with Mutations')
      page.wait_for_selector("button:has-text('Edit')")
      page.wait_for_selector("button:has-text('Delete')")

      content = page.content
      expect(content).to include('shape :update')
      expect(content).to include('shape :delete')
      expect(content).to include('Current ID:')
    end
  end
end
