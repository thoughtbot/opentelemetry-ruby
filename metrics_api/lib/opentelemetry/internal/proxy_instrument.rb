# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Metrics
    module ProxyInstrument
    end
  end
end

require 'opentelemetry/internal/proxy_instrument/delegate_synchronous_instrument'
require 'opentelemetry/internal/proxy_instrument/counter'
require 'opentelemetry/internal/proxy_instrument/histogram'
require 'opentelemetry/internal/proxy_instrument/up_down_counter'

require 'opentelemetry/internal/proxy_instrument/delegate_asynchronous_instrument'
require 'opentelemetry/internal/proxy_instrument/observable_counter'
require 'opentelemetry/internal/proxy_instrument/observable_gauge'
require 'opentelemetry/internal/proxy_instrument/observable_up_down_counter'
