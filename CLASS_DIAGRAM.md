# FlashFour Class Diagram

## Core Class Relationships

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              User                                        │
│  ────────────────────────────────────────────────────────────────────  │
│  + email: string (unique)                                               │
│  + display_name: string                                                 │
│  + encrypted_password: string                                           │
│  + remember_created_at: datetime                                        │
│  ────────────────────────────────────────────────────────────────────  │
│  + update_streak(): void                                                │
│  + decks(): Deck[]                                                      │
│  + flashcards(): Flashcard[]                                            │
│  + card_progresses(): CardProgress[]                                    │
│  + reviews(): Review[]                                                  │
└─────────────────────────────────────────────────────────────────────────┘
        │                    │                    │                    │
        │ 1                  │ 1                  │ 1                  │ 1
        │ owns               │ tracks             │ tracks             │ creates
        │ many               │ many               │ many               │ many
        ▼                    ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────────┐  ┌─────────────────┐  ┌────────────┐
│    Deck      │    │   CardProgress   │  │     Review      │  │            │
└──────────────┘    └──────────────────┘  └─────────────────┘  │            │
        │                    ▲                    ▲              │            │
        │ 1                  │ many               │ many         │            │
        │ contains           │ per                │ per          │            │
        │ many               │ (user,card)        │ event        │            │
        ▼                    │                    │              │            │
┌──────────────────────────────────────────────────────────────────────────┐
│                            Flashcard                                      │
│  ──────────────────────────────────────────────────────────────────────  │
│  + front_text: text (required)                                           │
│  + back_text: text (required)                                            │
│  + card_type: enum (basic=0)                                             │
│  + extras: json                                                          │
│  + suspended: boolean                                                    │
│  + deck_id: integer (FK)                                                 │
│  ──────────────────────────────────────────────────────────────────────  │
│  + translate_front_text(): void [before_create]                          │
└──────────────────────────────────────────────────────────────────────────┘
        │                    │
        │ has                │ has
        │ many               │ many
        ▼                    ▼
