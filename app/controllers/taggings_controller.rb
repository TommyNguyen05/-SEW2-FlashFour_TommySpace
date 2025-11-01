class TaggingsController < ApplicationController
  before_action :require_login

  def create
    card = Card.find(params[:card_id])
    tag  = Tag.find(params[:tag_id])
    tagging = Tagging.new(card: card, tag: tag)

    if tagging.save
      redirect_back fallback_location: card.deck, notice: "Tag added."
    else
      redirect_back fallback_location: card.deck, alert: tagging.errors.full_messages.to_sentence
    end
  end

  def destroy
    tagging = Tagging.find(params[:id])
    tagging.destroy
    redirect_back fallback_location: tagging.card.deck, notice: "Tag removed."
  end
end
