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

`Delaunator.triangulate()` returns an array of triangle vertex indices (each group of three numbers forms a triangle). All triangles are directed counterclockwise.

```ruby
points = [[382, 302], [382, 328], [382, 205], [623, 175], [382, 188], [382, 284], [623, 87], [623, 341], [141, 227]]
triangles = Delaunator.triangulate(points)
# => [2, 3, 4, 2, 5, 3, 5, 7, 3, 3, 6, 4, 0, 7, 5, 1, 7, 0, 0, 8, 1, 5, 8, 0, 2, 8, 5, 4, 8, 2, 6, 8, 4]
```

You can then use these indices to get the coordinates of each triangle:

```ruby
(0..triangles.length-1).step(3) do |i|
    ax, ay = points[triangles[i]]
    bx, by = points[triangles[i + 1]]
    cx, cy = points[triangles[i + 2]]
    # (ax, ay), (bx, by), (cx, cy) are your triangle points
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hendrixfan/delaunator-ruby.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
