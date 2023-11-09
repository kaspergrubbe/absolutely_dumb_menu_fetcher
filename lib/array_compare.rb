require 'chunky_png'
require_relative 'sample_match_data'

class ArrayCompare
  def initialize(screen, sample, match_percentage)
    @screen = screen
    @sample = sample
    @match_percentage = match_percentage
  end

  attr_accessor :screen, :sample, :match_percentage

  def compare(screen_x, screen_y)
    sample_pixels = []
    (0..sample.width - 1).each do |sample_x|
      (0..sample.height - 1).each do |sample_y|
        sample_pixels << sample.get_pixel(sample_x, sample_y)
      end
    end
    sample_pixels = sample_pixels.each

    pixel_score_data = []
    disqualified = false

    (screen_x..screen_x + sample.width - 1).each do |search_x|
      (screen_y..screen_y + sample.height - 1).each do |search_y|
        sample_pixel     = sample_pixels.next
        sub_screen_pixel = screen.get_pixel(search_x, search_y)
        pixel_score      = ChunkyPNG::Color.euclidean_distance_rgba(sample_pixel, sub_screen_pixel)

        if match_percentage.include?(pixel_score)
          pixel_score_data << pixel_score
        else
          disqualified = true
          break
        end
      end

      break if disqualified
    end

    return nil if disqualified

    match_score = 1 - (pixel_score_data.sum.fdiv(pixel_score_data.size) / ChunkyPNG::Color::MAX_EUCLIDEAN_DISTANCE_RGBA)
    SampleMatchData.new(screen_x, screen_y, screen_x + sample.width, screen_y + sample.height, match_score)
  end
end
