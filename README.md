[![Gem Version](https://badge.fury.io/rb/delaunator.svg)](https://badge.fury.io/rb/delaunator)
[![Build Status](https://travis-ci.com/hendrixfan/delaunator-ruby.svg?branch=master)](https://travis-ci.com/hendrixfan/delaunator-ruby)

# Delaunay Triangulation

This is a port of [Mapbox's Delaunator project](https://github.com/mapbox/delaunator).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'delaunator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install delaunator

## Usage

```ruby
Delaunator.triangulate([[516, 661], [369, 793], [426, 539]...])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hendrixfan/delaunator-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