┌──────────────────┐  ┌─────────────────┐
│  CardProgress    │  │     Review      │
└──────────────────┘  └─────────────────┘
```

## Detailed Class Diagrams

### User Model
```
┌─────────────────────────────────────────┐
│              User                        │
├─────────────────────────────────────────┤
│ Attributes:                             │
│  + id: integer [PK]                     │
│  + email: string [unique]               │
│  + display_name: string                 │
│  + encrypted_password: string           │
│  + remember_created_at: datetime        │
│  + created_at: datetime                 │
│  + updated_at: datetime                 │
├─────────────────────────────────────────┤
│ Methods:                                │
│  + update_streak(): void                │
├─────────────────────────────────────────┤
│ Associations:                           │
│  ○ has_many :decks (as owner)           │
│  ○ has_many :flashcards (through decks) │
│  ○ has_many :card_progresses            │
│  ○ has_many :reviews                    │
├─────────────────────────────────────────┤
│ Devise Modules:                         │
│  • database_authenticatable             │
│  • registerable                         │
│  • recoverable                          │
│  • rememberable                         │
│  • validatable                          │
└─────────────────────────────────────────┘
```

### Deck Model
```
┌─────────────────────────────────────────┐
│              Deck                        │
├─────────────────────────────────────────┤
│ Attributes:                             │
│  + id: integer [PK]                     │
│  + owner_id: integer [FK → users]       │
│  + title: string [required]             │
│  + description: text                    │
│  + is_public: boolean [default: false]  │
│  + parent_id: integer [FK → decks]      │
│  + created_at: datetime                 │
│  + updated_at: datetime                 │
├─────────────────────────────────────────┤
│ Associations:                           │
│  ○ belongs_to :owner (User)             │
│  ○ has_many :flashcards                 │
│  ○ has_many :subdecks (self-ref)        │
│  ○ belongs_to :parent (self-ref, opt)   │
└─────────────────────────────────────────┘
```

### Flashcard Model
```
┌─────────────────────────────────────────┐
│           Flashcard                      │
│        (table: cards)                    │
├─────────────────────────────────────────┤
│ Attributes:                             │
│  + id: integer [PK]                     │
│  + deck_id: integer [FK → decks]        │
│  + card_type: integer [enum]            │
│  + front_text: text [required]          │
│  + back_text: text [required]           │
│  + extras: json [default: {}]           │
│  + suspended: boolean [default: false]  │
│  + created_at: datetime                 │
│  + updated_at: datetime                 │
├─────────────────────────────────────────┤
│ Methods:                                │
│  - translate_front_text(): void         │
│    [before_create callback]             │
├─────────────────────────────────────────┤
│ Associations:                           │
│  ○ belongs_to :deck                     │
│  ○ has_many :card_progresses            │
│  ○ has_many :reviews                    │
├─────────────────────────────────────────┤
│ Validations:                            │
│  • validates :front_text, presence      │
│  • validates :back_text, presence       │
├─────────────────────────────────────────┤
│ Enums:                                  │
│  • card_type: { basic: 0 }              │
└─────────────────────────────────────────┘
```

### CardProgress Model (SRS Engine)
```
┌──────────────────────────────────────────────┐
│           CardProgress                       │
├──────────────────────────────────────────────┤
│ Attributes:                                  │
│  + id: integer [PK]                          │
│  + user_id: integer [FK → users]             │
│  + card_id: integer [FK → cards]             │
│  + repetitions: integer [default: 0]         │
│  + lapses: integer [default: 0]              │
│  + interval_days: integer [default: 0]       │
│  + ease_factor: decimal(5,2) [default: 2.5]  │
│  + due_at: datetime                          │
│  + state: integer [enum]                     │
│  + review_on: date                           │
│  + created_at: datetime                      │
│  + updated_at: datetime                      │
├──────────────────────────────────────────────┤
│ Methods:                                     │
│  + update_from_review(quality): void         │
│    [Implements SRS algorithm]                │
├──────────────────────────────────────────────┤
│ Scopes:                                      │
│  • due_now: where('review_on <= ?', today)   │
├──────────────────────────────────────────────┤
│ Associations:                                │
│  ○ belongs_to :user                          │
│  ○ belongs_to :card (Flashcard)              │
├──────────────────────────────────────────────┤
│ Validations:                                 │
│  • validates :ease_factor, >= 1.3            │
│  • validates :interval_days, >= 0            │
├──────────────────────────────────────────────┤
│ Enums:                                       │
│  • state: {                                  │
│      fresh: 0,                               │
│      learning: 1,                            │
│      review: 2,                              │
│      relearning: 3                           │
│    }                                         │
└──────────────────────────────────────────────┘
```

### Review Model (Analytics)
```
┌──────────────────────────────────────────────┐
│              Review                          │
├──────────────────────────────────────────────┤
│ Attributes:                                  │
│  + id: integer [PK]                          │
│  + user_id: integer [FK → users]             │
│  + card_id: integer [FK → cards]             │
│  + rating: integer [enum]                    │
│  + time_taken_ms: integer [default: 0]       │
│  + scheduled_interval_days: integer          │
│  + new_interval_days: integer                │
│  + new_ease_factor: decimal(5,2)             │
│  + reviewed_at: datetime                     │
│  + created_at: datetime                      │
│  + updated_at: datetime                      │
├──────────────────────────────────────────────┤
│ Associations:                                │
│  ○ belongs_to :user                          │
│  ○ belongs_to :card (Flashcard)              │
├──────────────────────────────────────────────┤
│ Validations:                                 │
│  • validates :time_taken_ms, >= 0            │
├──────────────────────────────────────────────┤
│ Enums:                                       │
│  • rating: {                                 │
│      again: 0,                               │
│      hard: 1,                                │
│      good: 2,                                │
│      easy: 3                                 │
│    }                                         │
└──────────────────────────────────────────────┘
```

## Controller Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ApplicationController                         │
│  ─────────────────────────────────────────────────────────────  │
│  + authenticate_user! (from Devise)                             │
│  + current_user                                                 │
└─────────────────────────────────────────────────────────────────┘
                              △
                              │ inherits
              ┌───────────────┼───────────────┬───────────────┐
              │               │               │               │
              │               │               │               │
┌─────────────┴──────┐  ┌────┴────────┐  ┌───┴──────────┐  ┌─┴────────────┐
│  DecksController   │  │  Flashcards │  │   Learning   │  │   Quizzes    │
│                    │  │  Controller │  │   Sessions   │  │  Controller  │
│                    │  │             │  │  Controller  │  │              │
│ + index            │  │ + new       │  │ + start      │  │ + start      │
│ + show             │  │ + create    │  │ + show       │  │ + show       │
│ + new              │  │             │  │ + rate       │  │ + answer     │
│ + create           │  │             │  │ + complete   │  │ + complete   │
│ + edit             │  │             │  │ + restart    │  │ + restart    │
│ + update           │  │             │  │              │  │              │
│ + destroy          │  │             │  │              │  │              │
│ + export           │  │             │  │              │  │              │
│ + import           │  │             │  │              │  │              │
└────────────────────┘  └─────────────┘  └──────────────┘  └──────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    ProgressController                            │
│  ─────────────────────────────────────────────────────────────  │
│  + index                                                        │
│  - compute_streak_for(user): integer                            │
│  - deck_stats_for(deck, user): hash                             │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagram: Learning Session

```
   User                Controller              Session Store         Model
    │                       │                       │                 │
    │   Click "Learn"       │                       │                 │
    ├──────────────────────>│                       │                 │
    │                       │  Fetch Cards          │                 │
    │                       ├───────────────────────────────────────>│
    │                       │<───────────────────────────────────────┤
    │                       │  Shuffle & Initialize │                 │
    │                       ├──────────────────────>│                 │
    │                       │                       │                 │
    │   Display Card        │                       │                 │
    │<──────────────────────┤                       │                 │
    │                       │                       │                 │
    │   Flip Card           │                       │                 │
    │   (JavaScript)        │                       │                 │
    │                       │                       │                 │
    │   Rate Card           │                       │                 │
    ├──────────────────────>│                       │                 │
    │                       │  Update Session       │                 │
    │                       ├──────────────────────>│                 │
    │                       │  Get Next Card        │                 │
    │                       ├──────────────────────>│                 │
    │                       │                       │                 │
    │   Display Next        │                       │                 │
    │<──────────────────────┤                       │                 │
    │                       │                       │                 │
    │   ... (repeat)        │                       │                 │
    │                       │                       │                 │
    │   Complete Session    │                       │                 │
    │<──────────────────────┤                       │                 │
    │                       │  Calculate Stats      │                 │
    │                       ├──────────────────────>│                 │
    │                       │                       │                 │
    │   Show Stats          │                       │                 │
    │<──────────────────────┤                       │                 │
    │                       │                       │                 │
