# frozen_string_literal: true

class DecksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck, only: %i[show edit update destroy]

  # List all top-level decks for the current user
  def index
    @decks = current_user.decks.where(parent_id: nil) # Only top-level decks
  end

  def show; end

  # Render form for creating a new deck
  def new
    @deck = current_user.decks.new(deck_params) # Associate new deck with current user

    # Attempt to save the new deck
    if @deck.save 
      redirect_to @deck, notice: 'Deck was successfully created.' 
    else
      render :new
    end
  end

  def edit

  end

  # Update an existing deck
  def update 
    if @deck.update(deck_params) # Attempt to update the deck
      redirect_to @deck, notice: 'Deck was successfully updated.' # Redirect on success
    else
      render :edit 
    end
  end

  # Delete a deck
  def destroy 
    @deck.destroy # Delete the deck
    redirect_to decks_url, notice: 'Deck was successfully destroyed.' # Redirect to decks list
  end

  private

  # Set the deck based on the current user and provided ID
  def set_deck 
    @deck = current_user.decks.find(params[:id]) # Find the deck belonging to the current user
  end

  # Strong parameters for deck
  def deck_params 
    params.require(:deck).permit(:name, :parent_id) # Permit name and parent_id for nested decks
  end
end