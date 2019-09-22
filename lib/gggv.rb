require 'osc-ruby'

$client = OSC::Client.new('localhost', 4200)
def send_osc(*args)
  msg = OSC::Message.new(*args)
  $client.send(msg)
end

class Program
  def initialize(name, vPath, gPath, fPath)
    @name = name
    @inputs = []
    @vPath = vPath
    @gPath = gPath
    @fPath = fPath
    send_osc("/program/watch", name, vPath, gPath, fPath)
  end

  attr_reader :name, :vPath, :gPath, :fPath
end

class Source
  attr_reader :name

  attr_reader :wrap_s
  def wrap_s=(value)
    @wrap_s = value
    send_osc("/source/set/wrap.s", name, value)
  end

  attr_reader :wrap_t
  def wrap_t=(value)
    @wrap_t = value
    send_osc("/source/set/wrap.t", name, value)
  end

  attr_reader :minfilter
  def minfilter=(value)
    @minfilter = value
    send_osc("/source/set/minfilter", name, value)
  end

  attr_reader :magfilter
  def magfilter=(value)
    @magfilter = value
    send_osc("/source/set/magfilter", name, value)
  end
end

class Shader < Source
  def initialize(name)
    @name = name
    @inputs = []
    send_osc("/source.shader/create", name)
  end

  attr_reader :program
  def program=(value)
    @program = value
    send_osc("/source.shader/set/program", name, program.name)
  end

  def set_input(index, value)
    @inputs[index] = value
    send_osc("/source.shader/set/input", name, index, value.name)
  end

  def set_uniform(name, value)
    @uniforms[name] = value
    send_osc("/source.shader/set/uniform1f", name, index, value)
  end
end

class Window < Shader
  def initialize
    @name = 'window'
    @inputs = []
  end
end

class FFVideo < Source
  def initialize(name, path)
    @name = name
    @path = path

    send_osc("/source.ffvideo/create", name, path)
  end

  attr_reader :name, :path
end
