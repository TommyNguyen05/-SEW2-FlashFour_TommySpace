# frozen_string_literal: true

class QuizzesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck
  before_action :initialize_quiz_session, only: [:start]
  before_action :load_quiz_session, only: [:show, :answer]

  def start
    # Initialize a new quiz session
    @cards = @deck.flashcards.where(suspended: false).to_a.shuffle
    
    if @cards.empty?
      redirect_to @deck, alert: 'This deck has no cards to quiz.'
      return
    end

    # Store quiz session data
    session[:quiz_session] = {
      deck_id: @deck.id,
      card_ids: @cards.map(&:id),
      current_index: 0,
      answers: {},
      correct_count: 0
    }

    redirect_to deck_quiz_path(@deck)
  end

  def show
    if quiz_complete?
      redirect_to complete_deck_quiz_path(@deck)
      return
    end

    @current_card = current_card
    
    unless @current_card
      redirect_to complete_deck_quiz_path(@deck)
      return
    end
    
    @answer_options = generate_answer_options(@current_card)
    @cards_remaining = cards_remaining
    @total_cards = total_cards
    @current_number = current_number
  end

  def answer
    selected_answer = params[:answer]
    current_card_obj = current_card
    
    if current_card_obj && selected_answer
      correct = (selected_answer == current_card_obj.back_text)
      
      # Get quiz session data
      quiz_data = session[:quiz_session]
      
      # Store the answer
      quiz_data['answers'][current_card_obj.id.to_s] = {
        'selected' => selected_answer,
        'correct' => correct
      }
      
      # Increment correct count if answer is correct
      if correct
        quiz_data['correct_count'] += 1
      end
      
      # Move to next card
      quiz_data['current_index'] += 1
      
      # Save back to session
      session[:quiz_session] = quiz_data
      
      # Update progress analytics - create or update card_progress
      update_card_progress(current_card_obj, correct)
    end

    if quiz_complete?
      redirect_to complete_deck_quiz_path(@deck)
    else
      redirect_to deck_quiz_path(@deck)
    end
  end

  def complete
    load_quiz_session
    
    @total_cards = total_cards
    @correct_count = @quiz_session[:correct_count] || 0
    @score_percentage = @total_cards > 0 ? (@correct_count.to_f / @total_cards * 100).round : 0
    
    # Clear the quiz session
    session.delete(:quiz_session)
  end

  def restart
    session.delete(:quiz_session)
    redirect_to start_deck_quiz_path(@deck)
  end

  private

  def set_deck
    @deck = (current_user.decks.find(params[:deck_id]) rescue Deck.where(owner_id: current_user.id).find(params[:deck_id]))
  end

  def initialize_quiz_session
    session.delete(:quiz_session)
  end

  def load_quiz_session
    @quiz_session = session[:quiz_session]&.with_indifferent_access
    
    unless @quiz_session
      redirect_to @deck, alert: 'No active quiz session found.' and return
    end
  end

  def current_card
    return nil unless @quiz_session
    card_id = @quiz_session[:card_ids][@quiz_session[:current_index]]
    Flashcard.find_by(id: card_id)
  end

  def quiz_complete?
    return true unless @quiz_session
    @quiz_session[:current_index] >= @quiz_session[:card_ids].length
  end

  def cards_remaining
    return 0 unless @quiz_session
    @quiz_session[:card_ids].length - @quiz_session[:current_index]
  end

  def total_cards
    return 0 unless @quiz_session
    @quiz_session[:card_ids].length
  end

  def current_number
    return 0 unless @quiz_session
    @quiz_session[:current_index] + 1
  end

  def generate_answer_options(card)
    # Get all cards from the deck
    all_cards = @deck.flashcards.where(suspended: false).where.not(id: card.id).to_a
    
    # Determine how many wrong answers to include (up to 3)
    wrong_answer_count = [all_cards.length, 3].min
    
    # Select random wrong answers
    wrong_answers = all_cards.sample(wrong_answer_count).map(&:back_text)
    
    # Combine correct answer with wrong answers and shuffle
    options = ([card.back_text] + wrong_answers).shuffle
    
    options
  end

  def update_card_progress(card, correct)
    # Find or create card_progress for this user and card
    card_progress = CardProgress.find_or_initialize_by(user_id: current_user.id, card_id: card.id)
    
    if correct
      # Increase repetitions and ease for correct answers
      card_progress.repetitions += 1
      card_progress.ease_factor = [card_progress.ease_factor + 0.1, 2.5].max
    else
      # Reset or decrease for incorrect answers
      card_progress.lapses += 1
      card_progress.ease_factor = [card_progress.ease_factor - 0.2, 1.3].max
    end
    
    # Update the due date (simple logic - can be enhanced)
    interval_days = correct ? card_progress.repetitions : 0
    card_progress.interval_days = interval_days
    card_progress.due_at = interval_days.days.from_now
    card_progress.review_on = interval_days.days.from_now.to_date
    
    card_progress.save
    
    # Also create a review record
    Review.create(
      user_id: current_user.id,
      card_id: card.id,
      rating: correct ? 3 : 1, # Simple rating: 3 for correct, 1 for incorrect
      time_taken_ms: 0,
      scheduled_interval_days: card_progress.interval_days,
      new_interval_days: interval_days,
      new_ease_factor: card_progress.ease_factor,
      reviewed_at: Time.current
    )
  end
end
