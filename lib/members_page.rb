# frozen_string_literal: true

require 'scraped'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :member_urls do
    noko.css('.list-of-things-item a[href*="/person/"]/@href').map(&:text)
  end

  field :next_page do
    noko.css('.pagination a.next/@href').text
  end

  field :term do
    URI.decode_www_form(URI.parse(url).query).to_h['session'][2..-1]
  end
end
