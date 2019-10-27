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

      # B.C. first (match longest string first)
      return ParseDate.send(:earliest_century_bc, date_str) if date_str.match(YY_YY_CENTURY_BC_REGEX)
      return ParseDate.send(:between_bc_earliest_year, date_str) if date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
      return ParseDate.send(:year_int_for_bc, date_str) if date_str.match(YEAR_BC_REGEX)

      result ||= ParseDate.send(:between_earliest_year, date_str)
      result ||= ParseDate.send(:negative_first_four_digits, date_str)
      result ||= ParseDate.send(:first_four_digits, date_str)
      result ||= ParseDate.send(:year_from_mm_dd_yy, date_str)
      result ||= ParseDate.send(:first_year_for_decade, date_str) # 198x or 201x
      result ||= ParseDate.send(:first_year_for_century, date_str) # includes BC
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

      # B.C. first (match longest string first)
      return ParseDate.send(:last_year_mult_centuries_bc, date_str) if date_str.match(YY_YY_CENTURY_BC_REGEX)
      return ParseDate.send(:between_bc_latest_year, date_str) if date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
      return ParseDate.send(:last_year_for_bc_century, date_str) if date_str.match(BC_CENTURY_REGEX)
      return ParseDate.send(:year_int_for_bc, date_str) if date_str.match(BC_REGEX)

      result ||= ParseDate.send(:between_latest_year, date_str)
      result ||= ParseDate.send(:hyphen_4digit_latest_year, date_str)
      result ||= ParseDate.send(:hyphen_2digit_latest_year, date_str)
      result ||= ParseDate.send(:yyuu_after_hyphen, date_str)
      result ||= ParseDate.send(:year_after_or, date_str)
      result ||= ParseDate.send(:negative_4digits_after_hyphen, date_str)
      result ||= ParseDate.send(:negative_first_four_digits, date_str)
      result ||= ParseDate.send(:first_four_digits, date_str)
      result ||= ParseDate.send(:year_from_mm_dd_yy, date_str)
      result ||= ParseDate.send(:last_year_for_decade, date_str) # 198x or 201x
      result ||= ParseDate.send(:last_year_mult_centuries, date_str) # nth-nth century
      result ||= ParseDate.send(:last_year_for_century, date_str)
      result ||= ParseDate.send(:last_year_for_early_numeric, date_str)
      unless result
        # try removing brackets between digits in case we have 169[5] or [18]91
        no_brackets = ParseDate.send(:remove_brackets, date_str)
        return earliest_year(no_brackets) if no_brackets
      end
      result.to_i if result && year_int_valid?(result.to_i)
    end

    # true if the year is between -9999 and (current year + 1), inclusive
    # @return [Boolean] true if the year is between -999 and (current year + 1); false otherwise
    def self.year_int_valid?(year)
      return false unless year.is_a? Integer

      (-10000 < year.to_i) && (year < Date.today.year + 2)
    end

    protected

    REGEX_OPTS = Regexp::IGNORECASE | Regexp::MULTILINE
    BC_REGEX = Regexp.new(/\s*B\.?\s*C\.?/im)
    BRACKETS_BETWEEN_DIGITS_REGEX = Regexp.new('\d[' + Regexp.escape('[]') + ']\d')

    # removes brackets between digits such as 169[5] or [18]91
    def remove_brackets(date_str)
      date_str.delete('[]') if date_str.match(BRACKETS_BETWEEN_DIGITS_REGEX)
    end

    YYYY_HYPHEN_YYYY_REGEX = Regexp.new(/(?<first>\d{4})\??\s*[-—]\s*(?<last>\d{4})\??/m)

    # Integer value for latest year if we have "yyyy-yyyy" pattern
    # @return [Integer, nil] yyyy if date_str matches pattern; nil otherwise
    def hyphen_4digit_latest_year(date_str)
      Regexp.last_match(:last).to_i if date_str.match(YYYY_HYPHEN_YYYY_REGEX)
    end

    YYYY_HYPHEN_YY_REGEX = Regexp.new(/(?<first>\d{4})\??\s*[-—]\s*(?<last>\d{2})\??([^-0-9].*)?$/)

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

    YYUU = '\\d{1,2}[u\\-]{2}'
    YYuu_HYPHEN_YYuu_REGEX =
      Regexp.new("(?<first>#{YYUU})\\??\\s*[-—]\\s*(?<last>#{YYUU})\\??([^u\\-]|$)??", REGEX_OPTS)

    # Integer value for latest year if we have "yyuu-yyuu" pattern
    # @return [Integer, nil] yyyy if date_str matches pattern; nil otherwise
    def yyuu_after_hyphen(date_str)
      last_year_for_century(Regexp.last_match(:last)).to_i if date_str.match(YYuu_HYPHEN_YYuu_REGEX)
    end

    YYXX = '\\d{1,2}[u\\-\\d]{2}'
    YExx_OR_YExx_REGEX = Regexp.new("(?<first>#{YYXX})\\??\\s*or\\s*(?<last>#{YYXX})\\??([^u\\-]|$)??", REGEX_OPTS)

    # Integer value for latest year if we have "yyyy or yyyy" pattern
    # @return [Integer, nil] yyyy if date_str matches pattern; nil otherwise
    def year_after_or(date_str)
      latest_year(Regexp.last_match(:last)).to_i if date_str.match(YExx_OR_YExx_REGEX)
    end

    # NOTE: some actual data seemed to have a diff hyphen char. (slightly longer)
    YY_YY_CENTURY_REGEX = Regexp.new(/(?<first>\d{1,2})[a-z]{2}?\s*(-|–|or)\s*(?<last>\d{1,2})[a-z]{2}?\s+centur.*/im)

    # Integer value for latest year if we have nth-nth century pattern
    # @return [Integer, nil] yy99 if date_str matches pattern; nil otherwise
    def last_year_mult_centuries(date_str)
      matches = date_str.match(YY_YY_CENTURY_REGEX)
      return unless matches

      nth = Regexp.last_match(:last).to_i
      (nth - 1) * 100 + 99
    end

    YY_YY_CENTURY_BC_REGEX = Regexp.new("#{YY_YY_CENTURY_REGEX}#{BC_REGEX}", REGEX_OPTS)

    # Integer value for earliest year if we have nth-nth century BC pattern
    # @return [Integer, nil] -yy99 if date_str matches pattern; nil otherwise
    def earliest_century_bc(date_str)
      matches = date_str.match(YY_YY_CENTURY_BC_REGEX)
      return unless matches

      nth = Regexp.last_match(:first).to_i
      nth * -100 - 99
    end

    # Integer value for latest year if we have nth-nth century BC pattern
    # @return [Integer, nil] -yy00 if date_str matches pattern; nil otherwise
    def last_year_mult_centuries_bc(date_str)
      matches = date_str.match(YY_YY_CENTURY_BC_REGEX)
      return unless matches

      nth = Regexp.last_match(:last).to_i
      nth * -100
    end

    # looks for -yyyy at beginning of date_str and returns if found
    # @return [String, nil] negative 4 digit year (e.g. -1865) if date_str has -yyyy, nil otherwise
    def negative_first_four_digits(date_str)
      Regexp.last_match(1) if date_str.match(/^(\-\d{4})/)
    end

    # looks for -yyyy after hyphen and returns if found
    # @return [String, nil] negative 4 digit year (e.g. -1865) if date_str has -yyyy - -yyyy, nil otherwise
    def negative_4digits_after_hyphen(date_str)
      Regexp.last_match(1) if date_str.match(/\-\d{4}\s*\-\s*(\-\d{4})/)
    end

    # looks for 4 consecutive digits in date_str and returns first occurrence if found
    # @return [String, nil] 4 digit year (e.g. 1865, 0950) if date_str has yyyy, nil otherwise
    def first_four_digits(date_str)
      Regexp.last_match(1) if date_str.match(/(\d{4})/)
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

    DECADE_4CHAR_REGEX = Regexp.new('(^|\D)\d{3}[u\-?x]($|\D)', REGEX_OPTS)

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

    CENTURY_WORD_REGEX = Regexp.new('(\d{1,2})[a-z]{2}?\s*century', REGEX_OPTS)
    CENTURY_4CHAR_REGEX = Regexp.new('(\d{1,2})[u\-]{2}([^u\-]|$)', REGEX_OPTS)
    BC_CENTURY_REGEX = Regexp.new("#{CENTURY_WORD_REGEX}\\s+#{BC_REGEX}", REGEX_OPTS)

    # first year of century if we have:  yyuu, yy--, yy--? or xxth century pattern; handles B.C.
    # @return [Integer, nil] yy00 if date_str matches pattern, nil otherwise
    def first_year_for_century(date_str)
      return Regexp.last_match(1).to_i * -100 - 99 if date_str.match(BC_CENTURY_REGEX)
      return Regexp.last_match(1).to_i * 100 if date_str.match(CENTURY_4CHAR_REGEX)
      return (Regexp.last_match(:first).to_i - 1) * 100 if date_str.match(YY_YY_CENTURY_REGEX)
      return (Regexp.last_match(1).to_i - 1) * 100 if date_str.match(CENTURY_WORD_REGEX)
    end

    # last year of century if we have:  yyuu, yy--, yy--? or xxth century pattern
    # @return [Integer, nil] yy99 if date_str matches pattern, nil otherwise; also nil if B.C. in pattern
    def last_year_for_century(date_str)
      return Regexp.last_match(1).to_i * 100 + 99 if date_str.match(CENTURY_4CHAR_REGEX)
      return (Regexp.last_match(1).to_i - 1) * 100 + 99 if date_str.match(CENTURY_WORD_REGEX)
    end

    # last year of century (as String) if we have:  nth century BC
    # @return [Integer, nil] -yy00 if date_str matches pattern, nil otherwise; also nil if B.C. in pattern
    def last_year_for_bc_century(date_str)
      Regexp.last_match(1).to_i * -100 if date_str.match(BC_CENTURY_REGEX)
    end

    BETWEEN_Yn_AND_Yn_REGEX = Regexp.new(/between\s+(?<first>\d{1,4})\??\s+and\s+(?<last>\d{1,4})\??/im)

    # Integer value for earliest if we have "between y and y" pattern
    # NOTE: must match for BC first with between_bc_earliest_year
    # @return [Integer, nil] year if date_str matches pattern; nil otherwise
    def between_earliest_year(date_str)
      Regexp.last_match(:first).to_i if date_str.match(BETWEEN_Yn_AND_Yn_REGEX)
    end

    # Integer value for latest year if we have "between y and y" pattern
    # NOTE: must match for BC first with between_bc_latest_year
    # @return [Integer, nil] year if date_str matches pattern; nil otherwise
    def between_latest_year(date_str)
      Regexp.last_match(:last).to_i if date_str.match(BETWEEN_Yn_AND_Yn_REGEX)
    end

    YEAR_BC_REGEX = Regexp.new("(\\d{1,4})#{BC_REGEX}", REGEX_OPTS)

    # Integer value for B.C. if we have B.C. pattern
    # @return [Integer, nil] -ddd if B.C. in pattern; nil otherwise
    def year_int_for_bc(date_str)
      "-#{Regexp.last_match(1)}".to_i if date_str.match(YEAR_BC_REGEX)
    end

    BETWEEN_Yn_AND_Yn_BC_REGEX = Regexp.new("#{BETWEEN_Yn_AND_Yn_REGEX}#{BC_REGEX}", REGEX_OPTS)

    # Integer value for earliest year if we have "between y and y B.C." pattern
    # @return [Integer, nil] -ddd if date_str matches pattern; nil otherwise
    def between_bc_earliest_year(date_str)
      "-#{Regexp.last_match(:first)}".to_i if date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
    end

    # Integer value for latest year if we have "between y and y B.C." pattern
    # @return [Integer, nil] -ddd if date_str matches pattern; nil otherwise
    def between_bc_latest_year(date_str)
      "-#{Regexp.last_match(:last)}".to_i if date_str.match(BETWEEN_Yn_AND_Yn_BC_REGEX)
    end

    EARLY_NUMERIC_REGEX = Regexp.new('^\-?\d{1,3}([^\du\[]|$)', REGEX_OPTS)

    # year if date_str contains yyy, yy, y, -y, -yy, -yyy, -yyyy
    # @return [Integer, nil] year if date_str matches pattern; nil otherwise
    def year_for_early_numeric(date_str)
      date_str.to_i if date_str.match(EARLY_NUMERIC_REGEX) || date_str =~ /^-\d{4}([^\du\-\[]|$)$/
    end

    FIRST_LAST_EARLY_NUMERIC_REGEX =
      Regexp.new(/^(?<first>\-?\d{1,3})\??\s*(-|–|or)\s*(?<last>\-?\d{1,4})\??([^\du\-\[]|$)/im)

    # Integer value for latest year if we have early numeric year range or single early numeric year
    # @return [Integer, nil] year if date_str matches pattern; nil otherwise
    def last_year_for_early_numeric(date_str)
      return Regexp.last_match(:last).to_i if date_str.match(FIRST_LAST_EARLY_NUMERIC_REGEX)

      year_for_early_numeric(date_str) # if single year, not matched above
    end
  end
end
