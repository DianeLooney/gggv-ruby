load './lib/pile.rb'
load './lib/gggv.rb'

shatter = Program.new("fx.shatter", "shaders/vert/fx.shatter.glsl", "shaders/geom/fx.shatter.glsl", "shaders/frag/fx.shatter.glsl")
video = FFVideo.new("funtimes", "sample.mp4")
window = Window.new
window.program = shatter
window.set_input(0, video)

tempo(120)
beat_now

on(0.2, 1, :apple) | maybe(1) | ->(x) { puts "Apple #{x}" }
on(0.4, 1, :banana) | maybe(1) | ->(x) { puts "Banana #{x}" }
on(0, 1, :carrot) | maybe(1) | ->(x) { puts "Carrot #{x}" }

stop(:apple)
stop(:banana)
stop(:carrot)

fuck
@client
message = OSC::Message.new('/a', 'b', 'c')
@client.send(message)
