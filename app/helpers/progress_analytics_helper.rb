# frozen_string_literal: true

module ProgressAnalyticsHelper
  # Display rating as stars
  def rating_stars(rating)
    content_tag(:span, '⭐' * rating, class: 'badge bg-light text-dark')
  end

  # Format study time for display
  def format_study_time(seconds)
    return '0m' if seconds == 0
    
    hours = (seconds / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i
    
    if hours > 0
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end
end
