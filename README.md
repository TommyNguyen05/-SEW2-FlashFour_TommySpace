# FlashFour - Flashcard Learning Application

A modern, web-based flashcard learning application built with Ruby on Rails that helps users master new information through scientifically-proven spaced repetition.

## 📚 Project Documentation

**For comprehensive project architecture and design information, see:**

- **[PROJECT_ARCHITECTURE_DOCUMENTATION.md](PROJECT_ARCHITECTURE_DOCUMENTATION.md)** - Complete technical documentation
  - Detailed class descriptions with all attributes and methods
  - Design pattern explanations with code examples
  - Design decision rationale
  - Complete database schema
  - Implementation details and future enhancements

- **[CLASS_DIAGRAM.md](CLASS_DIAGRAM.md)** - Visual diagrams and architecture charts
  - ASCII art class diagrams
  - Entity-relationship diagrams
  - Data flow diagrams
  - State machine diagrams
  - Technology stack visualization

- **[PRESENTATION_SUMMARY.md](PRESENTATION_SUMMARY.md)** - Quick reference for presentations
  - Executive summary
  - Key talking points
  - Quick facts and metrics
  - Visual aids summary

## ✨ Features

- **Deck Management**: Create, organize, import, and export flashcard decks
- **Learning Sessions**: Self-paced review with flip cards and self-assessment
- **Quiz Mode**: Active recall testing with multiple-choice questions
- **Spaced Repetition System (SRS)**: Custom algorithm for optimal learning retention
- **Progress Analytics**: Comprehensive tracking with streaks, accuracy, and activity charts
- **User Authentication**: Secure account management with Devise

## 🚀 Getting Started

### Prerequisites

- Ruby 3.x or higher
- Rails 8.0.3
- SQLite 3

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd -SEW2-FlashFour_TommySpace
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   bin/rails db:migrate
   ```

4. Start the application server:
   ```bash
   bin/rails server
   ```

5. Access the application at: http://localhost:3000

## 🛠️ Technology Stack

- **Framework**: Ruby on Rails 8.0.3
- **Database**: SQLite 3
- **Authentication**: Devise gem
- **Frontend**: Stimulus.js, Turbo Rails, ERB templates
- **Testing**: Minitest, Capybara, Selenium
- **Web Server**: Puma

## 🏗️ Architecture Overview

FlashFour follows the Model-View-Controller (MVC) architecture pattern with:

- **5 Core Models**: User, Deck, Flashcard, CardProgress, Review
- **5 Controllers**: Decks, Flashcards, Learning Sessions, Quizzes, Progress
- **8 Database Tables**: Comprehensive schema with proper relationships
- **10+ Design Patterns**: Including Active Record, Strategy, Facade, and more

See [PROJECT_ARCHITECTURE_DOCUMENTATION.md](PROJECT_ARCHITECTURE_DOCUMENTATION.md) for detailed information.

## 📖 Key Concepts

### Spaced Repetition System (SRS)

FlashFour implements a custom SRS algorithm that:
- Adjusts review intervals based on performance
- Tracks card states (fresh → learning → review → relearning)
- Uses dynamic ease factors for personalized learning
- Schedules reviews at optimal times for retention

### Study Modes

1. **Learning Sessions**: Self-directed review with flip cards and three-level ratings
2. **Quizzes**: Active recall with multiple-choice questions and automatic scoring

### Analytics

Track your progress with:
- Overall statistics (total cards, due today, accuracy)
- Per-deck breakdowns
- Daily streak tracking
- 14-day activity charts

## 🧪 Testing

Run the test suite:
```bash
bin/rails test
```

Run specific tests:
```bash
bin/rails test test/models/
bin/rails test test/controllers/
```

## 🔒 Security

- Devise authentication with bcrypt password hashing
- Authorization guards on all actions
- Scoped queries to prevent unauthorized data access
- Input validation at model and controller levels
- Brakeman security scanning

## 📝 Development Notes

### About Devise

FlashFour uses the Devise gem for user authentication. Devise automatically provides:
- User registration (sign-up forms)
- User login (sign-in forms)
- User logout
- "Forgot my password" functionality
- Password encryption and security

This eliminates the need to build authentication from scratch.

## 🤝 Contributing

This is a coursework project for software engineering.

## 📄 License

This project is part of academic coursework.

## 👥 Authors

- Tommy Nguyen - Project Lead
- Course: SEW2

## 🔗 Additional Resources

- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [Devise Documentation](https://github.com/heartcombo/devise)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Turbo Rails](https://turbo.hotwired.dev/)