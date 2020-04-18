# frozen_string_literal: true

require_relative '../draw_notes'
require_relative './note_utils'
require_relative './countdown_clock'

# Melody Madness game mode
module MelodyMadness
  INSTRUCTIONS_TEXT = <<~TEXT.strip
    Instructions:
    Type commands like \"up\" or \"down\"
    in Slack: #community-orchestra-game
  TEXT

  DISABLED_CURRENT_COLOR = Color.new(r: 0.5, g: 0.5, b: 0.5, a: 0).freeze
  ACTIVE_CURRENT_COLOR = Color.new(r: 1, a: 0).freeze

  # core functionality for mode
  module Logic
    include CountdownClock
    include PlaySounds
    include DrawNotes

    def post_countdown_clock
      run! do |wait|
        wait.for_seconds 0.25
        @notes.push(@current)
        if @notes.length >= 8
          run_play_notes!
        else
          run_countdown_clock!(&method(:post_countdown_clock))
        end
        # @notes.length >= 8 ? run_play_notes! : run_countdown_clock!
      end
    end

    def run_play_notes!
      run! do |wait|
        until Input.key_hit(:a)
          if Input.key_hit(:p)
            @notes.each do |note|
              play_note! note
              wait.for_seconds 0.5
            end
          end
          wait.next_frame
        end
        @notes = []
        run_countdown_clock!(&method(:post_countdown_clock))
      end
    end

    def draw_notes!
      @notes.each_with_index(&method(:draw_note!))
    end

    def draw_self!
      draw_notes!
      draw_note!(
        @current,
        @notes.length,
        @disabled ? DISABLED_CURRENT_COLOR : ACTIVE_CURRENT_COLOR
      )
    end

    def handle_controls(up_votes, down_votes)
      @current += up_votes - down_votes
      @current += 1 if Input.key_hit(:up)
      @current -= 1 if Input.key_hit(:down)
      @current = @current.clamp 57, 84
    end

    def draw_instructions!
      Draw.text!(
        depth: 55,
        font: :inconsolata,
        position: Vector.new(-300, -160),
        halign: :left,
        valign: :bottom,
        text: INSTRUCTIONS_TEXT,
        color: Color.new(r: 0, g: 0, b: 0),
        size: Vector.new(24, 24)
      )
    end
  end

  # Mode game object
  class GameMode < GameObject
    include CountdownClock
    include MelodyMadness::Logic

    def on_start!
      @notes = []
      @current = 69
      run_countdown_clock!(&method(:post_countdown_clock))
    end

    def update!
      draw_self!
      draw_instructions!
      return if @disabled

      slack_inputs = Slack.drain_input!.map { |m| m[:text] }
      up_votes = slack_inputs.filter { |t| t.match(/up/i) }.length
      down_votes = slack_inputs.filter { |t| t.match(/down/i) }.length
      handle_controls up_votes, down_votes
    end
  end
end
