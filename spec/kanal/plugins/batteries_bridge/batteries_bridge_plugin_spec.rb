# frozen_string_literal: true

require "kanal/plugins/batteries/batteries_plugin"

class IntegrationTestBridge < Kanal::Plugins::BatteriesBridge::Bridges::Bridge
  def setup
    require_source :test_source

    input_convert :raw_input_prop, :baked_input_prop do |value|
      "#{value}_input"
    end

    output_convert :raw_output_prop, :baked_output_prop do |value|
      "#{value}_output"
    end
  end
end

class IntegrationTestBridgeToAvoid < Kanal::Plugins::BatteriesBridge::Bridges::Bridge
  def setup
    require_source :other_source

    input_convert :raw_input_prop, :forbidden_input_prop do |value|
      "#{value}_input"
    end

    output_convert :raw_output_prop, :forbidden_output_prop do |value|
      "#{value}_output"
    end
  end
end

RSpec.describe Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin do
  it "fails to register in the core without batteries plugin" do
    core = Kanal::Core::Core.new

    expect do
      core.register_plugin Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin.new
    end.to raise_error(/cannot register plugin/)
  end

  it "registers successfully in the Kanal" do
    core = Kanal::Core::Core.new

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

    expect do
      core.register_plugin Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin.new
    end.not_to raise_error
  end

  it "integrates into kanal workflow successfully, with hooks and calling bridges" do
    core = Kanal::Core::Core.new

    core.register_input_parameter :raw_input_prop
    core.register_input_parameter :baked_input_prop

    core.register_output_parameter :raw_output_prop
    core.register_output_parameter :baked_output_prop

    core.router.default_response do
      body "Default response"
    end

    core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

    bb_plugin = Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin.new

    bb_plugin.add_bridge IntegrationTestBridge.new
    bb_plugin.fail_loud

    core.register_plugin bb_plugin

    core.router.configure do
      on :flow, :any do
        respond do
          body "Something something"

          raw_output_prop "val123"
        end
      end
    end

    # Using lambda to insert into hook and use tests inside of it
    check_for_input_baked = lambda do |inp|
      expect(inp.baked_input_prop).to eq "input_hey_input"
    end

    core.hooks.attach :input_before_router do |input|
      check_for_input_baked.call input
    end

    input = core.create_input
    input.source = :test_source
    input.raw_input_prop = "input_hey"

    output = nil

    core.router.output_ready do |o|
      output = o
    end

    core.router.consume_input input

    expect(output).not_to be_nil
    expect(output.baked_output_prop).to eq "val123_output"
  end

  # it "calls only suited :source bridges" do
  #   core = Kanal::Core::Core.new

  #   core.register_input_parameter :raw_input_prop
  #   core.register_input_parameter :baked_input_prop

  #   core.register_output_parameter :raw_output_prop
  #   core.register_output_parameter :baked_output_prop

  #   core.router.default_response do
  #     body "Default response"
  #   end

  #   core.register_plugin Kanal::Plugins::Batteries::BatteriesPlugin.new

  #   bb_plugin = Kanal::Plugins::BatteriesBridge::BatteriesBridgePlugin.new

  #   bb_plugin.add_bridge IntegrationTestBridge.new
  #   bb_plugin.add_bridge IntegrationTestBridgeToAvoid.new

  #   core.register_plugin bb_plugin

  #   core.router.configure do
  #     on :flow, :any do
  #       respond do
  #         body "Something something"
  #       end
  #     end
  #   end

  #   input = core.create_input
  #   input.source = :test_source
  #   input.raw_input_prop = "input_hey"

  #   output = nil

  #   core.router.output_ready do |o|
  #     output = o
  #   end

  #   core.router.consume_input input

  #   expect(output).not_to be_nil
  # end
end
