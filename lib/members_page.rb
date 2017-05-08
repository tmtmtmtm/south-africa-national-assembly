# frozen_string_literal: true

require 'scraped'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :member_urls do
    noko.css('.list-of-people a[href*="/person/"]/@href').map(&:text)
  end

  field :next_page do
    noko.css('.pagination a.next/@href').text
  end
end
