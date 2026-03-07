# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../spec_helper'

RSpec.describe Pages::Admin::Auth::RegisterLoader do
  let(:email) { 'retry@example.com' }
  let(:session_data) { {} }
  let(:existing_user) { instance_double(User, id: 42) }
  let(:rodauth) { instance_double('RodauthMainInternal') }

  let(:loader) do
    described_class.new.tap do |instance|
      allow(instance).to receive(:params).and_return(
        ActionController::Parameters.new(name: 'Retry User', email: email)
      )
      allow(instance).to receive(:session).and_return(session_data)
      allow(instance).to receive(:rodauth_internal_options) { |options = {}| options }
    end
  end

  before do
    stub_const('Rodauth::InternalRequestError', Class.new(StandardError))

    allow(RodauthApp).to receive(:rodauth).and_return(rodauth)
    allow(rodauth).to receive(:create_account).and_raise(Rodauth::InternalRequestError.new('duplicate'))
    allow(User).to receive(:find_by).with(email: email).and_return(existing_user)
    allow(AccountWebauthnKey).to receive(:where).with(account_id: existing_user.id).and_return(
      instance_double(ActiveRecord::Relation, exists?: false)
    )
    allow(rodauth).to receive(:webauthn_setup_params).and_return(
      webauthn_setup: { challenge: 'challenge-json' },
      webauthn_setup_challenge: 'challenge-token',
      webauthn_setup_challenge_hmac: 'hmac-token'
    )
  end

  it 'allows registration retry when account exists without passkey and no user is signed in' do
    allow(loader).to receive(:current_user).and_return(nil)

    result = loader.begin_register

    expect(result).to be_a(ReactiveView::MutationResult)
    expect(result.success?).to eq(true)
    expect(result.to_json_hash).to include(
      success: true,
      email: email,
      challenge: 'challenge-token',
      challenge_hmac: 'hmac-token'
    )
    expect(session_data[:pending_webauthn_account_id]).to eq(existing_user.id)
    expect(rodauth).to have_received(:webauthn_setup_params).with(hash_including(account_id: existing_user.id))
  end

  it 'rejects retry when another user is signed in' do
    allow(loader).to receive(:current_user).and_return(instance_double(User, id: 99))
    allow(loader).to receive(:rodauth_error_message).and_return('duplicate')

    result = loader.begin_register

    expect(result.error?).to eq(true)
    expect(result.to_json_hash).to eq(success: false, errors: { base: ['duplicate'] })
    expect(rodauth).not_to have_received(:webauthn_setup_params)
    expect(session_data[:pending_webauthn_account_id]).to be_nil
  end
end
