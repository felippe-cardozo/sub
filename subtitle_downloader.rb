# frozen_string_literal: true

require 'digest'
require 'net/https'
require 'ostruct'

class SubtitleDownloader
  VIDEO_EXTENSION_PATTERN = %w[avi mp4 mkv flv rm mwv m4v].freeze
  def initialize(path:, lang:)
    @base_dir = path
    @videos = videos_from_path(path)
    @lang = lang || 'pt'
  end

  def download
    mapped_videos = map_videos_to_hash(@videos)
    download_subs(mapped_videos)
  end

  private

  def videos_from_path(path)
    files = list_files_from_path(path)
    files.select { |file| file.end_with?(*VIDEO_EXTENSION_PATTERN) }
  end

  def list_files_from_path(path)
    return [path] if File.file?(path)

    Dir.entries(path).map { |file_path| File.join(@base_dir, file_path) }
  end

  def map_videos_to_hash(videos)
    videos.map do |video|
      OpenStruct.new(
        subdb_hash: generate_hash_for_subdb(video),
        subtitle: video.gsub(/\.[^.]*$/, '.srt')
      )
    end
  end

  def generate_hash_for_subdb(file_path)
    readsize = 64 * 1024
    File.open(file_path, 'rb') do |f|
      chunk = f.read(readsize)
      f.seek(-readsize, IO::SEEK_END)
      chunk += f.read(readsize)
      Digest::MD5.hexdigest(chunk)
    end
  end

  def download_subs(videos)
    header = {
      'User-Agent' =>
      'SubDB/1.0 (SubDB /1.0; https://github.com/felippe-cardozo/sub)'
    }
    http = Net::HTTP.new 'api.thesubdb.com'
    videos.each do |video|
      uri = "/?action=download&hash=#{video.subdb_hash}&language=#{@lang}"
      response = http.send_request('GET', uri, nil, header)

      puts "#{video.subtitle} was not found" if response.body.empty?

      File.open(video.subtitle, 'wb') { |sub| sub.write(response.body) }
      puts "#{video.subtitle} successfully downloaded"
    end
  end
end
