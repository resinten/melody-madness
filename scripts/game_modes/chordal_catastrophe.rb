# frozen_string_literal: true

require_relative '../draw_notes'
require_relative './note_utils'
require_relative './countdown_clock'

# Chordal Catastrophe game mode
module ChordalCatastrophe
  INSTRUCTIONS_TEXT = <<~TEXT.strip
    Instructions:
    Type notes like "a sharp" or "g"
    in Slack: #community-orchestra-game
  TEXT

  DISABLED_CURRENT_COLOR = Color.new(r: 0.5, g: 0.5, b: 0.5, a: 0).freeze
  ACTIVE_CURRENT_COLOR = Color.new(r: 1, a: 0).freeze

  # accept chord information from slack functionality for mode
  module SlackLogic
    include CountdownClock

    def add_chord_notes!(&block)
      @game_mode = :add_chords
      run_countdown_clock!(&block)
    end
  end

  # set root notes of chord
  module RootLogic
    include ChordalCatastrophe::SlackLogic

    def set_root_note!
      @game_mode = :set_root
      @current = {}
      run! do |wait|
        until Input.key_hit :enter
          @current_root += 1 if Input.key_hit(:up)
          @current_root -= 1 if Input.key_hit(:down)
          @current_root = @current_root.clamp(57, 84)
          wait.next_frame
        end
        add_chord_notes!(&method(:handle_next_chord))
      end
    end

    def handle_next_chord
      @game_mode = :advancing
      run! do |wait|
        wait.for_seconds 0.25
        @notes.push [*@current.values, @current_root]
        if @notes.length >= 5
          play_all_chords!
        else
          set_root_note!
        end
      end
    end

    def play_all_chords!
      @game_mode = :playing
      run! do |wait|
        until Input.key_hit(:a)
          if Input.key_hit(:p)
            @notes.each do |chord|
              chord.each { |note| play_note! note }
              wait.for_seconds 0.5
            end
          end
          wait.next_frame
        end
        @notes = []
        set_root_note!
      end
    end
  end

  # Mode game object
  class GameMode < GameObject
    include DrawNotes
    include ChordalCatastrophe::RootLogic

    def on_start!
      @notes = []
      @current = {}
      @current_root = 69
      set_root_note!
    end

    def update!
      accept_slack_input if @game_mode == :add_chords
      draw_self
    end

    def accept_slack_input
      root_octave = 12 * NoteUtils.midi_to_octave(@current_root)
      Slack
        .drain_input!
        .filter { |m| NoteUtils.valid_note? m[:text] }
        .each do |m|
          new_note = NoteUtils.text_to_intra_octave(m[:text])
          new_note = root_octave + new_note
          new_note += 12 while new_note <= @current_root
          @current[m[:user]] = new_note
        end
    end

    def draw_self
      @notes.each_with_index do |chord, idx|
        chord.each { |note| draw_note!(note, idx) }
      end
      Draw.text!(
        depth: 55,
        font: :inconsolata,
        position: Vector.new(-300, -160),
        halign: :left,
        valign: :bottom,
        text: INSTRUCTIONS_TEXT,
        color: Color.new(r: 0, g: 0, b: 0),
        scale: Vector.new(24, 24)
      )
      return if @game_mode == :playing

      draw_note!(@current_root, @notes.length, root_color)
      @current.each_value do |note|
        draw_note!(note, @notes.length, current_color)
      end
    end

    def root_color
      case @game_mode
      when :set_root then ACTIVE_CURRENT_COLOR
      when :add_chords then Color.new(a: 0)
      else DISABLED_CURRENT_COLOR
      end
    end

    def current_color
      if @game_mode == :set_root || @game_mode == :add_chords
        ACTIVE_CURRENT_COLOR
      else
        DISABLED_CURRENT_COLOR
      end
    end
  end
end
