require 'dalli'

module Reports
  module Storage
    class Memcached
      def initialize(memcached=Dalli::Client.new)
        @memcached = memcached

        memcached.alive!
      rescue Dalli::RingError => e
        raise Reports::ConfigurationError.new("Could not connect to memcached: #{e.message}")
      end

      def read(key)
        value = @memcached.get(key)
        Marshal.load(value) if value
      end

      def write(key, value)
        @memcached.set(key, Marshal.dump(value))
      end

      def flush
        @memcached.flush
      end
    end
  end
end
