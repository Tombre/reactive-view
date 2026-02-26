require_relative 'e2e_helper'

RSpec.describe 'ReactiveView example app', type: :e2e do
  it 'renders the main static pages' do
    with_page do |page|
      page.goto("#{e2e_base_url}/")
      page.wait_for_selector('text=Welcome to ReactiveView')

      page.click("a:has-text('About')")
      page.wait_for_selector('text=About ReactiveView')

      page.click("a:has-text('Counter')")
      page.wait_for_selector('text=Reactive Counter Demo')
    end
  end

  it 'renders nested and grouped routes' do
    with_page do |page|
      page.goto("#{e2e_base_url}/dashboard")
      page.wait_for_selector('text=Dashboard Overview')

      page.goto("#{e2e_base_url}/login")
      page.wait_for_selector('text=Admin Login')
    end
  end
end
