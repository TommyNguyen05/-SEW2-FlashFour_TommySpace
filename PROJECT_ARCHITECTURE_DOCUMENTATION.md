# FlashFour Project Architecture Documentation

## Project Overview

FlashFour is a web-based flashcard learning application built with Ruby on Rails 8.0. The system enables users to create decks of flashcards, study them through learning sessions and quizzes, and track their progress using a spaced repetition system (SRS) with comprehensive analytics.

---

## 1. Class Diagram & Relationships

### Core Domain Models

#### User
- **Purpose**: Represents authenticated users of the application
- **Technology**: Uses Devise gem for authentication
- **Key Attributes**:
  - `email` (string, unique)
  - `display_name` (string)
  - `encrypted_password` (string)
  - `remember_created_at` (datetime)
- **Relationships**:
  - Has many `Deck` (as owner)
  - Has many `Flashcard` (through decks)
  - Has many `CardProgress` (tracking learning progress)
  - Has many `Review` (tracking review history)

#### Deck
- **Purpose**: Container for organizing flashcards into logical groups
- **Key Attributes**:
  - `title` (string, required)
  - `description` (text)
  - `is_public` (boolean, default: false)
  - `owner_id` (foreign key to User)
- **Relationships**:
  - Belongs to `User` (as owner)
  - Has many `Flashcard` (dependent destroy)
  - Has many `Subdeck` (self-referential, for hierarchical organization)
  - Belongs to `Parent Deck` (optional, for subdeck functionality)
- **Special Features**:
  - Supports hierarchical deck structure (parent/subdeck relationships)
  - Import/Export functionality for deck sharing

#### Flashcard
- **Purpose**: Individual learning cards with front/back content
- **Database Table**: `cards` (legacy naming)
- **Key Attributes**:
  - `front_text` (text, required)
  - `back_text` (text, required)
  - `card_type` (enum: basic=0)
  - `extras` (JSON, default: {})
  - `suspended` (boolean, default: false)
  - `deck_id` (foreign key)
- **Relationships**:
  - Belongs to `Deck`
  - Has many `CardProgress` (tracking per-user progress)
  - Has many `Review` (tracking review history)
- **Business Logic**:
  - `translate_front_text` callback - simulates translation with 0.5s delay
  - Validation for presence of front and back text

#### CardProgress
- **Purpose**: Tracks individual user progress on each flashcard using SRS algorithm
- **Key Attributes**:
  - `user_id` (foreign key)
  - `card_id` (foreign key)
  - `repetitions` (integer, default: 0)
  - `lapses` (integer, default: 0)
  - `interval_days` (integer, default: 0)
  - `ease_factor` (decimal(5,2), default: 2.5)
  - `due_at` (datetime)
  - `state` (enum: fresh=0, learning=1, review=2, relearning=3)
  - `review_on` (date)
- **Relationships**:
  - Belongs to `User`
  - Belongs to `Flashcard` (as card)
- **Business Logic**:
  - `update_from_review(quality)` - Implements SRS algorithm
  - `due_now` scope - Returns cards due for review
  - Ease factor validation (>= 1.3)
  - Interval days validation (>= 0)

#### Review
- **Purpose**: Records individual review events for analytics
- **Key Attributes**:
  - `user_id` (foreign key)
  - `card_id` (foreign key)
  - `rating` (enum: again=0, hard=1, good=2, easy=3)
  - `time_taken_ms` (integer, default: 0)
  - `scheduled_interval_days` (integer)
  - `new_interval_days` (integer)
  - `new_ease_factor` (decimal(5,2))
  - `reviewed_at` (datetime)
- **Relationships**:
  - Belongs to `User`
  - Belongs to `Flashcard` (as card)
- **Business Logic**:
  - Tracks time taken for performance analytics
  - Records SRS algorithm state changes

#### ApplicationRecord
- **Purpose**: Base class for all Active Record models
- **Pattern**: Template Method Pattern
- **Inherits From**: `ActiveRecord::Base`
- **Feature**: Marked as `primary_abstract_class`

### Supporting Models (Database Schema Only)

The schema also includes these tables for future/extended functionality:

#### Tags
- `name` (string, unique)
- Purpose: Tag organization for flashcards

#### Taggings
- Links tags to cards (many-to-many relationship)
- Unique constraint on tag_id and card_id

#### DeckCollaborators
- `deck_id`, `user_id`, `role` (enum)
- Purpose: Share decks with other users
- Not yet implemented in model layer

