# CSS Refactoring Documentation

## Overview
This document describes the CSS refactoring performed to improve maintainability and performance by splitting the monolithic `application.css` into modular, section-specific CSS files.

## Before Refactoring
- **Single file**: `application.css` (136 lines)
- All styles for every section were loaded on every page
- Difficult to maintain and find specific styles
- No clear separation between global and section-specific styles

## After Refactoring

### File Structure
```
app/assets/stylesheets/
├── application.css      (75 lines) - Global styles + Header
├── authentication.css   (74 lines) - Login, registration, password reset
├── decks.css           (79 lines) - Deck management
└── flashcards.css      (10 lines) - Flashcard-specific styles
```

### CSS Files Description

#### 1. `application.css` (Global Styles)
**Always loaded on every page**
- Body styles (background, font-family, margins)
- Main content container styles
- Header navigation styles (logo, user nav, buttons)
- Used by: All pages

#### 2. `authentication.css`
**Loaded only on authentication pages**
- `.auth-container` styles for form containers
- Form field styles (labels, inputs)
- Submit button styles
- Link styles for "Sign up", "Forgot password", etc.
- Used by:
  - Login page (`/users/sign_in`)
  - Registration page (`/users/sign_up`)
  - Edit account page (`/users/edit`)
  - Password reset pages (`/users/password/*`)
  - Confirmation pages (`/users/confirmation/*`)
  - Unlock pages (`/users/unlock/*`)

#### 3. `decks.css`
**Loaded only on deck-related pages**
- `.center-card` styles for deck forms
- Form field styles specific to decks
- Button styles (`.button`, `.button.primary`)
- Used by:
  - Deck index page (`/decks`)
  - Deck show page (`/decks/:id`)
  - New deck page (`/decks/new`)
  - Edit deck page (`/decks/:id/edit`)

#### 4. `flashcards.css`
**Loaded only on flashcard pages**
- Additional textarea styles for flashcard content
- Extends styles from `decks.css`
- Used by:
  - New flashcard page (`/decks/:id/flashcards/new`)

## Implementation Details

### Per-Page CSS Loading
The refactoring uses Rails' `content_for` mechanism to load CSS files selectively:

**In the layout** (`app/views/layouts/application.html.erb`):
```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= yield :stylesheets %>
```

**In views** (e.g., `app/views/devise/sessions/new.html.erb`):
```erb
<% content_for :stylesheets do %>
  <%= stylesheet_link_tag "authentication", "data-turbo-track": "reload" %>
<% end %>
```

### Benefits
1. **Performance**: Pages only load the CSS they need
2. **Maintainability**: Easy to find and update section-specific styles
3. **Scalability**: Simple to add new section-specific CSS files
4. **Clear Separation**: Global vs. section-specific styles are clearly defined
5. **Cache Efficiency**: Changes to one section don't invalidate caches for other sections

### Architecture Pattern
```
Every Page Loads:
├── application.css (global + header)

Authentication Pages Also Load:
└── authentication.css

Deck Pages Also Load:
└── decks.css

Flashcard Pages Also Load:
├── decks.css (for form container)
└── flashcards.css (for additional flashcard styles)
```

## Testing Checklist
To verify the refactoring works correctly:

- [ ] Login page displays correctly with authentication styles
- [ ] Registration page displays correctly with authentication styles
- [ ] Password reset pages display correctly
- [ ] Deck index page displays correctly
- [ ] Deck creation form displays correctly with `.center-card` styles
- [ ] Flashcard creation form displays correctly
- [ ] Header appears correctly on all pages
- [ ] Global body styles apply to all pages

## Migration Guide
If you need to add new section-specific styles:

1. Create a new CSS file in `app/assets/stylesheets/` (e.g., `reviews.css`)
2. Add the styles to that file
3. In the relevant views, add:
   ```erb
   <% content_for :stylesheets do %>
     <%= stylesheet_link_tag "reviews", "data-turbo-track": "reload" %>
   <% end %>
   ```

## Notes
- This refactoring is compatible with Propshaft (Rails 8 asset pipeline)
- No build step required - CSS files are served directly
- Turbo tracking ensures proper cache invalidation
- CSS files are small enough that the performance gain is minimal, but the maintainability improvement is significant

## Additional Improvements Made
- Added missing `.center-card` styles for deck and flashcard forms
- Fixed missing closing `</div>` tags in authentication views
- Ensured consistent structure across all Devise views
