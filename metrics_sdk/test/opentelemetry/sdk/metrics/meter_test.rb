# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::Meter do
  before { OpenTelemetry::SDK.configure }

  describe '#instrumentation_scope' do
    it 'creates an instrumentation_scope' do
      meter = build_meter(
        'test-meter',
        version: '1.0.0',
        schema_url: 'https://example.com/schema/1.0.0',
        attributes: { 'key' => 'value' }
      )

      assert(meter.instrumentation_scope.instance_of?(OpenTelemetry::SDK::InstrumentationScope))
      assert(meter.instrumentation_scope.name == 'test-meter')
      assert(meter.instrumentation_scope.version == '1.0.0')
      assert(meter.instrumentation_scope.schema_url == 'https://example.com/schema/1.0.0')
      assert(meter.instrumentation_scope.attributes == { 'key' => 'value' })
    end
  end

  describe '#create_counter' do
    it 'creates a counter instrument' do
      instrument = build_meter.create_counter(
        'test-instrument',
        unit: 'b',
        description: 'bytes received',
        advice: { some: { value: 123 }}
      )

      assert(instrument.instance_of?(OpenTelemetry::SDK::Metrics::Instrument::Counter))
      assert(instrument.name == 'test-instrument')
      assert(instrument.unit == 'b')
      assert(instrument.description == 'bytes received')
      assert(instrument.advice == { some: { value: 123 }})
    end
  end

  describe '#create_histogram' do
    it 'creates a histogram instrument' do
      instrument = build_meter.create_histogram(
        'test-instrument',
        unit: 'seconds',
        description: 'request duration',
        advice: { some: { value: 123 }}
      )

      assert(instrument.instance_of?(OpenTelemetry::SDK::Metrics::Instrument::Histogram))
      assert(instrument.name == 'test-instrument')
      assert(instrument.unit == 'seconds')
      assert(instrument.description == 'request duration')
      assert(instrument.advice == { some: { value: 123 }})
    end
  end

  describe '#create_up_down_counter' do
    it 'creates an up_down_counter instrument' do
      instrument = build_meter.create_up_down_counter(
        'test-instrument',
        unit: 'jobs',
        description: 'number of jobs in a queue',
        advice: { some: { value: 123 }}
      )

      assert(instrument.instance_of?(OpenTelemetry::SDK::Metrics::Instrument::UpDownCounter))
      assert(instrument.name == 'test-instrument')
      assert(instrument.unit == 'jobs')
      assert(instrument.description == 'number of jobs in a queue')
      assert(instrument.advice == { some: { value: 123 }})
    end
  end

  describe '#create_observable_counter' do
    it 'creates an observable_counter instrument' do
      callback = ->{}
      instrument = build_meter.create_observable_counter(
        'test-instrument',
        unit: 'faults',
        description: 'number of page faults',
        callbacks: [callback]
      )

      assert(instrument.instance_of?(OpenTelemetry::SDK::Metrics::Instrument::ObservableCounter))
      assert(instrument.name == 'test-instrument')
      assert(instrument.unit == 'faults')
      assert(instrument.description == 'number of page faults')
      assert(instrument.callbacks == [callback])
    end
  end

  describe '#create_observable_gauge' do
    it 'creates an observable_gauge instrument' do
      callback = ->{}
      instrument = build_meter.create_observable_gauge(
        'test-instrument',
        unit: 'celsius',
        description: 'room temperature',
        callbacks: [callback]
      )

      assert(instrument.instance_of?(OpenTelemetry::SDK::Metrics::Instrument::ObservableGauge))
      assert(instrument.name == 'test-instrument')
      assert(instrument.unit == 'celsius')
      assert(instrument.description == 'room temperature')
      assert(instrument.callbacks == [callback])
    end
  end

  describe '#create_observable_up_down_counter' do
    it 'creates an observable_up_down_counter instrument' do
      callback = ->{}
      instrument = build_meter.create_observable_up_down_counter(
        'test-instrument',
        unit: 'b',
        description: 'process heap size',
        callbacks: [callback]
      )

      assert(instrument.instance_of?(OpenTelemetry::SDK::Metrics::Instrument::ObservableUpDownCounter))
      assert(instrument.name == 'test-instrument')
      assert(instrument.unit == 'b')
      assert(instrument.description == 'process heap size')
      assert(instrument.callbacks == [callback])
    end
  end

  def build_meter(name = 'test-meter', **kwargs)
    OpenTelemetry::SDK::Metrics::Meter.new(name, **kwargs)
  end
end
