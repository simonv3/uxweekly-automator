require 'envyable'
require 'gibbon'
require 'pinboard'
require 'liquid'
require 'optparse'

Envyable.load 'config/env.yml', 'development'

Gibbon::Export.new(ENV['MAILCHIMP_API_KEY'])
Gibbon::Export.timeout = 15
Gibbon::Export.throws_exceptions = false

Liquid::Template.file_system = Liquid::LocalFileSystem.new('templates/partials')

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: auto.rb [options]"

  opts.on('-i', '--issue ISSUE', 'Issue Number') { |v| options[:issue] = v }
  opts.on('-b', '--blurb BLURB', 'Blurb') { |v| options[:blurb] = v }
end.parse!

gb = Gibbon::API.new
list = gb.lists.list({ filters: { list_name: 'UX Weekly' } })
list_id = list['data'][0]['id']

pinboard = Pinboard::Client.new(:username => ENV['PINBOARD_USERNAME'],
                                :password => ENV['PINBOARD_PASSWORD'])

edition = options[:issue]
blurb = options[:blurb]

puts blurb

upcoming = pinboard.posts(tag: 'uxweekly-sending')

upcoming_hash = upcoming.map do |link|
  tag_regex = /\/\/\/([A-Za-z]*)\/\/\//
  extra_regex = /---(\n.*)/
  tag = tag_regex.match(link.to_h[:extended])


  # Liquid only accepts string hashes, not ruby 1.9 hashes
  # https://github.com/Shopify/liquid/issues/289
  link_hash = link.to_h
  extended = link_hash[:extended].gsub(tag_regex, '').gsub(extra_regex, '')
  { "description" => link_hash[:description],
    "href" => link_hash[:href],
    "extended" => extended,
    "tag" => tag ? tag[1] : '' }

end

upcoming_hash.sort! do |a, b|
  if a['tag'] == "Job"
    1
  elsif b['tag'] == "Job"
    -1
  else
    0
  end
end

subject = "UX Weekly ##{edition}"

source = File.read('templates/uxweekly-mailchimp-template.liquid', :encoding => 'utf-8')
html = Liquid::Template.parse(source).render 'upcoming' => upcoming_hash,
                                             'edition' => edition,
                                             'blurb' => blurb,
                                             'sent_on' => Date.today

gb.campaigns.create({ type: 'regular',
                      options: { list_id: list_id,
                                 subject: subject,
                                 from_email: 'simon@uxwkly.com',
                                 from_name: 'Simon',
                                 generate_text: true
                                 },
                      content: { html: html }
                    })

puts "created"
