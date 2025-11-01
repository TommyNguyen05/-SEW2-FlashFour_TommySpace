# Progress Analytics Feature

This document describes the progress analytics feature that was merged from the Loay_database repository.

## Overview

The progress analytics feature provides users with detailed insights into their learning progress, including:
- Overall statistics (total cards, cards reviewed today, cards due now, accuracy, streak)
- Per-deck breakdown of statistics
- Visual activity chart showing review activity over the last 14 days

## Components Added

### Models

1. **CardProgress** (`app/models/card_progress.rb`)
   - Tracks a user's progress on individual flashcards
   - Includes spaced repetition system (SRS) data: ease_factor, interval_days, repetitions, lapses
   - Has states: new, learning, review, relearning
   - Includes `due_now` scope for finding cards that need review

2. **Review** (`app/models/review.rb`)
   - Records individual review sessions for cards
   - Tracks rating (again, hard, good, easy), time taken, and scheduling information
   - Links user and card for analytics purposes

### Controllers

1. **ProgressController** (`app/controllers/progress_controller.rb`)
   - `index` action displays all analytics
   - Calculates:
     - Total cards being studied
     - Cards due now
     - Reviews completed today
     - Accuracy percentage (last 30 days)
     - Current streak (consecutive days with reviews)
     - Per-deck statistics
     - 14-day review activity chart

### Views

1. **Progress Index** (`app/views/progress/index.html.erb`)
   - Main analytics page that renders all sections

2. **Summary Partial** (`app/views/progress/_summary.html.erb`)
   - Displays overview cards with key statistics

3. **Deck Breakdown Partial** (`app/views/progress/_deck_breakdown.html.erb`)
   - Shows a table with statistics for each deck

4. **Activity Chart Partial** (`app/views/progress/_activity_chart.html.erb`)
   - Displays a bar chart of review activity over the last 14 days

### Styling

**Progress CSS** (`app/assets/stylesheets/progress.css`)
- Responsive design for analytics page
- Card-based layout for statistics
- Table styling for deck breakdown
- Bar chart visualization for activity
- Mobile-friendly responsive breakpoints

### Routes

Added route: `GET /progress` -> `progress#index`

### Tests

1. **ProgressControllerTest** (`test/controllers/progress_controller_test.rb`)
   - Tests for authentication requirements
   - Tests for rendering all analytics sections
   - Tests for displaying overview statistics

2. **CardProgressTest** (`test/models/card_progress_test.rb`)
   - Tests for associations
   - Tests for validations
   - Tests for `due_now` scope

3. **ReviewTest** (`test/models/review_test.rb`)
   - Tests for associations
   - Tests for enum rating
   - Tests for validations

### Fixtures

- `test/fixtures/card_progresses.yml` - Sample card progress data
- `test/fixtures/reviews.yml` - Sample review data

## Database Schema

The following tables are already present in the database (from existing migrations):

- `card_progresses` - Stores user progress for each card
- `reviews` - Stores individual review events

## Navigation

A "Progress" link has been added to the main navigation header for authenticated users.

## Usage

1. Users can access the progress analytics by clicking "Progress" in the navigation
2. The page shows an overview of their learning statistics
3. Per-deck breakdowns help identify which decks need more attention
4. The activity chart visualizes daily study habits

## Key Differences from Loay_database

1. Authentication: Uses Devise instead of has_secure_password
2. Model naming: Uses `Flashcard` instead of `Card` (with table alias)
3. Associations: Adapted to work with existing Ezra models
4. Deck scope: Simplified to only show user's own decks (no collaborators in Ezra)
5. Styling: Matched existing Ezra UI patterns

## Future Enhancements

Potential improvements could include:
- Adding review functionality to actually create Review records during learning sessions
- Implementing the SRS algorithm to update CardProgress records
- Adding date filters for custom time ranges
- Exporting analytics data
- Comparing progress across different time periods
