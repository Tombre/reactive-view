# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::Benchmark::Statistics do
  describe '#initialize' do
    it 'sorts timings on initialization' do
      timings = [0.03, 0.01, 0.02]
      stats = described_class.new(timings)
      expect(stats.timings).to eq([0.01, 0.02, 0.03])
    end

    it 'handles empty arrays' do
      stats = described_class.new([])
      expect(stats.count).to eq(0)
    end
  end

  describe '#count' do
    it 'returns the number of samples' do
      stats = described_class.new([0.01, 0.02, 0.03])
      expect(stats.count).to eq(3)
    end
  end

  describe '#sum' do
    it 'returns total time in seconds' do
      stats = described_class.new([0.01, 0.02, 0.03])
      expect(stats.sum).to be_within(0.0001).of(0.06)
    end

    it 'returns 0 for empty array' do
      stats = described_class.new([])
      expect(stats.sum).to eq(0)
    end
  end

  describe '#mean' do
    it 'calculates the average' do
      stats = described_class.new([0.01, 0.02, 0.03])
      expect(stats.mean).to be_within(0.0001).of(0.02)
    end

    it 'returns 0 for empty array' do
      stats = described_class.new([])
      expect(stats.mean).to eq(0.0)
    end
  end

  describe '#median' do
    it 'returns the middle value for odd count' do
      stats = described_class.new([0.01, 0.02, 0.03])
      expect(stats.median).to eq(0.02)
    end

    it 'returns interpolated value for even count' do
      stats = described_class.new([0.01, 0.02, 0.03, 0.04])
      expect(stats.median).to be_within(0.0001).of(0.025)
    end
  end

  describe '#min' do
    it 'returns minimum value' do
      stats = described_class.new([0.03, 0.01, 0.02])
      expect(stats.min).to eq(0.01)
    end

    it 'returns 0 for empty array' do
      stats = described_class.new([])
      expect(stats.min).to eq(0.0)
    end
  end

  describe '#max' do
    it 'returns maximum value' do
      stats = described_class.new([0.03, 0.01, 0.02])
      expect(stats.max).to eq(0.03)
    end

    it 'returns 0 for empty array' do
      stats = described_class.new([])
      expect(stats.max).to eq(0.0)
    end
  end

  describe '#std_dev' do
    it 'calculates standard deviation' do
      stats = described_class.new([0.01, 0.02, 0.03])
      expect(stats.std_dev).to be_within(0.001).of(0.01)
    end

    it 'returns 0 for single value' do
      stats = described_class.new([0.02])
      expect(stats.std_dev).to eq(0.0)
    end

    it 'returns 0 for empty array' do
      stats = described_class.new([])
      expect(stats.std_dev).to eq(0.0)
    end
  end

  describe '#percentile' do
    let(:timings) { (1..100).map { |i| i / 1000.0 } } # 0.001 to 0.1 seconds
    let(:stats) { described_class.new(timings) }

    it 'returns 0 for empty array' do
      empty_stats = described_class.new([])
      expect(empty_stats.percentile(50)).to eq(0.0)
    end

    it 'returns the value for single item' do
      single_stats = described_class.new([0.05])
      expect(single_stats.percentile(50)).to eq(0.05)
    end

    it 'calculates p50 (median)' do
      expect(stats.percentile(50)).to be_within(0.001).of(0.0505)
    end

    it 'calculates p95' do
      expect(stats.percentile(95)).to be_within(0.001).of(0.095)
    end

    it 'calculates p99' do
      expect(stats.percentile(99)).to be_within(0.001).of(0.099)
    end
  end

  describe '#p95 and #p99' do
    let(:timings) { (1..100).map { |i| i / 1000.0 } }
    let(:stats) { described_class.new(timings) }

    it 'returns 95th percentile' do
      expect(stats.p95).to eq(stats.percentile(95))
    end

    it 'returns 99th percentile' do
      expect(stats.p99).to eq(stats.percentile(99))
    end
  end

  describe '#distribution_buckets' do
    it 'groups timings into buckets' do
      # Timings in seconds: 3ms, 8ms, 12ms, 18ms, 24ms
      # Using exclusive upper bounds: [lower, upper)
      timings = [0.003, 0.008, 0.012, 0.018, 0.024]
      stats = described_class.new(timings)

      buckets = stats.distribution_buckets([5, 10, 15, 20, 25])

      expect(buckets['<5ms']).to eq(1)      # 3ms
      expect(buckets['5-10ms']).to eq(1)    # 8ms
      expect(buckets['10-15ms']).to eq(1)   # 12ms
      expect(buckets['15-20ms']).to eq(1)   # 18ms
      expect(buckets['20-25ms']).to eq(1)   # 24ms
      expect(buckets['>25ms']).to eq(0)
    end

    it 'uses default buckets if not specified' do
      timings = [0.003, 0.008]
      stats = described_class.new(timings)
      buckets = stats.distribution_buckets

      expect(buckets.keys).to include('<5ms', '5-10ms')
    end

    it 'handles empty timings' do
      stats = described_class.new([])
      buckets = stats.distribution_buckets([5, 10])

      expect(buckets['<5ms']).to eq(0)
      expect(buckets['5-10ms']).to eq(0)
      expect(buckets['>10ms']).to eq(0)
    end
  end

  describe '#to_h' do
    it 'exports all statistics in milliseconds' do
      timings = [0.01, 0.02, 0.03] # 10ms, 20ms, 30ms
      stats = described_class.new(timings)
      hash = stats.to_h

      expect(hash[:count]).to eq(3)
      expect(hash[:mean_ms]).to eq(20.0)
      expect(hash[:median_ms]).to eq(20.0)
      expect(hash[:min_ms]).to eq(10.0)
      expect(hash[:max_ms]).to eq(30.0)
      expect(hash).to have_key(:std_dev_ms)
      expect(hash).to have_key(:p95_ms)
      expect(hash).to have_key(:p99_ms)
    end
  end

  describe '#to_ms' do
    it 'converts seconds to milliseconds' do
      stats = described_class.new([0.01])
      expect(stats.to_ms(0.015)).to eq(15.0)
    end

    it 'rounds to 2 decimal places' do
      stats = described_class.new([0.01])
      expect(stats.to_ms(0.01234567)).to eq(12.35)
    end
  end
end
