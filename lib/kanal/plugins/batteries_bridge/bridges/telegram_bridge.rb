# frozen_string_literal: true

require "kanal"
require_relative "./bridge"

module Kanal
  module Plugins
    module BatteriesBridge
      module Bridges
        class TelegramBridge < Bridge
          include Kanal::Plugins::Batteries::Attachments

          def setup
            require_source :telegram

            input_convert :tg_text, :body do |val|
              val
            end

            input_convert :tg_image_link, :image do |val|
              Attachment.new val
            end

            input_convert :tg_audio_link, :audio do |val|
              Attachment.new val
            end

            output_convert :image, :tg_image_path do |val|
              val
            end

            output_convert :audio, :tg_audio_path do |val|
              val
            end

            output_convert :body, :tg_text do |val|
              val
            end

            output_convert :file, :tg_document_path do |val|
              val
            end
          end
        end
      end
    end
  end
end
