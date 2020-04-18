# frozen_string_literal: true

# module for playing sounds
module PlaySounds
  def play_note!(midi)
    note = NoteUtils.midi_to_note_with_octave midi
    Tone.play! note[:note], note[:octave]
  end
end

# module for showing a timer
module CountdownClock
  include PlaySounds

  COUNTDOWN_RADIUS = 72
  COUNTDOWN_CENTER = Vector.new(228, -88).freeze

  def run_countdown_clock!(&block)
    @disabled = false
    run_for!(20) { |e, d| countdown_clock(e, d, &block) }
  end

  def countdown_clock(elapsed, duration, &block)
    draw_clock!(elapsed, duration) if elapsed < duration
    return unless elapsed > duration

    @disabled = true
    block.call
    nil
  end

  def draw_clock!(elapsed, duration)
    draw_clock_arc! elapsed / duration
    draw_clock_time! duration - elapsed
  end

  def draw_clock_arc!(percent_elapased)
    red = percent_elapased < 0.5 ? 2 * percent_elapased : 1
    green = percent_elapased < 0.5 ? 1 : 2 - 2 * percent_elapased
    Draw.arc!(
      depth: 55,
      position: COUNTDOWN_CENTER,
      radius: COUNTDOWN_RADIUS,
      color: Color.new(r: red, g: green, b: 0),
      thickness: 12,
      from: percent_elapased * 2 * Math::PI,
      to: 0
    )
  end

  def draw_clock_time!(time_remaining)
    Draw.text!(
      depth: 56,
      position: COUNTDOWN_CENTER,
      scale: Vector.new(60, 60),
      color: Color.new(r: 0.2, g: 0.2, b: 0.2),
      text: [0, time_remaining.round].max.to_s
    )
  end
end
