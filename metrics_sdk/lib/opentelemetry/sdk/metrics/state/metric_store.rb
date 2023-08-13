# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Metrics
      module State
        # @api private
        #
        # The MetricStore module provides SDK internal functionality that is not a part of the
        # public API.
        class MetricStore
          def initialize
            @epoch_start_time = now_in_nano
            @epoch_end_time = nil

            @mutex = Mutex.new
            @metric_streams = []
          end

          def collect
            @mutex.synchronize do
              @epoch_end_time = now_in_nano
              metric_data = @metric_streams.map do |metric_stream|
                metric_stream.collect(@epoch_start_time, @epoch_end_time)
              end
              @epoch_start_time = @epoch_end_time

              metric_data
            end
          end

          def add_metric_stream(metric_stream)
            @mutex.synchronize do
              @metric_streams.push(metric_stream)
              nil
            end
          end

          private

          def now_in_nano
            (Time.now.to_r * 1_000_000_000).to_i
          end
        end
      end
    end
  end
end
