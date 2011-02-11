require "redis"

module UsefulStuff
  extend self

  attr_reader :configuration

  def setup
    @configuration ||= Configuration.new
    env = ENV['RACK_ENV'] || 'development'
    config_file = File.expand_path('../../../config.yml', __FILE__)
    configure do |config|
      hash = YAML.load(File.read(config_file))[env]
      config.from_hash(hash)
    end
    Cerberus.setup(@configuration)
  end

  def configure(&block)
    raise ArgumentError.new("block missing") unless block_given?
    yield @configuration
  end

  Error                 = Class.new(Exception)
  AttributeNotSupported = Class.new(Error)

  class Configuration
    ATTRIBUTE_NAMES = [:redis_host, :redis_port, :redis_db, :thread_safe]

    def initialize
      @options = {}
    end

    def from_hash(options)
      @options = options.symbolize_keys.slice(*ATTRIBUTE_NAMES)
    end

    private

    def method_missing(meth, *args, &blk)
      return @options[meth] if ATTRIBUTE_NAMES.include?(meth)
      if args.length == 1 && match = /^(.*)=$/.match(meth.to_s)
        name = match[1].to_sym
        return @options[name] = args.first if ATTRIBUTE_NAMES.include?(name)
      end
      raise AttributeNotSupported.new("attribute #{meth.to_s.inspect} is not supported")
    end
  end
end
