# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Aggregation::Sum do
  let(:start_time_unix_nano) { now_in_nano }
  let(:end_time_unix_nano) { start_time_unix_nano + 60*(10**9) }

  describe '.new' do
    it 'defaults to aggregation_temporality :delta' do
      sum = build_sum

      assert(sum.aggregation_temporality == :delta)
    end

    it 'defaults to monotonic true' do
      sum = build_sum

      assert(sum.monotonic == true)
    end
  end

  describe '#aggregation_temporality' do
    it 'returns aggregation_temporality' do
      sum = build_sum(aggregation_temporality: :delta)
      assert(sum.aggregation_temporality == :delta)

      sum = build_sum(aggregation_temporality: :cumulative)
      assert(sum.aggregation_temporality == :cumulative)
    end
  end

  describe '#monotonic' do
    it 'returns monotonic' do
      sum = build_sum(monotonic: true)
      assert(sum.monotonic == true)

      sum = build_sum(monotonic: false)
      assert(sum.monotonic == false)
    end
  end

  describe '#update' do
    describe 'when number data point does not exist' do
      it 'creates a new one and set increment' do
        sum = build_sum

        sum.update(5, { 'service' => 'aaa' })
        sum.update(1, { 'service' => 'bbb' })

        number_data_points = sum.collect(start_time_unix_nano, end_time_unix_nano)
        assert(number_data_points.size == 2)

        assert(number_data_points[0].value == 5)
        assert(number_data_points[0].attributes == { 'service' => 'aaa' })

        assert(number_data_points[1].value == 1)
        assert(number_data_points[1].attributes == { 'service' => 'bbb' })
      end
    end

    describe 'when number data point exists' do
      it 'updates the existing one adding increment' do
        sum = build_sum

        sum.update(5, { 'service' => 'aaa' })
        sum.update(1, { 'service' => 'bbb' })
        sum.update(10, { 'service' => 'aaa' })

        number_data_points = sum.collect(start_time_unix_nano, end_time_unix_nano)
        assert(number_data_points.size == 2)

        assert(number_data_points[0].value == 15)
        assert(number_data_points[0].attributes == { 'service' => 'aaa' })

        assert(number_data_points[1].value == 1)
        assert(number_data_points[1].attributes == { 'service' => 'bbb' })
      end
    end
  end

  describe '#collect' do
    describe 'when aggregation_temporality is :delta' do
      it'sets timestamps, returns array of number data points and clears, not aggregating between calls' do
        sum = build_sum(aggregation_temporality: :delta)

        sum.update(5, { 'service' => 'aaa' })
        sum.update(1, { 'service' => 'bbb' })

        number_data_points = sum.collect(start_time_unix_nano, end_time_unix_nano)
        assert(number_data_points.size == 2)

        assert(number_data_points[0].value == 5)
        assert(number_data_points[0].attributes == { 'service' => 'aaa' })
        assert(number_data_points[0].start_time_unix_nano == start_time_unix_nano)
        assert(number_data_points[0].time_unix_nano == end_time_unix_nano)

        assert(number_data_points[1].value == 1)
        assert(number_data_points[1].attributes == { 'service' => 'bbb' })
        assert(number_data_points[1].start_time_unix_nano == start_time_unix_nano)
        assert(number_data_points[1].time_unix_nano == end_time_unix_nano)

        new_start_time_unix_nano = start_time_unix_nano + 10*(10**9)
        new_end_time_unix_nano = end_time_unix_nano + 10*(10**9)

        number_data_points = sum.collect(new_start_time_unix_nano, new_end_time_unix_nano)
        assert(number_data_points.empty?)

        sum.update(10, { 'service' => 'aaa' })

        number_data_points = sum.collect(new_start_time_unix_nano, new_end_time_unix_nano)
        assert(number_data_points.size == 1)

        assert(number_data_points[0].value == 10)
        assert(number_data_points[0].attributes == { 'service' => 'aaa' })
        assert(number_data_points[0].start_time_unix_nano == new_start_time_unix_nano)
        assert(number_data_points[0].time_unix_nano == new_end_time_unix_nano)

        number_data_points = sum.collect(new_start_time_unix_nano, new_end_time_unix_nano)
        assert(number_data_points.empty?)
      end
    end

    describe 'when aggregation_temporality is not :delta' do
      it 'sets timestamps, returns array of number data points but does not clear, aggregating between calls' do
        sum = build_sum(aggregation_temporality: :anything)

        sum.update(5, { 'service' => 'aaa' })
        sum.update(1, { 'service' => 'bbb' })

        number_data_points = sum.collect(start_time_unix_nano, end_time_unix_nano)
        assert(number_data_points.size == 2)

        assert(number_data_points[0].value == 5)
        assert(number_data_points[0].attributes == { 'service' => 'aaa' })
        assert(number_data_points[0].start_time_unix_nano == start_time_unix_nano)
        assert(number_data_points[0].time_unix_nano == end_time_unix_nano)

        assert(number_data_points[1].value == 1)
        assert(number_data_points[1].attributes == { 'service' => 'bbb' })
        assert(number_data_points[1].start_time_unix_nano == start_time_unix_nano)
        assert(number_data_points[1].time_unix_nano == end_time_unix_nano)

        sum.update(10, { 'service' => 'aaa' })
        sum.update(3, { 'service' => 'ccc' })

        new_start_time_unix_nano = start_time_unix_nano + 10*(10**9)
        new_end_time_unix_nano = end_time_unix_nano + 10*(10**9)

        number_data_points = sum.collect(new_start_time_unix_nano, new_end_time_unix_nano)
        assert(number_data_points.size == 3)

        assert(number_data_points[0].value == 15)
        assert(number_data_points[0].attributes == { 'service' => 'aaa' })
        assert(number_data_points[0].start_time_unix_nano == start_time_unix_nano)
        assert(number_data_points[0].time_unix_nano == new_end_time_unix_nano)

        assert(number_data_points[1].value == 1)
        assert(number_data_points[1].attributes == { 'service' => 'bbb' })
        assert(number_data_points[1].start_time_unix_nano == start_time_unix_nano)
        assert(number_data_points[1].time_unix_nano == new_end_time_unix_nano)

        assert(number_data_points[2].value == 3)
        assert(number_data_points[2].attributes == { 'service' => 'ccc' })
        assert(number_data_points[2].start_time_unix_nano == new_start_time_unix_nano) # new start time
        assert(number_data_points[2].time_unix_nano == new_end_time_unix_nano)

        number_data_points = sum.collect(new_start_time_unix_nano, new_end_time_unix_nano)
        assert(number_data_points.size == 3)
      end
    end
  end

  def now_in_nano
    (Time.now.to_r * 1_000_000_000).to_i
  end

  def build_sum(**kwargs)
    OpenTelemetry::SDK::Metrics::Aggregation::Sum.new(**kwargs)
  end
end
