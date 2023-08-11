# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'test_helper'

describe OpenTelemetry::SDK::Metrics::MeterProvider do
  before do
    reset_metrics_sdk
    OpenTelemetry::SDK.configure
  end

  describe '#meter' do
    it 'requires a meter name' do
      _(-> { build_meter_provider.meter }).must_raise(ArgumentError)
    end

    it 'creates a new meter' do
      meter = build_meter_provider.meter('test-meter')

      _(meter).must_be_instance_of(OpenTelemetry::SDK::Metrics::Meter)
    end

    it 'repeated calls do not recreate a meter of the same name' do
      meter_provider = build_meter_provider

      meter_a = meter_provider.meter('test-meter')
      meter_b = meter_provider.meter('test-meter')

      _(meter_a.object_id).must_equal(meter_b.object_id)
    end

    describe 'when meter_provider is shutdown' do
      it 'returns a noop meter from API and logs a message' do
        OpenTelemetry::TestHelpers.with_test_logger do |log_stream|
          meter_provider = build_meter_provider
          meter_provider.shutdown

          meter = meter_provider.meter('test-meter')

          assert(meter.instance_of?(OpenTelemetry::Metrics::Meter))
          assert(log_stream.string.match?(
            /calling MeterProvider#meter after shutdown, a noop meter will be returned./
          ))
        end
      end
    end
  end

  describe '#shutdown' do
    it 'repeated calls to shutdown result in a failure' do
      with_test_logger do |log_stream|
        _(OpenTelemetry.meter_provider.shutdown).must_equal(OpenTelemetry::SDK::Metrics::Export::SUCCESS)
        _(OpenTelemetry.meter_provider.shutdown).must_equal(OpenTelemetry::SDK::Metrics::Export::FAILURE)
        _(log_stream.string).must_match(/calling MetricProvider#shutdown multiple times/)
      end
    end

    it 'returns a timeout response when it times out' do
      mock_metric_reader = new_mock_reader
      mock_metric_reader.expect(:nothing_gets_called_because_it_times_out_first, nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader)

      _(OpenTelemetry.meter_provider.shutdown(timeout: 0)).must_equal(OpenTelemetry::SDK::Metrics::Export::TIMEOUT)
    end

    it 'invokes shutdown on all registered Metric Readers' do
      mock_metric_reader1 = new_mock_reader
      mock_metric_reader2 = new_mock_reader
      mock_metric_reader1.expect(:shutdown, nil, [], timeout: nil)
      mock_metric_reader2.expect(:shutdown, nil, [], timeout: nil)

      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader1)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader2)
      OpenTelemetry.meter_provider.shutdown

      mock_metric_reader1.verify
      mock_metric_reader2.verify
    end
  end

  describe '#force_flush' do
    it 'returns a timeout response when it times out' do
      mock_metric_reader = new_mock_reader
      mock_metric_reader.expect(:nothing_gets_called_because_it_times_out_first, nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader)

      _(OpenTelemetry.meter_provider.force_flush(timeout: 0)).must_equal(OpenTelemetry::SDK::Metrics::Export::TIMEOUT)
    end

    it 'invokes force_flush on all registered Metric Readers' do
      mock_metric_reader1 = new_mock_reader
      mock_metric_reader2 = new_mock_reader
      mock_metric_reader1.expect(:force_flush, nil, [], timeout: nil)
      mock_metric_reader2.expect(:force_flush, nil, [], timeout: nil)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader1)
      OpenTelemetry.meter_provider.add_metric_reader(mock_metric_reader2)

      OpenTelemetry.meter_provider.force_flush

      mock_metric_reader1.verify
      mock_metric_reader2.verify
    end
  end

  describe '#add_metric_reader' do
    it 'adds a metric reader' do
      metric_reader = build_metric_reader

      OpenTelemetry.meter_provider.add_metric_reader(metric_reader)

      _(OpenTelemetry.meter_provider.instance_variable_get(:@metric_readers)).must_equal([metric_reader])
    end

    it 'associates the metric store with instruments created before the metric reader' do
      instrument = OpenTelemetry.meter_provider.meter('test-meter').create_counter('test-instrument')

      metric_reader_a = build_metric_reader
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_a)

      metric_reader_b = build_metric_reader
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_b)

      _(instrument.instance_variable_get(:@metric_streams).size).must_equal(2)
      _(metric_reader_a.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
      _(metric_reader_b.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
    end

    it 'associates the metric store with instruments created after the metric reader' do
      metric_reader_a = build_metric_reader
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_a)

      metric_reader_b = build_metric_reader
      OpenTelemetry.meter_provider.add_metric_reader(metric_reader_b)

      instrument = OpenTelemetry.meter_provider.meter('test-meter').create_counter('test-instrument')

      _(instrument.instance_variable_get(:@metric_streams).size).must_equal(2)
      _(metric_reader_a.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
      _(metric_reader_b.metric_store.instance_variable_get(:@metric_streams).size).must_equal(1)
    end
  end

  # # TODO: OpenTelemetry.meter_provider.add_view
  # describe '#add_view' do
  # end

  private

  def new_mock_reader
    Minitest::Mock.new(OpenTelemetry::SDK::Metrics::Export::MetricReader.new)
  end

  def build_metric_reader
    OpenTelemetry::SDK::Metrics::Export::MetricReader.new
  end

  def build_meter_provider
    OpenTelemetry::SDK::Metrics::MeterProvider.new
  end
end
