require 'portmidi'
require './lib/pile.rb'

Portmidi.start

$midi_in ||= Portmidi::Input.new(Portmidi.input_devices.find { |x| x.name == 'Launchpad MK2' }.device_id)
$midi_out ||= Portmidi::Output.new(Portmidi.output_devices.find { |x| x.name == 'Launchpad MK2' }.device_id)

class MidiGenerator < Generator
  def start
    @thread ||= Thread.new do
      loop do
        action = $midi_in.read(1)&.first
        if action
          Thread.new { send(action) }
          next 
        end

        sleep 0.05
      end
    end
  end

  def stop
    @thread&.exit
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
    message = action[:message]
    message[2] = color
    $midi_out.write([{ message: message, timestamp: action[:timestamp] }])

    action
  end
end

class OnUpPipe < Pipe
  def send(midi)
    super if midi[:message][2] == 0
  end
end

class OnDownPipe < Pipe
  def send(midi)
    super if midi[:message][2] == 127
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
      message = midi[:message]
      return unless message[0] == 144
      return unless message[1] % 10 < 9

      midi
    end
  end
  def only(key)
    ->(midi) do
      message = midi[:message]

      if key.is_a? Symbol
        return unless message[1] == LAUNCHPAD_MK2_KEYS[key]
      elsif key.is_a? Numeric
        return unless message[1] == key
      end

      midi
    end
  end

  def color(c)
    ColorPipe.new(c)
  end
end
