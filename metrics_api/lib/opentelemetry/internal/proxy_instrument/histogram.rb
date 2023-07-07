# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    module ProxyInstrument
      # @api private
      class Histogram < Metrics::Instrument::Histogram
        include DelegateSynchronousInstrument

        def record(amount, attributes: nil)
          @delegate_mutex.synchronize do
            if @delegate.nil?
              super
            else
              @delegate.record(amount, attributes: attributes)
            end
          end
        end
      end
    end
  end
end
