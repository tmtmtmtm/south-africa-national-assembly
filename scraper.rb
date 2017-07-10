#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def scrape_list(list_url)
  page = scrape(list_url => MembersPage)
  page.member_urls.each { |url| scrape_person(url, term: page.term) }
  scrape_list(page.next_page) unless page.next_page.to_s.empty?
end

def scrape_person(url, term:)
  data = scrape(url => MemberPage).to_h.merge(term: term)
  puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
25.upto(26).each do |term|
  scrape_list("https://www.pa.org.za/position/member/parliament/national-assembly/?session=na#{term}")
end
