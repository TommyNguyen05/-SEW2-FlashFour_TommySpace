class FlashcardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck

  # Render form for creating a new flashcard
  def new 
    @flashcard = @deck.flashcards.new
  end

  # Create a new flashcard in the specified deck
  def create 
    # Associate new flashcard with the deck
    @flashcard = @deck.flashcards.new(flashcard_params) 

    # Attempt to save the new flashcard
    if @flashcard.save 
      redirect_to @deck, notice: 'Flashcard was successfully created.'
    else
      render :new
    end
  end

  private
  
  # Set the deck based on the current user and provided deck_id
  def set_deck 
    @deck = current_user.decks.find(params[:deck_id])
  end

  # Strong parameters for flashcard
  def flashcard_params 
    params.require(:flashcard).permit(:front_text, :difficulty)
  end
end