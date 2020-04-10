# frozen_string_literal: true

# utilities for chawnging between numbers and notes
module NoteUtils
  STAFF_BASE_OFFSET = 0

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.note_to_midi(note, octave = 4)
    midi_base =
      case note
      when :c, :b_sharp then 12
      when :c_sharp, :d_flat then 13
      when :d then 14
      when :d_sharp, :e_flat then 15
      when :e then 16
      when :f then 17
      when :f_sharp, :g_flat then 18
      when :g then 19
      when :g_sharpp, :a_flat then 20
      when :a then 21
      when :a_sharp, :b_flat then 22
      when :b then 23
      end
    12 * octave + midi_base
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  INTRA_OCTAVE_OFFSETS = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6].freeze

  def self.midi_y(midi)
    octave = midi_to_octave midi
    intra_octave = midi_to_intra_octave midi
    84.0 * (octave - 4) + 12.0 * INTRA_OCTAVE_OFFSETS[intra_octave]
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.midi_to_note_with_octave(midi)
    {
      octave: midi_to_octave(midi),
      note:
        case midi_to_intra_octave(midi)
        when 0 then :c
        when 1 then :c_sharp
        when 2 then :d
        when 3 then :d_sharp
        when 4 then :e
        when 5 then :f
        when 6 then :f_sharp
        when 7 then :g
        when 8 then :g_sharp
        when 9 then :a
        when 10 then :a_sharp
        when 11 then :b
        end
    }
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.midi_to_octave(midi)
    (midi / 12).floor - 1
  end

  def self.midi_to_intra_octave(midi)
    midi % 12
  end

  def self.note_is_sharp?(midi)
    case midi_to_intra_octave(midi)
    when 1, 3, 6, 8, 10 then true
    else false
    end
  end
end
