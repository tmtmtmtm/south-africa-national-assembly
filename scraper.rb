# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def scraper(config)
  url, klass = config.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def members_data(list_url)
  page = scraper(list_url => MembersPage)
  data = page.member_urls.map { |url| member_data(url) }
  return data if page.next_page.empty?
  data + members_data(page.next_page)
end

def member_data(url)
  scraper(url => MemberPage).to_h
end

def scrape_for_term(term)
  members_data("https://www.pa.org.za/position/member/parliament/national-assembly/?session=na#{term}")
end

def get_members_with_term(term)
  scrape_for_term(term).map { |member| member.to_h.merge(term: term) }
end

data = []

26.upto(27).each do |term|
  data += get_members_with_term(term)
end

data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i[id term], data)
