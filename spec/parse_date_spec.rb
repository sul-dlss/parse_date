# frozen_string_literal: true

RSpec.describe ParseDate do
  it 'has a version number' do
    expect(ParseDate::VERSION).not_to be nil
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
        ['12345', 12345]
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
