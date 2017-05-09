#! /usr/bin/env ruby

require 'optparse'
require 'net/https'
require 'digest'

class SubDB
  attr_accessor :dir_path, :language, :extension
  def initialize(dir_path, language = 'pt',
                 extension = '*/*.{avi,mp4,mkv,flv,rm,mwv,m4v}')
    @dir_path = dir_path
    @language = language
    @extension = extension
    if @dir_path
      @files = extract_files
      @files_md5 = md5_dict
    end
  end

  # translation of thesubdb api method
  def get_md5(file_path)
    readsize = 64 * 1024
    File.open(file_path, 'rb') do |f|
      data = f.read(readsize)
      f.seek(-readsize, IO::SEEK_END)
      data += f.read(readsize)
      Digest::MD5.hexdigest(data)
    end
  end

  def extract_files
    if @dir_path[-1] == '/'
      Dir[@dir_path + '*' + @extension]
    else
      Dir[@dir_path + '/*' + @extension]
    end
  end

  def md5_dict
    md5 = []
    @files.each do |file|
      md5 << get_md5(file)
    end
    # generate an Hash with file_path as key and md5 as value
    Hash[@files.zip md5]
  end

  def download(md5)
    header = { 'User-Agent' => 'SubDB/1.0 (SubDB /1.0;
https://github.com/felippe-cardozo/sub)' }
    http = Net::HTTP.new 'api.thesubdb.com'
    begin
      download = http.send_request('GET', '/?action=download&hash=' + md5 +
                                   "&language=#{language}", nil, header)
      write(download, md5)
    rescue Exception => e
      puts e
    end
  end

  def write(content, md5)
    output = @files_md5.key(md5).gsub(/\.[^.]*$/, '.srt')
    if content.body.empty?
      puts out + 'failed'
    elsif File.file?(output)
      puts "file #{output} already exists"
    else
      File.open(output, 'wb') { |f| f.write(content.body) }
      puts output + 'successfully downloaded'
    end
  end

  def downloadall
    @files_md5.each do |_name, md5|
      download md5
    end
  end
end


options = {}
opt_parser = OptionParser.new do |opt|
  opt.banner = 'Usage: mejorsub.rb [OPTIONS] file_or_dir_path'
  opt.on('-l arg', '--language=arg', 'select target language to the
         subtitle(s)') do |lang|
    options[:language] = lang
  end
  opt.on('-e arg', '--extension=arg', 'manually select the video(s)
          extension(s) (RECOMMENDED') do |ext|
    options[:extension] = ext
  end
  opt.on('-h', '--help', 'help') do
    puts opt_parser
  end
end

opt_parser.parse!

if options.empty?
  SubDB.new(ARGV[0]).downloadall
else
  SubDB.new(ARGV[0],
            options[:language],
            options[:extension]).downloadall
end
