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
          # TODO: Kanal of version 0.4.1 uses this line to get logger method
          # TODO: New Kanal release will have shortcut for it so this line will be redundant
          include Kanal::Core::Logging::Logger

          attr_reader :core_hooks

          attr_writer :fail_gracefully

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
            _source = @source
            _input_converters = @input_converters
            _logger = logger

            @core_hooks.attach :input_before_router do |input|
              if input.source == _source
                _input_converters.each do |converter|
                  next if input.send(converter.from_param).nil?

                  input.send("#{converter.to_param}=", converter.block.call(input.send(converter.from_param)))
                rescue Exception => e
                  _logger.error "BatteriesBridge input param converter #{self.class} tried to convert #{converter.from_param} to #{converter.to_param} and experienced an error: #{e}"

                  raise unless @fail_gracefully
                end
              end
            end

            _output_converters = @output_converters
            @core_hooks.attach :output_before_returned do |input, output|
              if input.source == _source
                _output_converters.each do |converter|
                  next if output.send(converter.from_param).nil?

                  output.send("#{converter.to_param}=", converter.block.call(output.send(converter.from_param)))
                rescue Exception => e
                  _logger.error "BatteriesBridge output param converter #{self.class} tried to convert #{converter.from_param} to #{converter.to_param} and experienced an error: #{e}"

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
