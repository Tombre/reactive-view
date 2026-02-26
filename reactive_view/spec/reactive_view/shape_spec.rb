# frozen_string_literal: true

require "spec_helper"

RSpec.describe ReactiveView::Shape do
  describe "class-level DSL" do
    it "defines a shape via the shape block" do
      shape_class = Class.new(described_class) do
        shape do
          param :name
          param :email
        end
      end

      expect(shape_class._shape_builder_block).to be_a(Proc)
    end

    it "builds a dry schema from the block" do
      shape_class = Class.new(described_class) do
        shape do
          param :id, :integer
          param :name
        end
      end

      schema = shape_class.dry_schema
      expect(schema).to respond_to(:keys)
      expect(schema.keys.map(&:name)).to contain_exactly(:id, :name)
    end

    it "returns Types::Hash for shapes with no block" do
      shape_class = Class.new(described_class)
      expect(shape_class.dry_schema).to eq(ReactiveView::Types::Hash)
    end
  end

  describe ".call" do
    let(:shape_class) do
      Class.new(described_class) do
        shape do
          param :id, :integer
          param :name
        end
      end
    end

    it "returns a shape instance" do
      result = shape_class.call(id: 1, name: "Alice")
      expect(result).to be_a(described_class)
    end

    it "validates and coerces valid data" do
      result = shape_class.call(id: 1, name: "Alice")

      expect(result.valid?).to be true
      expect(result.success?).to be true
      expect(result.data).to eq({id: 1, name: "Alice"})
      expect(result.errors).to eq({})
    end

    it "coerces string params to expected types" do
      result = shape_class.call("id" => "42", "name" => "Bob")

      expect(result.valid?).to be true
      expect(result.data[:id]).to eq(42)
      expect(result.data[:id]).to be_a(Integer)
      expect(result.data[:name]).to eq("Bob")
    end

    it "filters out params not in the schema" do
      result = shape_class.call("id" => "1", "name" => "Alice", "extra" => "ignored", "_csrf" => "token")

      expect(result.valid?).to be true
      expect(result.data.keys).to contain_exactly(:id, :name)
    end

    it "returns failure for invalid data" do
      result = shape_class.call(id: "not_an_integer", name: 123)

      # The coercion tries to_i on the string, which yields 0
      # But name: 123 should fail type checking
      expect(result.failure?).to be true
      expect(result.errors).not_to be_empty
    end

    it "handles nil input" do
      result = shape_class.call(nil)
      expect(result).to be_a(described_class)
    end

    it "handles empty input" do
      result = shape_class.call({})
      expect(result).to be_a(described_class)
    end
  end

  describe ".call!" do
    let(:shape_class) do
      Class.new(described_class) do
        shape do
          param :id, :integer
          param :name
        end
      end
    end

    it "returns a valid shape instance for valid data" do
      result = shape_class.call!(id: 1, name: "Alice")

      expect(result.valid?).to be true
      expect(result.data).to eq({id: 1, name: "Alice"})
    end

    it "raises ValidationError for invalid data" do
      expect {
        shape_class.call!(id: 1, name: 123)
      }.to raise_error(ReactiveView::ValidationError)
    end
  end

  describe "instance behavior" do
    let(:shape_class) do
      Class.new(described_class) do
        shape do
          param :id, :integer
          param :name
        end
      end
    end

    it "creates an instance via new" do
      instance = shape_class.new(id: 1, name: "Alice")

      expect(instance.valid?).to be true
      expect(instance.data).to eq({id: 1, name: "Alice"})
    end

    it "normalizes ActionController::Parameters-like objects" do
      params_class = Class.new do
        def initialize(hash)
          @hash = hash
        end

        def to_unsafe_h
          @hash
        end
      end

      params = params_class.new({"id" => "5", "name" => "Bob"})
      instance = shape_class.new(params)

      expect(instance.valid?).to be true
      expect(instance.data[:id]).to eq(5)
      expect(instance.data[:name]).to eq("Bob")
    end
  end

  describe "type coercion" do
    context "with boolean fields" do
      let(:shape_class) do
        Class.new(described_class) do
          shape do
            param :enabled, :boolean
          end
        end
      end

      it "coerces truthy string values" do
        %w[true 1 yes on].each do |value|
          result = shape_class.call("enabled" => value)
          expect(result.data[:enabled]).to eq(true), "Expected '#{value}' to coerce to true"
        end
      end

      it "coerces falsy string values" do
        %w[false 0 no off].each do |value|
          result = shape_class.call("enabled" => value)
          expect(result.data[:enabled]).to eq(false), "Expected '#{value}' to coerce to false"
        end
      end

      it "preserves native boolean values" do
        expect(shape_class.call(enabled: true).data[:enabled]).to eq(true)
        expect(shape_class.call(enabled: false).data[:enabled]).to eq(false)
      end
    end

    context "with float fields" do
      let(:shape_class) do
        Class.new(described_class) do
          shape do
            param :price, :float
          end
        end
      end

      it "coerces string to float" do
        result = shape_class.call("price" => "3.14")
        expect(result.data[:price]).to eq(3.14)
        expect(result.data[:price]).to be_a(Float)
      end

      it "preserves native float values" do
        result = shape_class.call(price: 2.99)
        expect(result.data[:price]).to eq(2.99)
      end
    end

    context "with integer fields" do
      let(:shape_class) do
        Class.new(described_class) do
          shape do
            param :count, :integer
          end
        end
      end

      it "coerces string to integer" do
        result = shape_class.call("count" => "42")
        expect(result.data[:count]).to eq(42)
        expect(result.data[:count]).to be_a(Integer)
      end

      it "preserves native integer values" do
        result = shape_class.call(count: 7)
        expect(result.data[:count]).to eq(7)
      end
    end
  end

  describe "structured errors" do
    let(:shape_class) do
      Class.new(described_class) do
        shape do
          param :id, :integer
          param :name
        end
      end
    end

    it "returns field-level errors as a hash" do
      result = shape_class.call(id: 1, name: 123)
      expect(result.errors).to be_a(Hash)
      expect(result.errors.values.flatten).to all(be_a(String))
    end

    it "returns empty errors for valid data" do
      result = shape_class.call(id: 1, name: "Alice")
      expect(result.errors).to eq({})
    end
  end

  describe "collection fields" do
    let(:shape_class) do
      Class.new(described_class) do
        shape do
          param :id, :integer
          collection :pets do
            param :name
            param :species
          end
        end
      end
    end

    it "validates collection data" do
      result = shape_class.call(
        id: 1,
        pets: [
          {name: "Fido", species: "dog"},
          {name: "Whiskers", species: "cat"}
        ]
      )

      expect(result.valid?).to be true
      expect(result.data[:pets]).to be_an(Array)
      expect(result.data[:pets].length).to eq(2)
      expect(result.data[:pets].first[:name]).to eq("Fido")
    end

    it "coerces collection elements from string keys" do
      result = shape_class.call(
        "id" => "1",
        "pets" => [
          {"name" => "Fido", "species" => "dog"}
        ]
      )

      expect(result.data[:id]).to eq(1)
      expect(result.data[:pets]).to be_an(Array)
    end
  end

  describe "hash fields" do
    let(:shape_class) do
      Class.new(described_class) do
        shape do
          hash :contact do
            param :email
            param :phone
          end
        end
      end
    end

    it "validates nested hash data" do
      result = shape_class.call(
        contact: {email: "a@b.com", phone: "555-1234"}
      )

      expect(result.valid?).to be true
      expect(result.data[:contact][:email]).to eq("a@b.com")
    end

    it "coerces nested hash from string keys" do
      result = shape_class.call(
        "contact" => {"email" => "a@b.com", "phone" => "555-1234"}
      )

      expect(result.data[:contact][:email]).to eq("a@b.com")
    end
  end

  describe "standalone shape class" do
    # Simulates a user-defined shape class
    let(:user_shape) do
      Class.new(described_class) do
        shape do
          param :id, :integer
          param :name
          param :email
        end
      end
    end

    it "can be used independently of a loader" do
      result = user_shape.call(id: "1", name: "Alice", email: "alice@example.com")

      expect(result.valid?).to be true
      expect(result.data[:id]).to eq(1)
      expect(result.data[:name]).to eq("Alice")
    end

    it "supports .call! for raising validation" do
      result = user_shape.call!(id: 1, name: "Alice", email: "alice@example.com")
      expect(result.data[:email]).to eq("alice@example.com")
    end
  end
end
