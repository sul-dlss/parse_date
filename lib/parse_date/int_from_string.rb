# frozen_string_literal: true

require 'date' # so upstream callers don't have to require it

class ParseDate

  # Parse (Year) Integers from Date Strings
  module IntFromString

    # get Integer year if we can parse date_str to get a year.
    # NOTE:  if we have a x/x/yy or x-x-yy pattern (the only 2 digit year patterns
    #   found in our actual date strings in stanford-mods records), then
    #   we use 20 as century digits unless it is greater than current year:
    #   1/1/17  ->  2017
    #   1/1/27  ->  1927
    # @return [Integer, nil] Integer year if we could parse one, nil otherwise
    def self.year_int_from_date_str(orig_date_str)
      return if orig_date_str == '0000-00-00' # shpc collection has these useless dates
      # B.C. first in case there are 4 digits, e.g. 1600 B.C.
      return ParseDate.send(:sortable_year_int_for_bc, orig_date_str) if orig_date_str.match(BC_REGEX)

      result = ParseDate.send(:sortable_year_for_yyyy_or_yy, orig_date_str)
      result ||= ParseDate.send(:sortable_year_for_decade, orig_date_str) # 19xx or 20xx
      result ||= ParseDate.send(:sortable_year_for_century, orig_date_str)
      result ||= ParseDate.send(:sortable_year_int_for_early_numeric, orig_date_str)
      unless result
        # try removing brackets between digits in case we have 169[5] or [18]91
        no_brackets = ParseDate.send(:remove_brackets, orig_date_str)
        return year_int_from_date_str(no_brackets) if no_brackets
      end
      result.to_i if result && year_int_valid?(result.to_i)
    end

    # true if the year is between -999 and (current year + 1)
    # @return [Boolean] true if the year is between -999 and (current year + 1); false otherwise
    def self.year_int_valid?(year)
      return false unless year.is_a? Integer

      (-1000 < year.to_i) && (year < Date.today.year + 2)
    end

    protected

    # get String sortable value year if we can parse date_str to get a year.
    # @return [String, nil] String sortable year if we could parse one, nil otherwise
    #  note that these values must *lexically* sort to create a chronological sort.
    def sortable_year_for_yyyy_or_yy(orig_date_str)
      # most date strings have a four digit year
      result = ParseDate.sortable_year_for_yyyy(orig_date_str)
      result ||= ParseDate.sortable_year_for_yy(orig_date_str) # 19xx or 20xx
      result
    end

    BRACKETS_BETWEEN_DIGITS_REXEXP = Regexp.new('\d[' + Regexp.escape('[]') + ']\d')

    # removes brackets between digits such as 169[5] or [18]91
    def remove_brackets(orig_date_str)
      orig_date_str.delete('[]') if orig_date_str.match(BRACKETS_BETWEEN_DIGITS_REXEXP)
    end

    # looks for 4 consecutive digits in orig_date_str and returns first occurrence if found
    # @return [String, nil] 4 digit year (e.g. 1865, 0950) if orig_date_str has yyyy, nil otherwise
    def sortable_year_for_yyyy(orig_date_str)
      matches = orig_date_str.match(/\d{4}/) if orig_date_str
      matches&.to_s
    end

    # returns 4 digit year as String if we have a x/x/yy or x-x-yy pattern
    #   note that these are the only 2 digit year patterns found in our actual date strings in stanford-mods records
    #   we use 20 as century digits unless it is greater than current year:
    #   1/1/17  ->  2017
    #   1/1/27  ->  1927
    # @return [String, nil] 4 digit year (e.g. 1865, 0950) if orig_date_str matches pattern, nil otherwise
    def sortable_year_for_yy(orig_date_str)
      return unless orig_date_str

      slash_matches = orig_date_str.match(/\d{1,2}\/\d{1,2}\/\d{2}/)
      if slash_matches
        date_obj = Date.strptime(orig_date_str, '%m/%d/%y')
      else
        hyphen_matches = orig_date_str.match(/\d{1,2}-\d{1,2}-\d{2}/)
        date_obj = Date.strptime(orig_date_str, '%m-%d-%y') if hyphen_matches
      end
      date_obj = Date.new(date_obj.year - 100, date_obj.month, date_obj.mday) if date_obj && date_obj > Date.today
      date_obj.year.to_s if date_obj
    rescue ArgumentError
      nil # explicitly want nil if date won't parse
    end

    DECADE_4CHAR_REGEXP = Regexp.new('(^|\D)\d{3}[u\-?x]')

    # get first year of decade (as String) if we have:  yyyu, yyy-, yyy? or yyyx pattern
    #   note that these are the only decade patterns found in our actual date strings in MODS records
    # @return [String, nil] 4 digit year (e.g. 1860, 1950) if orig_date_str matches pattern, nil otherwise
    def sortable_year_for_decade(orig_date_str)
      decade_matches = orig_date_str.match(DECADE_4CHAR_REGEXP) if orig_date_str
      changed_to_zero = decade_matches.to_s.tr('u\-?x', '0') if decade_matches
      ParseDate.sortable_year_for_yyyy(changed_to_zero) if changed_to_zero
    end

    CENTURY_WORD_REGEXP = Regexp.new('(\d{1,2}).*century')
    CENTURY_4CHAR_REGEXP = Regexp.new('(\d{1,2})[u\-]{2}([^u\-]|$)')

    # get first year of century (as String) if we have:  yyuu, yy--, yy--? or xxth century pattern
    #   note that these are the only century patterns found in our actual date strings in MODS records
    # @return [String, nil] yy00 if orig_date_str matches pattern, nil otherwise; also nil if B.C. in pattern
    def sortable_year_for_century(orig_date_str)
      return unless orig_date_str
      return if orig_date_str =~ /B\.C\./

      century_matches = orig_date_str.match(CENTURY_4CHAR_REGEXP)
      if century_matches
        m = Regexp.last_match(1)
        return m + '00' if m.length == 2
        return '0' + m + '00' if m.length == 1
      end

      century_str_matches = orig_date_str.match(CENTURY_WORD_REGEXP)
      return unless century_str_matches

      yy = (Regexp.last_match(1).to_i - 1).to_s
      return yy + '00' if yy.length == 2
      return '0' + yy + '00' if yy.length == 1
    end

    BC_REGEX = Regexp.new('(\d{1,4}).*' + Regexp.escape('B.C.'))

    # get Integer sortable value for B.C. if we have B.C. pattern
    # @return [Integer, nil] Integer sortable -ddd if B.C. in pattern; nil otherwise
    def sortable_year_int_for_bc(orig_date_str)
      bc_matches = orig_date_str.match(BC_REGEX) if orig_date_str
      "-#{Regexp.last_match(1)}".to_i if bc_matches
    end

    EARLY_NUMERIC = Regexp.new('^\-?\d{1,3}$')

    # get Integer sortable value from date String containing yyy, yy, y, -y, -yy, -yyy, -yyyy
    # @return [Integer, nil] Integer sortable -ddd if orig_date_str matches pattern; nil otherwise
    def sortable_year_int_for_early_numeric(orig_date_str)
      return orig_date_str.to_i if orig_date_str.match(EARLY_NUMERIC)

      orig_date_str.to_i if orig_date_str =~ /^-\d{4}$/
    end
  end
end
