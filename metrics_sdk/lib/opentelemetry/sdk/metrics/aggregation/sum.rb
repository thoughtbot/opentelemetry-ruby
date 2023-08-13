# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module Aggregation
        # Contains the implementation of the Sum aggregation
        # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/metrics/sdk.md#sum-aggregation
        class Sum
          attr_reader :aggregation_temporality, :monotonic

          def initialize(aggregation_temporality: :delta, monotonic: true)
            @aggregation_temporality = aggregation_temporality
            @monotonic = monotonic

            @number_data_points = {}
          end

          def update(increment, attributes)
            @number_data_points[attributes] ||= build_number_data_point(attributes)
            @number_data_points[attributes].value += increment
            nil
          end

          def collect(start_time_unix_nano, end_time_unix_nano)
            if aggregation_temporality == :delta
              ndps = @number_data_points.map do |_attributes, ndp|
                ndp.start_time_unix_nano = start_time_unix_nano
                ndp.time_unix_nano = end_time_unix_nano
                ndp
              end
              @number_data_points.clear
              ndps
            else
              @number_data_points.map do |_attributes, ndp|
                # Start time of data point is from the first observation.
                ndp.start_time_unix_nano ||= start_time_unix_nano
                ndp.time_unix_nano = end_time_unix_nano
                ndp.dup
              end
            end
          end

          private

          def build_number_data_point(attributes)
            NumberDataPoint.new(
              attributes,
              nil,
              nil,
              0,
              nil
            )
          end
        end
      end
    end
  end
end
