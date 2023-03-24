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
          @fail_gracefully = true
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

          bridge.fail_gracefully = @fail_gracefully

          @bridges << bridge
          self
        end

        #
        # When bridge converter raises an error, raise it instead of swallowing (logs will be written in both cases)
        #
        # @return [void] <description>
        #
        def fail_loud
          @fail_gracefully = false
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
