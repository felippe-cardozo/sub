#!/usr/bin/env ruby

require 'optparse'
require 'net/http'
require 'digest'

# Generates an object that downloads subtitles from subdb
class SubDownloader
  def initialize(options)
    @target = ARGV[0]
    @language = options[:language] || @language = 'pt'
    @count_sucess = 0
    @count_fail = 0
    if File.directory?(@target)
      @ext = options[:extension] || @ext = '*/*.{avi,mp4,mkv,mpeg,flv,rm,wmv, m4v}'
      @files = listfiles
      @files_and_hashes = gen_hashes
      downloadall
    elsif File.file?(@target)
      @files = [@target]
      @files_and_hashes = gen_hashes
      download @target
    else
      abort('Argument must be a file or a directory path')
    end
  end

  # translate the python function given by thesubdb api to get the hash of a
  # file
  def get_hash(name)
    readsize = 64 * 1024
    File.open(name, 'rb') do |f|
      # size = File.size?(name) #useless line from the api
      data = f.read(readsize)
      f.seek(-readsize, IO::SEEK_END)
      data += f.read(readsize)
      Digest::MD5.hexdigest(data)
    end
  end

  # generate an array of files in a directory
  def listfiles
    if @target[-1] != '/'
      Dir[@target + '/*' + @ext]
    else
      Dir[@target + '*' + @ext]
    end
  end

  # takes a file array and returns an array of hashes
  def gen_hashes
    hashes = []
    @files.each do |file|
      hashes << get_hash(file)
    end
    # make a dict with filenames as keys and hashes as values
    # (we need the filenames to save the srt files later)
    Hash[@files.zip hashes]
  end

  # downloads from individual hashes
  def download(hash)
    header = { 'User-Agent' => 'SubDB/1.0 (MejorSub /1.0;
      https://github.com/felippe-cardozo/sub)' }
    http = Net::HTTP.new 'api.thesubdb.com'
    begin
      download = http.send_request('GET', '/?action=download&hash=' + hash +
                                   "&language=#{@language}", nil, header)
      out = @files_and_hashes.key(hash).gsub(/\.[^.]*$/, '.srt')
      unless download.body.empty?
        File.open(out, 'wb') { |f| f.write(download.body) }
        puts out + 'successfully downloaded'
        @count_sucess += 1
      else
        puts out + 'failed'
        @count_fail += 1
      end
    rescue Exception => e
      puts e
    end
  end

  def downloadall
    @files_and_hashes.each do |_filename, hash|
      download hash
    end
    puts "#{@count_sucess} file(s) downloaded successfully" unless
    @count_sucess < 1
    puts "#{@count_fail} download(s) failed" unless @count_fail < 1
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
MejorSub.new(options) if !ARGV.empty?
