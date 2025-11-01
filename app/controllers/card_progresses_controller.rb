class CardProgressesController < ApplicationController
  before_action :require_login
  before_action :set_deck
  before_action :set_card
  before_action :set_card_progress

  def show
    render json: @card_progress
  end

  def update
    if @card_progress.update(card_progress_params)
      render json: @card_progress
    else
      render json: { errors: @card_progress.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_deck
    @deck =
      Deck
        .left_outer_joins(:deck_collaborators)
        .where("decks.is_public = TRUE OR decks.owner_id = :uid OR deck_collaborators.user_id = :uid", uid: current_user.id)
        .distinct
        .find(params[:deck_id])
  end

  def set_card
    @card = @deck.cards.find(params[:card_id])
  end

  def set_card_progress
    @card_progress = current_user.card_progresses.find_or_initialize_by(card: @card)
  end

  def card_progress_params
    params.require(:card_progress).permit(:state, :ease_factor, :interval_days, :repetitions, :lapses, :due_at)
  end
end
