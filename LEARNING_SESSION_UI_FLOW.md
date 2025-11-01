# Learning Session Feature - UI Flow

This document provides a visual text representation of the Learning Session feature UI.

## 1. Deck Show Page (with Learn Button)

```
┌─────────────────────────────────────────────────────────────┐
│ FlashFour                          Hello, User One | Log out │
└─────────────────────────────────────────────────────────────┘

    ┌───────────────────────────────────────────────────────┐
    │                                                       │
    │  Spanish Vocabulary                                   │
    │  Learn basic Spanish words                            │
    │                                                       │
    │  [Learn]  [Add card]  [Back to decks]                │
    │                                                       │
    │  Cards                                                │
    │  • Front: Hello — Back: Hola                         │
    │  • Front: Goodbye — Back: Adiós                      │
    │                                                       │
    └───────────────────────────────────────────────────────┘
```

## 2. Learning Session - Card Front

```
┌─────────────────────────────────────────────────────────────┐
│ FlashFour                          Hello, User One | Log out │
└─────────────────────────────────────────────────────────────┘

    ┌───────────────────────────────────────────────────────┐
    │                                                       │
    │  ← Back to Deck overview       Cards remaining: 5 / 5│
    │                                                       │
    │  ┌─────────────────────────────────────────────────┐ │
    │  │                                                 │ │
    │  │                   FRONT                         │ │
    │  │                                                 │ │
    │  │                   Hello                         │ │
    │  │                                                 │ │
    │  │                                                 │ │
    │  └─────────────────────────────────────────────────┘ │
    │                                                       │
    │                  [Flip Card]                          │
    │                                                       │
    └───────────────────────────────────────────────────────┘
```

## 3. Learning Session - Card Back (After Flip)

```
┌─────────────────────────────────────────────────────────────┐
│ FlashFour                          Hello, User One | Log out │
└─────────────────────────────────────────────────────────────┘

    ┌───────────────────────────────────────────────────────┐
    │                                                       │
    │  ← Back to Deck overview       Cards remaining: 5 / 5│
    │                                                       │
    │  ┌─────────────────────────────────────────────────┐ │
    │  │                                                 │ │
    │  │                   BACK                          │ │
    │  │                                                 │ │
    │  │                   Hola                          │ │
    │  │                                                 │ │
    │  │                                                 │ │
    │  └─────────────────────────────────────────────────┘ │
    │                                                       │
    │     [Unfamiliar] [Still Learning] [Mastered]         │
    │         (red)         (yellow)       (green)         │
    │                                                       │
    └───────────────────────────────────────────────────────┘
```

## 4. Completion Screen

```
┌─────────────────────────────────────────────────────────────┐
│ FlashFour                          Hello, User One | Log out │
└─────────────────────────────────────────────────────────────┘

    ┌───────────────────────────────────────────────────────┐
    │                                                       │
    │         Learning Completed! 🎉                        │
    │                                                       │
    │         Session Statistics                            │
    │                                                       │
    │  ████████████████████████████░░░░░░░░ Mastered: 60%  │
    │                                                       │
    │  ███████████░░░░░░░░░░░░░░░░░░░░ Still Learning: 20% │
    │                                                       │
    │  ██████░░░░░░░░░░░░░░░░░░░░░░░░░░░ Unfamiliar: 20%  │
    │                                                       │
    │  ┌─────────────────────────────────────────────────┐ │
    │  │ Total cards reviewed: 5                         │ │
    │  │ Mastered: 3 (60%)                               │ │
    │  │ Still Learning: 1 (20%)                         │ │
    │  │ Unfamiliar: 1 (20%)                             │ │
    │  └─────────────────────────────────────────────────┘ │
    │                                                       │
    │         [Learn again?]  [Back to Deck]               │
    │                                                       │
    └───────────────────────────────────────────────────────┘
```

## UI Features

### Colors
- **Mastered**: Green (#28a745)
- **Still Learning**: Yellow/Amber (#ffc107)
- **Unfamiliar**: Red (#dc3545)
- **Primary Button**: Blue (#007bff)
- **Card Background**: White (#ffffff)
- **Page Background**: Light Gray (#f7f7f7)

### Animations
- **Card Flip**: 0.3s ease transition with rotateY transform
- **Stat Bars**: 0.5s ease width transition for smooth animation
- **Hover Effects**: Button color transitions on hover

### Typography
- **Headings**: Sans-serif, bold
- **Card Content**: 1.5rem, centered
- **Labels**: 0.9rem, uppercase, gray

### Layout
- **Max Width**: 800px (learning view), 700px (completion view)
- **Card Height**: Minimum 400px
- **Responsive**: Centered on page, works on all screen sizes

## Interaction Flow

1. **Click "Learn"** → Start session with shuffled cards
2. **View Front** → Read the question/term
3. **Click "Flip Card"** → See the answer
4. **Click Rating** → Submit difficulty and move to next card
5. **Complete All Cards** → View statistics
6. **Click "Learn again?"** → Restart with newly shuffled cards
7. **Click "Back to Deck"** → Return to deck overview

## Responsive Behavior

- Cards maintain centered layout on all screen sizes
- Buttons stack vertically on smaller screens
- Text scales appropriately
- Touch-friendly button sizes for mobile devices

## Accessibility

- Semantic HTML structure
- Clear button labels
- Color-coded with text labels (not color-only)
- Keyboard navigation support via standard form controls
- Proper heading hierarchy
