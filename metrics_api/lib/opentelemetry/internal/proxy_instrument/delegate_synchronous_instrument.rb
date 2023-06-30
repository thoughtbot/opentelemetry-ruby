# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    module ProxyInstrument
      # @api private
      module DelegateSynchronousInstrument
        def initialize(*args, **kwargs)
          super

          @mutex = Mutex.new
          @delegate = nil
        end

        def delegate=(instrument)
          @mutex.synchronize do
            if @delegate.nil?
              @delegate = instrument
            else
              OpenTelemetry.logger.warn('
                Attempt to reset delegate in Synchronous ProxyInstrument ignored'
              )
            end
          end
        end
      end
    end
  end
end
