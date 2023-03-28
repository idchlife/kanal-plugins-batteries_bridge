# frozen_string_literal: true

require "kanal/plugins/batteries/batteries_plugin"
require_relative "../../../../../lib/kanal/plugins/batteries_bridge/bridges/telegram_bridge"

RSpec.describe Kanal::Plugins::BatteriesBridge::Bridges::TelegramBridge do
  it "successfully converts parameters to telegram bridge parameters" do
    core = Kanal::Core::Core.new

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

    # TODO: kanal of version 0.4.1 doesn't have document, video, button_pressed parameters
    # TODO: Remove parameters below on Kanal update
    core.register_input_parameter :document, readonly: true
    core.register_output_parameter :document, readonly: true
    core.register_input_parameter :video, readonly: true
    core.register_output_parameter :video, readonly: true
    core.register_input_parameter :button_pressed, readonly: true

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

    # TODO: kanal of version 0.4.1 doesn't have button_pressed condition pack in batteries
    # TODO: Remove condition pack below on Kanal update
    core.add_condition_pack :button_pressed do
      add_condition :contains do
        met? do |input, _core, _argument|
          input.button_pressed.include?(_argument)
        end
      end
    end

    core.router.default_response do
      body "Default response"
    end

    bb_plugin = Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin.new

    bb_plugin.add_bridge Kanal::Plugins::BatteriesBridge::Bridges::TelegramBridge.new
    bb_plugin.fail_loud

    core.register_plugin bb_plugin

    core.router.configure do
      on :body, contains: "Test" do
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

      on :button_pressed, contains: "Clicked button" do
        respond do
          body "You clicked on a button"
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

    core.router.consume_input input

    expect(output.tg_text).to eq "Output text"
    expect(output.tg_image_path).to eq "/some/path/to/image.jpg"
    expect(output.tg_audio_path).to eq "/some/path/to/audio.mp3"
    expect(output.tg_video_path).to eq "/some/path/to/video.mp4"
    expect(output.tg_document_path).to eq "/some/path/to/document.doc"
    expect(output.tg_reply_markup.to_a).to eq [["First", "Second"]]

    input_conversion_check = lambda do |inp|
      expect(inp.button_pressed).to eq "Clicked button"
    end

    core.hooks.attach :input_before_router do |input|
      input_conversion_check.call input
    end

    input = core.create_input
    input.source = :telegram
    input.tg_button_pressed = "Clicked button"
    core.router.consume_input input
    expect(output.body).to eq "You clicked on a button"
  end
end

