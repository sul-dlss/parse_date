# frozen_string_literal: true

require 'date' # so upstream callers don't have to require it

class ParseDate

  # Parse (Year) Integers from Date Strings
  module IntFromString

    # earliest year as Integer if we can parse one from date_str
    #  e.g. if 17uu, result is 1700
    # NOTE:  if we have a x/x/yy or x-x-yy pattern (the only 2 digit year patterns
    #   found in our actual date strings in stanford-mods records), then
    #   we use 20 as century digits unless it is greater than current year:
    #   1/1/17  ->  2017
    #   1/1/27  ->  1927
    # @return [Integer, nil] Integer year if we could parse one, nil otherwise
    def self.earliest_year(date_str)
      return unless date_str && !date_str.empty?
      return if date_str == '0000-00-00' # shpc collection has these useless dates
      # B.C. first in case there are 4 digits, e.g. 1600 B.C.
      return ParseDate.send(:between_bc_earliest_year, date_str) if date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
      return ParseDate.send(:year_int_for_bc, date_str) if date_str.match(YEAR_BC_REGEX)
      return ParseDate.send(:between_earliest_year, date_str) if date_str.match(BETWEEN_Yn_AND_Yn_REGEX)

      result = ParseDate.send(:hyphen_4digit_earliest_year, date_str)
      result ||= ParseDate.send(:first_four_digits, date_str)
      result ||= ParseDate.send(:year_from_mm_dd_yy, date_str)
      result ||= ParseDate.send(:first_year_for_decade, date_str) # 19xx or 20xx
      result ||= ParseDate.send(:first_year_for_century, date_str)
      result ||= ParseDate.send(:year_for_early_numeric, date_str)
      unless result
        # try removing brackets between digits in case we have 169[5] or [18]91
        no_brackets = ParseDate.send(:remove_brackets, date_str)
        return earliest_year(no_brackets) if no_brackets
      end
      result.to_i if result && year_int_valid?(result.to_i)
    end

    # latest year as Integer if we can parse one from date_str
    #  e.g. if 17uu, result is 1799
    # NOTE:  if we have a x/x/yy or x-x-yy pattern (the only 2 digit year patterns
    #   found in our actual date strings in stanford-mods records), then
    #   we use 20 as century digits unless it is greater than current year:
    #   1/1/17  ->  2017
    #   1/1/27  ->  1927
    # @return [Integer, nil] Integer year if we could parse one, nil otherwise
    def self.latest_year(date_str)
      return unless date_str && !date_str.empty?
      return if date_str == '0000-00-00' # shpc collection has these useless dates

      # B.C. first in case there are 4 digits, e.g. 1600 B.C.
      return ParseDate.send(:between_bc_latest_year, date_str) if date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
      return ParseDate.send(:year_int_for_bc, date_str) if date_str.match(BC_REGEX)
      return ParseDate.send(:between_latest_year, date_str) if date_str.match(BETWEEN_Yn_AND_Yn_REGEX)

      result = ParseDate.send(:hyphen_4digit_latest_year, date_str)
      result ||= ParseDate.send(:hyphen_2digit_latest_year, date_str)
      result ||= ParseDate.send(:first_four_digits, date_str)
      result ||= ParseDate.send(:year_from_mm_dd_yy, date_str)
      result ||= ParseDate.send(:last_year_for_decade, date_str) # 19xx or 20xx
      # NOTE:  may want to parse for last occurence of consecutive digits
      result ||= ParseDate.send(:last_year_for_century, date_str)
      result ||= ParseDate.send(:year_for_early_numeric, date_str)
      unless result
        # try removing brackets between digits in case we have 169[5] or [18]91
        no_brackets = ParseDate.send(:remove_brackets, date_str)
        return earliest_year(no_brackets) if no_brackets
      end
      result.to_i if result && year_int_valid?(result.to_i)
    end

    # true if the year is between -999 and (current year + 2)
    # @return [Boolean] true if the year is between -999 and (current year + 1); false otherwise
    def self.year_int_valid?(year)
      return false unless year.is_a? Integer

      (-1000 < year.to_i) && (year < Date.today.year + 2)
    end

    protected

    REGEX_OPTS = Regexp::IGNORECASE | Regexp::MULTILINE
    BRACKETS_BETWEEN_DIGITS_REGEX = Regexp.new('\d[' + Regexp.escape('[]') + ']\d')

    # removes brackets between digits such as 169[5] or [18]91
    def remove_brackets(date_str)
      date_str.delete('[]') if date_str.match(BRACKETS_BETWEEN_DIGITS_REGEX)
    end

    YYYY_HYPHEN_YYYY_REGEX = Regexp.new(/(?<first>\d{4})\??\s*-\s*(?<last>\d{1,4})\??/m)

    # Integer value for earliest if we have "yyyy-yyyy" pattern
    # @return [Integer, nil] yyyy if date_str matches pattern; nil otherwise
    def hyphen_4digit_earliest_year(date_str)
      matches = date_str.match(YYYY_HYPHEN_YYYY_REGEX)
      Regexp.last_match(:first).to_i if matches && Regexp.last_match(:first).length == Regexp.last_match(:last).length
    end

    # Integer value for latest year if we have "yyyy-yyyy" pattern
    # @return [Integer, nil] yyyy if date_str matches pattern; nil otherwise
    def hyphen_4digit_latest_year(date_str)
      matches = date_str.match(YYYY_HYPHEN_YYYY_REGEX)
      Regexp.last_match(:last).to_i if matches && Regexp.last_match(:first).length == Regexp.last_match(:last).length
    end

    YYYY_HYPHEN_YY_REGEX = Regexp.new(/(?<first>\d{4})\??\s*-\s*(?<last>\d{2})\??([^-0-9].*)?$/)

    # Integer value for latest year if we have "yyyy-yy" pattern
    # @return [Integer, nil] yyyy if date_str matches pattern; nil otherwise
    def hyphen_2digit_latest_year(date_str)
      matches = date_str.match(YYYY_HYPHEN_YY_REGEX)
      return unless matches

      first = Regexp.last_match(:first)
      century = first[0, 2]
      last = "#{century}#{Regexp.last_match(:last)}"
      last.to_i if ParseDate.year_range_valid?(first.to_i, last.to_i)
    end

    # looks for 4 consecutive digits in date_str and returns first occurrence if found
    # @return [String, nil] 4 digit year (e.g. 1865, 0950) if date_str has yyyy, nil otherwise
    def first_four_digits(date_str)
      matches = date_str.match(/\d{4}/)
      matches&.to_s
    end

    # returns 4 digit year as String if we have a x/x/yy or x-x-yy pattern
    #   note that these are the only 2 digit year patterns found in stanford-mods date fields
    #   we use 20 as century digits unless it is greater than current year:
    #   1/1/17  ->  2017
    #   1/1/27  ->  1927
    # @return [String, nil] 4 digit year (e.g. 1865, 0950) if date_str matches pattern, nil otherwise
    def year_from_mm_dd_yy(date_str)
      slash_matches = date_str.match(/\d{1,2}\/\d{1,2}\/\d{2}/)
      if slash_matches
        date_obj = Date.strptime(date_str, '%m/%d/%y')
      else
        hyphen_matches = date_str.match(/\d{1,2}-\d{1,2}-\d{2}/)
        date_obj = Date.strptime(date_str, '%m-%d-%y') if hyphen_matches
      end
      date_obj = Date.new(date_obj.year - 100, date_obj.month, date_obj.mday) if date_obj && date_obj > Date.today
      date_obj.year.to_s if date_obj
    rescue ArgumentError
      nil # explicitly want nil if date won't parse
    end

    DECADE_4CHAR_REGEX = Regexp.new('(^|\D)\d{3}[u\-?x]', REGEX_OPTS)

    # first year of decade (as String) if we have:  yyyu, yyy-, yyy? or yyyx pattern
    #   note that these are the only decade patterns found in our actual date strings in MODS records
    # @return [String, nil] 4 digit year (e.g. 1860, 1950) if date_str matches pattern, nil otherwise
    def first_year_for_decade(date_str)
      decade_matches = date_str.match(DECADE_4CHAR_REGEX)
      changed_to_zero = decade_matches.to_s.tr('u\-?x', '0') if decade_matches
      ParseDate.first_four_digits(changed_to_zero) if changed_to_zero
    end

    # last year of decade (as String) if we have:  yyyu, yyy-, yyy? or yyyx pattern
    #   note that these are the only decade patterns found in our actual date strings in MODS records
    # @return [String, nil] 4 digit year (e.g. 1869, 1959) if date_str matches pattern, nil otherwise
    def last_year_for_decade(date_str)
      decade_matches = date_str.match(DECADE_4CHAR_REGEX)
      changed_to_nine = decade_matches.to_s.tr('u\-?x', '9') if decade_matches
      ParseDate.first_four_digits(changed_to_nine) if changed_to_nine
    end

    CENTURY_WORD_REGEX = Regexp.new('(\d{1,2}).*century', REGEX_OPTS)
    CENTURY_4CHAR_REGEX = Regexp.new('(\d{1,2})[u\-]{2}([^u\-]|$)', REGEX_OPTS)

    # first year of century (as String) if we have:  yyuu, yy--, yy--? or xxth century pattern
    #   note that these are the only century patterns found in our actual date strings in MODS records
    # @return [String, nil] yy00 if date_str matches pattern, nil otherwise; also nil if B.C. in pattern
    def first_year_for_century(date_str)
      return if date_str =~ /B\.C\./
      return "#{Regexp.last_match(1)}00" if date_str.match(CENTURY_4CHAR_REGEX)
      return "#{(Regexp.last_match(1).to_i - 1).to_s}00" if date_str.match(CENTURY_WORD_REGEX)
    end

    # last year of century (as String) if we have:  yyuu, yy--, yy--? or xxth century pattern
    #   note that these are the only century patterns found in our actual date strings in MODS records
    # @return [String, nil] yy99 if date_str matches pattern, nil otherwise; also nil if B.C. in pattern
    def last_year_for_century(date_str)
      return if date_str =~ /B\.C\./
      return "#{Regexp.last_match(1)}99" if date_str.match(CENTURY_4CHAR_REGEX)

      # TODO:  do we want to look for the very last match of digits before "century" instead of the first one?
      return "#{(Regexp.last_match(1).to_i - 1).to_s}99" if date_str.match(CENTURY_WORD_REGEX)
    end

    BETWEEN_Yn_AND_Yn_REGEX = Regexp.new(/between\s+(?<first>\d{1,4})\??\s+and\s+(?<last>\d{1,4})\??/im)

    # Integer value for earliest if we have "between y and y" pattern
    # NOTE: must match for BC first with between_bc_earliest_year
    # @return [Integer, nil] year if date_str matches pattern; nil otherwise
    def between_earliest_year(date_str)
      matches = date_str.match(BETWEEN_Yn_AND_Yn_REGEX)
      Regexp.last_match(:first).to_i if matches
    end

    # Integer value for latest year if we have "between y and y" pattern
    # NOTE: must match for BC first with between_bc_latest_year
    # @return [Integer, nil] year if date_str matches pattern; nil otherwise
    def between_latest_year(date_str)
      matches = date_str.match(BETWEEN_Yn_AND_Yn_REGEX)
      Regexp.last_match(:last).to_i if matches
    end

    BC_REGEX = Regexp.new(/\s*B\.?\s*C\.?/im)
    YEAR_BC_REGEX = Regexp.new("(\\d{1,4})#{BC_REGEX}", REGEX_OPTS)

    # Integer value for B.C. if we have B.C. pattern
    # @return [Integer, nil] -ddd if B.C. in pattern; nil otherwise
    def year_int_for_bc(date_str)
      bc_matches = date_str.match(YEAR_BC_REGEX)
      "-#{Regexp.last_match(1)}".to_i if bc_matches
    end

    BETWEEN_Yn_AND_Yn_BC_REGEX = Regexp.new("#{BETWEEN_Yn_AND_Yn_REGEX}#{BC_REGEX}", REGEX_OPTS)

    # Integer value for earliest year if we have "between y and y B.C." pattern
    # @return [Integer, nil] -ddd if date_str matches pattern; nil otherwise
    def between_bc_earliest_year(date_str)
      matches = date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
      "-#{Regexp.last_match(:first)}".to_i if matches
    end

    # Integer value for latest year if we have "between y and y B.C." pattern
    # @return [Integer, nil] -ddd if date_str matches pattern; nil otherwise
    def between_bc_latest_year(date_str)
      matches = date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
      "-#{Regexp.last_match(:last)}".to_i if matches
    end

    EARLY_NUMERIC_REGEX = Regexp.new('^\-?\d{1,3}$', REGEX_OPTS)

    # year if date_str contains yyy, yy, y, -y, -yy, -yyy, -yyyy
    # @return [String, nil] year if date_str matches pattern; nil otherwise
    def year_for_early_numeric(date_str)
      date_str if date_str.match(EARLY_NUMERIC_REGEX) || date_str =~ /^-\d{4}$/
    end
  end
end
