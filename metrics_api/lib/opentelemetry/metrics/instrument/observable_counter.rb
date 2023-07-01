# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of ObservableCounter.
      class ObservableCounter < AsynchronousInstrument
        def kind
          :observable_counter
        end
      end
    end
  end
end
