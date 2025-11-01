class ReviewsController < ApplicationController
  before_action :require_login
  before_action :set_deck
  before_action :set_card

  def create
    @review = Review.new(review_params)
    @review.user = current_user
    @review.card = @card

    if @review.save
      respond_to do |format|
        format.html { redirect_to [@deck, @card], notice: "Review recorded." }
        format.json { render json: { status: "ok" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to [@deck, @card], alert: @review.errors.full_messages.to_sentence }
        format.json { render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity }
      end
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

  def review_params
    params.require(:review).permit(:rating, :time_taken_ms)
  end
end
