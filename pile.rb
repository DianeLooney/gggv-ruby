load './lib/pile.rb'
load './lib/gggv.rb'
load './lib/launchpad.rb'

m = MidiGenerator.new

m >> only(:volume) | on_down | color(52)
m >> only(:volume) | on_up | toggle \
  > color(16) | ->(x) { puts "Toggle is on" } \
  > color(0) | ->(x) { puts "Toggle is off" }

m.start

sleep(60)