### Class Relationship Summary

```
User
├── owns many Decks
├── tracks progress in many CardProgresses
├── has many Reviews
└── has many Flashcards (through Decks)

Deck
├── belongs to User (owner)
├── contains many Flashcards
├── has many Subdecks (self-referential)
└── belongs to Parent Deck (optional)

Flashcard
├── belongs to Deck
├── has many CardProgresses (one per user)
└── has many Reviews

CardProgress
├── belongs to User
└── belongs to Flashcard

Review
├── belongs to User
└── belongs to Flashcard
```

---

## 2. Design Patterns

### 2.1 Active Record Pattern
**Where**: All model classes (`User`, `Deck`, `Flashcard`, `CardProgress`, `Review`)

**Why**: Rails' core architectural pattern combining data access and business logic. Each model class represents a database table and encapsulates both:
- Database operations (CRUD)
- Business logic related to that entity
- Relationships and associations

**Benefits**:
- Simplifies development with convention over configuration
- Reduces boilerplate code
- Provides automatic ORM mapping

### 2.2 Model-View-Controller (MVC) Pattern
**Where**: Throughout the entire application

**Components**:
- **Models**: `app/models/` - Business logic and data access
- **Views**: `app/views/` - Presentation layer (ERB templates)
- **Controllers**: `app/controllers/` - Request handling and coordination

**Why**: Separates concerns into three distinct layers:
- Models handle data and business rules
- Views handle presentation
- Controllers coordinate between models and views

**Example Flow**:
```
User Request → Router → Controller → Model (Business Logic) → View (Rendering) → Response
```

### 2.3 Template Method Pattern
**Where**: `ApplicationRecord` and `ApplicationController`

**Why**: Provides a base template for common functionality while allowing subclasses to override specific behaviors.

**Implementation**:
- `ApplicationRecord` - Base for all models with shared Active Record configuration
- `ApplicationController` - Base for all controllers with shared authentication/authorization

**Benefits**:
- DRY principle - common code in one place
- Consistent behavior across all models/controllers
- Easy to add application-wide features

### 2.4 Strategy Pattern (Implicit)
**Where**: Session management in `LearningSessionsController` and `QuizzesController`

**Why**: Different learning strategies (learning session vs quiz) with interchangeable algorithms.

**Implementation**:
- Both controllers manage flashcard review sessions
- Different rating/scoring strategies:
  - Learning Session: Three-level self-assessment (unfamiliar, still_learning, mastered)
  - Quiz: Multiple-choice with automatic correctness checking
- Session data structure varies by strategy
- Separate completion logic and statistics

**Benefits**:
- Supports multiple study methods
- Easy to add new learning strategies
- Each strategy can be modified independently

### 2.5 Facade Pattern
**Where**: `ProgressController`

**Why**: Provides a simplified interface to complex subsystems (CardProgress, Review, Deck analytics).

**Implementation**:
```ruby
def index
  # Facades complex queries into simple instance variables
  @total_cards = current_user.card_progresses.count
  @due_now = current_user.card_progresses.due_now.count
  @reviews_today = current_user.reviews.where(...).count
  @accuracy = calculate_accuracy(...)
  @streak_days = compute_streak_for(current_user)
  @per_deck_stats = aggregate_deck_statistics(...)
end
```

**Benefits**:
- Hides complexity of multiple model interactions
- Provides clean API for view layer
- Centralized analytics logic

### 2.6 Callback Pattern
**Where**: Model lifecycle hooks

**Examples**:
- `Flashcard#before_create :translate_front_text` - Auto-translation simulation
- Devise callbacks in User model

**Why**: Execute code at specific points in object lifecycle without cluttering main logic.

**Benefits**:
- Separation of concerns
- Automatic data processing
- Consistent behavior enforcement

### 2.7 Dependency Injection (Rails Convention)
**Where**: Controllers receiving dependencies through Rails framework

**Examples**:
- `current_user` - Injected by Devise
- `session` - Injected by Rails
- `params` - Injected by Rails

**Why**: Loose coupling and testability

**Benefits**:
- Controllers don't instantiate their dependencies
- Easy to mock in tests
- Framework manages lifecycle

### 2.8 Observer Pattern (Implicit)
**Where**: Not explicitly implemented but suggested for future

**Potential Use**: User streak tracking mentioned in `User#update_streak`

