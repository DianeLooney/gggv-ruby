fuck
load './lib/pile.rb'
tempo(120)
on(0, 1, :apple) | maybe(0.1) | ->(x) { puts "Apple #{x}" }
on(0, 1, :banana) | maybe(0.5) | ->(x) { puts "Banana #{x}" }
on(0, 1, :carrot) | maybe(1) | ->(x) { puts "Carrot #{x}" }