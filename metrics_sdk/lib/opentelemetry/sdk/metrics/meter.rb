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
        # TODO: refer yard doc comments to API

        def create_counter(name, unit: nil, description: nil, advice: nil)
          register_instrument(name) do
            SDK::Metrics::Instrument::Counter.new(
              name,
              unit: unit,
              description: description,
              advice: advice,
              # @meter_provider # TODO: Check if we should pass meter/meter provider to Instrument
            )
          end
        end

        def create_histogram(name, unit: nil, description: nil, advice: nil)
          register_instrument(name) do
            SDK::Metrics::Instrument::Histogram.new(
              name,
              unit: unit,
              description: description,
              advice: advice,
              # @meter_provider
            )
          end
        end

        def create_up_down_counter(name, unit: nil, description: nil, advice: nil)
          register_instrument(name) do
            SDK::Metrics::Instrument::UpDownCounter.new(
              name,
              unit: unit,
              description: description,
              advice: advice,
              # @meter_provider
            )
          end
        end

        def create_observable_counter(name, unit: nil, description: nil, callbacks: nil)
          register_instrument(name) do
            SDK::Metrics::Instrument::ObservableCounter.new(
              name,
              unit: unit,
              description: description,
              callbacks: callbacks,
              # @meter_provider
            )
          end
        end

        def create_observable_gauge(name, unit: nil, description: nil, callbacks: nil)
          register_instrument(name) do
            SDK::Metrics::Instrument::ObservableGauge.new(
              name,
              unit: unit,
              description: description,
              callbacks: callbacks,
              # @meter_provider
            )
          end
        end

        def create_observable_up_down_counter(name, unit: nil, description: nil, callbacks: nil)
          register_instrument(name) do
            SDK::Metrics::Instrument::ObservableUpDownCounter.new(
              name,
              unit: unit,
              description: description,
              callbacks: callbacks,
              # @meter_provider
            )
          end
        end
      end
    end
  end
end
