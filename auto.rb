require 'envyable'
require 'gibbon'
require 'pinboard'
require 'liquid'

Envyable.load 'config/env.yml', 'development'

Gibbon::Export.new(ENV['MAILCHIMP_API_KEY'])
Gibbon::Export.timeout = 15
Gibbon::Export.throws_exceptions = false

Liquid::Template.file_system = Liquid::LocalFileSystem.new('templates/partials')

gb = Gibbon::API.new
list = gb.lists.list({ filters: { list_name: 'UX Weekly' } })
list_id = list['data'][0]['id']

pinboard = Pinboard::Client.new(:username => ENV['PINBOARD_USERNAME'],
                                :password => ENV['PINBOARD_PASSWORD'])

edition = 118

upcoming = pinboard.posts(tag: 'uxweekly-sending')

upcoming_hash = upcoming.map do |link|
  tag_regex = /\/\/\/([A-Za-z]*)\/\/\//
  tag = tag_regex.match(link.to_h[:extended])

  # Liquid only accepts string hashes, not ruby 1.9 hashes
  # https://github.com/Shopify/liquid/issues/289
  link_hash = link.to_h
  { "description" => link_hash[:description],
    "href" => link_hash[:href],
    "extended" => link_hash[:extended].gsub(tag_regex, ''),
    "tag" => tag ? tag[1] : '' }

end

subject = "UX Weekly #{edition}: Not just another link dump"

source = File.read('templates/uxweekly-mailchimp-template.liquid', :encoding => 'utf-8')
html = Liquid::Template.parse(source).render 'upcoming' => upcoming_hash,
                                             'edition' => edition,
                                             'sent_on' => Date.today

# puts html

gb.campaigns.create({ type: 'regular',
                      options: { list_id: list_id,
                                 subject: subject,
                                 from_email: 'simon@uxwkly.com',
                                 from_name: 'Simon',
                                 generate_text: true
                                 },
                      content: { html: html }
                    })

