# frozen_string_literal: true

require_relative 'n_one/version'
require_relative 'n_one/query'
require_relative 'n_one/runner'

# Reliable N+1 detection based on sql fingerprinting
module NOne
  class NPlusOneDetected < StandardError #:nodoc:
    def initialize(report)
      @report = report
      super
    end

    def message
      @report.map do |detected_case|
        <<~MESSAGE
          SQL query called #{detected_case[:count]} times
          ---
          #{detected_case[:sql]}

          Backtrace:
          ---
          #{detected_case[:caller]}
        MESSAGE
      end.join("\n\n")
    end
  end

  module_function

  def scan(whitelist: [], &block)
    Runner.new(whitelist: whitelist).scan(&block)
  end

  def scan!(whitelist: [], &block)
    Runner.new(whitelist: whitelist).scan!(&block)
  end
end