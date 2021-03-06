require 'optparse'
require 'oink/reports/base'
require 'oink/reports/active_record_instantiation_report'
require 'oink/reports/memory_usage_report'

module Oink
  class Cli

    def initialize(args)
      @args = args
    end

    def process
      options = { :format => :short_summary, :type => :memory }

      op = OptionParser.new do |opts|
        opts.banner = "Usage: oink [options] files"

        opts.on("-t", "--threshold [INTEGER]", Integer,
                "Memory threshold in MB") do |threshold|
          options[:threshold] = threshold
        end

        opts.on("-f", "--file filepath", "Output to file") do |filename|
          options[:output_file] = filename
        end

        format_list = (Oink::Reports::Base::FORMAT_ALIASES.keys + Oink::Reports::Base::FORMATS).join(',')
        opts.on("--format FORMAT", Oink::Reports::Base::FORMATS, Oink::Reports::Base::FORMAT_ALIASES, "Select format",
                "  (#{format_list})") do |format|
          options[:format] = format.to_sym
        end

        opts.on("-m", "--memory", "Check for Memory Threshold (default)") do |v|
           options[:type] = :memory
        end

        opts.on("-r", "--active-record", "Check for Active Record Threshold") do |v|
           options[:type] = :active_record
        end

      end

      op.parse!(@args)

      #if @args.empty?
        #puts op
        #exit
      #end

      output = nil

      if options[:output_file]
        output = File.open(options[:output_file], 'w')
      else
        output = STDOUT
      end

      files = get_file_listing(@args)

      handles = files.map { |f| File.open(f) }
      
      if handles.empty?
        puts "no input files, reading from STDIN"
        handles << STDIN 
      end

      if options[:type] == :memory

        options[:threshold] ||= 75
        options[:threshold] *= 1024

        Oink::Reports::MemoryUsageReport.new(handles, options[:threshold], :format => options[:format]).print(output)

      elsif options[:type] == :active_record

        options[:threshold] ||= 500

        Oink::Reports::ActiveRecordInstantiationReport.new(handles, options[:threshold], :format => options[:format]).print(output)

      end

      output.close
      handles.each { |h| h.close }
    end

  protected

    def get_file_listing(args)
      listing = []
      args.each do |file|
        unless File.exist?(file)
          raise "Could not find \"#{file}\""
        end
        if File.directory?(file)
          listing += Dir.glob("#{file}/**")
        else
          listing << file
        end
      end
      listing
    end

  end
end

