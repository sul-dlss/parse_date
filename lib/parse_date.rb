# frozen_string_literal: true

require 'singleton'
require 'zeitwerk'

class ParseDateInflector < Zeitwerk::Inflector
  def camelize(basename, _abspath)
    case basename
    when 'version'
      'VERSION'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.new
loader.inflector = ParseDateInflector.new
loader.push_dir(File.absolute_path("#{__FILE__}/.."))
loader.setup

class ParseDate
  class Error < StandardError; end

  include Singleton
  extend ParseDate::IntFromString

  # class method delegation
  def self.earliest_year(date_str)
    ParseDate::IntFromString.earliest_year(date_str)
  end

  def self.latest_year(date_str)
    ParseDate::IntFromString.latest_year(date_str)
  end

  def self.year_int_valid?(date_str)
    ParseDate::IntFromString.year_int_valid?(date_str)
  end

  # @return [Array] array of Integer year values from earliest year to latest year, inclusive
  def self.parse_range(date_str)
    first = earliest_year(date_str)
    last = latest_year(date_str)
    return nil unless first || last
    raise ParseDate::Error, "Unable to parse range from '#{date_str}'" unless year_range_valid?(first, last)

    range_array(first, last)
  rescue StandardError => e
    raise ParseDate::Error, "Unable to parse range from '#{date_str}': #{e.message}"
  end

  # true if:
  #   both years are not newer than (current year + 1)
  #   first_year <= last_year
  # false otherwise
  def self.year_range_valid?(first_year, last_year)
    upper_bound = Date.today.year + 2
    return false if first_year > upper_bound || last_year > upper_bound
    return false if first_year > last_year

    true
  end

  # @param [Integer, String] first_year, expecting integer or parseable string for .to_i
  # @param [Integer, String] last_year, expecting integer or parseable string for .to_i
  # @return [Array] array of Integer year values from first to last, inclusive
  def self.range_array(first_year, last_year)
    first_year = first_year.to_i if first_year.is_a?(String) && first_year.match?(/^-?\d+$/)
    last_year = last_year.to_i if last_year.is_a?(String) && last_year.match?(/^-?\d+$/)

    return [] unless last_year || first_year
    return [first_year] if last_year.nil? && first_year
    return [last_year] if first_year.nil? && last_year
    raise(ParseDate::Error, "unable to create year range array from #{first_year}, #{last_year}") unless
      year_range_valid?(first_year, last_year)

    Range.new(first_year, last_year).to_a
  end
end
