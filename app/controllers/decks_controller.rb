class DecksController < ApplicationController
  before_action :require_login
  before_action :set_deck, only: %i[show edit update destroy]

  def index
    @decks = Deck.public_or_owned_by(current_user).includes(:owner)
  end

  def show
    @cards = @deck.cards.includes(:tags)
  end

  def new
    @deck = current_user.owned_decks.new
  end

  def create
    @deck = current_user.owned_decks.new(deck_params)
    if @deck.save
      redirect_to @deck, notice: "Deck created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_owner!(@deck)
  end

  def update
    authorize_owner!(@deck)
    if @deck.update(deck_params)
      redirect_to @deck, notice: "Deck updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_owner!(@deck)
    @deck.destroy
    redirect_to decks_path, notice: "Deck deleted."
  end

  private

  def set_deck
    @deck =
      Deck
        .left_outer_joins(:deck_collaborators)
        .where("decks.is_public = TRUE OR decks.owner_id = :uid OR deck_collaborators.user_id = :uid", uid: current_user.id)
        .distinct
        .find(params[:id])
  end

  def deck_params
    params.require(:deck).permit(:title, :description, :is_public)
  end

  def authorize_owner!(deck)
    return if deck.owner_id == current_user.id
    redirect_to deck, alert: "Only the owner can do that."
  end
end
