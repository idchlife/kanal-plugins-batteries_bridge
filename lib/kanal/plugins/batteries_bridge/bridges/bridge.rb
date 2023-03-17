# frozen_string_literal: true

require "kanal"

module Kanal
  module Plugins
    module BatteriesBridge
      module Bridges
        #
        # Base class for bridges
        #
        class Bridge
          attr_reader :core_hooks

          ParamConverter = Struct.new("ParamConverter", :from_param, :to_param, :block)

          #
          # @param [Kanal::Core::Hooks::HookStorage] core_hooks <description>
          #
          def initialize(core_hooks)
            @core_hooks = core_hooks
            @source = nil
            @input_converters = []
            @output_converters = []
          end

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

          def input_convert(from_param, to_param, &block)
            @input_converters << ParamConverter.new(from_param, to_param, block)
          end

          def output_convert(from_param, to_param, &block)
            @output_converters << ParamConverter.new(from_param, to_param, block)
          end

          private

          def attach_hooks
            @core_hooks.attach :input_before_router do |_core, input|
              if input.try(:source) == @source
                @input_converters.each do |converter|
                  next if input.try(converter.from_param).nil?

                  input.send(converter.to_param + "=", converter.block.call(input.try(converter.from_param)))
                end
              end
            end

            @core_hooks.attach :output_before_returned do |_core, input, _output|
              if input.try(:source) == @source
                @output_converters.each do |converter|
                  next if output.try(converter.from_param).nil?

                  output.send(converter.to_param + "=", converter.block.call(output.try(converter.from_param)))
                end
              end
            end
          end

          def internal_setup
            if (@source.nil? && @nevermind_source == false) || (@input_converters.empty? && @output_converters.empty?)
              raise "Cannot setup #{self.class} without required parameters: source, at least one input/output converter"
            end
          end
        end
      end
    end
  end
end
