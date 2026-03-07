# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/controllers/reactive_view/loader_data_controller'

RSpec.describe ReactiveView::LoaderDataController do
  describe '#valid_mutation_method?' do
    let(:controller) { described_class.new }

    let(:base_loader_class) do
      Class.new(ReactiveView::Loader) do
        def inherited_mutation
          render_success
        end
      end
    end

    let(:loader_class) do
      Class.new(base_loader_class) do
        def mutate
          render_success
        end

        def update
          render_success
        end

        def stream
          render_success
        end

        private

        def hidden_mutation
          render_success
        end
      end
    end

    let(:loader) { loader_class.new }

    it 'allows mutation methods declared directly on the loader class' do
      expect(controller.send(:valid_mutation_method?, loader, :mutate)).to be(true)
      expect(controller.send(:valid_mutation_method?, loader, :update)).to be(true)
      expect(controller.send(:valid_mutation_method?, loader, :stream)).to be(true)
    end

    it 'blocks load and inherited framework/helper methods' do
      expect(controller.send(:valid_mutation_method?, loader, :load)).to be(false)
      expect(controller.send(:valid_mutation_method?, loader, :render_success)).to be(false)
      expect(controller.send(:valid_mutation_method?, loader, :mutation_redirect)).to be(false)
      expect(controller.send(:valid_mutation_method?, loader, :process)).to be(false)
    end

    it 'allows inherited custom mutation methods but blocks non-public methods' do
      expect(controller.send(:valid_mutation_method?, loader, :inherited_mutation)).to be(true)
      expect(controller.send(:valid_mutation_method?, loader, :hidden_mutation)).to be(false)
    end
  end

  describe '#handle_stream_error' do
    let(:controller) { described_class.new }
    let(:logger) { instance_double(Logger, debug: nil, error: nil) }

    before do
      allow(ReactiveView).to receive(:logger).and_return(logger)
    end

    it 'treats client disconnect as non-error noise' do
      error = IOError.new('client disconnected')

      controller.send(:handle_stream_error, error)

      expect(logger).to have_received(:debug).with('[ReactiveView] Stream closed by client during setup')
      expect(logger).not_to have_received(:error)
    end
  end

  describe '#validate_and_coerce_action_params!' do
    let(:controller) { described_class.new }

    let(:loader_class) do
      Class.new(ReactiveView::Loader) do
        params_shape do
          param :id, :integer
        end
      end
    end

    let(:loader) { loader_class.new }

    before do
      loader.params = ActionController::Parameters.new({ 'id' => '42', 'extra' => 'keep-me' })
    end

    it 'coerces configured action params and keeps unrelated keys' do
      controller.send(:validate_and_coerce_action_params!, loader_class, loader, :load)

      expect(loader.params[:id]).to eq(42)
      expect(loader.params[:extra]).to eq('keep-me')
    end

    it 'raises ValidationError when required params are missing' do
      loader.params = ActionController::Parameters.new({})

      expect do
        controller.send(:validate_and_coerce_action_params!, loader_class, loader, :load)
      end.to raise_error(ReactiveView::ValidationError)
    end
  end

  describe '#show' do
    let(:controller) { described_class.new }

    let(:loader_class) do
      Class.new(ReactiveView::Loader) do
        params_shape do
          param :id, :integer
        end

        def load
          { ok: true }
        end
      end
    end

    let(:loader) { loader_class.new }

    before do
      loader.params = ActionController::Parameters.new({})
      allow(ReactiveView::LoaderRegistry).to receive(:class_for_path).and_return(loader_class)
      allow(controller).to receive(:loader_path).and_return('test')
      allow(controller).to receive(:build_loader).and_return(loader)
      allow(controller).to receive(:render)
    end

    it 'renders 422 when load params fail validation' do
      controller.show

      expect(controller).to have_received(:render).with(
        json: hash_including(:error),
        status: :unprocessable_entity
      )
    end
  end

  describe '#mutate' do
    let(:controller) { described_class.new }

    let(:loader_class) do
      Class.new(ReactiveView::Loader) do
        params_shape :update do
          param :name
        end

        def update
          render_success
        end
      end
    end

    let(:loader) { loader_class.new }

    before do
      loader.params = ActionController::Parameters.new({})
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new({ '_mutation' => 'update' }))
      allow(ReactiveView::LoaderRegistry).to receive(:class_for_path).and_return(loader_class)
      allow(controller).to receive(:loader_path).and_return('test')
      allow(controller).to receive(:build_loader).and_return(loader)
      allow(controller).to receive(:render)
    end

    it 'renders 422 when mutation params fail validation' do
      controller.mutate

      expect(controller).to have_received(:render).with(
        json: hash_including(success: false, error: kind_of(String)),
        status: :unprocessable_entity
      )
    end
  end
end
