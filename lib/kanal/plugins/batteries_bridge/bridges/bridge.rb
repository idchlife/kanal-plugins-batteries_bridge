# frozen_string_literal: true

require "kanal"

module Kanal
  module Plugins
    module BatteriesBridge
      module Bridges
        #
        # Base class for bridges. All bridges should be derived from this class
        #
        class Bridge
          include Kanal::Core::Logging

          attr_reader :core_hooks

          # Struct for using in param converters
          ParamConverter = Struct.new("ParamConverter", :from_param, :to_param, :block)

          def initialize
            @core_hooks = nil
            @source = nil
            @input_converters = []
            @output_converters = []
            @fail_gracefully = true
          end

          #
          # Required for overriding method in the derived bridge classes
          #
          # @return [void] <description>
          #
          def setup
            raise NotImplementedError
          end

          #
          # When converter raises an error, raise it instead of swallowing (logs will be written in both cases)
          #
          # @return [void] <description>
          #
          def fail_loud
            @fail_gracefully = false
          end

          protected :core_hooks

          #
          # :source input parameter will be checked for this
          #
          # @param [Symbol] source <description>
          #
          # @return [void] <description>
          #
          def require_source(source)
            @source = source
          end

          #
          # Register input converter
          #
          # @param [Symbol] from_param which input parameter will be used for getting value
          # @param [Symbol] to_param which input parameter will be populated with return value from block
          # @param [Proc] &block block will receive value from parameter defined in from_param argument, returned value will be used for new parameter value
          #
          # @return [void] <description>
          #
          def input_convert(from_param, to_param, &block)
            @input_converters << ParamConverter.new(from_param, to_param, block)
          end

          #
          # See #input_convert
          #
          # @param [Symbol] from_param <description>
          # @param [Symbol] to_param <description>
          # @param [Proc] &block <description>
          #
          # @return [void] <description>
          #
          def output_convert(from_param, to_param, &block)
            @output_converters << ParamConverter.new(from_param, to_param, block)
          end

          private

          def attach_hooks
            @core_hooks.attach :input_before_router do |input|
              if input.source == @source
                @input_converters.each do |converter|
                  next if input.try(converter.from_param).nil?

                  input.send(converter.to_param + "=", converter.block.call(input.try(converter.from_param)))
                rescue Exception => e
                  logger.error "BatteriesBridge input param converter #{self.class} tried to convert #{converter.from_param} to #{converter.to_param} and experienced an error: #{e}"

                  raise unless @fail_gracefully
                end
              end
            end

            @core_hooks.attach :output_before_returned do |input, _output|
              if input.source == @source
                @output_converters.each do |converter|
                  next if output.try(converter.from_param).nil?

                  output.send(converter.to_param + "=", converter.block.call(output.try(converter.from_param)))
                rescue Exception => e
                  logger.error "BatteriesBridge output param converter #{self.class} tried to convert #{converter.from_param} to #{converter.to_param} and experienced an error: #{e}"

                  raise unless @fail_gracefully
                end
              end
            end
          end

          #
          # This method will be called by the plugin to setup bridge and provide needed dependencies
          #
          # @param [Kanal::Core::Hooks::HookStorage] core_hooks <description>
          #
          # @return [void] <description>
          #
          def internal_setup(core_hooks)
            @core_hooks = core_hooks

            setup

            if @source.nil? || (@input_converters.empty? && @output_converters.empty?)
              raise "Cannot setup #{self.class} without required parameters: source, at least one input/output converter"
            end

            attach_hooks
          end
        end
      end
    end
  end
end
