# Feature Implementation Roadmap

## Overview
This document outlines how to implement the remaining features from LoayDatabase using the models that have been integrated.

## Models Already Added ✅
- CardProgress - Spaced repetition tracking
- Review - Study session history
- Tag - Card categorization
- Tagging - Tag-card associations
- DeckCollaborator - Deck sharing permissions

## Feature 1: Tagging System

### Controllers Needed
```ruby
# app/controllers/tags_controller.rb
class TagsController < ApplicationController
  before_action :authenticate_user!
  
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

# app/controllers/taggings_controller.rb  
class TaggingsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    flashcard = Flashcard.find(params[:flashcard_id])
    tag = Tag.find(params[:tag_id])
    tagging = Tagging.new(flashcard: flashcard, tag: tag)
    
    if tagging.save
      redirect_back fallback_location: flashcard.deck, notice: "Tag added."
    else
      redirect_back fallback_location: flashcard.deck, alert: tagging.errors.full_messages.to_sentence
    end
  end
  
  def destroy
    tagging = Tagging.find(params[:id])
    tagging.destroy
    redirect_back fallback_location: tagging.flashcard.deck, notice: "Tag removed."
  end
end
```

### Routes Needed
```ruby
resources :tags, only: [:index, :create]
resources :flashcards do
  resources :taggings, only: [:create, :destroy]
end
```

### Views Needed
- `app/views/tags/index.html.erb` - List all tags
- Add tag selection to flashcard forms
- Show tags on flashcard show page

## Feature 2: Deck Collaboration

### Controller Needed
```ruby
# app/controllers/deck_collaborators_controller.rb
class DeckCollaboratorsController < ApplicationController
  before_action :authenticate_user!
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
    @deck = current_user.decks.find(params[:deck_id])
  end
  
  def authorize_owner!(deck)
    return if deck.owner_id == current_user.id
    redirect_to deck, alert: "Only the owner can manage collaborators."
  end
end
```

### Routes Needed
```ruby
resources :decks do
  resources :deck_collaborators, only: [:index, :create, :destroy]
end
```

### DecksController Updates
Update `set_deck` to include collaborated decks:
```ruby
def set_deck
  @deck = Deck
    .left_outer_joins(:deck_collaborators)
    .where("decks.owner_id = :uid OR deck_collaborators.user_id = :uid", uid: current_user.id)
    .distinct
    .find(params[:id])
end
```

### Views Needed
- `app/views/deck_collaborators/index.html.erb` - Manage collaborators
- Add "Share" button to deck show page

## Feature 3: Spaced Repetition & Reviews

### Controller Needed
```ruby
# app/controllers/reviews_controller.rb
class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_deck
  before_action :set_flashcard
  
  def create
    @review = Review.new(review_params)
    @review.user = current_user
    @review.card = @flashcard  # Note: card_id column works with flashcard
    
    if @review.save
      # Update card progress based on review
      update_card_progress(@flashcard, review_params[:rating])
      
      respond_to do |format|
        format.html { redirect_to [@deck, @flashcard], notice: "Review recorded." }
        format.json { render json: { status: "ok" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to [@deck, @flashcard], alert: @review.errors.full_messages.to_sentence }
        format.json { render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  def set_deck
    @deck = Deck
      .left_outer_joins(:deck_collaborators)
      .where("decks.owner_id = :uid OR deck_collaborators.user_id = :uid", uid: current_user.id)
      .distinct
      .find(params[:deck_id])
  end
  
  def set_flashcard
    @flashcard = @deck.flashcards.find(params[:flashcard_id])
  end
  
  def review_params
    params.require(:review).permit(:rating, :time_taken_ms)
  end
  
  def update_card_progress(flashcard, rating)
    progress = current_user.card_progresses.find_or_initialize_by(card: flashcard)
    # Implement spaced repetition algorithm here
    # Update interval_days, ease_factor, due_at based on rating
    progress.save
  end
end
```

### Routes Needed
```ruby
resources :decks do
  resources :flashcards do
    resources :reviews, only: [:create]
  end
end
```

### LearningSessionsController Integration
Update the existing learning sessions to use reviews and card progress.

## Feature 4: Progress Analytics Dashboard

