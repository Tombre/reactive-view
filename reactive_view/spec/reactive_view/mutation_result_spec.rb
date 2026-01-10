# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::MutationResult do
  describe '.success' do
    it 'creates a success result' do
      result = described_class.success

      expect(result.type).to eq(:success)
      expect(result.success?).to be true
      expect(result.error?).to be false
      expect(result.redirect?).to be false
      expect(result.status).to eq(200)
    end

    it 'includes data in the result' do
      result = described_class.success(user: { id: 1, name: 'John' })

      expect(result.data).to eq(user: { id: 1, name: 'John' })
    end

    it 'extracts revalidate from data' do
      result = described_class.success(user: { id: 1 }, revalidate: ['users/index'])

      expect(result.data).to eq(user: { id: 1 })
      expect(result.revalidate).to eq(['users/index'])
    end

    it 'converts to JSON hash' do
      result = described_class.success(user: { id: 1 }, revalidate: ['users/index'])
      json = result.to_json_hash

      expect(json[:success]).to be true
      expect(json[:user]).to eq(id: 1)
      expect(json[:revalidate]).to eq(['users/index'])
    end

    it 'omits revalidate from JSON when empty' do
      result = described_class.success(user: { id: 1 })
      json = result.to_json_hash

      expect(json).not_to have_key(:revalidate)
    end
  end

  describe '.error' do
    it 'creates an error result' do
      result = described_class.error(name: ["can't be blank"])

      expect(result.type).to eq(:error)
      expect(result.error?).to be true
      expect(result.success?).to be false
      expect(result.redirect?).to be false
      expect(result.status).to eq(422)
    end

    it 'normalizes hash errors' do
      result = described_class.error(name: "can't be blank")

      expect(result.errors).to eq(name: ["can't be blank"])
    end

    it 'normalizes string errors' do
      result = described_class.error('Something went wrong')

      expect(result.errors).to eq(base: ['Something went wrong'])
    end

    it 'normalizes model errors' do
      model = double(errors: double(to_hash: { email: ['is invalid'] }))
      result = described_class.error(model)

      expect(result.errors).to eq(email: ['is invalid'])
    end

    it 'handles model with messages method' do
      model = double(errors: double(messages: { name: ['is required'] }))
      allow(model.errors).to receive(:respond_to?).with(:to_hash).and_return(false)
      allow(model.errors).to receive(:respond_to?).with(:messages).and_return(true)

      result = described_class.error(model)

      expect(result.errors).to eq(name: ['is required'])
    end

    it 'converts to JSON hash' do
      result = described_class.error(name: ["can't be blank"])
      json = result.to_json_hash

      expect(json[:success]).to be false
      expect(json[:errors]).to eq(name: ["can't be blank"])
    end
  end

  describe '.redirect' do
    it 'creates a redirect result' do
      result = described_class.redirect('/users')

      expect(result.type).to eq(:redirect)
      expect(result.redirect?).to be true
      expect(result.success?).to be false
      expect(result.error?).to be false
      expect(result.status).to eq(200)
    end

    it 'stores the redirect path' do
      result = described_class.redirect('/users')

      expect(result.redirect_path).to eq('/users')
    end

    it 'stores revalidate paths' do
      result = described_class.redirect('/users', revalidate: ['users/index'])

      expect(result.revalidate).to eq(['users/index'])
    end

    it 'converts string revalidate to array' do
      result = described_class.redirect('/users', revalidate: 'users/index')

      expect(result.revalidate).to eq(['users/index'])
    end

    it 'converts to JSON hash' do
      result = described_class.redirect('/users', revalidate: ['users/index'])
      json = result.to_json_hash

      expect(json[:_redirect]).to eq('/users')
      expect(json[:_revalidate]).to eq(['users/index'])
    end
  end
end
