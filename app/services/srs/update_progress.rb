module Srs
  class UpdateProgress
    # rating: "again"|"hard"|"good"|"easy"
    def self.call(progress:, rating:, time_taken_ms: 0)
      ef = progress.ease_factor.to_f
      q = { "again" => 0, "hard" => 1, "good" => 2, "easy" => 3 }[rating.to_s].to_i

      # SM-2 ease update (bounded)
      ef = ef + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02))
      ef = [[ef, 1.3].max, 3.0].min

      interval =
        if progress.repetitions.zero?
          q >= 2 ? 1 : 0
        elsif progress.repetitions == 1
          q >= 2 ? 6 : 0
        else
          q >= 2 ? (progress.interval_days * ef).round : 0
        end

      repetitions = q >= 2 ? progress.repetitions + 1 : 0
      lapses = q >= 2 ? progress.lapses : progress.lapses + 1
      state = q >= 2 ? :review : :relearning
      due_at = if interval.zero?
                 10.minutes.from_now
               else
                 interval.days.from_now
               end

      # log review BEFORE updating, capture prior scheduled interval
      scheduled_interval = progress.interval_days

      Review.create!(
        user: progress.user, card: progress.card,
        rating: Review.ratings[rating],
        time_taken_ms: time_taken_ms,
        scheduled_interval_days: scheduled_interval,
        new_interval_days: interval,
        new_ease_factor: ef,
        reviewed_at: Time.current
      )

      progress.update!(
        ease_factor: ef,
        interval_days: interval,
        repetitions: repetitions,
        lapses: lapses,
        state: CardProgress.states[state],
        due_at: due_at
      )

      progress
    end
  end
end