### Controller Needed
```ruby
# app/controllers/progress_controller.rb
class ProgressController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @total_cards = current_user.card_progresses.count
    @due_now = current_user.card_progresses.due_now.count
    @reviews_today = current_user.reviews.where(created_at: Time.zone.today.all_day).count
    
    last_30 = current_user.reviews.where("created_at >= ?", 30.days.ago)
    correct = last_30.where(rating: [:good, :easy]).count
    total = last_30.count
    @accuracy = total.positive? ? ((correct.to_f / total) * 100.0).round : nil
    
    @streak_days = compute_streak_for(current_user)
    
    @per_deck_stats = Deck
      .left_outer_joins(:deck_collaborators)
      .where("decks.owner_id = :uid OR deck_collaborators.user_id = :uid", uid: current_user.id)
      .distinct
      .map { |deck| deck_stats_for(deck, current_user) }
    
    raw = current_user.reviews
      .where("created_at >= ?", 14.days.ago.beginning_of_day)
      .group("DATE(created_at)")
      .order("DATE(created_at)")
      .count
    
    @review_activity = (0..13).map do |i|
      day = i.days.ago.to_date
      { date: day, count: raw[day] || 0 }
    end.reverse
  end
  
  private
  
  def compute_streak_for(user)
    streak = 0
    day = Time.zone.today
    loop do
      break unless user.reviews.where(created_at: day.all_day).exists?
      streak += 1
      day -= 1.day
    end
    streak
  end
  
  def deck_stats_for(deck, user)
    progress_for_deck = user.card_progresses.joins(card: :deck).where(cards: { deck_id: deck.id })
    total = progress_for_deck.count
    due = progress_for_deck.due_now.count
    
    reviews_today = user.reviews.joins(card: :deck)
      .where(cards: { deck_id: deck.id })
      .where(created_at: Time.zone.today.all_day)
      .count
    
    last_30 = user.reviews.joins(card: :deck)
      .where(cards: { deck_id: deck.id })
      .where("reviews.created_at >= ?", 30.days.ago)
    correct = last_30.where(rating: [:good, :easy]).count
    total_r = last_30.count
    accuracy = total_r.positive? ? ((correct.to_f / total_r) * 100.0).round : nil
    
    {
      name: deck.title,
      total: total,
      due: due,
      reviewed_today: reviews_today,
      accuracy: accuracy
    }
  end
end
```

### Routes Needed
```ruby
get 'progress', to: 'progress#index'
```

### View Needed
```erb
<!-- app/views/progress/index.html.erb -->
<div class="progress-analytics">
  <div class="analytics-section">
    <h2>Your Progress</h2>
    <div class="analytics-grid">
      <div class="analytics-card">
        <div class="label">Total Cards</div>
        <div class="value"><%= @total_cards %></div>
      </div>
      <div class="analytics-card">
        <div class="label">Due Now</div>
        <div class="value"><%= @due_now %></div>
      </div>
      <div class="analytics-card">
        <div class="label">Reviewed Today</div>
        <div class="value"><%= @reviews_today %></div>
      </div>
      <% if @accuracy %>
        <div class="analytics-card">
          <div class="label">Accuracy (30d)</div>
          <div class="value"><%= @accuracy %>%</div>
        </div>
      <% end %>
      <div class="analytics-card">
        <div class="label">Streak</div>
        <div class="value"><%= @streak_days %> days</div>
      </div>
    </div>
  </div>
  
  <div class="analytics-section">
    <h3>Review Activity (14 days)</h3>
    <div class="activity-bars">
      <% max_count = @review_activity.map { |d| d[:count] }.max || 1 %>
      <% @review_activity.each do |day| %>
        <div class="activity-bar">
          <div class="bar-fill" style="height: <%= (day[:count].to_f / max_count * 100).round %>%"></div>
          <div class="bar-label"><%= day[:date].strftime("%m/%d") %></div>
        </div>
      <% end %>
    </div>
  </div>
  
  <div class="analytics-section">
    <h3>Per-Deck Statistics</h3>
    <table class="analytics-table">
      <thead>
        <tr>
          <th>Deck</th>
          <th>Cards</th>
          <th>Due</th>
          <th>Today</th>
          <th>Accuracy</th>
        </tr>
      </thead>
      <tbody>
        <% @per_deck_stats.each do |stat| %>
          <tr>
            <td><%= stat[:name] %></td>
            <td><%= stat[:total] %></td>
            <td><%= stat[:due] %></td>
            <td><%= stat[:reviewed_today] %></td>
            <td><%= stat[:accuracy] ? "#{stat[:accuracy]}%" : "N/A" %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
  </div>
</div>
```

Note: The CSS for this view already exists in `app/assets/stylesheets/progress.css`

## Implementation Order

1. **Tagging System** (Low complexity, high value)
   - Independent feature
   - Adds immediate value for card organization

2. **Deck Collaboration** (Medium complexity, high value)
   - Requires permission checks
   - Enables team/classroom use

3. **Reviews Integration** (Medium complexity)
   - Integrate with existing learning sessions
   - Start collecting review data

4. **Spaced Repetition Algorithm** (High complexity)
   - Implement SM-2 or similar algorithm
   - Update card progress based on reviews

5. **Progress Dashboard** (Low complexity once reviews are working)
   - Visualize collected data
   - Motivates continued use

## Testing Requirements

For each feature:
1. Model tests (validations, associations)
2. Controller tests (actions, permissions)
3. Integration tests (user workflows)
4. System tests (UI interactions)

## Database Considerations

All tables already exist! No migrations needed for:
- card_progresses
- reviews
- tags
- taggings
- deck_collaborators

## Security Considerations

1. **Deck Access Control**
   - Always check if user is owner or collaborator
   - Respect viewer vs editor roles

2. **Data Isolation**
   - Card progress is per-user
   - Reviews are per-user
   - Don't expose other users' study data

3. **Input Validation**
   - Sanitize tag names
   - Validate email addresses for collaboration
   - Validate review ratings

## Performance Considerations

1. **Eager Loading**
   - Always use `.includes()` for associations
   - Avoid N+1 queries

2. **Indexing**
   - Database already has proper indexes
   - Monitor query performance

3. **Caching**
   - Cache progress statistics
   - Cache deck counts

## Additional Resources

- See LoayDatabase branch for reference implementations
- Refer to `LOAY_DATABASE_ANALYSIS.md` for detailed comparisons
- Check Rails guides for best practices

## Questions?

Contact the team or refer to the integration documentation.
