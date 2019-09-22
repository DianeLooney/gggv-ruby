require 'unimidi'
require './lib/pile.rb'

$midi_in = UniMIDI::Input.use(0)
$midi_out = UniMIDI::Output.use(0)

class MidiGenerator < Generator
  def start
    @thread ||= Thread.new do
      $midi_in.open
      $midi_out.open
      loop do
        begin
          actions = $midi_in.gets
          actions.each do |action|
            send(action)
          end
        rescue e
          binding.pry
        ensure
          sleep(0.05)
        end
      end
    end
  end

  def stop
    return unless @thread

    $midi_in.close
    $midi_out.close
    @thread.exit
    @thread = nil
  end
end

class ColorPipe < Pipe
  def initialize(color)
    @color = color
    super
  end

  attr_reader :color

  def send(action)
    data = action[:data]
    data[2] = color
    $midi_out.puts(data)

    action
  end
end

class OnUpPipe < Pipe
  def send(midi)
    super if midi[:data][2] == 0
  end
end

class OnDownPipe < Pipe
  def send(midi)
    super if midi[:data][2] == 127
  end
end

LAUNCHPAD_MK2_KEYS = {
  record_arm: 19,
  solo: 29,
  mute: 39,
  stop: 49,
  send_b: 59,
  send_a: 69,
  pan: 79,
  volume: 89,
}.freeze

Object.class_eval do
  def on_down
    OnDownPipe.new
  end
  def on_up
    OnUpPipe.new
  end
  def only_grid
    ->(midi) do
      data = midi[:data]
      return unless data[0] == 144
      return unless data[1] % 10 < 9

      midi
    end
  end
  def only(key)
    ->(midi) do
      data = midi[:data]

      if key.is_a? Symbol
        return unless data[1] == LAUNCHPAD_MK2_KEYS[key]
      elsif key.is_a? Numeric
        return unless data[1] == key
      end

      midi
    end
  end

  def color(c)
    ColorPipe.new(c)
  end
end
