# HDLRuby

Hardware Ruby is a library for describing and simulating digital electronic systems.

__Warning__: this is very preliminary work, in the present state there is nothing but the data structures for the low-level representation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'HDLRuby'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install HDLRuby

## Usage

### Using HDLRuby

You can use HDLRuby in a ruby program by loading `HDLRuby.rb` in your ruby file:

```ruby
require 'HDLRuby'
```

Then, including `HDLRuby::High` will setup Ruby for supporting the high-level
description of hardware components.

```ruby
include HDLRuby::High
```

Alternatively, you can also setup Ruby for supporting the building of a
low-level representation of hardware as follows:

```ruby
include HDLRuby::Low
```

It is then possible to load a low level representations of hardware as
follows, where `stream` is a stream containing the representation.

```ruby
hardwares = HDLRuby::from_yaml(stream)
```

For instance, you can load a sample description of an 8-bit adder as follows:

```ruby
HDLRuby::from_yaml(File.read("#{$:[0]}/HDLRuby/low_samples/adder.yaml"))
```

__Notes__:
- The low level representation of hardware can only be built through standard
  Ruby class constructors, and does not include any validity check of the
  resulting hardware.
- `HDLRuby::High` and `HDLRuby::Low` cannot be included at the same time.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Lovic Gauthier/HDLRuby.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

