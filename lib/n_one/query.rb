# frozen_string_literal: true

require 'pg_query'

module NOne
  # Abstract SQL fingerprinting
  module Query
    module_function

    def fingerprint(query)
      raise 'MySQL is not supported' if ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')

      begin
        PgQuery.fingerprint(query)
      rescue PgQuery::ParseError
        nil
      end
    end
  end
end
