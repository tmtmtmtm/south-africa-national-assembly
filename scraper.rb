#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

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

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::AbsoluteUrls

  field :id do
    url.to_s[/person\/(.*)\//, 1]
  end

  field :name do
    name_data.last
  end

  field :honorific_prefix do
    name_data.first
  end

  field :party do
    party_data.first
  end

  field :party_id do
    party_data.last
  end

  field :area do
    area = sidebar.xpath('.//h3[.="Province"]/following-sibling::ul[1]/li').text.tidy
    return 'National' if area.to_s.empty?
    area
  end

  field :email do
    email_from(noko.css('div.contact-actions__email a[href*="mailto:"]/@href'))
  end

  field :term do
    '26'
  end

  field :image do
    noko.css('.profile-pic img/@src').text
  end

  field :identifier__peoples_assembly do
    noko.at_css('meta[name="pombola-person-id"]/@content').text
  end

  field :source do
    url.to_s
  end

  private

  def sidebar
    noko.css('div.constituency-party')
  end

  def party_node
    sidebar.at_xpath('.//h3[text()="Party"]/following-sibling::ul/li')
  end

  def party_data
    return %w[Independent IND] unless party_node
    party_info = party_node.text.tidy
    return %w[Independent IND] if party_info.include? 'Not a member of any party'
    party_info.match(/(.*) \((.*)\)/).captures rescue [party_info, '']
  end

  def name_data
    remove_prefixes(noko.css('div.title-space h1').text.gsub(/[[:space:]]+/, ' ').tidy)
  end

  def email_from(nodes)
    return if nodes.nil? || nodes.empty?
    nodes.first.text.sub('mailto:', '')
  end

  PREFIXES = %w[Adv Dr Mrs Mr Ms Professor Rev Prince].to_set
  def remove_prefixes(name)
    enum = name.split(/\s/).slice_before { |w| !PREFIXES.include? w.chomp('.') }
    [enum.take(1), enum.drop(1)].map { |l| l.join ' ' }
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

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('http://www.pa.org.za/organisation/national-assembly/people/')
