# frozen_string_literal: true

require "kanal"
require "kanal/plugins/batteries/attachments/attachment"
require_relative "./bridge"
require "telegram/bot"

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

            input_convert :tg_username, :username do |val|
              val
            end

            input_convert :tg_button_pressed, :button_pressed do |val|
              val
            end

            input_convert :tg_image_link, :image do |val|
              Attachment.new val
            end

            input_convert :tg_audio_link, :audio do |val|
              Attachment.new val
            end

            input_convert :tg_video_link, :video do |val|
              Attachment.new val
            end

            input_convert :tg_document_link, :document do |val|
              Attachment.new val
            end

            output_convert :body, :tg_text do |val|
              val
            end

            output_convert :image, :tg_image_path do |val|
              val
            end

            output_convert :audio, :tg_audio_path do |val|
              val
            end

            output_convert :video, :tg_video_path do |val|
              val
            end

            output_convert :document, :tg_document_path do |val|
              val
            end

            output_convert :keyboard, :tg_reply_markup do |keyboard_object, input, output|
              nil if keyboard_object.nil? || !keyboard_object.to_a.count.positive?

              if output.specifics.get :tg_reply_keyboard
                regular_keyboard = []

                keyboard_object.to_a.each do |row_of_button_names|
                  row_of_buttons = []

                  row_of_button_names.each do |button_name|
                    row_of_buttons << Telegram::Bot::Types::KeyboardButton.new(text: button_name)
                  end

                  regular_keyboard << row_of_buttons
                end

                Telegram::Bot::Types::ReplyKeyboardMarkup.new keyboard: regular_keyboard
              else
                inline_keyboard = []

                keyboard_object.to_a.each do |row_of_button_names|
                  row_of_buttons = []

                  row_of_button_names.each do |button_name|
                    row_of_buttons << Telegram::Bot::Types::InlineKeyboardButton.new(text: button_name, callback_data: button_name)
                  end

                  inline_keyboard << row_of_buttons
                end

                Telegram::Bot::Types::InlineKeyboardMarkup.new inline_keyboard: inline_keyboard
              end
            end
          end
        end
      end
    end
  end
end
