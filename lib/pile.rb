Object.class_eval do
  def tempo(bpm)
    $metronome.set_bpm(bpm)
  end

  def every(*args)
    TimeGenerator.new(*args)
  end

  def pipe(*args)
    Pipe.new(*args)
  end

  def delay(*args)
    DelayPipe.new(*args)
  end

  def maybe(*args)
    MaybePipe.new(*args)
  end

  def take(*args)
    TakePipe.new(*args)
  end

  def toggle(*args)
    Toggle.new(*args)
  end

  def fuck_it
    ObjectSpace.each_object(Generator).each(&:stop)
    ObjectSpace.each_object(Metronome).each do |metronome|
      metronome.stop unless metronome == $metronome
    end

    ObjectSpace.each_object(MidiGenerator).each do |midi|
      midi.stop
    end
  end
  alias fuck fuck_it
  alias fuckit fuck_it

  def beat_now
    $metronome.beat_now
  end

  def on(remainder, divisor, name = nil)
    $metronome.on(remainder, divisor, name)
  end

  def once(remainder, divisor)
    $metronome.on(remainder, divisor)
  end

  def stop(name)
    $metronome.stop(name)
  end
end

class Pipeline < Array
  def send(value)
    each do |entry|
      output = entry.send(value)
      return if output.nil?

      value = output
    end

    @children&.each do |child|
      child.send(value)
    end
  end

  def |(value)
    if value.is_a? Pipe
      push(value)
    elsif value.is_a? Proc
      push(ExecPipe.new(value))
    elsif value.is_a? Toggle
      push(value)
    elsif value.is_a? Pipeline
      concat(value)
    else
      raise "Not sure what to do with this in Pipeline's | operator: #{value}"
    end

    self
  end

  def >>(value)
    p = Pipeline.new
    (@children ||= []).push(p)
    p | value
  end

  def >(value)
    last > value

    self
  end
end

class Pipe
  def initialize(*options)
    @options = options
    @children = []
  end

  def |(value)
    p = Pipeline.new
    p | self
    p | value
  end

  def send(value)
    value
  end
end

class Toggle < Pipe
  def initialize
    @i = 0
    @children = []
  end
  
  def send(value)
    return unless @children.any?
    @i = @i % @children.count
    @children[@i].send(value)
    @i += 1

    value
  end

  def >(value)
    @children.push(value)
  end
end

class ExecPipe < Pipe
  def send(value)
    proc.call(value)
  end

  private

  def proc
    @options.first
  end
end

class DelayPipe < Pipe
  def send(value)
    sleep(duration)
    value
  end

  private

  def duration
    @options.first
  end
end

class TakePipe < Pipe
  def initialize(*args)
    super

    @i = 0
  end

  def send(*_args)
    @i ||= 0
    @i+=1
    @i %= count

    super if @i.zero?
  end

  private

  def count
    @options.first
  end
end

class MaybePipe < Pipe
  def send(*_args)
    super if rand < chance
  end

  private

  def chance
    @options.first
  end
end

class Generator < Pipe
  def >>(value)
    p = Pipeline.new
    @children.push(p)
    p | value
  end

  def send(value)
    @children.each do |child|
      child.send(value)
    end
  end

  def start; end
  def stop; end
end

class TimeGenerator < Generator
  def start
    @thread ||= Thread.new do
      loop do
        sleep(duration)
        send(Time.now)
      end
    end
  end

  def stop
    @thread&.exit
    @thread = nil
  end

  private

  def duration
    @options.first
  end
end

class Metronome < Generator
  Listener = Struct.new(:beat, :remainder, :divisor, :pipe, :name)

  def initialize(bpm)
    @bpm = bpm
    @delta = 0.002
    @listeners = []

    @current_beat = 0
  end

  def set_bpm(bpm)
    @bpm = bpm.to_f
  end

  def once(remainder, divisor)
    pipe = Pipe.new
    beat = (@current_beat / divisor).floor * divisor + remainder
    beat += divisor if beat < @current_beat

    @listeners.push(Listener.new(beat, 0, 0, pipe))

    pipe
  end

  def on(remainder, divisor, name = nil)
    pipe = Pipe.new
    beat = (@current_beat / divisor).floor * divisor + remainder
    beat += divisor if beat < @current_beat

    @listeners.reject! { |x| x.name == name }
    @listeners.push(Listener.new(beat, remainder, divisor, pipe, name))

    pipe
  end

  def beat_now
    @current_beat = @current_beat.ceil
    @current_time = Time.now
  end

  def start
    @thread ||= Thread.new do
      @current_time = Time.now

      loop do
        sleep(@delta)
        next_time = Time.now
        @current_beat += (next_time - @current_time) * (@bpm / 60)
        @current_time = next_time

        next unless @listeners.any? { |listener| listener.beat < @current_beat }
        to_send, @listeners = @listeners.partition { |listener| listener.beat < @current_beat }

        to_send.each do |listener|
          listener.pipe.send({ beat: listener.beat, time: @current_time })
          next if listener.divisor.zero?

          @listeners.push(Listener.new(
            listener.beat + listener.divisor,
            listener.remainder,
            listener.divisor,
            listener.pipe,
            listener.name,
          ))
        end
      end
    end
  end

  def stop(name = nil)
    if name
      @listeners.reject! { |x| x.name == name }
    else
      @thread&.exit
      @thread = nil
    end
  end
end

$metronome = Metronome.new(60)
$metronome.start