```

## Data Flow Diagram: Quiz with SRS Update

```
   User                Controller              Session             Model Layer
    │                       │                     │                CardProgress/Review
    │   Start Quiz          │                     │                      │
    ├──────────────────────>│                     │                      │
    │                       │  Initialize         │                      │
    │                       ├────────────────────>│                      │
    │                       │                     │                      │
    │   Show Question       │                     │                      │
    │<──────────────────────┤                     │                      │
    │                       │                     │                      │
    │   Submit Answer       │                     │                      │
    ├──────────────────────>│                     │                      │
    │                       │  Check Answer       │                      │
    │                       ├────────────────────>│                      │
    │                       │                     │                      │
    │                       │  Update Progress    │                      │
    │                       ├──────────────────────────────────────────>│
    │                       │                     │  find_or_create     │
    │                       │                     │  update SRS params  │
    │                       │                     │  create Review      │
    │                       │<────────────────────────────────────────<│
    │                       │                     │                      │
    │   Show Feedback       │                     │                      │
    │<──────────────────────┤                     │                      │
    │                       │                     │                      │
```

## Inheritance Hierarchy

```
ActiveRecord::Base
      △
      │
ApplicationRecord (primary_abstract_class)
      △
      ├─────────────────┬──────────────┬──────────────┬──────────┐
      │                 │              │              │          │
    User              Deck        Flashcard    CardProgress   Review
