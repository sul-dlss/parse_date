# frozen_string_literal: true

RSpec.describe ParseDate::IntFromString do
  unparseable = [ # here to remind us of what they might look like in our data
    nil,
    '',
    '[]',
    '?',
    'uuuu',
    'Aug',
    'publiée le 26 germinal an VI',
    "l'an IVe",
    'Feb',
    "L'AN 2 DE LA // LIBERTÉ",
    'Paris',
    "publié en frimaire l'an 3.e de la République française",
    'an 6',
    'an sept',
    's.n.]',
    'M. D. LXI',
    '[An 4]',
    '[s.d.]',
    'Undated',
    '1uuu'
  ]
  # example string as key, expected parsed value as value
  invalid_but_can_get_year = {
    '1966-14-14' => '1966',  # 14 isn't a valid month ...
    '1966\4\11' => '1966',   # slashes wrong way
    '2/31/1950' => '1950',   # no 31 of Feb
    '1869-00-00' => '1869',
    '1862-01-00' => '1862',
    '1985-05-00' => '1985'
  }
  # example string as key, expected parsed value as value
  single_year = {
    '0700' => '0700',
    '0999' => '0999',
    '1000' => '1000',
    '1798' => '1798',
    '1583.' => '1583',
    '1885-' => '1885',
    '1644.]' => '1644',
    '1644]' => '1644',
    '1584].' => '1584',
    '1729?]' => '1729',
    '1500 CE' => '1500',
    '1877?' => '1877',
    '1797 goda' => '1797',
    "1616: Con licenza de'svperiori" => '1616',

    '[1789]' => '1789',
    '[1968?-' => '1968',
    '[1860?]' => '1860',
    '[1789 ?]' => '1789',
    '[[1790]]' => '1790',
    '[1579].' => '1579',
    '[Ca 1790]' => '1790',
    '[c1926]' => '1926',
    '[ca 1790]' => '1790',
    '[ca. 1790]' => '1790',
    '[ca. 1850?]' => '1850',
    '[ca.1600]' => '1600',
    '[after 1726]' => '1726',
    '[an II, i.e. 1794]' => '1794',
    '[approximately 1600]' => '1600',
    '[approximately 1558].' => '1558',
    '[approximately 1717?]' => '1717',
    '[not after 1652]' => '1652',
    '[not before 1543].' => '1543',

    "A' 1640" => '1640',
    'A1566' => '1566',
    'Ans. 1656' => '1656',
    'Antonio Laffreri 1570' => '1570',
    'An 6. 1798' => '1798',
    'An 6 1798' => '1798',
    'a. 1652' => '1652',
    'ad decennium 1592' => '1592',
    'after 1622' => '1622',
    'an 10 (1802)' => '1802',
    'an 14, 1805' => '1805',
    'anno 1801' => '1801',
    'anno 1603.' => '1603',
    'approximately 1580.' => '1580',
    'approximately 1700?' => '1700',
    'approximately 1544]' => '1544',
    'anno 1599 (v. 1).' => '1599',
    'anno MDCXXXV [1635].' => '1635',
    'anno dom. 1600 (v. 3).' => '1600',
    'anno j65i [1651]' => '1651',
    'Ca. 1580 CE' => '1580',
    'c1887' => '1887',
    'ca 1796]' => '1796',
    'ca. 1558' => '1558',
    'ca. 1560?]' => '1560',
    'ca. 1700]' => '1700',
    'circa 1860' => '1860',
    'copyright 1855' => '1855',
    'en 1788' => '1788',
    'im jahr 1681' => '1681',
    "l'an 1.er de la Rep. 1792" => '1792',
    "l'anno1570" => '1570',
    'MDLXXXVIII [1588]]' => '1588',
    'MDLXI [1561]' => '1561',
    'MDCCLII. [1752-' => '1752',
    'No. 15 1792' => '1792',
    's.a. [1712]' => '1712',
    'publié le 24 floréal [1796]' => '1796',
    "Fructidor l'an 3.e [i.e. 1795]" => '1795'
  }
  # example string as key, expected parsed value as value
  specific_month = {
    '1975-05' => '1975', # vs 1918-27
    '1996 Jun' => '1996',
    'February 1798' => '1798',
    'March, 1794' => '1794',
    '[ ?] 10 1793' => '1793',
    'agosto 1799' => '1799',
    'Jan.y. thes.et 1798' => '1798',
    '[[décembre 1783]]' => '1783',
    'im Mai 1793' => '1793',
    'in Febr. 1795' => '1795',
    'juin année 1797' => '1797'
  }
  # example string as key, expected parsed value as value
  specific_day = {
    '1/1/1961' => '1961',
    '10/1/1987' => '1987',
    '5-1-1959' => '1959',

    # year first
    '1888-02-18' => '1888',
    '1966-2-5' => '1966',

    # text; starts with day
    '1 July 1799' => '1799',
    '1 Feb. 1782' => '1782',
    '15 Jan.y 1797' => '1797',
    '12.th May 1794' => '1794',
    '12th May 1794' => '1794',
    '12th Dec.r 1794' => '1794',
    '14th Feb.y 1794' => '1794',
    '18 Febr. 1790' => '1790',
    '23 Nov.r 1797' => '1797',

    # text; starts with year
    '1793 March 1st' => '1793',
    '1892, Jan. 1' => '1892',
    '1991 May 14' => '1991',
    '1997 Sep 6' => '1997',

    # text starts with words
    'Boston, November 25, 1851' => '1851',
    'd. 16 Feb. 1793' => '1793',
    'published the 30 of June 1799' => '1799',
    'Published the 1 of June 1799' => '1799',
    'Pub.d Nov.r 1st 1798' => '1798',
    'Published July 5th, 1784' => '1784',

    # text starts with month
    'April 01 1797' => '1797',
    'April 1 1796' => '1796',
    'April 1. 1796' => '1796',
    'April 16, 1632' => '1632',
    'April 11th 1792' => '1792',
    '[April 1 1795]' => '1795',

    'Aug. 1st 1797' => '1797',
    'Aug 30th 1794' => '1794',
    'Aug. 16 1790' => '1790',
    'Aug. 20, 1883' => '1883',
    'Aug. 3rd, 1886' => '1886',
    'Aug.st 4 1795' => '1795',
    'Aug.t 16 1794' => '1794',
    'Augt. 29, 1804' => '1804',
    'August 1 1794' => '1794',

    'Dec. 1 1792' => '1792',
    'Dec.r 1 1792' => '1792',
    'Dec.r 8th 1798' => '1798',
    'Decb.r 1, 1789' => '1789',
    'December 16 1795' => '1795',

    'Feb 12 1800' => '1800',
    'Feb. 10 1798' => '1798',
    'Feb. 25, 1744]' => '1744',
    'Feb.ry 12 1793' => '1793',
    'Feb.ry 7th 1796' => '1796',
    'Feb.y 1 1794' => '1794',
    'Feb.y 13th 1798' => '1798',
    'Feb.y 23rd 1799' => '1799',
    '[Feb.y 18 1793]' => '1793',

    'Jan. 1 1789' => '1789',
    'Jan. 1. 1795' => '1795',
    'Jan.y 15. 1795' => '1795',
    'Jan.y 12st 1793' => '1793',
    'Jan.y 18th 1790' => '1790',

    'July 1 1796' => '1796',
    'July 1. 1793' => '1793',
    'July 13, 1787' => '1787',
    'July 15th 1797' => '1797',

    'June 1 1793' => '1793',
    'June 1. 1800' => '1800',
    'June1st.1805' => '1805',
    'June 22, 1804' => '1804',
    'July 23d 1792' => '1792',
    'June 30th 1799' => '1799',
    '[June 2 1793]' => '1793',

    'May 9, 1795' => '1795',
    'May 12 1792' => '1792',
    'May 21st 1798' => '1798',
    'May 15th 1798' => '1798',

    'Mar. 1. 1792' => '1792',
    'March 1 1795' => '1795',
    'March 1.t 1797' => '1797',
    'March 1, 1793' => '1793',
    'March 1st 1797' => '1797',
    'March 6th 1798' => '1798',
    '[March 16 1798]' => '1798',

    'Nov. 1. 1796' => '1796',
    'Nov. 14th 1792' => '1792',
    'Nov. 20 1789' => '1789',
    'Nov.r 9, 1793' => '1793',
    'Novem. 13th 1797' => '1797',
    'Novembr 22nd 1794' => '1794',

    'Oct 12 1792' => '1792',
    'Oct 18th 1794' => '1794',
    'Oct. 29 1796' => '1796',
    'Oct. 11th 1794' => '1794',
    'Oct.er 1st 1786' => '1786',
    'Oct.r 25 1796' => '1796',
    'Oct.r 25th 1794' => '1794',
    'Octo.r 15 1795' => '1795',

    'Sep.r 1, 1795' => '1795',
    'Sep.tr 15.th 1796' => '1796',
    'Sept.r 5th 1793' => '1793'
  }
  specific_day_ruby_parse_fail = {
    # note ruby Date.parse only handles american or euro date order, not both ??
    '1/30/1979' => '1979',
    '10/20/1976' => '1976',
    '5-18-2014' => '2014',
    # year first
    '1980-23-02' => '1980',
    '1792 20 Dec' => '1792',
    # text
    'le 22 juin 1794' => '1794',
    'mis au jour le 26 juillet 1791' => '1791',
    'April 12 sd 1794' => '1794',
    'Dec. 10 & 11, 1855' => '1855',
    'January 22th [1800]' => '1800',
    'June the 12, 1794' => '1794',
    'Mai 1st 1789' => '1789',
    'March 22 d. 1794' => '1794',
    'N. 7 1796' => '1796',
    'N[ovember] 21st 1786' => '1786',
    'Oct. the 2.d 1793' => '1793'
  }
  # example string as key, expected parsed value as value
  specific_day_2_digit_year = {
    '1/2/79' => '1979',
    '2/12/15' => '2015',
    '6/11/99' => '1999',
    '10/1/90' => '1990',
    '10/21/08' => '2008',
    '5-1-59' => '1959',
    '5-1-21' => '1921',
    '5-1-14' => '2014'
  }
  # example string as key, expected parsed value as value
  multiple_years = {
    '1783-1788' => ['1783', '1784', '1785', '1786', '1787', '1788'],
    '1862-1868]' => ['1862', '1863', '1864', '1865', '1866', '1867', '1868'],
    '1640-1645?]' => ['1640', '1641', '1642', '1643', '1644', '1645'],
    '1578, 1584]' => ['1578', '1584'],
    '1860, [1862]' => ['1860', '1862'],
    '1901, c1900' => ['1901', '1900'], # pub date is one without the c,
    '1627 [i.e. 1646]' => ['1627', '1646'],
    '1698/1715' => ['1698', '1715'],
    '1965,1968' => ['1965', '1968'], # revs
    '1965|1968' => ['1965', '1968'], # revs
    '1789 ou 1790]' => ['1789', '1790'],
    '1689 [i.e. 1688-89]' => ['1689', '1688'],
    '1598 or 1599' => ['1598', '1599'],
    '1890 [c1884]' => ['1890', '1884'], # pub date is one without the c
    '1873,c1868' => ['1873', '1868'], # # pub date is one without the c
    '1872-1877 [t.5, 1874]' => ['1872', '1873', '1874', '1875', '1876', '1877'],
    '1809 [ca. 1810]' => ['1809', '1810'],
    '1726 or 1738]' => ['1726', '1738'],

    '[1789-1791]' => ['1789', '1790', '1791'],
    '[1627-1628].' => ['1627', '1628'],
    '[1789-1791' => ['1789', '1790', '1791'],
    '[1793 ou 1794]' => ['1793', '1794'],
    '[entre 1789 et 1791]' => ['1789', '1790', '1791'],
    '[Entre 1789 et 1791]' => ['1789', '1790', '1791'],
    '[entre 1789-1791]' => ['1789', '1790', '1791'],
    '[entre 1789 et 1791 ?]' => ['1789', '1790', '1791'],
    '[between 1882 and 1887]' => ['1882', '1883', '1884', '1885', '1886', '1887'],
    '[ca 1789-1791]' => ['1789', '1790', '1791'],
    '[ca 1790 et 1792]' => ['1790', '1791', '1792'],
    '[ca. 1550-1552]' => ['1550', '1551', '1552'],

    'Anno 1789-1790' => ['1789', '1790'],
    "L'an VII de la République [1798 or 1799]" => ['1798', '1799'],
    'MDCXIII [1613] (v. 1); MDLXXXIII [1583] (v. 2); and MDCVI [1606] (v. 3).' => ['1613', '1583', '1606'],
    'entre 1793 et 1795' => ['1793', '1794', '1795'],
    'entre 1793 et 1795]' => ['1793', '1794', '1795'],
    'approximately 1600-1602.' => ['1600', '1601', '1602'],
    'approximately 1650-1652]' => ['1650', '1651', '1652'],
    'approximately 1643-1644.]' => ['1643', '1644'],
    'ca. 1740-1745]' => ['1740', '1741', '1742', '1743', '1744', '1745'],
    'circa 1851-1852' => ['1851', '1852'],
    's.a. [ca. 1660, erschienen: 1782]' => ['1660', '1782'],
    'view of approximately 1848, published about 1865' => ['1848', '1865']
  }
  # example string as key, expected parsed value as value
  multiple_years_4_digits_once = {
    '1918-20' => ['1918', '1919', '1920'], # vs. 1961-04
    '1965-8' => ['1965', '1966', '1967', '1968'], # revs
    '[1846-51]' => ['1846', '1847', '1848', '1849', '1850', '1851']
  }
  # example string as key, expected parsed value as value
  decade_only_4_digits = {
    'early 1890s' => ['1890', '1891', '1892', '1893', '1894', '1895', '1896', '1897', '1898', '1899'],
    '1950s' => ['1950', '1951', '1952', '1953', '1954', '1955', '1956', '1957', '1958', '1959'],
    "1950's" => ['1950', '1951', '1952', '1953', '1954', '1955', '1956', '1957', '1958', '1959']
  }
  decade_only = {
    '156u' => ['1560', '1561', '1562', '1563', '1564', '1565', '1566', '1567', '1568', '1569'],
    '167-?]' => ['1670', '1671', '1672', '1673', '1674', '1675', '1676', '1677', '1678', '1679'],
    '[171-?]' => ['1710', '1711', '1712', '1713', '1714', '1715', '1716', '1717', '1718', '1719'],
    '[189-]' => ['1890', '1891', '1892', '1893', '1894', '1895', '1896', '1897', '1898', '1899'],
    'ca.170-?]' => ['1700', '1701', '1702', '1703', '1704', '1705', '1706', '1707', '1708', '1709'],
    '200-?]' => ['2000', '2001', '2002', '2003', '2004', '2005', '2006', '2007', '2008', '2009'],
    '186?' => ['1860', '1861', '1862', '1863', '1864', '1865', '1866', '1867', '1868', '1869'],
    '195x' => ['1950', '1951', '1952', '1953', '1954', '1955', '1956', '1957', '1958', '1959']
  }
  century_only = [
    '18th century CE',
    '17uu',
    '17--',
    '17--?]',
    '17--]',
    '[17--]',
    '[17--?]'
  ]
  brackets_in_middle_of_year = {
    '169[5]' => '1695',
    'October 3, [18]91' => '1891'
  }
  # we have data like this for our Roman coins collection
  early_numeric_dates = {
    '-999' => -999,
    '-914' => -914,
    '-18' => -18,
    '-1' => -1,
    '0' => 0,
    '5' => 5,
    '33' => 33,
    '945' => 945
  }
  bc_dates_to_int = {
    '801 B.C.' => -801,
    '800 B.C.' => -800,
    '750 B.C.' => -750,
    '700 B.C.' => -700,
    '699 B.C.' => -699,
    '75 B.C.' => -75,
    '8 B.C.' => -8
  }

  describe '.earliest_year' do
    single_year
      .merge(specific_month)
      .merge(specific_day)
      .merge(specific_day_2_digit_year)
      .merge(bc_dates_to_int)
      .merge(specific_day_ruby_parse_fail)
      .merge(brackets_in_middle_of_year)
      .merge(invalid_but_can_get_year).each do |example, expected|
      it "#{expected} for single value #{example}" do
        expect(ParseDate.earliest_year(example)).to eq expected.to_i
      end
    end

    it '1999 for 19990211' do
      expect(ParseDate.earliest_year('19990211')).to eq 1999
    end

    multiple_years
      .merge(multiple_years_4_digits_once)
      .merge(decade_only)
      .merge(decade_only_4_digits).each do |example, expected|
      it "#{expected.first} for multi-value #{example}" do
        expect(ParseDate.earliest_year(example)).to eq expected.first.to_i
      end
    end

    { # example string as key, expected result as value
      '1496-1499' => 1496,
      '1496 - 1499' => 1496,
      '1750?-1867' => 1750,
      '1265-1371?' => 1265,
      'ca. 1400-1525' => 1400,
      'between 1750-1800?' => 1750,
      '1835 or 1836' => 1835,
      '17-- or 18--' => 1700,
      '15-- or 16--?' => 1500,
      '17th or 18th century?' => 1600,
      'ca. 5th–6th century A.D.' => 400,
      'ca. 9th–8th century B.C.' => -999,
      'ca. 13th–12th century B.C.' => -1399,
      # '2nd millennium B.C. or ca. 8th century B.C.' => -899, # millennium not yet implemented
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.earliest_year(example)).to eq expected
      end
    end

    century_only.each do |example|
      it "1700 from #{example}" do
        expect(ParseDate.earliest_year(example)).to eq 1700
      end
    end

    {
      '5th century' => 400,
      '5th century B.C.' => -599,
      '1st century A.D.' => 0,
      '2th century CE' => 100,
      '11th century?' => 1000,
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.earliest_year(example)).to eq expected
      end
    end

    {
      '17--?-18--?' => 1700,
      '17--? - 18--?' => 1700,
      '12--? -13--?' => 1200
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.earliest_year(example)).to eq expected
      end
    end

    early_numeric_dates.each do |example, expected|
      it "#{example} for #{example}" do
        expect(ParseDate.earliest_year(example)).to eq expected
      end
    end

    { # example string as key, expected result as value
      'between 2000 and 1000 B.C.' => -2000,
      'between 300 and 150 BC.' => -300,
      'between 30 and 15 BC' => -30,
      'between 3 and 1 B. C.' => -3,
      'between 1000 and 2000' => 1000,
      'between 1694 and 1799?' => 1694,
      'between 1600? and 1683' => 1600,
      'between 1500 and 1799?)' => 1500,
      'between 150 and 300' => 150,
      'between 15 and 30' => 15,
      'between 1 and 5' => 1
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.earliest_year(example)).to eq expected
      end
    end

    it 'nil for -1666' do
      skip('code broken for -yyyy dates but no existing data for this yet')
      expect(ParseDate.earliest_year('-1666')).to eq nil
    end
    it '-1666 for 1666 B.C.' do
      expect(ParseDate.earliest_year('1666 B.C.')).to eq(-1666)
    end

    [ # bad dates
      '9999',
      '2035',
      '0000-00-00',
      'uuuu',
      '1uuu'
    ].each do |example|
      it "nil for #{example}" do
        expect(ParseDate.earliest_year(example)).to eq nil
      end
    end
  end

  describe '.latest_year' do
    single_year
      .merge(specific_month)
      .merge(specific_day)
      .merge(specific_day_2_digit_year)
      .merge(bc_dates_to_int)
      .merge(specific_day_ruby_parse_fail)
      .merge(brackets_in_middle_of_year)
      .merge(invalid_but_can_get_year).each do |example, expected|
      it "#{expected} for single value #{example}" do
        expect(ParseDate.latest_year(example)).to eq expected.to_i
      end
    end

    it '2000 for 20000222' do
      expect(ParseDate.latest_year('20000222')).to eq 2000
    end

    { # example string as key, expected result as value
      '1496-1499' => 1499,
      '1496 - 1499' => 1499,
      '1750?-1867' => 1867,
      '1265-1371?' => 1371,
      'ca. 1400-1525' => 1525,
      'between 1750-1800?' => 1800,
      '1757-58' => 1758,
      '1675-76?' => 1676,
      '1835 or 1836' => 1836,
      '17-- or 18--' => 1899,
      '15-- or 16--?' => 1699,
      '17th or 18th century?' => 1799,
      'ca. 5th–6th century A.D.' => 599,
      'ca. 9th–8th century B.C.' => -800,
      'ca. 13th–12th century B.C.' => -1200,
      # '2nd millennium B.C. or ca. 8th century B.C.' => -800, # millennium not yet implemented
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.latest_year(example)).to eq expected
      end
    end

    {
      '199u' => '1999',
      '200-' => '2009',
      '201?' => '2019',
      '115x' => '1159',
      '167-?]' => '1679',
      '[171-?]' => '1719',
      '[189-]' => '1899',
      'ca.170-?]' => '1709',
      '200-?]' => '2009',
      # not yet
      # '1950s' => '1959',
      # 'early 1890s' => '1895',
      # "1950's" => '1959'
    }.each do |example, expected|
      it "#{expected} for decade value #{example}" do
        expect(ParseDate.latest_year(example)).to eq expected.to_i
      end
    end

    # NOTE: not yet parsing this out
    # multiple_years
    #   .merge(multiple_years_4_digits_once).each do |example, expected|
    #   it "#{expected.last} for multi-value #{example}" do
    #     expect(ParseDate.latest_year(example)).to eq expected.last.to_i
    #   end
    # end

    century_only.each do |example|
      it "1799 from #{example}" do
        expect(ParseDate.latest_year(example)).to eq 1799
      end
    end

    {
      '5th century' => 499,
      '5th century B.C.' => -500,
      '1st century A.D.' => 99,
      '2th century CE' => 199,
      '11th century?' => 1099,
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.latest_year(example)).to eq expected
      end
    end

    {
      '17--?-18--?' => 1899,
      '17--? - 18--?' => 1899,
      '12--? -13--?' => 1399
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.latest_year(example)).to eq expected
      end
    end

    early_numeric_dates.each do |example, expected|
      it "#{example} for #{example}" do
        expect(ParseDate.latest_year(example)).to eq expected
      end
    end

    { # example string as key, expected result as value
      'between 2000 and 1000 B.C' => -1000,
      'between 300 and 150 B.C.' => -150,
      'between 30 and 15 BC' => -15,
      'between 3 and 1 B. C.' => -1,
      'between 1000 and 2000' => 2000,
      'between 1694 and 1799?' => 1799,
      'between 1600? and 1683' => 1683,
      'between 1500 and 1799?)' => 1799,
      'between 150 and 300' => 300,
      'between 15 and 30' => 30,
      'between 1 and 5' => 5
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.latest_year(example)).to eq expected
      end
    end

    it 'nil for -1666' do
      skip('code broken for -yyyy dates but no existing data for this yet')
      expect(ParseDate.latest_year('-1666')).to eq nil
    end
    it '-1666 for 1666 B.C.' do
      expect(ParseDate.latest_year('1666 B.C.')).to eq(-1666)
    end

    [ # bad dates
      '9999',
      '2035',
      '0000-00-00',
      'uuuu',
      '1uuu'
    ].each do |example|
      it "nil for #{example}" do
        expect(ParseDate.latest_year(example)).to eq nil
      end
    end
  end

  describe '.year_int_valid?' do
    { # example int as key, expected result as value
      -1666 => false,
      -999 => true,
      -35 => true,
      -3 => true,
      0 => true,
      5 => true,
      33 => true,
      150 => true,
      (Date.today.year + 1) => true, # current year + 1
      (Date.today.year + 2) => false, # current year + 2
      9999 => false,
      '165x' => false,
      '198-' => false,
      'random text' => false,
      nil => false
    }.each do |example, expected|
      it "#{expected} for #{example}" do
        expect(ParseDate.year_int_valid?(example)).to eq expected
      end
    end
    it 'true for 0000' do
      expect(ParseDate.year_int_valid?(0000)).to eq true
    end
  end

  context 'private instance methods - tests illustrate some nuances/make development easier' do
    describe '#hyphen_4digit_latest_year' do
      { # example string as key, expected result as value
        '1496-1499' => 1499,
        '1496 - 1499' => 1499,
        '1750?-1867' => 1867,
        '1265-1371?' => 1371,
        'ca. 1400-1525' => 1525,
        'between 1750-1800?' => 1800,
        '1966-2-5' => nil,
        '1888-02-18' => nil,
        '1975-05' => nil,
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:hyphen_4digit_latest_year, example)).to eq expected
        end
      end
    end

    describe '#hyphen_2digit_latest_year' do
      { # example string as key, expected result as value
        '1757-58' => 1758,
        '1675-76?' => 1676,
        '1675?-76' => 1676,
        '1675?-76?' => 1676,
        '1475 - 76' => 1476,
        'ca. 1960-64' => 1964,
        'between 1750-75?' => 1775,
        '1496-1499' => nil, # doesn't match pattern
        '1888-02-18' => nil, # doesn't match pattern
        '1975-05' => nil, # matches pattern, but range invalid
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:hyphen_2digit_latest_year, example)).to eq expected
        end
      end
    end

    describe '#yyuu_after_hyphen' do
      {
        '17--?-18--?' => 1899,
        '17--? - 18--?' => 1899,
        '12--? -13--?' => 1399
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:yyuu_after_hyphen, example)).to eq expected
        end
      end
    end

    describe '#earliest_century_bc' do
      {
        'ca. 9th–8th century B.C.' => -999,
        'ca. 13th–12th century B.C.' => -1399,
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:earliest_century_bc, example)).to eq expected
        end
      end
    end

    describe '#last_year_mult_centuries_bc' do
      {
        'ca. 9th–8th century B.C.' => -800,
        'ca. 13th–12th century B.C.' => -1200,
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:last_year_mult_centuries_bc, example)).to eq expected
        end
      end
    end

    describe '#last_year_mult_centuries' do
      {
        '17th or 18th century?' => 1799,
        'ca. 5th-6th century A.D.' => 599,
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:last_year_mult_centuries, example)).to eq expected
        end
      end
    end

    describe '#first_four_digits' do
      single_year
        .merge(specific_month)
        .merge(specific_day)
        .merge(invalid_but_can_get_year)
        .merge(specific_day_ruby_parse_fail).each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:first_four_digits, example)).to eq expected
        end
      end

      multiple_years
        .merge(multiple_years_4_digits_once)
        .merge(decade_only_4_digits).each do |example, expected|
        it "#{expected.first} for #{example}" do
          expect(ParseDate.send(:first_four_digits, example)).to eq expected.first
        end
      end

      # indicate some of the strings this method cannot handle (so must be parsed with other instance methods)
      unparseable
        .push(*brackets_in_middle_of_year.keys)
        .push(*specific_day_2_digit_year.keys)
        .push(*decade_only.keys)
        .push(*century_only).each do |example|
        it "nil for #{example}" do
          expect(ParseDate.send(:first_four_digits, example)).to eq nil if example
        end
      end
    end

    describe '#year_from_mm_dd_yy' do
      specific_day_2_digit_year.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:year_from_mm_dd_yy, example)).to eq expected
        end
      end
      it '2000 for 12/25/00' do
        expect(ParseDate.send(:year_from_mm_dd_yy, '12/25/00')).to eq '2000'
      end

      # indicate some of the strings this method cannot handle (so must be parsed with other instance methods)
      [
        '92/1/31',  # yy/mm/dd:  doesn't work.  :-(
        '92-31-1',  # yy-dd-mm:  doesn't work.  :-(
      ].push(*decade_only.keys).each do |example|
        it "nil for #{example}" do
          expect(ParseDate.send(:year_from_mm_dd_yy, example)).to eq nil
        end
      end
    end

    describe '#first_year_for_decade' do
      decade_only.each do |example, expected|
        it "#{expected.first} for #{example}" do
          expect(ParseDate.send(:first_year_for_decade, example)).to eq expected.first
        end
      end
      { # example string as key, expected result as value
        '199u' => '1990',
        '200-' => '2000',
        '201?' => '2010',
        '202x' => '2020'
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:first_year_for_decade, example)).to eq expected
        end
      end

      # some of the strings this method cannot handle (so must be parsed with other instance methods)
      decade_only_4_digits.keys.push(*specific_day_2_digit_year.keys).each do |example|
        it "nil for #{example}" do
          expect(ParseDate.send(:first_year_for_decade, example)).to eq nil
        end
      end
    end

    describe '#first_year_for_century' do
      century_only.each do |example|
        it "1700 from #{example}" do
          expect(ParseDate.send(:first_year_for_century, example)).to eq 1700
        end
      end
      it '700 for 7--' do
        expect(ParseDate.send(:first_year_for_century, '7--')).to eq 700
      end
      it '7th century B.C.' do
        expect(ParseDate.send(:first_year_for_century, '7th century B.C.')).to eq(-799)
      end
    end

    describe '#year_int_for_bc' do
      bc_dates_to_int.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:year_int_for_bc, example)).to eq expected
        end
      end
    end

    describe '#between_bc_earliest_year' do
      { # example string as key, expected result as value
        'between 2000 and 1000 B.C' => -2000,
        'between 300 and 150 B.C' => -300,
        'between 30 and 15 B.C' => -30,
        'between 3 and 1 B.C' => -3,
        'between 3 and 1 B.C.' => -3,
        'between 3 and 1 B. C.' => -3,
        'between 3 and 1 BC.' => -3,
        'Between 3 and 1 BC' => -3,
        'Between 650 and 750' => nil
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:between_bc_earliest_year, example)).to eq expected
        end
      end
    end

    describe '#between_bc_latest_year' do
      { # example string as key, expected result as value
        'between 2000 and 1000 B.C' => -1000,
        'between 300 and 150 B.C' => -150,
        'between 30 and 15 B.C' => -15,
        'between 3 and 1 B.C' => -1,
        'between 3 and 1 B.C.' => -1,
        'between 3 and 1 B. C.' => -1,
        'between 3 and 1 BC.' => -1,
        'Between 3 and 1 BC' => -1,
        'Between 1 and 3' => nil
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:between_bc_latest_year, example)).to eq expected
        end
      end
    end

    describe '#between_earliest_year' do
      { # example string as key, expected result as value
        'between 1000 and 2000' => 1000,
        'between 150 and 300' => 150,
        'between 15 and 30' => 15,
        'between 1 and 5' => 1,
        'Between 850 and 750 BC' => 850 # NOTE: must match for BC first
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:between_earliest_year, example)).to eq expected
        end
      end
    end

    describe '#between_latest_year' do
      { # example string as key, expected result as value
        'between 1000 and 2000' => 2000,
        'between 150 and 300' => 300,
        'between 15 and 30' => 30,
        'between 1 and 5' => 5,
        'Between 850 and 750 BC' => 750 # NOTE: must match for BC first
      }.each do |example, expected|
        it "#{expected} for #{example}" do
          expect(ParseDate.send(:between_latest_year, example)).to eq expected
        end
      end
    end
  end
end
