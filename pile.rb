load './lib/pile.rb'
tempo(120)
beat_now

on(0.2, 1, :apple) | maybe(1) | ->(x) { puts "Apple #{x}" }
on(0.4, 1, :banana) | maybe(1) | ->(x) { puts "Banana #{x}" }
on(0, 1, :carrot) | maybe(1) | ->(x) { puts "Carrot #{x}" }

stop(:apple)
stop(:banana)
stop(:carrot)

fuck
