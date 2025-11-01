# frozen_string_literal: true

class ProgressAnalyticsController < ApplicationController
  include ProgressAnalyticsHelper
  before_action :authenticate_user!

  def index
    @total_cards_studied = current_user.total_cards_studied
    @total_reviews = current_user.reviews.count
    @total_study_time = format_study_time(current_user.total_study_time)
    @study_streak = current_user.calculate_study_streak

    # Cards by state
    @new_cards = current_user.cards_by_state('new')
    @learning_cards = current_user.cards_by_state('learning')
    @review_cards = current_user.cards_by_state('review')
    @relearning_cards = current_user.cards_by_state('relearning')

    # Recent reviews (last 10)
    @recent_reviews = current_user.reviews.recent.limit(10).includes(card: :deck)

    # Reviews by day for the last 7 days
    @reviews_by_day = calculate_reviews_by_day(7)

    # Average rating
    @average_rating = current_user.reviews.any? ? current_user.reviews.average_rating : 0

    # Deck progress
    @deck_stats = calculate_deck_stats
  end

  def deck
    @deck = current_user.decks.find(params[:id])
    @deck_reviews = Review.for_deck(@deck).for_user(current_user)
    
    @total_cards = @deck.flashcards.count
    @cards_studied = @deck_reviews.select(:card_id).distinct.count
    @total_reviews = @deck_reviews.count
    @average_rating = @deck_reviews.any? ? @deck_reviews.average_rating : 0
    @total_study_time = format_study_time(@deck_reviews.total_study_time)

    # Cards by state for this deck
    @deck_progress = CardProgress.for_deck(@deck).for_user(current_user)
    @new_cards = @deck_progress.new_card.count
    @learning_cards = @deck_progress.learning.count
    @review_cards = @deck_progress.review.count
    @relearning_cards = @deck_progress.relearning.count

    # Recent reviews for this deck
    @recent_reviews = @deck_reviews.recent.limit(10).includes(:card)

    # Reviews by day for the last 7 days
    @reviews_by_day = calculate_deck_reviews_by_day(@deck, 7)
  end

  private

  def calculate_reviews_by_day(days)
    end_date = Date.current
    start_date = end_date - (days - 1).days

    reviews_by_date = current_user.reviews
                                   .between_dates(start_date.beginning_of_day, end_date.end_of_day)
                                   .group('DATE(reviewed_at)')
                                   .count

    (start_date..end_date).map do |date|
      {
        date: date.strftime('%m/%d'),
        count: reviews_by_date[date] || 0
      }
    end
  end

  def calculate_deck_reviews_by_day(deck, days)
    end_date = Date.current
    start_date = end_date - (days - 1).days

    reviews_by_date = Review.for_deck(deck)
                            .for_user(current_user)
                            .between_dates(start_date.beginning_of_day, end_date.end_of_day)
                            .group('DATE(reviewed_at)')
                            .count

    (start_date..end_date).map do |date|
      {
        date: date.strftime('%m/%d'),
        count: reviews_by_date[date] || 0
      }
    end
  end

  def calculate_deck_stats
    current_user.decks.map do |deck|
      deck_progress = CardProgress.for_deck(deck).for_user(current_user)
      deck_reviews = Review.for_deck(deck).for_user(current_user)
      
      {
        deck: deck,
        total_cards: deck.flashcards.count,
        cards_studied: deck_reviews.select(:card_id).distinct.count,
        mastered: deck_progress.review.count,
        learning: deck_progress.learning.count,
        new: deck_progress.new_card.count
      }
    end
  end
end
