# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyMeter} is an implementation of {OpenTelemetry::Metrics::Meter}.
    # It is returned from the ProxyMeterProvider until a delegate meter provider
    # is installed. After the delegate meter provider is installed,
    # the ProxyMeter will delegate to the corresponding "real" meter.
    class ProxyMeter < Metrics::Meter
      def initialize(name, version: nil, schema_url: nil, attributes: nil)
        super

        @delegate = nil
      end

      # Set the delegate Meter. If this is called more than once, a warning will
      # be logged and superfluous calls will be ignored.
      #
      # @param [Meter] meter The Meter to delegate to
      def delegate=(meter)
        @mutex.synchronize do
          if @delegate.nil?
            @delegate = meter
            @instrument_registry.each_value { |instrument| instrument.upgrade_with(meter) }
          else
            OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyMeter ignored.'
          end
        end
      end

      private

      def create_instrument(kind, name, unit, description, advice, callbacks)
        super do
          if @delegate.nil?
            ProxyInstrument.new(kind, name, unit, description, advice, callbacks)
          else
            case kind
            when :counter
              @delegate.create_counter(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            when :histogram
              @delegate.create_histogram(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            when :up_down_counter
              @delegate.create_up_down_counter(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            when :observable_counter
              @delegate.create_observable_counter(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            when :observable_gauge
              @delegate.create_observable_gauge(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            when :observable_up_down_counter
              @delegate.create_observable_up_down_counter(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            end
          end
        end
      end
    end
  end
end
