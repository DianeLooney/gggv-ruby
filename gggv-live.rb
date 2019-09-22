load './lib/gggv.rb'

w = Window.new
p = Program.new('window', 'shaders/vert/window.glsl', 'shaders/geom/window.glsl', 'shaders/frag/window.glsl')
v1 = FFVideo.new('video1', 'leto-1.mp4')
ep = Program.new('edges', 'shaders/vert/default.glsl', 'shaders/geom/default.glsl', 'shaders/frag/filt.edges.glsl')
sh = Shader.new('edges')
sh.program = ep
sh.set_input(0, v1)
w.set_input(0, sh)
