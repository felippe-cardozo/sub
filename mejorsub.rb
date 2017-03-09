#!/usr/bin/env ruby

require 'net/http'
require 'digest'

# Generates an object that downloads subtitles from subdb
class SubDownloader
  def initialize(folder, language = 'pt')
    @folder = folder
    @language = language
    @files = listfiles @folder
    @files_and_hashes = get_hashes @files
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
  def listfiles(folder)
    if folder[-1] != '/'
      Dir[folder + '/*']
    else
      Dir[folder + '*']
    end
  end

  # takes a file array and returns an array of hashes
  def get_hashes(filelist)
    hashes = []
    filelist.each do |file|
      hashes << get_hash(file)
    end
    # make a dict with filenames as keys and hashes as values
    # (we need the filenames to save the srt files later)
    Hash[filelist.zip hashes]
  end

  # downloads from individual hashes
  def download(hash)
    header = { 'User-Agent' => 'SubDB/1.0 (Subtitle-Downloader /1.0;
        https://github.com/gautamsawhney/Subtitle-Downloader)' }
    http = Net::HTTP.new 'api.thesubdb.com'
    begin
      download = http.send_request('GET', '/?action=download&hash=' + hash +
                                   "&language=#{@language}", nil, header)
      out = @files_and_hashes.key(hash).gsub(/\.[^.]*$/, '.srt')
      File.open(out, 'wb') { |f| f.write(download.body) }
      puts out + ' sucessfully downloaded'
    rescue Exception => e
      puts e
    end
  end

  def downloadall
    @files_and_hashes.each do |_filename, hash|
      download hash
    end
  end
end

s = SubDownloader.new ARGV[0]
s.downloadall
