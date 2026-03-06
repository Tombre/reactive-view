require_relative 'e2e_helper'
require 'json'
require 'net/http'

RSpec.describe 'ReactiveView loaders', type: :e2e do
  it 'shows auth entry links in the top navigation when signed out' do
    with_page do |page|
      page.goto("#{e2e_base_url}/")
      page.wait_for_selector("a:has-text('Sign In')")
      page.wait_for_selector("a:has-text('Create Account')")
      expect(page.content).not_to include('Signed in as')
    end
  end

  it 'shows signed-in controls in top navigation after test auth bootstrap' do
    with_page do |page|
      page.goto("#{e2e_base_url}/")
      result = page.evaluate(
        <<~JS
          async () => {
            const response = await fetch('/__e2e__/auth/sign_in?email=alice@example.com');
            return response.json();
          }
        JS
      )
      expect(result['success']).to eq(true)

      page.goto("#{e2e_base_url}/")
      page.wait_for_selector('text=Signed in as Alice Johnson')
      page.wait_for_selector("button:has-text('Sign out')")

      sign_out_result = page.evaluate(
        <<~JS
          async () => {
            const response = await fetch('/__e2e__/auth/sign_out');
            return response.json();
          }
        JS
      )
      expect(sign_out_result['success']).to eq(true)
    end
  end

  it 'renders users data from the index loader' do
    with_page do |page|
      page.goto("#{e2e_base_url}/users")
      page.wait_for_selector('text=All Users')
      page.wait_for_selector('text=Showing')

      content = page.content
      expect(content).to include('users/index.loader.rb')
      expect(content).to include('Loader Data Source')
    end
  end

  it 'does not redirect from users to login due to dashboard preloading' do
    with_page do |page|
      page.goto("#{e2e_base_url}/users")
      page.wait_for_selector('text=All Users')
      page.wait_for_timeout(1000)
      expect(URI(page.url).path).to eq('/users')
    end
  end

  it 'renders passkey login page from grouped route' do
    with_page do |page|
      page.goto("#{e2e_base_url}/login")
      page.wait_for_selector('text=Sign in with passkey')
      page.wait_for_selector('text=Continue with passkey')
    end
  end

  it 'redirects unauthenticated dashboard access to login' do
    with_page do |page|
      page.goto("#{e2e_base_url}/dashboard")
      page.wait_for_selector('text=Sign in with passkey')
      expect(URI(page.url).path).to eq('/login')
    end
  end

  it 'redirects client-side dashboard navigation to login when signed out' do
    with_page do |page|
      page.goto("#{e2e_base_url}/")
      page.wait_for_selector("a:has-text('Dashboard')")
      page.click("a:has-text('Dashboard')")
      page.wait_for_selector('text=Sign in with passkey')
      expect(URI(page.url).path).to eq('/login')
    end
  end

  it 'renders register page from grouped route' do
    with_page do |page|
      page.goto("#{e2e_base_url}/register")
      page.wait_for_selector('text=Create account')
      page.wait_for_selector('text=Create account with passkey')
    end
  end

  it 'returns 422 when load params are missing for a typed loader' do
    response = Net::HTTP.get_response(URI("#{e2e_base_url}/_reactive_view/loaders/users/%5Bid%5D/load"))

    expect(response.code).to eq('422')
    expect(JSON.parse(response.body)['error']).to include("doesn't conform schema")
  end
end
