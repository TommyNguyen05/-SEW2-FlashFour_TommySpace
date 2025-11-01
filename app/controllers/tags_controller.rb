class TagsController < ApplicationController
  before_action :require_login

  def index
    @tags = Tag.order(:name)
  end

  def create
    @tag = Tag.new(tag_params)
    if @tag.save
      redirect_to tags_path, notice: "Tag created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def tag_params
    params.require(:tag).permit(:name)
  end
end
