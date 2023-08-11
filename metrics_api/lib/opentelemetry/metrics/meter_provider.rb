# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    # No-op implementation of a meter provider.
    class MeterProvider
      NOOP_METER = Meter.new('no-op')
      Key = Struct.new(:name, :version, :schema_url)

      private_constant :NOOP_METER, :Key

      attr_reader :resource, :metric_readers

      def initialize(resource: nil)
        @resource = resource

        @mutex = Mutex.new
        @stopped = false
        @metric_readers = []
        @meter_registry = {}
      end

      # @param [String] name
      #   Uniquely identifies the instrumentation scope, such as the instrumentation library
      #   (e.g. io.opentelemetry.contrib.mongodb), package, module or class name
      # @param [optional String] version
      #   Version of the instrumentation scope if the scope has a version (e.g. a library version)
      # @param [optional String] schema_url
      #   Schema URL that should be recorded in the emitted telemetry
      # @param [optional Hash{String => String, Numeric, Boolean, Array<String, Numeric, Boolean>}] attributes
      #   Instrumentation scope attributes to associate with emitted telemetry
      #
      # @return [Metrics::Meter]
      def meter(name, version: nil, schema_url: nil, attributes: nil)
        NOOP_METER
      end

      # @api private
      def each_metric_reader
        @mutex.synchronize do
          @metric_readers.each do |metric_reader|
            yield(metric_reader)
          end
        end
      end
    end
  end
end
