# frozen_string_literal: true

module NOne
  class Runner # :nodoc:
    # Instantiation
    #
    # @param whitelist [<String>] frame substrings to be ignored
    # @param ignore_names [<String>] query names to be ignored
    # @param stacktrace_sanitizer [Proc<Array<String>>] if given, used to filter the stack trace
    #   that is used to calculate the location key
    #
    def initialize(whitelist: [], ignore_names: [], stacktrace_sanitizer: nil)
      @whitelist = ['active_record/validations/uniqueness'] + whitelist
      @ignore_names = ignore_names
      @stacktrace_sanitizer = stacktrace_sanitizer
    end

    def scan(&block)
      init_store
      record_sql(&block)
      detect_n_plus_ones
    end

    def scan!(&block)
      report = scan(&block)

      raise NPlusOneDetected, report unless report.empty?
    end

    private

    attr_reader :store, :whitelist, :ignore_names

    def init_store
      @store = {}
    end

    def detect_n_plus_ones # rubocop:disable  Metrics/AbcSize, Metrics/MethodLength
      store.values.map do |statement|
        next if statement[:count] <= 1
        next if statement[:caller].any? do |backtrace_line|
                  whitelist.any? do |whitelisted|
                    backtrace_line.include?(whitelisted)
                  end
                end

        compact_caller = statement[:caller].reject { |line| line.include?(::Bundler.bundle_path.to_s) }

        {
          sql: statement[:sql],
          count: statement[:count],
          caller: compact_caller
        }
      end.compact
    end

    def record_sql(&block) # rubocop:disable  Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
      subscriber = ActiveSupport::Notifications.subscribe 'sql.active_record' do |_, _, _, _, data|
        sql = data[:sql]
        cached = data[:cached]

        next if !sql.include?('SELECT') || cached
        next if ignore_names.include?(data[:name])

        sql_fingerprint = Query.fingerprint(sql)
        next unless sql_fingerprint

        stacktrace = caller
        stacktrace = @stacktrace_sanitizer.call(stacktrace) if @stacktrace_sanitizer
        location_key = Digest::SHA1.hexdigest(stacktrace.join)

        store["#{sql_fingerprint}_#{location_key}"] ||= {
          count: 0,
          sql: [],
          caller: nil
        }

        store["#{sql_fingerprint}_#{location_key}"][:count] += 1
        store["#{sql_fingerprint}_#{location_key}"][:sql] << sql
        store["#{sql_fingerprint}_#{location_key}"][:sql].uniq!
        store["#{sql_fingerprint}_#{location_key}"][:caller] ||= stacktrace
      end

      block.call
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end
end
