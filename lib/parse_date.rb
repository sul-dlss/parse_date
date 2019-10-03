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

  # class method delegation for ParseDate.year_int_from_date_str
  def self.year_int_from_date_str(orig_date_str)
    ParseDate::IntFromString.year_int_from_date_str(orig_date_str)
  end

  # class method delegation for ParseDate.year_int_valid?
  def self.year_int_valid?(orig_date_str)
    ParseDate::IntFromString.year_int_valid?(orig_date_str)
  end
end
