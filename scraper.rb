#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :member_urls do
    noko.css('.list-of-people a[href*="/person/"]/@href').map(&:text)
  end

  field :next_page do
    noko.css('.pagination a.next/@href').text
  end
end

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def scrape_list(list_url)
  page = scrape(list_url => MembersPage)
  page.member_urls.each { |url| scrape_person(url) }
  scrape_list(page.next_page) unless page.next_page.to_s.empty?
end

def scrape_person(url)
  data = scrape(url => MemberPage).to_h
  # puts data.reject { |k, v| v.to_s.empty? }.sort_by { |k, v| k }.to_h
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://www.pa.org.za/organisation/national-assembly/people/')