**Future Enhancement**: Could notify user when:
- Cards become due for review
- Streaks are at risk
- Milestones are reached

### 2.9 Command Pattern (Session Actions)
**Where**: Learning session actions (`rate`, `answer`)

**Why**: Encapsulates user actions as objects.

**Implementation**:
- Each user interaction (rating a card) is a command
- Stored in session for replay/undo capability
- Enables statistics calculation from command history

### 2.10 Repository Pattern (Scopes)
**Where**: `CardProgress.due_now` scope

**Why**: Encapsulates query logic for reusability.

**Implementation**:
```ruby
scope :due_now, -> { where('review_on <= ?', Date.today) }
```

**Benefits**:
- Query logic stays in model
- Composable with other queries
- Named queries improve readability

---

## 3. Key Design Decisions

### 3.1 Authentication: Devise Gem
**Decision**: Use Devise instead of custom authentication

**Rationale**:
- Industry-standard, battle-tested authentication solution
- Provides complete user management (registration, login, logout, password recovery)
- Security features built-in (password encryption, remember me, session management)
- Reduces development time and security risks

**Implementation**:
- `devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`
- Automatic route generation for auth flows
- `authenticate_user!` before_action in controllers

**Trade-offs**:
- Dependency on external gem
- Less control over authentication flow
- Learning curve for customization

### 3.2 Spaced Repetition System (SRS)
**Decision**: Implement custom SRS algorithm in `CardProgress`

**Rationale**:
- Core feature for effective learning
- Based on proven cognitive science principles
- Optimizes review timing for long-term retention

**Algorithm Details**:
```ruby
def update_from_review(quality)
  if quality < 3  # Incorrect answer
    self.state = 'relearning'
    self.interval_days = 1  # Review tomorrow
    self.repetition_count = 0
  else  # Correct answer
    self.state = 'review'
    self.interval_days = calculate_interval  # Progressive intervals: 1, 6, then exponential
    self.repetition_count += 1
  end
  
  # Adjust ease factor based on performance
  self.ease_factor += (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
  self.ease_factor = [1.3, self.ease_factor].max  # Minimum ease factor
end
```

**Key Parameters**:
- Ease Factor: Starts at 2.5, minimum 1.3
- Intervals: 1 day → 6 days → exponential growth
- States: fresh → learning → review → relearning

**Benefits**:
- Scientifically proven to improve retention
- Personalized to individual user performance
- Prevents wasted time on well-known cards

### 3.3 Session-Based Learning Tracking
**Decision**: Store learning session state in Rails session (cookies)

**Rationale**:
- Lightweight and stateless
- No database writes during active learning
- Fast performance
- Session data: deck_id, card_ids (shuffled), current_index, responses

**Alternatives Considered**:
- Database-backed sessions: More reliable but slower
- In-memory cache (Redis): Requires additional infrastructure

**Trade-offs**:
- Data lost if cookie is cleared
- Limited session size (4KB cookie limit)
- No cross-device session persistence

**Mitigation**:
- Session data is temporary by design
- Final statistics saved to Review records on completion

### 3.4 Dual Study Modes
**Decision**: Implement both Learning Sessions and Quizzes

**Learning Sessions**:
- Self-directed review
- Flip cards to see answers
- Self-rate understanding (unfamiliar/still learning/mastered)
- No right/wrong judgment

**Quizzes**:
- Active recall testing
- Multiple choice questions
- Automatic correctness checking
- Immediate feedback

**Rationale**:
- Different learning science principles
- Caters to different learning preferences
- Learning sessions for initial exposure
- Quizzes for active recall practice

### 3.5 Progressive Enhancement with Stimulus.js
**Decision**: Use Stimulus.js for interactive features (card flip)

**Rationale**:
- Minimal JavaScript framework
- Progressive enhancement philosophy
- Works with server-rendered HTML
- No heavy client-side framework (React/Vue) needed

**Implementation**:
```javascript
// flashcard_controller.js
flip() {
  this.element.classList.toggle('flipped');
}
```

**Benefits**:
- Fast initial page load
- Graceful degradation
- Easy to maintain
- Follows Rails conventions

### 3.6 Deck Hierarchy (Parent/Subdeck)
**Decision**: Support hierarchical deck organization

**Rationale**:
- Mirrors real-world organization (e.g., "Spanish" → "Spanish Verbs")
- Scalable for large card collections
- Flexibility in studying entire subjects or specific topics

