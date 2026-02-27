require_relative 'e2e_helper'

RSpec.describe 'ReactiveView streaming mutations', type: :e2e do
  it 'returns SSE json/done events from the stream endpoint' do
    with_page do |page|
      page.goto("#{e2e_base_url}/ai/chat")
      page.wait_for_selector('text=AI Chat')
      page.wait_for_selector('text=simulated AI assistant')
      page.wait_for_selector('text=Model: reactive-view-demo-v1')

      payload = page.evaluate(
        <<~JS,
          async ({ prompt }) => {
            const token = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
            const response = await fetch("/_reactive_view/loaders/ai/chat/stream?_mutation=generate", {
              method: "POST",
              headers: {
                "Accept": "text/event-stream",
                "Content-Type": "application/json",
                "X-CSRF-Token": token || ""
              },
              credentials: "include",
              body: JSON.stringify({ prompt })
            });

            if (!response.ok) {
              throw new Error(`Unexpected status ${response.status}`);
            }

            return await response.text();
          }
        JS
        arg: { prompt: 'Explain ReactiveView streaming' }
      )

      expect(payload).to include('"type":"json"')
      expect(payload).to include('"type":"done"')
      expect(payload).to include('"word"')
    end
  end
end
