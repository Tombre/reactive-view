# frozen_string_literal: true

module Pages
  module Ai
    class ChatLoader < ReactiveView::Loader
      shape :load do
        param :greeting, ReactiveView::Types::String
        param :model, ReactiveView::Types::String
      end

      shape :generate do
        param :prompt, ReactiveView::Types::String
      end

      def load
        {
          greeting: "Hello! I'm a simulated AI assistant. Ask me anything!",
          model: "reactive-view-demo-v1"
        }
      end

      def generate
        prompt = shapes.generate(params)[:prompt]

        render_stream do |out|
          # Simulate AI response with delayed token generation
          response_text = generate_response(prompt)
          words = response_text.split(" ")

          words.each_with_index do |word, i|
            sleep(rand(0.03..0.08)) # Simulate variable token latency
            separator = i < words.length - 1 ? " " : ""
            out << "#{word}#{separator}"
          end

          # Send metadata at the end (like token usage)
          out.json({
            usage: {
              prompt_tokens: prompt.split(" ").length,
              completion_tokens: words.length,
              model: "reactive-view-demo-v1"
            }
          })
        end
      end

      private

      def generate_response(prompt)
        responses = [
          "That's an interesting question! Let me think about this carefully. " \
          "Based on my analysis, I'd say the key factors to consider are the context " \
          "of your question, the underlying assumptions, and the practical implications. " \
          "I hope this perspective is helpful for your understanding.",

          "Great question! Here's what I know about that topic. " \
          "The fundamental concept revolves around understanding how different components " \
          "interact with each other in a system. When you break it down step by step, " \
          "the solution becomes much clearer. Let me know if you'd like more details.",

          "I appreciate you asking about that! This is a topic I find fascinating. " \
          "The short answer is that it depends on your specific use case and requirements. " \
          "However, I can share some general principles that tend to apply across " \
          "most situations. Would you like me to elaborate on any particular aspect?"
        ]

        responses.sample
      end
    end
  end
end
