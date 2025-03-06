# this tool generates the link table for the README.md file
# in Awesome Web Desktops repository

require 'json'
require 'rest-client'

def escape_markdown(text)
  text.gsub(/([\\\|])/, '\\\\\1').gsub("\n", '<br>')
end

websites_object = JSON.parse(RestClient.get('https://raw.githubusercontent.com/syxanash/syxanash.github.io/development/src/resources/remote-desktops.json'))

markdown_content = ''

websites_object.each do |website|
  escaped_website_name = escape_markdown(website['name'])
  markdown_content += "[#{escaped_website_name}](#{website['url']}) |"

  if website['source'].empty?
    markdown_content += ' ![locked](assets/locked.png) private |'
  else
    markdown_content += " [![open](assets/open.png) available](#{website['source']}) |"
  end

  unless website['notes'].empty?
    markdown_content += " #{escape_markdown(website['notes'])} |"
  end

  markdown_content += "\n"
end

puts markdown_content