```

## Design Pattern Summary

```
┌──────────────────────┬─────────────────────────────────────────┐
│    Pattern           │    Implementation                       │
├──────────────────────┼─────────────────────────────────────────┤
│ Active Record        │ All Models (User, Deck, etc.)           │
│ MVC                  │ Entire Application Architecture         │
│ Template Method      │ ApplicationRecord, ApplicationController│
│ Strategy             │ Learning vs Quiz Controllers            │
│ Facade               │ ProgressController                      │
│ Callback             │ before_create :translate_front_text     │
│ Dependency Injection │ current_user, session, params           │
│ Command              │ Session actions (rate, answer)          │
│ Repository (Scope)   │ CardProgress.due_now                    │
└──────────────────────┴─────────────────────────────────────────┘
```

## Database Entity-Relationship Diagram

```
┌─────────┐       ┌─────────┐       ┌──────────────┐       ┌──────────┐
│  User   │       │  Deck   │       │  Flashcard   │       │   Tag    │
│         │───┐   │         │───┐   │   (cards)    │───┐   │          │
└─────────┘   │   └─────────┘   │   └──────────────┘   │   └──────────┘
    │         │        │         │          │           │        │
    │ 1       │        │ 1       │          │ 1         │        │
    │ owns    │        │ contains│          │ has       │        │
    │ many    │        │ many    │          │ many      │        │
    ▼         │        ▼         │          ▼           │        │
┌─────────┐  │   ┌──────────────┐     ┌──────────┐    │   ┌──────────┐
│  Deck   │  │   │  Flashcard   │     │CardProg. │    │   │ Tagging  │
└─────────┘  │   │   (cards)    │     └──────────┘    │   └──────────┘
             │   └──────────────┘          │          │        │
             │        │                    │ belongs  │        │ links
             │        │ 1                  │ to       │        │ M:N
             │        │ belongs            │ 1        │        │
             │        │ to                 ▼          │        ▼
             │        ▼                ┌──────────┐   │   ┌──────────┐
             │   ┌─────────┐           │   User   │   └──>│   Tag    │
             │   │  Deck   │           └──────────┘       └──────────┘
             │   └─────────┘
             │        △
             │        │ parent/subdeck
             │        │ (self-ref)
             └────────┘

┌─────────┐       ┌──────────────┐
│  User   │       │  Flashcard   │
│         │───┐   │   (cards)    │───┐
└─────────┘   │   └──────────────┘   │
    │         │          │            │
    │ creates │          │ reviewed   │
    │ many    │          │ in many    │
    │         │          │            │
    ▼         │          ▼            │
┌─────────────┴──────────────────────┘
│           Review                    │
│  (analytics/history)                │
└─────────────────────────────────────┘
```

## State Machine: CardProgress States

```
                    ┌────────────┐
                    │   FRESH    │ (New card, never seen)
                    │  (state=0) │
                    └──────┬─────┘
                           │
                    First Review
                           │
                           ▼
                    ┌────────────┐
                 ┌─>│  LEARNING  │ (Currently learning)
                 │  │  (state=1) │
                 │  └──────┬─────┘
                 │         │
                 │   Correct Answer
                 │         │
                 │         ▼
    Wrong Answer │  ┌────────────┐
                 │  │   REVIEW   │ (Learned, periodic review)
                 │  │  (state=2) │
                 │  └──────┬─────┘
                 │         │
                 │   Wrong Answer
                 │         │
                 │         ▼
                 │  ┌────────────┐
                 └──│ RELEARNING │ (Forgotten, relearning)
                    │  (state=3) │
                    └────────────┘
                           │
                     Correct Answer
                           │
                           └──────> Back to REVIEW
```

## Technology Stack Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ─────────────────────────────────────────────────────────  │
│  • ERB Templates                                            │
│  • Stimulus.js (JavaScript interactions)                    │
│  • Turbo Rails (SPA-like navigation)                        │
│  • CSS (Custom styling)                                     │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                          │
│  ─────────────────────────────────────────────────────────  │
│  • Controllers (Request handling)                           │
│  • Routes (URL mapping)                                     │
│  • Authentication (Devise)                                  │
│  • Session Management                                       │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                      │
│  ─────────────────────────────────────────────────────────  │
│  • Models (Domain logic)                                    │
│  • SRS Algorithm (CardProgress)                             │
│  • Analytics (ProgressController helpers)                   │
│  • Validations                                              │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Data Access Layer                         │
│  ─────────────────────────────────────────────────────────  │
│  • Active Record (ORM)                                      │
│  • Database Queries                                         │
│  • Migrations                                               │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Database Layer                            │
│  ─────────────────────────────────────────────────────────  │
│  • SQLite 3 (Development)                                   │
│  • Schema Management                                        │
│  • Indexes & Constraints                                    │
└─────────────────────────────────────────────────────────────┘
```
