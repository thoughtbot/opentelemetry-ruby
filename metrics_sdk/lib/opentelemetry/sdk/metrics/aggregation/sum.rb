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
          def initialize(aggregation_temporality: :delta, monotonic: true)
            @aggregation_temporality = aggregation_temporality
            @monotonic = monotonic

            @data_points = {}
          end

          def collect(start_time, end_time)
            if @aggregation_temporality == :delta
              # Set timestamps and 'move' data point values to result.
              ndps = @data_points.each_value do |ndp|
                ndp.start_time_unix_nano = start_time
                ndp.time_unix_nano = end_time
              end
              @data_points.clear
              ndps
            else
              # Update timestamps and take a snapshot.
              @data_points.values.map! do |ndp|
                ndp.start_time_unix_nano ||= start_time # Start time of a data point is from the first observation.
                ndp.time_unix_nano = end_time
                ndp.dup
              end
            end
          end

          def update(increment, attributes)
            @data_points[attributes] ||= build_data_point(attributes)
            @data_points[attributes].value += increment
            nil
          end

          private

          def build_data_point(attributes)
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
