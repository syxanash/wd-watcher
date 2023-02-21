require 'selenium-webdriver'
require 'json'
require 'rest-client'
require 'colorize'
require 'fuzzystringmatch'
require 'fileutils'

SIMILARITY_THRESHOLD = 70

# https://stackoverflow.com/a/10823131
def sanitize_filename(filename)
  # Split the name when finding a period which is preceded by some
  # character, and is followed by some character other than a period,
  # if there is no following period that is followed by something
  # other than a period (yeah, confusing, I know)
  fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

  # We now have one or two parts (depending on whether we could find
  # a suitable period). For each of these parts, replace any unwanted
  # sequence of characters with an underscore
  fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

  # Finally, join the parts with a period and return the result
  fn.join '.'
end

websites_object = JSON.parse(RestClient.get('https://raw.githubusercontent.com/syxanash/syxanash.github.io/development/src/resources/remote-desktops.json'))
jarow = FuzzyStringMatch::JaroWinkler.create(:native)

websites_object.each_with_index do |website_obj, index|
  directory_name = "archive/#{sanitize_filename(website_obj['name'])}"

  first_scan = false

  if !Dir.exist? directory_name
    FileUtils.mkdir_p(directory_name)
  end

  begin
    print "[#{index + 1}/#{websites_object.size}]".yellow
    print " Scanning #{website_obj['name']}...".blue

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')

    driver = Selenium::WebDriver.for :chrome, options: options
    driver.manage.window.resize_to(1792, 1120)
    driver.get website_obj['url']
    sleep(1)
    source = driver.page_source
    driver.quit

    if File.exist? "#{directory_name}/recent.html"
      FileUtils.cp("#{directory_name}/recent.html", "#{directory_name}/previous.html")
    else
      first_scan = true
      puts 'Initialized.'.yellow
    end

    File.write("#{directory_name}/recent.html", source)

    if !first_scan
      print 'Comparing...'.light_blue
      first_file = File.read("#{directory_name}/recent.html")
      second_file = File.read("#{directory_name}/previous.html")

      if jarow.getDistance(first_file, second_file).to_f * 100 < SIMILARITY_THRESHOLD
        puts ''
        puts '[?] Found differences in:'.yellow
        puts website_obj['url']
      end
    end
    puts 'Done.'
  rescue StandardError => error
    puts ''
    puts "[!] Can't connect to: #{website_obj['url']}".red
    puts error.to_s.red
  end
end

Dir.chdir('archive') do
  website_folders = Dir.glob('*')

  if website_folders.size > websites_object.size
    object_directory_names = websites_object.map { |item| sanitize_filename(item['name']) }

    different_folders = website_folders - object_directory_names

    different_folders.each do |folder_to_remove|
      puts "[X] Removed #{folder_to_remove}".cyan
      FileUtils.rm_rf(folder_to_remove)
    end
  end
end

puts 'All Done.'

#https://imagemagick.org/script/command-line-options.php#metric
#compare 1.png 2.png -metric FUZZ null:

#   if !first_scan
#     first_file = "#{directory_name}/selenium.png"
#     second_file = "#{directory_name}/previous.png"

#     comparison = `compare #{first_file} #{second_file} -metric FUZZ null: 2>&1`

#     compare_percentage = /\((.*?)\)%?/mi.match(comparison)[1].to_f * 100

#     if compare_percentage > 45
#       puts "something wrong with:"
#       puts website_obj['url']
#     end
#   end