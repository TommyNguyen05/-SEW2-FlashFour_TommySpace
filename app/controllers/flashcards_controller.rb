class FlashcardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck

  def new
    @flashcard = @deck.flashcards.new
  end

  def create
    @flashcard = @deck.flashcards.new(flashcard_params)
    if @flashcard.save
      if params[:commit] == 'Create and add another'
        redirect_to new_deck_flashcard_path(@deck), notice: 'Card added.'
      else
        redirect_to deck_path(@deck), notice: 'Card added.'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_deck
    @deck = current_user.decks.find(params[:deck_id])
  end

  def flashcard_params
    params.require(:flashcard).permit(:front_text, :back_text, :card_type)
  end
end