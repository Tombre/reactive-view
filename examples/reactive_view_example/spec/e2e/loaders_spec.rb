require_relative 'e2e_helper'
require 'json'
require 'net/http'

RSpec.describe 'ReactiveView loaders', type: :e2e do
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

  it 'renders grouped route loader data on login page' do
    with_page do |page|
      page.goto("#{e2e_base_url}/login")
      page.wait_for_selector('text=Admin Login')
      page.wait_for_selector('text=Two-factor authentication is required')
      page.wait_for_selector('text=Session timeout: 30 minutes')
    end
  end

  it 'renders analytics loader data on the dashboard route' do
    with_page do |page|
      page.goto("#{e2e_base_url}/dashboard/analytics")
      page.wait_for_selector('text=Viewing analytics for: week')
      page.wait_for_selector('text=Page Views - Week')
      page.wait_for_selector('text=Mon')
      page.wait_for_selector('text=Top Pages')
      page.wait_for_selector('text=/dashboard')
      page.wait_for_selector('text=Traffic Sources')
      page.wait_for_selector('text=Direct')
    end
  end

  it 'returns 422 when load params are missing for a typed loader' do
    response = Net::HTTP.get_response(URI("#{e2e_base_url}/_reactive_view/loaders/users/%5Bid%5D/load"))

    expect(response.code).to eq('422')
    expect(JSON.parse(response.body)['error']).to include("doesn't conform schema")
  end
end
