require_relative 'e2e_helper'

RSpec.describe 'ReactiveView nested layouts', type: :e2e do
  it 'requires authentication before entering dashboard layout routes' do
    with_page do |page|
      page.goto("#{e2e_base_url}/dashboard")
      page.wait_for_selector('text=Sign in with passkey')
      expect(URI(page.url).path).to eq('/login')

      page.goto("#{e2e_base_url}/dashboard/analytics")
      page.wait_for_selector('text=Sign in with passkey')
      expect(URI(page.url).path).to eq('/login')
    end
  end
end
