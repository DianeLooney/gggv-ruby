load './lib/gggv.rb'
load './lib/launchpad.rb'
load './lib/pile.rb'

m = MidiGenerator.new

m >> only_grid | on_up | color(0)
m >> only(:volume) | on_down | color(52)
m >> only(:volume) | on_up | toggle > color(16) > color(0)
m >> only(:pan) | on_down | color(52)
m >> only(:pan) | on_up | toggle > color(16) > color(0)

m.start
m.stop
sleep(60)


$midi_in = UniMIDI::Input.use(0)
$midi_out = UniMIDI::Output.use(0)
$midi_in.open
$midi_out.open
