require 'playwright'
require 'uri'

module E2E
  module PlaywrightHelpers
    def with_page(context_options: {}, page_options: {})
      Playwright.create(playwright_cli_executable_path: playwright_cli) do |playwright|
        playwright.chromium.launch(headless: headless?) do |browser|
          context = browser.new_context(**context_options)
          page = context.new_page(**page_options)

          begin
            yield page
          ensure
            context.close
          end
        end
      end
    end

    private

    def wait_for_path(page, expected_path, timeout: 10)
      wait_until(timeout: timeout) do
        URI(page.url).path == expected_path
      end
    end

    def wait_for_url_includes(page, expected_fragment, timeout: 10)
      wait_until(timeout: timeout) do
        page.url.include?(expected_fragment)
      end
    end

    def wait_until(timeout: 10)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

      loop do
        return if yield

        raise "Condition not met within #{timeout}s" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

        sleep 0.05
      end
    end

    def e2e_base_url
      ENV.fetch('E2E_BASE_URL', 'http://127.0.0.1:3000')
    end

    def playwright_cli
      ENV.fetch('PLAYWRIGHT_CLI', 'npx playwright')
    end

    def headless?
      ENV.fetch('PLAYWRIGHT_HEADLESS', '1') != '0'
    end
  end
end
