# frozen_string_literal: true

class SampleMatchData
  def initialize(x0, y0, x1, y1, quality_score)
    @x0 = x0
    @y0 = y0
    @x1 = x1
    @y1 = y1
    @quality_score = quality_score
  end

  def width
    x1 - x0
  end

  def height
    y1 - y0
  end

  attr_reader :x0, :y0, :x1, :y1, :quality_score

  def to_a
    [x0, y0, x1, y1, quality_score]
  end
end
