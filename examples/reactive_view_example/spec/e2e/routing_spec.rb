require_relative 'e2e_helper'

RSpec.describe 'ReactiveView routing', type: :e2e do
  it 'resolves top-level, grouped, and dynamic routes' do
    with_page do |page|
      page.goto("#{e2e_base_url}/")
      page.wait_for_selector('text=Welcome to ReactiveView')

      page.goto("#{e2e_base_url}/about")
      page.wait_for_selector('text=About ReactiveView')

      page.goto("#{e2e_base_url}/counter")
      page.wait_for_selector('text=Reactive Counter Demo')

      page.goto("#{e2e_base_url}/dashboard")
      page.wait_for_selector('text=Dashboard Overview')

      page.goto("#{e2e_base_url}/login")
      page.wait_for_selector('text=Admin Login')

      page.goto("#{e2e_base_url}/ai/chat")
      page.wait_for_selector('text=AI Chat')

      page.goto("#{e2e_base_url}/users")
      page.wait_for_selector('text=All Users')
      page.click("a[href^='/users/']")
      page.wait_for_selector('text=Dynamic Route with Mutations')

      expect(URI(page.url).path).to match(%r{\A/users/\d+\z})
    end
  end
end
