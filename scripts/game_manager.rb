# frozen_string_literal: true

require_relative './game_modes/melody_madness'
require_relative './music_staff'

# fading and easing text
module GameManagerText
  def ease_out_elastic(percent)
    if percent <= 0 then 0
    elsif percent >= 1 then 1
    else
      c4 = 2.0 * Math::PI / 3.0
      2.pow(-10 * percent) * Math.sin((percent * 10 - 0.75) * c4) + 1
    end
  end

  def ease_in_menu
    run_for!(2) do |elapsed, duration|
      @text_y =
        if elapsed > duration then 40
        else 180 * ease_out_elastic(elapsed / duration) - 140
        end
    end
  end

  def fade_out_menu
    run_for!(3) do |elapsed, duration|
      @text_alpha = [0, 1 - elapsed / duration].max
    end
    run! do |wait|
      wait.for_seconds(2.5)
      @staff = Game.create! MusicStaff.new
      @game = Game.create! yield
    end
  end

  def fade_in_menu
    run_for!(2) do |elapsed, duration|
      @text_alpha = [1, elapsed / duration].min
    end
  end
end

# manage which game is being played
class GameManager < GameObject
  include GameManagerText

  def on_start!
    @started = false
    @text_y = -200
    @text_alpha = 0
  end

  def start_action!
    @started = true
    @text_y = -200
    @text_alpha = 1
    ease_in_menu
  end

  def update!
    Draw.rectangle!(
      width: 640,
      height: 320,
      depth: 1,
      position: Vector.new(0, 0),
      color: Color.new(r: 1, g: 1, b: 1, a: 1)
    )

    start_action! if Input.key_hit :s
    return unless @started

    if @game.nil? then main_menu_update!
    elsif Input.key_hit :escape
      Game.delete! @staff
      Game.delete! @game
      @staff = nil
      @game = nil
      fade_in_menu
      ease_in_menu
    end
  end

  def main_menu_update!
    if Input.key_hit :_1
      fade_out_menu { MelodyMadness.new }
    elsif Input.key_hit :_2
      fade_out_menu { MelodyMadness.new }
    end

    Draw.text!(
      text: "St. Luke's\nCommunity Orchestra",
      size: 48,
      position: Vector.new(0, @text_y),
      color: Color.new(r: 0, g: 0, b: 0, a: @text_alpha)
    )
  end
end
