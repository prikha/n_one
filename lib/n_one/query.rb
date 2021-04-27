# frozen_string_literal: true

module NOne
  # Abstract SQL fingerprinting
  module Query
    module_function

    def fingerprint(query)
      raise 'MySQL is not supported' if ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')

      try_pg_fingerpring(query)
    end

    def try_pg_fingerpring(query)
      require_missing_dependency

      begin
        PgQuery.fingerprint(query)
      rescue PgQuery::ParseError
        nil
      end
    end

    def require_missing_dependency
      require 'pg_query'
    rescue LoadError => e
      msg = "Could not load the 'pg_query' gem. Add `gem 'pg_query'` to your Gemfile"
      raise LoadError, msg, e.backtrace
    end
  end
end
