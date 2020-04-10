# frozen_string_literal: true

require_relative './note_utils'
require_relative './countdown_clock'

# module to draw notes on screen
module DrawNotes
  def draw_notes!
    @notes.each_with_index(&method(:draw_note!))
    current_color =
      if @disabled then Color.new(r: 0.5, g: 0.5, b: 0.5, a: 0)
      else Color.new(r: 1, g: 0, b: 0, a: 0)
      end
    draw_note!(@current, @notes.length, current_color) if @notes.length < 8
  end

  def draw_note!(note, idx, color = Color.new(r: 0, g: 0, b: 0, a: 0))
    draw_lower_ledger_lines!(note, idx) if NoteUtils.midi_y(note) <= 0
    draw_upper_ledger_lines!(note, idx) if NoteUtils.midi_y(note) > 132
    draw_accidental!(note, idx, color) if NoteUtils.note_is_sharp? note
    Draw.sprite!(
      depth: 55,
      sprite: :quarter_note,
      brighten: color,
      position: note_position(note, idx),
      scale: Vector.new(0.65, 0.65),
      rotation: note >= 71 ? Math::PI : 0
    )
  end

  def draw_lower_ledger_lines!(note, idx)
    note_y = NoteUtils.midi_y(note)
    line = 0
    while line >= note_y - 12
      Draw.rectangle!(
        depth: 50,
        position: Vector.new(
          60 * idx - 188, NoteUtils::STAFF_BASE_OFFSET + line
        ),
        width: 36,
        height: 2,
        color: Color.new(r: 0, g: 0, b: 0)
      )
      line -= 24
    end
  end

  def draw_upper_ledger_lines!(note, idx)
    note_y = NoteUtils.midi_y(note)
    line = 144
    while line <= note_y + 12
      Draw.rectangle!(
        depth: 50,
        position: Vector.new(
          60 * idx - 188, NoteUtils::STAFF_BASE_OFFSET + line
        ),
        width: 36,
        height: 2,
        color: Color.new(r: 0, g: 0, b: 0)
      )
      line += 24
    end
  end

  def draw_accidental!(note, idx, color)
    Draw.sprite!(
      depth: 55,
      sprite: :sharp_sign,
      brighten: Color.new(r: color.r, g: color.g, b: color.b, a: 0),
      position: note_position(note, idx) - Vector.new(20, 0),
      scale: Vector.new(0.4, 0.4)
    )
  end

  def note_position(note, idx)
    Vector.new(
      60 * idx - 188, NoteUtils::STAFF_BASE_OFFSET + NoteUtils.midi_y(note)
    )
  end
end

# class for displaying music notes
class MelodyMadness < GameObject
  include CountdownClock
  include DrawNotes

  def on_start!
    @notes = []
    @current = 69
    run_countdown_clock!
  end

  def update!
    draw_notes!
    draw_instructions!
    return if @disabled

    slack_inputs = Slack.drain_input!.map { |m| m[:text] }
    up_votes = slack_inputs.filter { |t| t.match(/up/i) }.length
    down_votes = slack_inputs.filter { |t| t.match(/down/i) }.length
    @current += up_votes - down_votes
    @current += 1 if Input.key_hit(:up)
    @current -= 1 if Input.key_hit(:down)
    @current = @current.clamp 57, 84
    # play_note! @current if @previous != @current
  end

  def draw_instructions!
    Draw.text!(
      depth: 55,
      font: :inconsolata,
      position: Vector.new(-300, -160),
      halign: :left,
      valign: :bottom,
      text: "Instructions:\nType commands like \"up\" or \"down\"\nin Slack: #community-orchestra-game",
      color: Color.new(r: 0, g: 0, b: 0),
      size: 24
    )
  end
end