**Implementation**:
- Self-referential association in Deck model
- `parent_id` foreign key
- `has_many :subdecks` and `belongs_to :parent`

**Trade-offs**:
- Complexity in UI navigation
- Not fully implemented in current controllers
- Future feature potential

### 3.7 Import/Export Functionality
**Decision**: JSON-based deck sharing

**Rationale**:
- Enables content sharing between users
- Platform-independent format
- Human-readable for debugging
- Simple structure for parsing

**Format**:
```json
{
  "deck": {
    "title": "Spanish Basics",
    "description": "Common Spanish phrases"
  },
  "flashcards": [
    {"front_text": "Hello", "back_text": "Hola"},
    {"front_text": "Goodbye", "back_text": "Adiós"}
  ]
}
```

**Benefits**:
- Easy deck sharing
- Backup capability
- Content reuse
- Integration possibilities

### 3.8 Enum Pattern for State Management
**Decision**: Use Rails enums for state fields

**Examples**:
- `CardProgress.state`: fresh, learning, review, relearning
- `Review.rating`: again, hard, good, easy
- `Flashcard.card_type`: basic (extensible for future types)

**Rationale**:
- Type safety
- Database efficiency (stored as integers)
- Clear, named states in code
- Easy to query (`CardProgress.state_review`)

**Syntax**:
```ruby
enum :state, { fresh: 0, learning: 1, review: 2, relearning: 3 }, prefix: true
```

**Benefits**:
- Self-documenting code
- Query methods auto-generated
- Prevents invalid states

### 3.9 Analytics-First Design
**Decision**: Comprehensive progress tracking from day one

**Features**:
- Total cards studied
- Cards due today
- Reviews completed today
- Accuracy percentage (last 30 days)
- Daily streak tracking
- Per-deck breakdowns
- 14-day activity chart

**Rationale**:
- User motivation through visible progress
- Data-driven insights
- Gamification elements (streaks)
- Identify weak areas (per-deck accuracy)

**Implementation**:
- Separate `ProgressController` for analytics
- Review model records every interaction
- CardProgress maintains current state

### 3.10 Validation Strategy
**Decision**: Model-level validations with controller fallbacks

**Examples**:
```ruby
# Model validations
validates :front_text, presence: true
validates :back_text, presence: true
validates :ease_factor, numericality: { greater_than_or_equal_to: 1.3 }

# Controller validations
unless %w[unfamiliar still_learning mastered].include?(rating)
  redirect_to deck_learning_session_path(@deck), alert: 'Invalid rating'
end
```

**Rationale**:
- Data integrity at database level
- User-friendly error messages at controller level
- Defense in depth approach

### 3.11 Security Design
**Decision**: Authentication-first with scoped queries

**Implementation**:
```ruby
before_action :authenticate_user!  # All controllers
@decks = current_user.decks  # Scope to current user
@deck = current_user.decks.find(params[:id])  # Prevent unauthorized access
```

