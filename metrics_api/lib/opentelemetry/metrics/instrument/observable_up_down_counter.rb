# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of ObservableUpDownCounter.
      class ObservableUpDownCounter < AsynchronousInstrument
        def kind
          :observable_up_down_counter
        end
      end
    end
  end
end
