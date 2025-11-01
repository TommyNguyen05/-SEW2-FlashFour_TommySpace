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
end
