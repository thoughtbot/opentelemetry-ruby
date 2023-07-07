# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    # The Metrics module contains the OpenTelemetry metrics reference
    # implementation.
    module Metrics
      # {MeterProvider} is the SDK implementation of {OpenTelemetry::Metrics::MeterProvider}.
      class MeterProvider < OpenTelemetry::Metrics::MeterProvider
        def initialize(resource: OpenTelemetry::SDK::Resources::Resource.default)
          super
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
        # @return [SDK::Metrics::Meter]
        def meter(name, version: nil, schema_url: nil, attributes: nil)
          if @stopped
            OpenTelemetry.logger.warn 'calling MeterProvider#meter after shutdown, a noop meter will be returned.'

            NOOP_METER
          else
            key = build_key_for_meter(name, version, schema_url)
            meter = Meter.new(
              name,
              version: version,
              schema_url: schema_url,
              attributes: attributes
            )

            @mutex.synchronize do
              @meter_registry[key] ||= meter
            end
          end
        end

        # Attempts to stop all the activity for this {MeterProvider}.
        #
        # Calls MetricReader#shutdown for all registered MetricReaders.
        #
        # After this is called all the newly created {Meter}s will be no-op.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling MetricProvider#shutdown multiple times.')
              Export::FAILURE
            else
              start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
              results = @metric_readers.map do |metric_reader|
                remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
                if remaining_timeout&.zero?
                  Export::TIMEOUT
                else
                  metric_reader.shutdown(timeout: remaining_timeout)
                end
              end

              @stopped = true
              results.max || Export::SUCCESS
            end
          end
        end

        # This method provides a way for provider to notify the registered
        # {MetricReader} instances, so they can do as much as they could to consume
        # or send the metrics. Note: unlike Push Metric Exporter which can send data on
        # its own schedule, Pull Metric Exporter can only send the data when it is
        # being asked by the scraper, so ForceFlush would not make much sense.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          @mutex.synchronize do
            if @stopped
              Export::SUCCESS
            else
              start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
              results = @metric_readers.map do |metric_reader|
                remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
                if remaining_timeout&.zero?
                  Export::TIMEOUT
                else
                  metric_reader.force_flush(timeout: remaining_timeout)
                end
              end

              results.max || Export::SUCCESS
            end
          end
        end

        # Adds a new MetricReader to this {MeterProvider}.
        #
        # @param metric_reader the new MetricReader to be added.
        def add_metric_reader(metric_reader, aggregation: nil)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling MetricProvider#add_metric_reader after shutdown.')
            else
              @metric_readers.push(metric_reader)

              @meter_registry.each_value do |meter|
                meter.each_instrument do |_name, instrument|
                  metric_stream = build_metric_stream(meter, instrument, aggregation)

                  instrument.add_metric_stream(metric_stream)
                  metric_reader.metric_store.add_metric_stream(metric_stream)
                end
              end
            end

            nil
          end
        end

        # The type of the Instrument(s) (optional).
        # The name of the Instrument(s). OpenTelemetry SDK authors MAY choose to support wildcard characters, with the question mark (?) matching exactly one character and the asterisk character (*) matching zero or more characters.
        # The name of the Meter (optional).
        # The version of the Meter (optional).
        # The schema_url of the Meter (optional).
        def add_view
          # TODO: For each meter add this view to all applicable instruments
        end

        private

        def build_key_for_meter(name, version, schema_url)
          if name.nil? || name.empty?
            OpenTelemetry.logger.warn 'Invalid name provided to MeterProvider#meter: nil or empty'
          end

          Key.new(name, version, schema_url)
        end

        def build_metric_stream(meter, instrument, aggregation)
          aggregation ||= default_aggregation_for(instrument)

          SDK::Metrics::State::MetricStream.new(
            instrument.name,
            instrument.description,
            instrument.unit,
            instrument.kind,
            self,
            meter.instrumentation_scope,
            aggregation || build_default_aggregation_for(instrument)
          )
        end

        # https://opentelemetry.io/docs/specs/otel/metrics/sdk/#default-aggregation
        def build_default_aggregation_for(instrument)
          case instrument
          when Counter
            Aggregation::Sum.new
          when Histogram
            Aggregation::ExplicitBucketHistogram.new
          when UpDownCounter
            Aggregation::Sum.new
          when ObservableCounter
            # TODO: ?
          when ObservableGauge
            # TODO: ?
          when ObservableUpDownCounter
            # TODO: ?
          end
        end
      end
    end
  end
end
