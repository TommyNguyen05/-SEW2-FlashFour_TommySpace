class DeckCollaboratorsController < ApplicationController
  before_action :require_login
  before_action :set_deck

  def index
    authorize_owner!(@deck)
    @collaborators = @deck.deck_collaborators.includes(:user)
  end

  def create
    authorize_owner!(@deck)
    user = User.find_by(email: params[:email])
    unless user
      redirect_to deck_deck_collaborators_path(@deck), alert: "User not found." and return
    end

    collab = @deck.deck_collaborators.new(user: user, role: params[:role] || "viewer")
    if collab.save
      redirect_to deck_deck_collaborators_path(@deck), notice: "Collaborator added."
    else
      redirect_to deck_deck_collaborators_path(@deck), alert: collab.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize_owner!(@deck)
    collab = @deck.deck_collaborators.find(params[:id])
    collab.destroy
    redirect_to deck_deck_collaborators_path(@deck), notice: "Collaborator removed."
  end

  private

  def set_deck
    @deck = current_user.owned_decks.find(params[:deck_id])
  end

  def authorize_owner!(deck)
    return if deck.owner_id == current_user.id
    redirect_to deck, alert: "Only the owner can manage collaborators."
  end
end
