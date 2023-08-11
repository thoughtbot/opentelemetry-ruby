# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # https://opentelemetry.io/docs/specs/otel/metrics/api/#synchronous-instrument-api
      class SynchronousInstrument
        attr_reader :name, :unit, :description, :advice

        # @api private
        def initialize(name, unit: nil, description: nil, advice: nil, meter: nil)
          @name = name
          @unit = unit || ''
          @description = description || ''
          @advice = advice || {}

          @meter = meter

          @mutex = Mutex.new
          @metric_streams = []
        end

        # @api private
        def add_metric_stream(metric_stream)
          @mutex.synchronize do
            @metric_streams.push(metric_stream)
          end
        end

        private

        def update(value, attributes)
          @mutex.synchronize do
            @metric_streams.each do |metric_stream|
              metric_stream.update(value, attributes)
            end
          end
        end
      end
    end
  end
end
