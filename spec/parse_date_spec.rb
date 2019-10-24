# frozen_string_literal: true

RSpec.describe ParseDate do
  it 'has a version number' do
    expect(ParseDate::VERSION).not_to be nil
  end

  describe '.parse_range' do
    context 'when input is parseable' do
      # single value
      { # string to parse as key, expected result as value
        '12/25/00' => [2000],
        '5-1-25' => [1925],
        '1666 B.C.' => [-1666],
        '-914' => [-914],
        '[c1926]' => [1926],
        'ca. 1558' => [1558],
      }.each do |example, expected|
        it "array of single value #{expected} for '#{example}'" do
          expect(ParseDate.parse_range(example)).to eq expected
        end
      end

      # multiple values
      { # string to parse as key, expected result as value
        '195-' => (1950..1959).to_a,
        '199u' => (1990..1999).to_a,
        '197?' => (1970..1979).to_a,
        '196x' => (1960..1969).to_a,
        '18th century CE' => (1700..1799).to_a,
        '17uu' => (1700..1799).to_a,
        'between 1694 and 1799' => (1694..1799).to_a,
        'between 1 and 5' => (1..5).to_a,
        'between 300 and 150 B.C.' => (-300..-150).to_a,
        '-5 - 3' => (-5..3).to_a,
        '1496-1499' => (1496..1499).to_a,
        '1750?-1867' => (1750..1867).to_a,
        '17--?-18--?' => (1700..1899).to_a,
        '1835 or 1836' => [1835, 1836].to_a,
        '17-- or 18--?' => (1700..1899).to_a,
        '-2 or 1?' => (-2..1).to_a,
        '17th or 18th century?' => (1600..1799).to_a,
        'ca. 5th–6th century A.D.' => (400..599).to_a,
        'ca. 9th–8th century B.C.' => (-999..-800).to_a,
        'ca. 13th–12th century B.C.' => (-1399..-1200).to_a,
        '5th century B.C.' => (-599..-500).to_a,
        '502-504' => [502, 503, 504],
        '-2100 - -2000' => (-2100..-2000).to_a,
      }.each do |example, expected|
        it "#{example} returns array from earliest (#{expected.first}) to latest (#{expected.last})" do
          expect(ParseDate.parse_range(example)).to eq expected
        end
      end

      context 'when year is invalid' do
        [
          '1975 or 1905', # last year > first year
          '-100 - -150', # last year > first year
          '1975 - 1905', # last year > first year
          '2050', # year later than current year + 1
        ].each do |example|
          it "raises error: '#{example}'" do
            exp_msg_regex = /Unable to parse range from '#{example}'/
            expect { ParseDate.parse_range(example) }.to raise_error(ParseDate::Error, exp_msg_regex)
          end
        end
      end
    end
    context 'when years cannot be parsed' do
      [
        'random text',
        nil,
      ].each do |example|
        it "raises error: '#{example}'" do
          exp_msg_regex = /Unable to parse range from '#{example}'/
          expect { ParseDate.parse_range(example) }.to raise_error(ParseDate::Error, exp_msg_regex)
        end
      end
    end
  end

  describe '.year_range_valid?' do
    { # [first, last] as key, expected result as value
      [1975, 1905] => false,
      [2050, 2070] => false,
      [2050, 2007] => false,
      [2007, 2050] => false,
      [2007, 2009] => true,
      [150, 300] => true,
      [1, 5] => true,
      [-3, 2] => true,
      [-150, -100] => true,
      [-100, -150] => false,
      [-1500, -1499] => true,
      [-15000, -14999] => true,
    }.each do |key, expected|
      it "#{expected} for #{key}" do
        expect(ParseDate.year_range_valid?(key.first, key.last)).to eq expected
      end
    end
  end

  describe '.range_array' do
    context 'when input is valid: ' do
      [
        ['1993', '1995', [1993, 1994, 1995]],
        [1993, 1995, [1993, 1994, 1995]],
        [0, '0001', [0, 1]],
        ['-0003', '0000', [-3, -2, -1, 0]],
        [-1, 1, [-1, 0, 1]],
        [15, 15, [15]],
        [-100, '-99', [-100, -99]],
        ['98', 101, [98, 99, 100, 101]]
      ].each do |example|
        first_year = example[0]
        last_year = example[1]
        expected = example[2]
        it "(#{first_year} to #{last_year})" do
          expect(ParseDate.range_array(first_year, last_year)).to eq expected
        end
      end
    end
    context 'when input is invalid: ' do
      [
        ['1993', '1992'],
        [1993, 1992],
        ['-99', -100],
      ].each do |example|
        first_year = example[0]
        last_year = example[1]
        it "(#{first_year} to #{last_year})" do
          exp_msg_regex = /unable to create year range array from #{first_year}, #{last_year}/
          expect { ParseDate.range_array(first_year, last_year) }.to raise_error(StandardError, exp_msg_regex)
        end
      end

      [
        ['word1', 'word2']
      ].each do |example|
        first_year = example[0]
        last_year = example[1]
        it "(#{first_year} to #{last_year})" do
          exp_msg_regex = /comparison of String with/
          expect { ParseDate.range_array(first_year, last_year) }.to raise_error(ArgumentError, exp_msg_regex)
        end
      end
    end
  end
end
