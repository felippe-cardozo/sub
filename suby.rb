#! /usr/bin/env ruby
require 'optparse'
require './sub'

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

def format_arg(arg)
  (arg + '/' unless arg[-1] == '/') || arg
end

if options.empty?
  Suby.new(ARGV[0]).downloadall
else
  Suby.new(ARGV[0],
           options[:language],
           options[:extension]).downloadall
end
