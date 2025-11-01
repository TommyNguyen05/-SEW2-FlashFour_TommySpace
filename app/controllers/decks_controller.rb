# frozen_string_literal: true

class DecksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck, only: %i[show edit update destroy]

  def index
    @decks = current_user.decks.order(created_at: :desc) rescue Deck.where(owner_id: current_user.id).order(created_at: :desc)
  end

  def show
    # @deck set in before_action
  end

  def new
    @deck = Deck.new
  end

  def create
    @deck = Deck.new(deck_params)
    # Associate to current user. If your Deck model has belongs_to :owner, class_name: 'User'
    # you can use: @deck.owner = current_user
    # To be safe with current schema, set the foreign key directly:
    @deck.owner_id = current_user.id

    if @deck.save
      redirect_to @deck, notice: 'Deck was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @deck.update(deck_params)
      redirect_to @deck, notice: 'Deck was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deck.destroy
    redirect_to decks_path, notice: 'Deck was successfully deleted.'
  end

  def export
    @deck = (current_user.decks.find(params[:id]) rescue Deck.where(owner_id: current_user.id).find(params[:id]))
    
    # Generate the export content
    export_content = @deck.flashcards.map do |card|
      # Escape commas and newlines in the content
      front = card.front_text.gsub(',', '\\,').gsub("\n", ' ')
      back = card.back_text.gsub(',', '\\,').gsub("\n", ' ')
      "#{front},#{back}"
    end.join("\n")
    
    # Send the file for download
    send_data export_content,
              filename: "#{@deck.title.parameterize}-#{Time.current.to_i}.txt",
              type: 'text/plain',
              disposition: 'attachment'
  end

  private

  def set_deck
    # Prefer association if present; fall back to owner_id filter
    @deck = (current_user.decks.find(params[:id]) rescue Deck.where(owner_id: current_user.id).find(params[:id]))
  end

  def deck_params
    # Use db columns (title, description, is_public). Keep :name for backward compatibility if you had it earlier.
    params.require(:deck).permit(:title, :description, :is_public, :name)
  end
end