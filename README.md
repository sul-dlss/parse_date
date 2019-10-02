[![Gem Version](https://badge.fury.io/rb/parse_date.svg)](https://badge.fury.io/rb/preservation-client)
[![Build Status](https://travis-ci.org/sul-dlss/parse_date.svg?branch=master)](https://travis-ci.org/sul-dlss/parse_date)
[![Maintainability](https://api.codeclimate.com/v1/badges/2d006b4ccb3100434f4a/maintainability)](https://codeclimate.com/github/sul-dlss/parse_date/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/2d006b4ccb3100434f4a/test_coverage)](https://codeclimate.com/github/sul-dlss/parse_date/test_coverage)

# ParseDate

ParseDate is a Ruby gem that parses date values out of strings and normalizes the values for searching, faceting, display, etc. (e.g. in Solr search engine).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'parse_date'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install parse_date

## Usage

ParseDate is a module with date string parsing methods.

Include the desired functionality in the class of your choice:

```
require 'parse_date/int_from_string'

class DummyClass
  include ParseDate::IntFromString
end
```

And then you may use the public methods as you like:

```
klass = DummyClass.new
klass.year_int_from_date_str('12/25/00') # 2000
klass.year_int_from_date_str('5-1-21') # 1921
klass.year_int_from_date_str('18th century CE') # 1700
klass.year_int_from_date_str('1666 B.C.') # -1666
klass.year_int_from_date_str('17uu') # 1700
klass.year_int_from_date_str('-914') # -914
klass.year_int_from_date_str('[c1926]') # 1926
klass.year_int_from_date_str('ca. 1558') # 1558

klass.year_int_valid?(0) # true
klass.year_int_valid?(5) # true
klass.year_int_valid?(33) # true
klass.year_int_valid?(150) # true
klass.year_int_valid?(2019) # true
klass.year_int_valid?(Date.today.year + 1) # true
klass.year_int_valid?(-3) # true
klass.year_int_valid?(-35) # true
klass.year_int_valid?(-999) # true
klass.year_int_valid?(-1666) # false - four digit negative years not considered valid here
klass.year_int_valid?(165x) # false
klass.year_int_valid?(198-) # false
klass.year_int_valid?('random text') # false
klass.year_int_valid?(nil) # false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ndushay/parse_date.

## Copyright

Copyright (c) 2019 Stanford Libraries. See LICENSE for details.
