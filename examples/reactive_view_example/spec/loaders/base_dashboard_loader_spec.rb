# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../spec_helper'

RSpec.describe Pages::Admin::BaseDashboardLoader do
  describe '#load' do
    let(:loader) { Pages::Admin::Dashboard::AnalyticsLoader.new }
    let(:payload) { { chart_data: [] } }

    it 'enforces authentication before loading dashboard data' do
      expect(loader).to receive(:require_authenticated_user!).ordered
      expect(loader).to receive(:dashboard_load).ordered.and_return(payload)

      expect(loader.load).to eq(payload)
    end

    it 'raises authentication errors from the auth guard' do
      allow(loader).to receive(:require_authenticated_user!).and_raise(
        RodauthLoaderAuthentication::AuthenticationRequired.new
      )

      expect { loader.load }.to raise_error(RodauthLoaderAuthentication::AuthenticationRequired)
    end
  end

  it 'is used by all dashboard loaders' do
    dashboard_loaders = [
      Pages::Admin::DashboardLoader,
      Pages::Admin::Dashboard::IndexLoader,
      Pages::Admin::Dashboard::AnalyticsLoader,
      Pages::Admin::Dashboard::SettingsLoader,
      Pages::Admin::Dashboard::Reports::IndexLoader,
      Pages::Admin::Dashboard::Reports::SourcesLoader
    ]

    dashboard_loaders.each do |loader_class|
      expect(loader_class < described_class).to eq(true)
    end
  end
end
