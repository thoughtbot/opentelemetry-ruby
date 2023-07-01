# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module Instrument
      # No-op implementation of ObservableGauge.
      class ObservableGauge < AsynchronousInstrument
        def kind
          :observable_gauge
        end
      end
    end
  end
end
