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
    @deck = current_user.decks.find_by(id: params[:id]) || Deck.find_by!(owner_id: current_user.id, id: params[:id])
    
    # Generate the export content as JSON
    export_data = {
      deck: {
        title: @deck.title,
        description: @deck.description
      },
      flashcards: @deck.flashcards.map do |card|
        {
          front_text: card.front_text,
          back_text: card.back_text
        }
      end
    }
    
    # Send the file for download
    send_data export_data.to_json,
              filename: "#{@deck.title.parameterize}-#{Time.current.to_i}.json",
              type: 'application/json',
              disposition: 'attachment'
  end

  def import_form
    @deck = Deck.new
  end

  def import
    @deck = Deck.new(import_deck_params)
    @deck.owner_id = current_user.id

    if params[:deck][:file].blank?
      @deck.errors.add(:base, "Please upload a file")
      render :import_form, status: :unprocessable_entity
      return
    end

    file = params[:deck][:file]
    
    # Parse the uploaded JSON file
    begin
      content = file.read.force_encoding('UTF-8')
      
      # Parse JSON
      data = JSON.parse(content)
      
      # Validate JSON structure
      unless data.is_a?(Hash) && data['flashcards'].is_a?(Array)
        @deck.errors.add(:base, "Invalid JSON structure. Expected a hash with 'flashcards' array.")
        render :import_form, status: :unprocessable_entity
        return
      end
      
      flashcards = data['flashcards']
      
      if flashcards.empty?
        @deck.errors.add(:base, "The uploaded file contains no flashcards")
        render :import_form, status: :unprocessable_entity
        return
      end

      # Save the deck first
      if @deck.save
        # Create flashcards from the JSON data
        cards_created = 0
        flashcards.each do |card_data|
          next unless card_data.is_a?(Hash)
          
          # Explicitly handle nil values
          front_text = card_data['front_text']
          back_text = card_data['back_text']
          
          next if front_text.nil? || back_text.nil?
          
          front = front_text.to_s.strip
          back = back_text.to_s.strip
          
          next if front.blank? || back.blank?

          @deck.flashcards.create(
            front_text: front,
            back_text: back,
            card_type: :basic
          )
          cards_created += 1
        end

        if cards_created > 0
          redirect_to @deck, notice: "Deck was successfully imported with #{cards_created} cards."
        else
          @deck.destroy
          @deck = Deck.new(import_deck_params)
          @deck.errors.add(:base, "No valid cards found in the file")
          render :import_form, status: :unprocessable_entity
        end
      else
        render :import_form, status: :unprocessable_entity
      end
    rescue JSON::ParserError => e
      @deck.errors.add(:base, "Invalid JSON format: #{e.message}")
      render :import_form, status: :unprocessable_entity
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
      @deck.errors.add(:base, "Invalid file encoding. Please ensure the file is UTF-8 encoded.")
      render :import_form, status: :unprocessable_entity
    rescue StandardError => e
      @deck.errors.add(:base, "Error reading file: #{e.message}")
      render :import_form, status: :unprocessable_entity
    end
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

  def import_deck_params
    params.require(:deck).permit(:title, :description)
  end
end