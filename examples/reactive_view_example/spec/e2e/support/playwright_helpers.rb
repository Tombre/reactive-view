require 'playwright'

module E2E
  module PlaywrightHelpers
    def with_page
      Playwright.create(playwright_cli_executable_path: playwright_cli) do |playwright|
        playwright.chromium.launch(headless: headless?) do |browser|
          context = browser.new_context
          page = context.new_page

          begin
            yield page
          ensure
            context.close
          end
        end
      end
    end

    private

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
