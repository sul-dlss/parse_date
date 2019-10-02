# frozen_string_literal: true

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

module ParseDate
  class Error < StandardError; end
  require 'parse_date/int_from_string'
end
