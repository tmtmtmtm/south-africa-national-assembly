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

def list_data(list_url)
  scrape(list_url => MembersPage).member_urls.map { |url| person_data(url) }
  scrape_list(page.next_page) unless page.next_page.to_s.empty?
end

def scrape_person(url)
  data = scrape(url => MemberPage).to_h
  puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('https://www.pa.org.za/organisation/national-assembly/people/')
