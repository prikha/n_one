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

  def assert_n_plus_one(count: 1, whitelist: [], &block)
    report = NOne.scan(whitelist: whitelist) do
      block.call
    end
    assert(report.size == count)
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
end
