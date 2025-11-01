class CardProgressesController < ApplicationController
  before_action :authenticate_user!

  def index
    @total_cards    = current_user.card_progresses.count
    @due_now        = current_user.card_progresses.due_now.count
    @reviews_today  = current_user.reviews.where(reviewed_at: Time.zone.today.all_day).count

    last_30         = current_user.reviews.where('reviewed_at >= ?', 30.days.ago)
    correct         = last_30.where(rating: %i[good easy]).count
    total           = last_30.count
    @accuracy       = total.positive? ? ((correct.to_f / total) * 100.0).round : nil

    @streak_days    = compute_streak_for(current_user)

    @per_deck_stats = Deck
                      .where(owner_id: current_user.id)
                      .distinct
                      .map { |deck| deck_stats_for(deck, current_user) }

    raw = current_user.reviews
                      .where('reviewed_at >= ?', 14.days.ago.beginning_of_day)
                      .group('DATE(reviewed_at)')
                      .order('DATE(reviewed_at)')
                      .count

    @review_activity = (0..13).map do |i|
      day = i.days.ago.to_date
      { date: day, count: raw[day] || 0 }
    end.reverse
  end

  private

  def compute_streak_for(user)
    streak = 0
    day = Time.zone.today
    loop do
      break unless user.reviews.where(reviewed_at: day.all_day).exists?

      streak += 1
      day -= 1.day
    end
    streak
  end

  def deck_stats_for(deck, user)
    progress_for_deck = user.card_progresses.joins(:card).where(cards: { deck_id: deck.id })
    total = progress_for_deck.count
    due   = progress_for_deck.due_now.count

    reviews_today = user.reviews.joins(:card)
                        .where(cards: { deck_id: deck.id })
                        .where(reviewed_at: Time.zone.today.all_day)
                        .count

    last_30 = user.reviews.joins(:card)
                  .where(cards: { deck_id: deck.id })
                  .where('reviews.reviewed_at >= ?', 30.days.ago)
    correct  = last_30.where(rating: %i[good easy]).count
    total_r  = last_30.count
    accuracy = total_r.positive? ? ((correct.to_f / total_r) * 100.0).round : nil

    {
      name: deck.title,
      total: total,
      due: due,
      reviewed_today: reviews_today,
      accuracy: accuracy
    }
  end
end
