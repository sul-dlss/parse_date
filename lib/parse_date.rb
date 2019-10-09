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
  def self.earliest_year(orig_date_str)
    ParseDate::IntFromString.earliest_year(orig_date_str)
  end
  def self.latest_year(orig_date_str)
    ParseDate::IntFromString.latest_year(orig_date_str)
  end
  def self.year_int_valid?(orig_date_str)
    ParseDate::IntFromString.year_int_valid?(orig_date_str)
  end
end