**Rationale**:
- Prevent unauthorized access
- Automatic data scoping
- No manual permission checks needed
- Fails safely (404 instead of showing other user's data)

---

## 4. Database Structure

### Schema Version: 2025_11_01_132955

### Tables Overview

#### users
**Purpose**: Store user accounts and authentication data

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing user ID |
| email | string | NOT NULL, UNIQUE | User's email address |
| display_name | string | NOT NULL | User's display name |
| encrypted_password | string | NOT NULL | Hashed password (Devise) |
| remember_created_at | datetime | nullable | Remember me token timestamp |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_users_on_email` (unique)

**Relationships**:
- One-to-many: decks (as owner)
- One-to-many: card_progresses
- One-to-many: reviews

---

#### decks
**Purpose**: Organize flashcards into logical groups/subjects

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing deck ID |
| owner_id | integer | NOT NULL, FK → users | User who owns the deck |
| title | string | NOT NULL | Deck name/title |
| description | text | nullable | Optional deck description |
| is_public | boolean | NOT NULL, default: false | Public sharing flag |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_decks_on_owner_id`
- `index_decks_on_owner_id_and_title`

**Foreign Keys**:
- `owner_id` → `users(id)`

**Relationships**:
- Many-to-one: user (owner)
- One-to-many: cards (flashcards)
- One-to-many: deck_collaborators

---

#### cards
**Purpose**: Store individual flashcard content (Note: table named "cards", model named "Flashcard")

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing card ID |
| deck_id | integer | NOT NULL, FK → decks | Parent deck |
| card_type | integer | NOT NULL, default: 0 | Type of card (0=basic) |
| front_text | text | NOT NULL | Front side content |
| back_text | text | NOT NULL | Back side content |
| extras | json | NOT NULL, default: {} | Additional metadata |
| suspended | boolean | NOT NULL, default: false | Card suspended from study |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_cards_on_deck_id`
- `index_cards_on_card_type`
- `index_cards_on_suspended`

**Foreign Keys**:
- `deck_id` → `decks(id)`

**Relationships**:
- Many-to-one: deck
- One-to-many: card_progresses
- One-to-many: reviews
- Many-to-many: tags (through taggings)

**Enums**:
- `card_type`: 0=basic (extensible for future types like cloze, image, etc.)

---

#### card_progresses
**Purpose**: Track per-user progress on each flashcard using spaced repetition

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing progress ID |
| user_id | integer | NOT NULL, FK → users | User tracking progress |
| card_id | integer | NOT NULL, FK → cards | Card being tracked |
| repetitions | integer | NOT NULL, default: 0 | Successful review count |
| lapses | integer | NOT NULL, default: 0 | Failed review count |
| interval_days | integer | NOT NULL, default: 0 | Days until next review |
| ease_factor | decimal(5,2) | NOT NULL, default: 2.5 | SRS ease multiplier |
| due_at | datetime | NOT NULL, default: NOW() | Next review datetime |
| state | integer | NOT NULL, default: 0 | Learning state (enum) |
| review_on | date | nullable | Next review date |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_card_progresses_on_user_id`
- `index_card_progresses_on_card_id`
- `index_card_progresses_on_user_id_and_card_id` (unique)
- `index_card_progresses_on_user_id_and_due_at`
- `index_card_progresses_on_state`

**Foreign Keys**:
- `user_id` → `users(id)`
- `card_id` → `cards(id)`

**Relationships**:
- Many-to-one: user
- Many-to-one: card (flashcard)

**Enums**:
- `state`: 0=fresh, 1=learning, 2=review, 3=relearning

**Constraints**:
- `ease_factor` >= 1.3 (validated in model)
- `interval_days` >= 0 (validated in model)
- Unique composite index on (user_id, card_id)

---

#### reviews
**Purpose**: Log every review event for analytics and history

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing review ID |
| user_id | integer | NOT NULL, FK → users | User who reviewed |
| card_id | integer | NOT NULL, FK → cards | Card that was reviewed |
| rating | integer | NOT NULL | User rating/difficulty |
| time_taken_ms | integer | NOT NULL, default: 0 | Time spent (milliseconds) |
| scheduled_interval_days | integer | NOT NULL, default: 0 | Interval before review |
| new_interval_days | integer | NOT NULL, default: 0 | Interval after review |
| new_ease_factor | decimal(5,2) | NOT NULL, default: 2.5 | Ease factor after review |
| reviewed_at | datetime | NOT NULL, default: NOW() | Review timestamp |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_reviews_on_user_id`
- `index_reviews_on_card_id`
- `index_reviews_on_user_id_and_card_id_and_reviewed_at`

**Foreign Keys**:
- `user_id` → `users(id)`
- `card_id` → `cards(id)`

**Relationships**:
- Many-to-one: user
- Many-to-one: card (flashcard)

**Enums**:
- `rating`: 0=again, 1=hard, 2=good, 3=easy

---

#### tags
**Purpose**: Provide tagging/categorization system for cards

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing tag ID |
| name | string | NOT NULL, UNIQUE | Tag name |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_tags_on_name` (unique)

**Relationships**:
- Many-to-many: cards (through taggings)

---

#### taggings
**Purpose**: Join table for many-to-many relationship between tags and cards

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing tagging ID |
| tag_id | integer | NOT NULL, FK → tags | Tag reference |
| card_id | integer | NOT NULL, FK → cards | Card reference |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_taggings_on_tag_id`
- `index_taggings_on_card_id`
- `index_taggings_on_tag_id_and_card_id` (unique)

**Foreign Keys**:
- `tag_id` → `tags(id)`
- `card_id` → `cards(id)`

**Constraints**:
- Unique composite index on (tag_id, card_id) prevents duplicate taggings

---

#### deck_collaborators
**Purpose**: Enable deck sharing with other users (not yet implemented in models)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | integer | PRIMARY KEY | Auto-incrementing ID |
| deck_id | integer | NOT NULL, FK → decks | Shared deck |
| user_id | integer | NOT NULL, FK → users | Collaborating user |
| role | integer | NOT NULL, default: 0 | Collaboration role |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record last update timestamp |

**Indexes**:
- `index_deck_collaborators_on_deck_id`
- `index_deck_collaborators_on_user_id`
- `index_deck_collaborators_on_deck_id_and_user_id` (unique)

**Foreign Keys**:
- `deck_id` → `decks(id)`
- `user_id` → `users(id)`

**Note**: Schema exists but not yet integrated into model layer or controllers

---

### Database Relationships Diagram

```
users ─────┬─────┐
           │     │
           ↓     ↓
    (owns) decks cards ←──── (belongs to)
           │     │
           ↓     ↓
    flashcards  card_progresses
           │     │
           ↓     ↓
       reviews   tags (via taggings)
```

### Key Database Features

#### Referential Integrity
- All foreign keys defined with `add_foreign_key`
- Cascading deletes on appropriate relationships:
  - Decks deleted → Flashcards deleted
  - Users deleted → Decks, CardProgresses, Reviews deleted
  - Cards deleted → CardProgresses, Reviews deleted

#### Indexing Strategy
- Primary keys (automatic)
- Foreign keys (all indexed for join performance)
- Unique constraints on natural keys (user email, tag name)
- Composite indexes for common queries:
  - `(user_id, card_id)` for card progress lookup
  - `(user_id, due_at)` for due cards query
  - `(tag_id, card_id)` for tagging uniqueness

#### Data Types
- **Integers**: IDs, counters, enums
- **Strings**: Short text (email, name, title)
- **Text**: Long content (descriptions, card text)
- **JSON**: Flexible metadata (card extras)
- **Decimals**: Precise calculations (ease_factor)
- **Booleans**: Flags (is_public, suspended)
- **Timestamps**: Automatic Rails timestamps (created_at, updated_at)

#### Enum Storage
Enums stored as integers for efficiency:
- `card_type`: 0=basic
- `state`: 0=fresh, 1=learning, 2=review, 3=relearning
- `rating`: 0=again, 1=hard, 2=good, 3=easy
- `role`: 0=viewer (not yet implemented)

### Database Technology
- **Development/Test**: SQLite 3 (>= 2.1)
- **Characteristics**:
  - Serverless, file-based
  - Zero configuration
  - Perfect for single-user desktop or small web apps
  - Schema stored in `db/schema.rb`
  - Migrations in `db/migrate/`

---

## 5. Application Architecture

### MVC Layers

#### Controllers
- **ApplicationController**: Base authentication and common behaviors
- **DecksController**: Deck CRUD + import/export
- **FlashcardsController**: Card creation within decks
- **LearningSessionsController**: Self-paced review sessions
- **QuizzesController**: Multiple-choice testing
- **ProgressController**: Analytics dashboard

#### Views
- ERB templates in `app/views/`
- Partials for reusable components:
  - `progress/_summary.html.erb`
  - `progress/_deck_breakdown.html.erb`
  - `progress/_activity_chart.html.erb`
- Layouts: `application.html.erb`
- Turbo-powered for SPA-like experience

#### Models
- ActiveRecord models in `app/models/`
- Business logic encapsulated in models
- Scopes for common queries
- Callbacks for automatic processing
- Enums for state management

### Technology Stack

- **Framework**: Ruby on Rails 8.0.3
- **Ruby Version**: Compatible with Rails 8.0
- **Database**: SQLite 3 (development), adaptable for production
- **Authentication**: Devise gem
- **Frontend**:
  - Importmap for JavaScript modules
  - Stimulus.js for interactions
  - Turbo Rails for fast navigation
  - Propshaft for assets
- **Testing**:
  - Minitest (Rails default)
  - Capybara for system tests
  - Selenium WebDriver
- **Web Server**: Puma
- **Background Jobs**: Solid Queue (Rails 8 default)
- **Caching**: Solid Cache (Rails 8 default)
- **WebSockets**: Solid Cable (Rails 8 default)
- **Code Quality**:
  - Brakeman (security scanning)
  - RuboCop (linting)
- **Deployment**: Docker (Dockerfile provided), Kamal for orchestration

---

## 6. Key Features Implementation

### Feature 1: Learning Sessions
- **Flow**: Start → Shuffle cards → Display front → Flip → Self-rate → Next card → Complete
- **Session Storage**: Rails session (cookie)
- **Ratings**: Unfamiliar, Still Learning, Mastered
- **Statistics**: Percentage breakdown on completion

### Feature 2: Quizzes
- **Flow**: Start → Shuffle cards → Multiple choice → Answer → Feedback → Next → Score
- **Answer Generation**: 1 correct + up to 3 random wrong answers
- **Progress Integration**: Updates CardProgress and creates Review records
- **Scoring**: Correct count and percentage

### Feature 3: Progress Analytics
- **Global Stats**: Total cards, due today, reviews today, accuracy, streak
- **Per-Deck Stats**: Cards, due, reviews, accuracy per deck
- **Activity Chart**: 14-day review frequency visualization
- **Streak Calculation**: Consecutive days with at least one review

### Feature 4: Spaced Repetition System
- **Algorithm**: Custom implementation based on SuperMemo principles
- **State Machine**: Fresh → Learning → Review → (if failed) → Relearning
- **Intervals**: Progressive (1, 6, exponential)
- **Ease Factor**: Dynamic adjustment based on performance

### Feature 5: Deck Import/Export
- **Format**: JSON
- **Export**: Full deck metadata + all flashcards
- **Import**: Parse JSON, validate, create deck and cards
- **Use Cases**: Sharing, backup, content reuse

---

## 7. Testing Strategy

### Test Types
- **Unit Tests**: Models (`test/models/`)
- **Controller Tests**: Request/response validation (`test/controllers/`)
- **System Tests**: End-to-end flows (not yet implemented)

### Test Coverage
- Model validations
- Model associations
- Controller authentication
- Controller actions
- Business logic (SRS algorithm, statistics)

### Fixtures
- `test/fixtures/*.yml` - Predefined test data
- Users, Decks, Cards, CardProgresses, Reviews

---

## 8. Security Features

### Authentication
- Devise gem with bcrypt password hashing
- Remember me functionality
- Session management
- CSRF protection (Rails default)

### Authorization
- `authenticate_user!` before all controller actions
- Scoped queries (`current_user.decks`)
- Prevents unauthorized access to other users' data

### Data Validation
- Model-level validations
- Controller input validation
- Enum constraints
- Foreign key constraints

### Security Scanning
- Brakeman gem for static analysis
- Regular dependency updates

---

## 9. Performance Considerations

### Database
- Indexes on foreign keys and frequently queried columns
- Composite indexes for multi-column queries
- Eager loading to avoid N+1 queries (potential improvement area)

### Session Storage
- Cookie-based sessions for learning (lightweight)
- No database writes during active study
- Final results persisted to Reviews table

### Caching
- Solid Cache configured (Rails 8)
- Fragment caching opportunities (not yet implemented)

### Asset Pipeline
- Propshaft for fast asset serving
- Importmap for JavaScript (no build step)
- Minimal JavaScript for performance

---

## 10. Future Enhancements

### Planned Features (based on code analysis)
1. **Tag System**: Database schema exists, UI not implemented
2. **Deck Collaboration**: Schema ready, feature not active
3. **Subdeck Navigation**: Model relationships exist, UI incomplete
4. **Enhanced Card Types**: Infrastructure for multiple types (currently only basic)
5. **Public Deck Sharing**: `is_public` flag ready, sharing UI missing

### Potential Improvements
1. **Mobile App**: API-first design enables mobile client
2. **Social Features**: Study groups, leaderboards
3. **Advanced Analytics**: Learning curves, predictions
4. **Content Marketplace**: Share/purchase pre-made decks
5. **Audio/Image Cards**: Rich media support
6. **Offline Support**: PWA with service workers
7. **AI-Powered**: Auto-generate cards from text, optimize SRS

---

## Conclusion

FlashFour is a well-architected, production-ready flashcard application that demonstrates solid software engineering principles:

- **Clean separation of concerns** with MVC pattern
- **Robust data model** with proper relationships and constraints
- **Scientific learning approach** with spaced repetition system
- **User-focused features** including multiple study modes and comprehensive analytics
- **Maintainable codebase** following Rails conventions and best practices
- **Scalable foundation** with room for future enhancements

The architecture supports the current feature set while remaining extensible for future growth, making it an excellent example of pragmatic software design.
