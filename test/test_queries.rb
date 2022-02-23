# frozen_string_literal: true

require 'test_helper'

class TestQueries < Minitest::Test
  def setup
    create_chairs
  end

  def create_chairs(count = 20)
    create_list(:chair, count).each do |chair|
      create_list(:leg, 4, chair: chair)
    end
  end

  def assert_no_n_plus_one(whitelist: [], &block)
    report = NOne.scan(whitelist: whitelist) do
      block.call
    end
    assert(report.size.zero?)
  end

  def assert_n_plus_one(count: 1, whitelist: [], stacktrace_sanitizer: nil, &block)
    report = NOne.scan(whitelist: whitelist, stacktrace_sanitizer: stacktrace_sanitizer) do
      block.call
    end
    assert(report.size == count)
  end

  def trigger_ar_compiled_delegation
    klass = Class.new(Chair) do
      def self.some_records
        first(5)
      end
    end

    2.times { klass.all.some_records }
  end

  def test_stacktrace_sanitizer
    assert_no_n_plus_one do
      trigger_ar_compiled_delegation
    end

    sanitizer = lambda do |stacktrace|
      stacktrace.reject { |s| s.include?('/active_record/relation/delegation.rb') }
    end

    assert_n_plus_one(stacktrace_sanitizer: sanitizer) do
      trigger_ar_compiled_delegation
    end
  end

  def test_clean_scan
    assert_no_n_plus_one do
      Chair.includes(:legs).last(20).each do |c|
        c.legs.first
      end
    end
  end

  def test_n_plus_one_scan
    assert_n_plus_one do
      Chair.last(20).each do |c|
        c.legs.first
      end
    end
  end

  def test_pluck_in_has_many_loop
    assert_n_plus_one do
      Chair.last(20).each do |c|
        c.legs.pluck(:id)
      end
    end
  end

  def test_type_change
    assert_n_plus_one do
      Chair.last(20).map { |c| c.becomes(ArmChair) }.each do |ac|
        ac.legs.map(&:id)
      end
    end
  end

  def test_association_in_loop
    assert_n_plus_one do
      Leg.last(10).each(&:chair)
    end
  end

  def test_uniqueness_validations_is_not_captured
    assert_no_n_plus_one do
      Chair.last(10).each do |c|
        c.update(name: "#{c.name} + 1")
      end
    end
  end

  def test_scan_with_exception
    assert_raises NOne::NPlusOneDetected do
      NOne.scan! do
        Leg.last(10).each(&:chair)
      end
    end
  end

  def test_ignore_schema_names
    assert_raises NOne::NPlusOneDetected do
      NOne.scan! do
        10.times { ActiveRecord::Base.connection.execute('SELECT COUNT(*) FROM chairs', 'COUNTS') }
      end
    end

    NOne.scan!(ignore_names: ['COUNTS']) do
      10.times { ActiveRecord::Base.connection.execute('SELECT COUNT(*) FROM chairs', 'COUNTS') }
    end
  end
end
