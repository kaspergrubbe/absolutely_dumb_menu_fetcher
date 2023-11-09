require 'chunky_png'
require_relative 'array_compare'

class Search
  SEARCH_DIRECTION = %w[top-left top-right bottom-left bottom-right].freeze
  SEARCH_MODE = %i[all one].freeze

  def find_all_samples(screen, sample, opts = {})
    opts.merge!({ search_mode: :all })
    _find_subimage(screen, sample, opts)
  end

  def find_first_sample(screen, sample, opts = {})
    opts.merge!({ search_mode: :one })
    _find_subimage(screen, sample, opts).first
  end

  def _find_subimage(screen, sample, opts)
    match_percentage = 0..15
    match_data = []
    bound_x = 0
    bound_y = 0
    bound_width = screen.width - 1
    bound_height = screen.height - 1

    # Set search mode
    #
    # Specifies whether or not we want to find all matches, or want
    # to stop search after we have found one match.
    # --------------------------------------------------------------
    search_mode = opts.fetch(:search_mode, :all)
    raise "Unsupported search-mode: #{search_mode}" unless SEARCH_MODE.include?(search_mode)

    # Set matching strategy
    # --------------------------------------------------------------
    match_strategy = ArrayCompare

    # Set search direction
    #
    # Specifies where we want to start searching for an item, for an
    # example we might know that we are searching for something in
    # the lower half of the screen, so it would be wasteful to start
    # looking in the top of the screen.
    # --------------------------------------------------------------
    search_direction = opts.fetch(:search_direction, 'top-left')
    raise "Unsupported search-direction: #{search_direction}" unless SEARCH_DIRECTION.include?(search_direction)

    vertical_search_direction, horizontal_search_direction = search_direction.split('-')

    vertical_search_direction = case vertical_search_direction
                                when 'top'
                                  (bound_y..bound_height).to_a.freeze
                                when 'bottom'
                                  (bound_y..bound_height).to_a.reverse.freeze
                                end

    horizontal_search_direction = case horizontal_search_direction
                                  when 'left'
                                    (bound_x..bound_width).to_a.freeze
                                  when 'right'
                                    (bound_x..bound_width).to_a.reverse.freeze
                                  end

    #
    # Start searching
    # --------------------------------------------------------------
    catch :job_done do
      horizontal_search_direction.each do |screen_x|
        vertical_search_direction.each do |screen_y|
          #
          # Check out of bounds
          # --------------------------------------------------------------
          next if bound_width - screen_x < sample.width - 1
          next if bound_height - screen_y < sample.height - 1

          #
          # Matching
          # --------------------------------------------------------------
          initial_match_distance = ChunkyPNG::Color.euclidean_distance_rgba(
            screen.get_pixel(screen_x, screen_y),
            sample.get_pixel(0, 0)
          )

          next unless match_percentage.include?(initial_match_distance)

          ac = match_strategy.new(screen, sample, match_percentage)
          match = ac.compare(screen_x, screen_y)
          if match
            match_data << match
            throw :job_done if search_mode == :one
          end
        end
      end
    end

    match_data
  end
end
