# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    module ProxyInstrument
      # @api private
      module DelegateAsynchronousInstrument
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
              OpenTelemetry.logger.warn(
                'Attempt to reset delegate in Asynchronous ProxyInstrument ignored'
              )
            end
          end
        end

        def register_callbacks(*callbacks)
          if @delegate.nil?
            super
          else
            @delegate.register_callbacks(*callbacks)
          end
        end

        def unregister_callbacks(*callbacks)
          if @delegate.nil?
            super
          else
            @delegate.unregister_callbacks(*callbacks)
          end
        end
      end
    end
  end
end