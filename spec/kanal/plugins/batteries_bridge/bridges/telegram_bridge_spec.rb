# frozen_string_literal: true

require "kanal/plugins/batteries/batteries_plugin"
require_relative "../../../../../lib/kanal/plugins/batteries_bridge/bridges/telegram_bridge"

RSpec.describe Kanal::Plugins::BatteriesBridge::Bridges::TelegramBridge do
  it "successfully converts parameters to telegram bridge parameters" do
    core = Kanal::Core::Core.new

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

    # Old version of kanal without document parameter in batteries used
    # Instead kanal provides file parameter - which is obsolete
    core.register_input_parameter :document
    core.register_output_parameter :document

    core.register_input_parameter :tg_text, readonly: true
    core.register_input_parameter :tg_image_link, readonly: true
    core.register_input_parameter :tg_audio_link, readonly: true

    core.register_output_parameter :tg_text
    core.register_output_parameter :tg_reply_markup
    core.register_output_parameter :tg_image_path
    core.register_output_parameter :tg_audio_path
    core.register_output_parameter :tg_document_path

    core.router.default_response do
      body "Default response"
    end

    bb_plugin = Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin.new

    bb_plugin.add_bridge Kanal::Plugins::BatteriesBridge::Bridges::TelegramBridge.new
    bb_plugin.fail_loud

    core.register_plugin bb_plugin

    core.router.configure do
      on :flow, :any do
        respond do
          body "Output text"
          image "/some/path/to/image.jpg"
          audio "/some/path/to/audio.mp3"
          keyboard.build do
            row "First", "Second"
          end
        end
      end
    end

    input_conversion_check = lambda do |inp|
      expect(inp.body).to eq "Input text"
      expect(inp.image.class).to eq Kanal::Plugins::Batteries::Attachments::Attachment
      expect(inp.image.url).to eq "https://something.com/image.jpg"
      expect(inp.image.class).to eq Kanal::Plugins::Batteries::Attachments::Attachment
      expect(inp.audio.url).to eq "https://something.com/audio.mp3"
    end

    core.hooks.attach :input_before_router do |input|
      input_conversion_check.call input
    end

    output = nil

    core.router.output_ready do |o|
      output = o
    end

    input = core.create_input
    input.source = :telegram
    input.tg_text = "Input text"
    input.tg_image_link = "https://something.com/image.jpg"
    input.tg_audio_link = "https://something.com/audio.mp3"

    core.router.consume_input input

    expect(output.tg_text).to eq "Output text"
    expect(output.tg_image_path).to eq "/some/path/to/image.jpg"
    expect(output.tg_audio_path).to eq "/some/path/to/audio.mp3"
    expect(output.tg_reply_markup.to_a).to eq [["First", "Second"]]
  end
end

