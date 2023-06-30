# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    module ProxyInstrument
      # @api private
      class UpDownCounter < Metrics::Instrument::UpDownCounter
        include DelegateSynchronousInstrument

        def add(amount, attributes: nil)
          if @delegate.nil?
            super
          else
            @delegate.add(amount, attributes: attributes)
          end
        end
      end
    end
  end
end
