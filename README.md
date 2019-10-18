[![Gem Version](https://badge.fury.io/rb/parse_date.svg)](https://badge.fury.io/rb/parse_date)
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

ParseDate has class methods for date string parsing.

```
require 'parse_date'

ParseDate.earliest_year('12/25/00') # 2000
ParseDate.earliest_year('5-1-21') # 1921
ParseDate.earliest_year('1666 B.C.') # -1666
ParseDate.earliest_year('-914') # -914
ParseDate.earliest_year('[c1926]') # 1926
ParseDate.earliest_year('ca. 1558') # 1558
ParseDate.earliest_year('195-') # 1950
ParseDate.earliest_year('199u') # 1990
ParseDate.earliest_year('197?') # 1970
ParseDate.earliest_year('196x') # 1960
ParseDate.earliest_year('18th century CE') # 1700
ParseDate.earliest_year('17uu') # 1700
ParseDate.earliest_year('between 1694 and 1799') # 1694
ParseDate.earliest_year('between 1 and 5') # 1
ParseDate.earliest_year('between 300 and 150 B.C.') # -300
ParseDate.earliest_year('1496-1499') # 1496
ParseDate.earliest_year('1750?-1867') # 1750
ParseDate.earliest_year('17--?-18--?') # 1700
ParseDate.earliest_year('1835 or 1836') # 1835
ParseDate.earliest_year('17-- or 18--?') # 1700
ParseDate.earliest_year('17th or 18th century?') # 1600
ParseDate.earliest_year('ca. 5th–6th century A.D.') # 400

ParseDate.latest_year('195-') # 1959
ParseDate.latest_year('199u') # 1999
ParseDate.latest_year('197?') # 1979
ParseDate.latest_year('196x') # 1969
ParseDate.latest_year('18th century CE') # 1799
ParseDate.latest_year('17uu') # 1799
ParseDate.latest_year('between 1694 and 1799') # 1799
ParseDate.latest_year('between 1 and 5') # 5
ParseDate.latest_year('between 300 and 150 B.C.') # -150
ParseDate.latest_year('1496-1499') # 1499
ParseDate.latest_year('1750?-1867') # 1867
ParseDate.latest_year('17--?-18--?') # 1899
ParseDate.latest_year('1757-58') # 1758
ParseDate.latest_year('1975-05') # 1975 (range invalid)
ParseDate.latest_year('1835 or 1836') # 1836
ParseDate.latest_year('17-- or 18--?') # 1899
ParseDate.earliest_year('17th or 18th century?') # 1799
ParseDate.earliest_year('ca. 5th–6th century A.D.') # 599

ParseDate.year_range_valid?()
ParseDate.year_range_valid?(1975, 1905) # false, first year > last year
ParseDate.year_range_valid?(-100, -150) # false, first year > last year
ParseDate.year_range_valid?(2050, 2070) # false, year later than current year + 1
ParseDate.year_range_valid?(2007, 2050) # false, year later than current year + 1
ParseDate.year_range_valid?(2007, 2009) # true
ParseDate.year_range_valid?(75, 150) # true
ParseDate.year_range_valid?(-3, 2) # true
ParseDate.year_range_valid?(-100, -50) # true
ParseDate.year_range_valid?(-1500, -1499) # true
ParseDate.year_range_valid?(-15000, -14999) # true

ParseDate.year_int_valid?(0) # true
ParseDate.year_int_valid?(5) # true
ParseDate.year_int_valid?(33) # true
ParseDate.year_int_valid?(150) # true
ParseDate.year_int_valid?(2019) # true
ParseDate.year_int_valid?(Date.today.year + 1) # true
ParseDate.year_int_valid?(-3) # true
ParseDate.year_int_valid?(-35) # true
ParseDate.year_int_valid?(-999) # true
ParseDate.year_int_valid?(-1666) # false - four digit negative years not considered valid here
ParseDate.year_int_valid?(165x) # false
ParseDate.year_int_valid?(198-) # false
ParseDate.year_int_valid?('random text') # false
ParseDate.year_int_valid?(nil) # false
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ndushay/parse_date.

## Copyright

Copyright (c) 2019 Stanford Libraries. See LICENSE for details.
