# frozen_string_literal: true

require "spec_helper"

RSpec.describe ReactiveView::StreamResponse do
  describe "#initialize" do
    it "stores the block" do
      block = proc { |out| out << "hello" }
      response = described_class.new(block)
      expect(response.block).to eq(block)
    end
  end

  describe "#block" do
    it "returns the stored block" do
      block = proc { |out| out << "hello" }
      response = described_class.new(block)
      expect(response.block).to be_a(Proc)
    end

    it "can be called with a writer" do
      output = []
      block = proc { |out| output << out }
      response = described_class.new(block)
      response.block.call("writer")
      expect(output).to eq(["writer"])
    end
  end
end
