# frozen_string_literal: true

require "kanal/plugins/batteries/batteries_plugin"
require_relative "../../../../../lib/kanal/plugins/batteries_bridge/bridges/telegram_bridge"

RSpec.describe Kanal::Plugins::BatteriesBridge::Bridges::TelegramBridge do
  it "successfully converts parameters to telegram bridge parameters" do
    core = Kanal::Core::Core.new

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

    core.register_input_parameter :tg_text, readonly: true
    core.register_input_parameter :tg_image_link, readonly: true
    core.register_input_parameter :tg_audio_link, readonly: true
    core.register_input_parameter :tg_video_link, readonly: true
    core.register_input_parameter :tg_document_link, readonly: true
    core.register_input_parameter :tg_button_pressed

    core.register_output_parameter :tg_text
    core.register_output_parameter :tg_reply_markup
    core.register_output_parameter :tg_image_path
    core.register_output_parameter :tg_audio_path
    core.register_output_parameter :tg_video_path
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
          video "/some/path/to/video.mp4"
          document "/some/path/to/document.doc"
          keyboard.build do
            row "First", "Second"
          end
        end
      end
    end

    input_conversion_check = lambda do |inp|
      expect(inp.body).to eq "Test"
      expect(inp.image.class).to eq Kanal::Plugins::Batteries::Attachments::Attachment
      expect(inp.image.url).to eq "https://something.com/image.jpg"
      expect(inp.audio.class).to eq Kanal::Plugins::Batteries::Attachments::Attachment
      expect(inp.audio.url).to eq "https://something.com/audio.mp3"
      expect(inp.video.class).to eq Kanal::Plugins::Batteries::Attachments::Attachment
      expect(inp.video.url).to eq "https://something.com/video.mp4"
      expect(inp.document.class).to eq Kanal::Plugins::Batteries::Attachments::Attachment
      expect(inp.document.url).to eq "https://something.com/document.doc"
      expect(inp.button_pressed).to eq "Button pressed"
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
    input.tg_text = "Test"
    input.tg_image_link = "https://something.com/image.jpg"
    input.tg_audio_link = "https://something.com/audio.mp3"
    input.tg_video_link = "https://something.com/video.mp4"
    input.tg_document_link = "https://something.com/document.doc"
    input.tg_button_pressed = "Button pressed"

    core.router.consume_input input

    expect(output.tg_text).to eq "Output text"
    expect(output.tg_image_path).to eq "/some/path/to/image.jpg"
    expect(output.tg_audio_path).to eq "/some/path/to/audio.mp3"
    expect(output.tg_video_path).to eq "/some/path/to/video.mp4"
    expect(output.tg_document_path).to eq "/some/path/to/document.doc"
    expect(output.tg_reply_markup.instance_of?(::Telegram::Bot::Types::InlineKeyboardMarkup)).to eq true
  end
end

