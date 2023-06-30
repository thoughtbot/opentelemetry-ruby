# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    module ProxyInstrument
      # @api private
      class ObservableUpDownCounter < Metrics::Instrument::ObservableUpDownCounter
        include DelegateAsynchronousInstrument
      end
    end
  end
end
