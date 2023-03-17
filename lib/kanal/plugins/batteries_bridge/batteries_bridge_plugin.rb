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

        def initialize(bridges: [])
          super

          @available_bridges = {
            telegram: TelegramBridge
          }

          @bridges_to_register = bridges
        end

        def name
          :batteries_bridge
        end

        #
        # @param [Kanal::Core::Core] core <description>
        #
        # @return [void] <description>
        #
        def setup(core)
          unless core.plugin_registered? :batteries
            logger.error "[Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin]: cannot register plugin because :batteries plugin is not (maybe yet) registered in the core. It is required"
            return
          end

          @bridges_to_register.each do |bridge_symbol|
            bridge = bridge_for_symbol bridge_symbol, core.hooks

            bridge.setup
          end
        end

        #
        # <Description>
        #
        # @param [Symbol] bridge_symbol <description>
        # @param [Kanal::Core::Hooks::HookStorage] core_hooks <description>
        #
        # @return [Kanal::Plugins::BatteriesBridge::Bridges::Bridge] <description>
        #
        def bridge_for_symbol(bridge_symbol, core_hooks)
          raise "Cannot find bridge for #{bridge_symbol}" unless @available_bridges.key? bridge_symbol

          @available_bridges[bridge_symbol].new core_hooks
        end
      end
    end
  end
end
