# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReactiveView::FileSync::FileWatcher do
  let(:pages_path) { Pathname.new('/tmp/test_pages') }
  let(:working_dir) { Pathname.new('/tmp/test_working') }
  let(:mock_listener) { instance_double(Listen::Listener, start: nil, stop: nil) }

  before do
    allow(ReactiveView.configuration).to receive(:pages_absolute_path).and_return(pages_path)
    allow(ReactiveView.configuration).to receive(:working_directory_absolute_path).and_return(working_dir)
    allow(pages_path).to receive(:exist?).and_return(true)
    allow(Listen).to receive(:to).and_return(mock_listener)

    # Reset class state between tests
    described_class.instance_variable_set(:@listener, nil)
    described_class.instance_variable_set(:@pending, nil)
    described_class.instance_variable_set(:@debounce_thread, nil)
  end

  after do
    # Ensure listener is stopped after each test
    described_class.stop
  end

  describe '.start' do
    it 'starts a listener for the pages path' do
      expect(Listen).to receive(:to).with(pages_path.to_s).and_return(mock_listener)
      expect(mock_listener).to receive(:start)

      described_class.start
    end

    it 'does not start if pages path does not exist' do
      allow(pages_path).to receive(:exist?).and_return(false)
      expect(Listen).not_to receive(:to)

      described_class.start
    end

    it 'does not start a second listener if already running' do
      described_class.start

      expect(Listen).to have_received(:to).once

      described_class.start # Should be idempotent

      expect(Listen).to have_received(:to).once
    end

    it 'is thread-safe' do
      threads = 5.times.map do
        Thread.new { described_class.start }
      end
      threads.each(&:join)

      # Should only start once despite concurrent calls
      expect(Listen).to have_received(:to).once
    end
  end

  describe '.stop' do
    it 'stops the listener' do
      described_class.start
      expect(mock_listener).to receive(:stop)

      described_class.stop
    end

    it 'handles being called when not started' do
      expect { described_class.stop }.not_to raise_error
    end

    it 'is idempotent' do
      described_class.start
      expect(mock_listener).to receive(:stop).once

      described_class.stop
      described_class.stop # Should not raise
    end

    it 'kills any pending debounce thread' do
      described_class.start

      # Manually set a debounce thread
      debounce_thread = Thread.new { sleep 10 }
      described_class.instance_variable_set(:@debounce_thread, debounce_thread)

      described_class.stop

      debounce_thread.join(0.2)
      expect(debounce_thread).not_to be_alive
    end
  end

  describe 'debouncing behavior' do
    before do
      described_class.start
    end

    it 'deduplicates pending changes' do
      pending_mutex = described_class.send(:pending_mutex)

      # Simulate multiple changes to the same file
      pending_mutex.synchronize do
        pending = described_class.instance_variable_get(:@pending)
        pending[:modified] = ['/path/file.tsx', '/path/file.tsx', '/path/file.tsx']
        pending[:added] = ['/path/new.tsx', '/path/new.tsx']
        pending[:removed] = []
      end

      # Process changes directly (bypassing timer)
      allow(ReactiveView::FileSync::ComponentSyncer).to receive(:sync_file)

      described_class.send(:process_pending_changes)

      # The pending changes should have been processed and cleared
      pending = described_class.instance_variable_get(:@pending)
      expect(pending[:modified]).to be_empty
      expect(pending[:added]).to be_empty
    end

    it 'cancels out added and removed for same file' do
      pending_mutex = described_class.send(:pending_mutex)

      # File was added then removed - net no-op
      pending_mutex.synchronize do
        pending = described_class.instance_variable_get(:@pending)
        pending[:added] = ['/path/temp.tsx']
        pending[:removed] = ['/path/temp.tsx']
        pending[:modified] = []
      end

      # Should not sync files that net to no-op
      expect(ReactiveView::FileSync::ComponentSyncer).not_to receive(:sync_file)
      expect(ReactiveView::FileSync::ComponentSyncer).not_to receive(:remove_file)

      described_class.send(:process_pending_changes)
    end

    it 'batches rapid queue changes into one processing pass' do
      allow(described_class).to receive(:debounce_delay).and_return(0.01)
      allow(described_class).to receive(:handle_changes)

      described_class.send(:queue_changes, ["#{pages_path}/a.tsx"], [], [])
      described_class.send(:queue_changes, ["#{pages_path}/a.tsx", "#{pages_path}/b.tsx"], [], [])

      sleep 0.05

      expect(described_class).to have_received(:handle_changes).once
      expect(described_class).to have_received(:handle_changes).with(
        array_including("#{pages_path}/a.tsx", "#{pages_path}/b.tsx"),
        [],
        []
      )
    end
  end

  describe '.handle_changes' do
    before do
      described_class.start
      allow(ReactiveView::FileSync::ComponentSyncer).to receive(:sync_file)
      allow(ReactiveView::FileSync::ComponentSyncer).to receive(:remove_file)
      allow(ReactiveView::FileSync::WrapperGenerator).to receive(:generate_wrapper)
      allow(ReactiveView::FileSync::WrapperGenerator).to receive(:remove_wrapper)
      allow(ReactiveView::FileSync::WrapperGenerator).to receive(:regenerate_parent_layout)
      allow(ReactiveView::FileSync::ViteNotifier).to receive(:notify)
      allow(ReactiveView::FileSync::ViteNotifier).to receive(:loader_path_to_route)
      allow(ReactiveView::Types::TypescriptGenerator).to receive(:generate)
    end

    it 'handles empty changes without error' do
      expect { described_class.send(:handle_changes, [], [], []) }.not_to raise_error
    end

    it 'syncs modified asset files' do
      modified = ["#{pages_path}/index.tsx"]
      expect(ReactiveView::FileSync::ComponentSyncer).to receive(:sync_file).with(modified.first, pages_path)

      described_class.send(:handle_changes, modified, [], [])
    end

    it 'syncs added asset files and generates wrappers for TSX' do
      added = ["#{pages_path}/new.tsx"]
      expect(ReactiveView::FileSync::ComponentSyncer).to receive(:sync_file).with(added.first, pages_path)
      expect(ReactiveView::FileSync::WrapperGenerator).to receive(:generate_wrapper)
      expect(ReactiveView::FileSync::WrapperGenerator).to receive(:regenerate_parent_layout)

      described_class.send(:handle_changes, [], added, [])
    end

    it 'handles removed files and cleans up wrappers for TSX' do
      removed = ["#{pages_path}/old.tsx"]
      expect(ReactiveView::FileSync::ComponentSyncer).to receive(:remove_file)
      expect(ReactiveView::FileSync::WrapperGenerator).to receive(:remove_wrapper)
      expect(ReactiveView::FileSync::WrapperGenerator).to receive(:regenerate_parent_layout)

      described_class.send(:handle_changes, [], [], removed)
    end

    it 'does not generate wrappers for non-TSX files' do
      added = ["#{pages_path}/styles/main.css"]
      expect(ReactiveView::FileSync::ComponentSyncer).to receive(:sync_file)
      expect(ReactiveView::FileSync::WrapperGenerator).not_to receive(:generate_wrapper)

      described_class.send(:handle_changes, [], added, [])
    end

    it 'regenerates types for loader file changes' do
      modified = ["#{pages_path}/index.loader.rb"]
      allow(ReactiveView::FileSync::ViteNotifier).to receive(:loader_path_to_route).and_return('index')

      expect(ReactiveView::Types::TypescriptGenerator).to receive(:generate)
      expect(ReactiveView::FileSync::ViteNotifier).to receive(:notify)

      described_class.send(:handle_changes, modified, [], [])
    end

    it 'does not generate wrappers for TSX files in private folders' do
      added = ["#{pages_path}/_components/Button.tsx"]
      expect(ReactiveView::FileSync::ComponentSyncer).to receive(:sync_file)
      expect(ReactiveView::FileSync::WrapperGenerator).not_to receive(:generate_wrapper)

      described_class.send(:handle_changes, [], added, [])
    end

    it 'does not remove wrappers for TSX files in private folders' do
      removed = ["#{pages_path}/_components/Button.tsx"]
      expect(ReactiveView::FileSync::ComponentSyncer).to receive(:remove_file)
      expect(ReactiveView::FileSync::WrapperGenerator).not_to receive(:remove_wrapper)

      described_class.send(:handle_changes, [], [], removed)
    end

    it 'still syncs private files for imports to work' do
      added = ["#{pages_path}/_utils/helpers.ts"]
      expect(ReactiveView::FileSync::ComponentSyncer).to receive(:sync_file).with(added.first, pages_path)

      described_class.send(:handle_changes, [], added, [])
    end
  end

  describe 'DEBOUNCE_DELAY constant' do
    it 'is defined as 0.1 seconds' do
      expect(described_class::DEBOUNCE_DELAY).to eq(0.1)
    end
  end
end
