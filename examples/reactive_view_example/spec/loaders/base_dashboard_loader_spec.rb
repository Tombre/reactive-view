# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../spec_helper'

RSpec.describe 'Dashboard auth and loader wiring' do
  describe 'folder guard' do
    it 'applies authentication guard to all request contexts' do
      expect(Pages::Admin::Dashboard::Guard < ReactiveView::RouteGuard).to eq(true)
      expect(Pages::Admin::Dashboard::Guard.guards_for(:page)).to include(:require_authenticated_user!)
      expect(Pages::Admin::Dashboard::Guard.guards_for(:load)).to include(:require_authenticated_user!)
      expect(Pages::Admin::Dashboard::Guard.guards_for(:mutate)).to include(:require_authenticated_user!)
      expect(Pages::Admin::Dashboard::Guard.guards_for(:stream)).to include(:require_authenticated_user!)
    end
  end

  describe 'dashboard layout loader' do
    let(:loader) { Pages::Admin::DashboardLoader.new }

    it 'returns current_user profile data for layout UI' do
      allow(loader).to receive(:current_user).and_return(double('user', name: 'Alice', email: 'alice@example.com'))

      expect(loader.load).to eq({ name: 'Alice', email: 'alice@example.com' })
    end
  end

  describe 'loader fallback for protected routes without data loaders' do
    it 'uses ReactiveView::Loader for dashboard leaf pages without .loader.rb files' do
      expect(ReactiveView::LoaderRegistry.class_for_path('(admin)/dashboard/index')).to eq(ReactiveView::Loader)
      expect(ReactiveView::LoaderRegistry.class_for_path('(admin)/dashboard/settings')).to eq(ReactiveView::Loader)
      expect(ReactiveView::LoaderRegistry.class_for_path('(admin)/dashboard/reports/index')).to eq(ReactiveView::Loader)
      expect(ReactiveView::LoaderRegistry.class_for_path('(admin)/dashboard/reports/sources')).to eq(ReactiveView::Loader)
    end
  end
end
