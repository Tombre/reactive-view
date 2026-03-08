# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::GuardRunner do
  let(:request) { ActionDispatch::Request.new(Rack::MockRequest.env_for('/dashboard/settings')) }

  describe '.run!' do
    it 'runs guard methods in registration order for the requested context' do
      calls = []

      parent_guard = Class.new(ReactiveView::RouteGuard) do
        guard :check_parent

        define_method(:check_parent) do
          calls << :parent
        end
      end

      child_guard = Class.new(ReactiveView::RouteGuard) do
        guard :check_child

        define_method(:check_child) do
          calls << :child
        end
      end

      allow(ReactiveView::GuardRegistry).to receive(:classes_for_loader_path)
        .with('(admin)/dashboard/settings')
        .and_return([parent_guard, child_guard])

      described_class.run!(
        loader_path: '(admin)/dashboard/settings',
        context: :load,
        request: request,
        params: ActionController::Parameters.new({})
      )

      expect(calls).to eq(%i[parent child])
    end

    it 'skips guards that do not apply to the requested context' do
      calls = []

      scoped_guard = Class.new(ReactiveView::RouteGuard) do
        guard :load_only, on: :load

        define_method(:load_only) do
          calls << :load
        end
      end

      allow(ReactiveView::GuardRegistry).to receive(:classes_for_loader_path)
        .with('dashboard/index')
        .and_return([scoped_guard])

      described_class.run!(
        loader_path: 'dashboard/index',
        context: :mutate,
        request: request,
        params: ActionController::Parameters.new({})
      )

      expect(calls).to eq([])
    end

    it 'raises GuardRejectedError when a guard redirects' do
      redirecting_guard = Class.new(ReactiveView::RouteGuard) do
        guard :require_auth

        def require_auth
          redirect_to '/login?next=%2Fdashboard%2Fsettings'
        end
      end

      allow(ReactiveView::GuardRegistry).to receive(:classes_for_loader_path)
        .with('dashboard/settings')
        .and_return([redirecting_guard])

      expect do
        described_class.run!(
          loader_path: 'dashboard/settings',
          context: :page,
          request: request,
          params: ActionController::Parameters.new({})
        )
      end.to raise_error(ReactiveView::GuardRejectedError) { |error|
        expect(error.redirect_path).to eq('/login?next=%2Fdashboard%2Fsettings')
      }
    end

    it 'maps errors with redirect_path to GuardRejectedError' do
      auth_error_class = Class.new(StandardError) do
        attr_reader :redirect_path

        def initialize
          @redirect_path = '/login'
          super('Authentication required')
        end
      end

      raising_guard = Class.new(ReactiveView::RouteGuard) do
        guard :require_auth

        define_method(:require_auth) do
          raise auth_error_class.new
        end
      end

      allow(ReactiveView::GuardRegistry).to receive(:classes_for_loader_path)
        .with('dashboard/settings')
        .and_return([raising_guard])

      expect do
        described_class.run!(
          loader_path: 'dashboard/settings',
          context: :load,
          request: request,
          params: ActionController::Parameters.new({})
        )
      end.to raise_error(ReactiveView::GuardRejectedError) { |error|
        expect(error.message).to eq('Authentication required')
        expect(error.redirect_path).to eq('/login')
      }
    end
  end
end
