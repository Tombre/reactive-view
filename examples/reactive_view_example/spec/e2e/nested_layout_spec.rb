require_relative 'e2e_helper'

RSpec.describe 'ReactiveView nested layouts', type: :e2e do
  it 'keeps the dashboard layout while navigating child routes' do
    with_page do |page|
      page.goto("#{e2e_base_url}/dashboard")
      page.wait_for_selector('text=Dashboard Overview')
      page.wait_for_selector('text=Nested Layout Example')
      page.wait_for_timeout(500)

      page.click("a:has-text('Analytics')")
      page.wait_for_selector('text=Analytics')
      page.wait_for_selector('text=Nested Layout Example')

      page.click("a:has-text('Settings')")
      page.wait_for_selector('text=Settings')
      page.wait_for_selector('text=Nested Layout Example')
    end
  end
end
