# frozen_string_literal: true

require_relative './game_modes/note_utils'

# Draw the music staff
class MusicStaff < GameObject
  def draw_staff!
    draw_clef!
    draw_lines!
    draw_end_bar!
  end

  def draw_clef!
    Draw.sprite!(
      depth: 55,
      sprite: :treble_clef,
      position: Vector.new(-252, 60),
      scale: Vector.new(0.55, 0.55)
    )
  end

  def draw_lines!
    (0..4).each do |i|
      offset = 24 + NoteUtils::STAFF_BASE_OFFSET + 24 * i
      Draw.rectangle!(
        position: Vector.new(0, offset),
        depth: 50,
        width: 576,
        height: 2,
        color: Color.new(r: 0, g: 0, b: 0)
      )
    end
  end

  def draw_end_bar!
    Draw.rectangle!(
      depth: 51,
      position: Vector.new(276, 72),
      width: 2,
      height: 96,
      color: Color.new(r: 0, g: 0, b: 0)
    )
    Draw.rectangle!(
      depth: 51,
      position: Vector.new(285, 72),
      width: 6,
      height: 96,
      color: Color.new(r: 0, g: 0, b: 0)
    )
  end

  def update!
    draw_staff!
  end
end
