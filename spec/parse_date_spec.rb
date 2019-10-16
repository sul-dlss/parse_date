# frozen_string_literal: true

RSpec.describe ParseDate do
  it 'has a version number' do
    expect(ParseDate::VERSION).not_to be nil
  end

  context '.year_range_valid?' do
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
end
