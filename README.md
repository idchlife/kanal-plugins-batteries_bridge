# Kanal::Plugins::BatteriesBridge

### BatteriesBridge plugin provides the bridge between different interfaces with their properties to the batteries plugin properties.
E.g.: if you use telegram interface and have `input.tg_text` - this plugin will convert it into `input.body` (body property provided by the batteries plugin)

### Where to find Batteries plugin? Well, as of right now, Batteries plugin is a part of Kanal core codebase, part of it's repository. If you have Kanal core library -
you can get plugin via Kanal::Plugins::Batteries::BatteriesPlugin

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add kanal-plugins-batteries_bridge

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install kanal-plugins-batteries_bridge

## Usage

1. Create instance of plugin:

```rb
plugin = Kanal::Plugins::BatteriesBridge::BatteriesBridge.new
```

2. Include needed bridges:

```rb
plugin.add_telegram # This adds built in default Telegram bridge

plugin.add_bridge YourBridgeClass.new
```

3. Register plugin: 

```rb
core.register_plugin plugin
```

## Build-in bridges

- Telegram: `plugin.add_telegram`

## Creating bridge:

```rb
# WARNING: don't forget that all used input/output properties should be registered!

class YourBridgeClass < Kanal::Plugins::BatteriesBridge::Bridges::Bridge
  # Required method that will be used
  def setup
    # This line is required, you should specify which .source is needed for this bridge to work
    # Some info about input parameter :source - Batteries plugin introduced this parameter and ALL
    # interfaces should populate .source input parameter when creating input. Thanks to this we can determine whether
    # input came from telegram, or facebook messenger or some other source.
    require_source :my_messenger_source

    # Here with handy DSL methods you can specify which parameters to convert
    input_convert :input_parameter_to_convert, :input_parameter_that_will_be_populated do |value_of_input_parameter|
      # You can do anything with provided value here and return changed value, or return unchanged value for the sake of
      # just populating different input property
      your_changed_value
    end

    input_convert :float_param, :int_param do |value|
      value.to_i
    end

    output_convert :from_param, :to_param do |value|
      value
    end

    # You can specify as many convertations as you like
  end
end

plugin.add_bridge YourBridgeClass.new
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

### If there is interface without bridge for batteries out there - we will be grateful if you contribute new bridge!

Bug reports and pull requests are welcome on GitHub at https://github.com/idchlife/kanal-plugins-batteries_bridge. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/idchlife/kanal-plugins-batteries_bridge/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kanal::Plugins::BatteriesBridge project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/idchlife/kanal-plugins-batteries_bridge/blob/main/CODE_OF_CONDUCT.md).
