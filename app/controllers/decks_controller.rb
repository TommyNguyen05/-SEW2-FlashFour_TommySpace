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
    
    # Parse the uploaded file
    begin
      content = file.read.force_encoding('UTF-8')
      lines = content.split("\n").reject(&:blank?)
      
      if lines.empty?
        @deck.errors.add(:base, "The uploaded file is empty")
        render :import_form, status: :unprocessable_entity
        return
      end

      # Save the deck first
      if @deck.save
        # Create flashcards from the file content
        cards_created = 0
        lines.each do |line|
          # Split by first unescaped comma
          # Replace escaped commas temporarily, split, then restore
          temp_marker = "\u{FFFF}"
          temp_line = line.gsub('\\,', temp_marker)
          parts = temp_line.split(',', 2)
          next if parts.length < 2

          front = parts[0].gsub(temp_marker, ',').strip
          back = parts[1].gsub(temp_marker, ',').strip
          
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