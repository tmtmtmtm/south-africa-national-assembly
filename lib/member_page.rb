# frozen_string_literal: true

require 'scraped'

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.to_s[/person\/(.*)\//, 1]
  end

  field :name do
    name_data.name
  end

  field :honorific_prefix do
    name_data.prefix
  end

  field :party do
    party_data.first
  end

  field :party_id do
    party_data.last
  end

  field :party_wikidata_id do
    party_identifier = party_node.at_xpath('.//a/@data-identifier-wikidata')
    return nil if party_identifier.to_s.empty?
    party_identifier.text
  end

  field :area do
    area = area_node.text.tidy
    return 'National' if area.to_s.empty?
    area
  end

  field :area_wikidata_id do
    area_id = area_node.at_xpath('.//a/@data-identifier-wikidata')
    return nil if area_id.to_s.empty?
    area_id.text
  end

  field :email do
    sorted_email_list.join(' ; ')
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

  field :identifier__wikidata do
    wikidata_identifier = noko.at_css('meta[name="pa:identifier-wikidata"]/@content')
    return nil if wikidata_identifier.to_s.empty?
    wikidata_identifier.text
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

  def area_node
    sidebar.xpath('.//h3[.="Province"]/following-sibling::ul[1]/li')
  end

  def name_data
    fragment(noko.css('div.title-space h1') => MemberName)
  end

  def email_node
    noko.css('.email-address a[href*="mailto:"]/@href')
  end

  def email_list
    email_node.map do |node|
      node.text.sub('mailto:', '')
    end
  end

  def sorted_email_list
    email_list.sort_by { |e| e.include?('parliament.gov.za') ? -1 : 1 }
  end
end
