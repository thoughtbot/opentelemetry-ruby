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
      def initialize(*args, **kwargs)
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

            @instrument_registry.each_value do |proxy_instrument|
              proxy_instrument.delegate =
                case proxy_instrument
                when ProxyInstrument::Counter
                  meter.create_counter(
                    proxy_instrument.name,
                    unit:        proxy_instrument.unit,
                    description: proxy_instrument.description,
                    advice:      proxy_instrument.advice
                  )
                when ProxyInstrument::Histogram
                  meter.create_histogram(
                    proxy_instrument.name,
                    unit:        proxy_instrument.unit,
                    description: proxy_instrument.description,
                    advice:      proxy_instrument.advice
                  )
                when ProxyInstrument::UpDownCounter
                  meter.create_up_down_counter(
                    proxy_instrument.name,
                    unit:        proxy_instrument.unit,
                    description: proxy_instrument.description,
                    advice:      proxy_instrument.advice
                  )
                when ProxyInstrument::ObservableCounter
                  meter.create_observable_counter(
                    proxy_instrument.name,
                    unit:        proxy_instrument.unit,
                    description: proxy_instrument.description,
                    callbacks:   proxy_instrument.callbacks
                  )
                when ProxyInstrument::ObservableGauge
                  meter.create_observable_gauge(
                    proxy_instrument.name,
                    unit:        proxy_instrument.unit,
                    description: proxy_instrument.description,
                    callbacks:   proxy_instrument.callbacks
                  )
                when ProxyInstrument::ObservableUpDownCounter
                  meter.create_observable_up_down_counter(
                    proxy_instrument.name,
                    unit:        proxy_instrument.unit,
                    description: proxy_instrument.description,
                    callbacks:   proxy_instrument.callbacks
                  )
                end
            end
          else
            OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyMeter ignored.'
          end
        end
      end

      def create_counter(name, unit: nil, description: nil, advice: nil)
        register_instrument(name) do
          @mutex.synchronize do
            if @delegate.nil?
              ProxyInstrument::Counter.new(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            else
              @delegate.create_counter(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            end
          end
        end
      end

      def create_histogram(name, unit: nil, description: nil, advice: nil)
        register_instrument(name) do
          @mutex.synchronize do
            if @delegate.nil?
              ProxyInstrument::Histogram.new(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            else
              @delegate.create_histogram(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            end
          end
        end
      end

      def create_up_down_counter(name, unit: nil, description: nil, advice: nil)
        register_instrument(name) do
          @mutex.synchronize do
            if @delegate.nil?
              ProxyInstrument::UpDownCounter.new(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            else
              @delegate.create_up_down_counter(
                name,
                unit: unit,
                description: description,
                advice: advice
              )
            end
          end
        end
      end

      def create_observable_counter(name, unit: nil, description: nil, callbacks: nil)
        register_instrument(name) do
          @mutex.synchronize do
            if @delegate.nil?
              ProxyInstrument::ObservableCounter.new(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            else
              @delegate.create_observable_counter(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            end
          end
        end
      end

      def create_observable_gauge(name, unit: nil, description: nil, callbacks: nil)
        register_instrument(name) do
          @mutex.synchronize do
            if @delegate.nil?
              ProxyInstrument::ObservableGauge.new(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            else
              @delegate.create_observable_gauge(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            end
          end
        end
      end

      def create_observable_up_down_counter(name, unit: nil, description: nil, callbacks: nil)
        register_instrument(name) do
          @mutex.synchronize do
            if @delegate.nil?
              ProxyInstrument::ObservableUpDownCounter.new(
                name,
                unit: unit,
                description: description,
                callbacks: callbacks
              )
            else
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
