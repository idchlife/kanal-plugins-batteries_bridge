# frozen_string_literal: true

require "kanal"
require_relative "./bridges/telegram_bridge"

module Kanal
  module Plugins
    module BatteriesBridge
      #
      # Plugin registers all needed hooks to process
      #
      class BatteriesBridgePlugin < Kanal::Core::Plugins::Plugin
        include Kanal::Core::Logging
        include Bridges

        def initialize
          super

          @bridges = []
        end

        def name
          :batteries_bridge
        end

        #
        # @param [Bridge] bridge <description>
        #
        # @return [BatteriesBridgePlugin] <description>
        #
        def add_bridge(bridge)
          raise "bridge should be instance of a Bridge class" unless bridge.is_a? Bridge

          return if @bridges.include? bridge

          @bridges << bridge
          self
        end

        #
        # <Description>
        #
        # @return [BatteriesBridgePlugin] <description>
        #
        def add_telegram
          add_bridge TelegramBridge.new
          self
        end

        #
        # @param [Kanal::Core::Core] core <description>
        #
        # @return [void] <description>
        #
        def setup(core)
          unless core.plugin_registered? :batteries
            raise "[Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin]: cannot register plugin because :batteries plugin is not (maybe yet) registered in the core. It is required"
          end

          @bridges.each do |b|
            b.send("internal_setup", core.hooks)
          end
        end
      end
    end
  end
end
