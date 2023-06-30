# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyMeterProvider} is an implementation of {OpenTelemetry::Metrics::MeterProvider}.
    # It is the default global Meter provider returned by OpenTelemetry.meter_provider.
    # It delegates to a "real" MeterProvider after the global meter provider is registered.
    # It returns {ProxyMeter} instances until the delegate is installed.
    class ProxyMeterProvider < Metrics::MeterProvider
      def initialize(*args, **kwargs)
        super

        @delegate = nil
      end

      # Set the delegate Meter provider. If this is called more than once, a warning will
      # be logged and superfluous calls will be ignored.
      #
      # @param [MeterProvider] meter_provider The Meter provider to delegate to
      def delegate=(meter_provider)
        @mutex.synchronize do
          if @delegate.nil?
            @delegate = meter_provider

            @meter_registry.each do |key, proxy_meter|
              proxy_meter.delegate = meter_provider.meter(
                proxy_meter.name,
                version: proxy_meter.version,
                schema_url: proxy_meter.schema_url,
                attributes: proxy_meter.attributes,
              )
            end
          else
            OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyMeterProvider ignored.'
          end
        end
      end

      # @api private
      def meter(name, version: nil, schema_url: nil, attributes: nil)
        @mutex.synchronize do
          if @delegate.nil?
            proxy_meter = ProxyMeter.new(
              name,
              version: version,
              schema_url: schema_url,
              attributes: attributes
            )
            key = Key.new(
              proxy_meter.name,
              proxy_meter.version,
              proxy_meter.schema_url
            )

            @meter_registry[key] ||= proxy_meter
          else
            @delegate.meter(
              name,
              version: version,
              schema_url: schema_url,
              attributes: attributes
            )
          end
        end
      end
    end
  end
end
