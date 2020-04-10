# frozen_string_literal: true

require_relative './game_manager'

Draw.load_font :inconsolata, 'Inconsolata-Regular.ttf'

Draw.load_spritesheet :sprites, 'simple.png'
Draw.create_sprite(
  :treble_clef, :sprites, Vector.new(152, 0), Vector.new(88, 240)
)
Draw.create_sprite(
  :quarter_note, :sprites, Vector.new(0, 0), Vector.new(72, 240)
)

Draw.load_spritesheet :accidentals, '3-accidentals-sharp-flat-natural.png'
Draw.create_sprite(
  :sharp_sign, :accidentals, Vector.new(0, 16), Vector.new(40, 100)
)

Game.create! GameManager.new
