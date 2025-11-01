class CardsController < ApplicationController
  before_action :require_login
  before_action :set_deck
  before_action :set_card, only: %i[show edit update destroy]

  def index
    @cards = @deck.cards.active.order(:created_at)
  end

  def show
  end

  def new
    authorize_edit!(@deck)
    @card = @deck.cards.new
  end

  def create
    authorize_edit!(@deck)
    @card = @deck.cards.new(card_params)
    if @card.save
      redirect_to [@deck, @card], notice: "Card created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_edit!(@deck)
  end

  def update
    authorize_edit!(@deck)
    if @card.update(card_params)
      redirect_to [@deck, @card], notice: "Card updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_edit!(@deck)
    @card.destroy
    redirect_to deck_cards_path(@deck), notice: "Card deleted."
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
    @card = @deck.cards.find(params[:id])
  end

  def card_params
    params.require(:card).permit(:front_text, :back_text, :card_type, :suspended)
  end

  def authorize_edit!(deck)
    return if deck.owner_id == current_user.id
    return if deck.deck_collaborators.where(user_id: current_user.id, role: :editor).exists?
    redirect_to deck, alert: "You don’t have edit permission on this deck."
  end
end
