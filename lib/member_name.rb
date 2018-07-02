# frozen_string_literal: true

require 'scraped'

class MemberName < Scraped::HTML
  field :prefix do
    partitioned.first.join(' ')
  end

  field :name do
    partitioned.last.join(' ')
  end

  field :gender do
    return 'male' if (prefixes & MALE_PREFIXES).any?
    return 'female' if (prefixes & FEMALE_PREFIXES).any?
  end

  private

  FEMALE_PREFIXES  = %w[mrs ms].freeze
  MALE_PREFIXES    = %w[mr prince].freeze
  OTHER_PREFIXES   = %w[adv dr minister prof professor rev].freeze
  PREFIXES         = FEMALE_PREFIXES + MALE_PREFIXES + OTHER_PREFIXES

  def partitioned
    words.partition { |w| PREFIXES.include? w.chomp('.').downcase }
  end

  def prefixes
    partitioned.first.map { |w| w.chomp('.') }
  end

  def words
    noko.text.gsub(/[[:space:]]+/, ' ').tidy.split(/\s+/)
  end
end
