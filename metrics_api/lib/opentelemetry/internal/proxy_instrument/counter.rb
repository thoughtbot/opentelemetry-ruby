# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    module ProxyInstrument
      # @api private
      class Counter < Metrics::Instrument::Counter
        include DelegateSynchronousInstrument

        def add(increment, attributes: nil)
          @delegate_mutex.synchronize do
            if @delegate.nil?
              super
            else
              @delegate.add(increment, attributes: attributes)
            end
          end
        end
      end
    end
  end
end
