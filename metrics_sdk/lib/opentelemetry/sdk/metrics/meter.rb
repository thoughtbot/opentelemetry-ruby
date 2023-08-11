# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Metrics module contains the OpenTelemetry metrics reference
    # implementation.
    module Metrics
      # {Meter} is the SDK implementation of {OpenTelemetry::Metrics::Meter}.
      class Meter < OpenTelemetry::Metrics::Meter
        attr_reader :instrumentation_scope

        def initialize(*args, **kwargs)
          super

          @instrumentation_scope = InstrumentationScope.new(
            @name,
            @version,
            @schema_url,
            @attributes
          )
        end

        def create_counter(name, unit: nil, description: nil, advice: nil)
          instrument = SDK::Metrics::Instrument::Counter.new(
            name,
            unit: unit,
            description: description,
            advice: advice,
            meter: self
          )
          register_instrument(name, instrument)

          @meter_provider&.each_metric_reader do |metric_reader|
            build_and_add_metric_stream(metric_reader.metric_store, instrument, nil)
          end

          instrument
        end

        def create_histogram(name, unit: nil, description: nil, advice: nil)
          instrument = SDK::Metrics::Instrument::Histogram.new(
            name,
            unit: unit,
            description: description,
            advice: advice,
            meter: self
          )
          register_instrument(name, instrument)

          @meter_provider&.each_metric_reader do |metric_reader|
            build_and_add_metric_stream(metric_reader.metric_store, instrument, nil)
          end

          instrument
        end

        def create_up_down_counter(name, unit: nil, description: nil, advice: nil)
          instrument = SDK::Metrics::Instrument::UpDownCounter.new(
            name,
            unit: unit,
            description: description,
            advice: advice,
            meter: self
          )
          register_instrument(name, instrument)

          @meter_provider&.each_metric_reader do |metric_reader|
            build_and_add_metric_stream(metric_reader.metric_store, instrument, nil)
          end

          instrument
        end

        def create_observable_counter(name, unit: nil, description: nil, callbacks: nil)
          instrument = SDK::Metrics::Instrument::ObservableCounter.new(
            name,
            unit: unit,
            description: description,
            callbacks: callbacks,
            meter: self
          )
          register_instrument(name, instrument)
        end

        def create_observable_gauge(name, unit: nil, description: nil, callbacks: nil)
          instrument = SDK::Metrics::Instrument::ObservableGauge.new(
            name,
            unit: unit,
            description: description,
            callbacks: callbacks,
            meter: self
          )
          register_instrument(name, instrument)
        end

        def create_observable_up_down_counter(name, unit: nil, description: nil, callbacks: nil)
          instrument = SDK::Metrics::Instrument::ObservableUpDownCounter.new(
            name,
            unit: unit,
            description: description,
            callbacks: callbacks,
            meter: self
          )
          register_instrument(name, instrument)
        end

        # @api private
        def register_metric_store(metric_store, aggregation: nil)
          each_instrument do |_name, instrument|
            build_and_add_metric_stream(metric_store, instrument, aggregation)
          end
        end

        private

        def build_and_add_metric_stream(metric_store, instrument, aggregation)
          metric_stream = build_metric_stream(instrument, aggregation)

          metric_store.add_metric_stream(metric_stream)
          instrument.add_metric_stream(metric_stream)
        end

        def build_metric_stream(instrument, aggregation)
          aggregation ||= build_default_aggregation_for(instrument)

          SDK::Metrics::State::MetricStream.new(
            instrument.name,
            instrument.description,
            instrument.unit,
            instrument.kind,
            @meter_provider.resource,
            instrumentation_scope,
            aggregation
          )
        end

        def build_default_aggregation_for(instrument)
          case instrument
          when Instrument::Counter
            Aggregation::Sum.new
          when Instrument::Histogram
            Aggregation::ExplicitBucketHistogram.new
          when Instrument::UpDownCounter
            Aggregation::Sum.new
          when Instrument::ObservableCounter
            # TODO: ?
          when Instrument::ObservableGauge
            # TODO: ?
          when Instrument::ObservableUpDownCounter
            # TODO: ?
          end
        end
      end
    end
  end
end
