# frozen_string_literal: true

class LearningSessionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck
  before_action :initialize_session_data, only: [:start]
  before_action :load_session_data, only: [:show, :rate]

  def start
    # Initialize a new learning session
    @cards = @deck.flashcards.where(suspended: false).to_a.shuffle
    
    if @cards.empty?
      redirect_to @deck, alert: 'This deck has no cards to study.'
      return
    end

    # Store session data in Rails session
    session[:learning_session] = {
      deck_id: @deck.id,
      card_ids: @cards.map(&:id),
      current_index: 0,
      responses: {}
    }

    redirect_to deck_learning_session_path(@deck)
  end

  def show
    if session_complete?
      redirect_to complete_deck_learning_session_path(@deck)
      return
    end

    @current_card = current_card
    
    # If current card is nil (deleted or invalid), redirect to completion
    unless @current_card
      redirect_to complete_deck_learning_session_path(@deck)
      return
    end
    
    @cards_remaining = cards_remaining
    @total_cards = total_cards
  end

  def rate
    rating = params[:rating]
    
    unless %w[unfamiliar still_learning mastered].include?(rating)
      redirect_to deck_learning_session_path(@deck), alert: 'Invalid rating'
      return
    end

    # Get current card and store the rating
    card = current_card
    if card
      session[:learning_session]['responses'][card.id.to_s] = rating
      
      # Record review and update card progress
      record_review(card, rating)
      update_card_progress(card, rating)
    end

    # Move to next card
    session[:learning_session]['current_index'] += 1

    if session_complete?
      redirect_to complete_deck_learning_session_path(@deck)
    else
      redirect_to deck_learning_session_path(@deck)
    end
  end

  def complete
    @responses = session[:learning_session]['responses'] || {}
    @total = @responses.size

    # Calculate statistics
    @mastered_count = @responses.values.count('mastered')
    @still_learning_count = @responses.values.count('still_learning')
    @unfamiliar_count = @responses.values.count('unfamiliar')

    @mastered_percentage = @total > 0 ? (@mastered_count.to_f / @total * 100).round : 0
    @still_learning_percentage = @total > 0 ? (@still_learning_count.to_f / @total * 100).round : 0
    @unfamiliar_percentage = @total > 0 ? (@unfamiliar_count.to_f / @total * 100).round : 0
  end

  def restart
    session.delete(:learning_session)
    redirect_to start_deck_learning_session_path(@deck)
  end

  private

  def set_deck
    @deck = current_user.decks.find(params[:deck_id])
  end

  def initialize_session_data
    session.delete(:learning_session)
  end

  def load_session_data
    unless session[:learning_session]
      redirect_to start_deck_learning_session_path(@deck), alert: 'No active learning session'
      return
    end

    if session[:learning_session]['deck_id'] != @deck.id
      redirect_to start_deck_learning_session_path(@deck), alert: 'Session mismatch'
      return
    end
  end

  def current_card
    card_ids = session[:learning_session]['card_ids']
    current_index = session[:learning_session]['current_index']
    
    # Ensure we don't go out of bounds
    if current_index >= card_ids.size
      return nil
    end
    
    card_id = card_ids[current_index]
    card = Flashcard.find_by(id: card_id)
    
    # If card not found, it may have been deleted
    unless card
      # Skip to next card or end session if no more cards
      session[:learning_session]['current_index'] += 1
      return current_card if session[:learning_session]['current_index'] < card_ids.size
      return nil
    end
    
    card
  end

  def cards_remaining
    total_cards - session[:learning_session]['current_index']
  end

  def total_cards
    session[:learning_session]['card_ids'].size
  end

  def session_complete?
    session[:learning_session]['current_index'] >= total_cards
  end

  def record_review(card, rating)
    # Map text ratings to numeric values
    numeric_rating = case rating
    when 'unfamiliar' then 1
    when 'still_learning' then 2
    when 'mastered' then 4
    else 3
    end

    # Get time taken (you can track this in session if needed)
    time_taken_ms = 0 # Default to 0 for now

    # Get current progress if it exists
    progress = CardProgress.find_by(user: current_user, card: card)
    
    Review.create!(
      user: current_user,
      card: card,
      rating: numeric_rating,
      time_taken_ms: time_taken_ms,
      scheduled_interval_days: progress&.interval_days || 0,
      new_interval_days: calculate_new_interval(progress, numeric_rating),
      new_ease_factor: calculate_new_ease_factor(progress, numeric_rating),
      reviewed_at: Time.current
    )
  end

  def update_card_progress(card, rating)
    progress = CardProgress.find_or_initialize_by(user: current_user, card: card)
    
    # Map text ratings to numeric values for progress tracking
    numeric_rating = case rating
    when 'unfamiliar' then 1
    when 'still_learning' then 2
    when 'mastered' then 4
    else 3
    end

    progress.update_from_review(numeric_rating)
  end

  def calculate_new_interval(progress, rating)
    return 0 unless progress
    
    interval = progress.interval_days
    ease = progress.ease_factor

    case rating
    when 1
      0
    when 2
      [interval * 1.2, 1].max.to_i
    when 3, 4
      progress.new_card? || progress.learning? ? 1 : (interval * ease).to_i
    else
      interval
    end
  end

  def calculate_new_ease_factor(progress, rating)
    return 2.5 unless progress
    
    ease = progress.ease_factor
    
    case rating
    when 1
      [ease - 0.2, 1.3].max
    when 2
      [ease - 0.15, 1.3].max
    when 3
      ease
    when 4
      ease + 0.1
    else
      ease
    end
  end
end
