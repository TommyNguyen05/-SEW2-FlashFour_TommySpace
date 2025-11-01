import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "front", "back", "flipButton", "difficultyButtons"]

  flip() {
    // Toggle the flipped state
    this.cardTarget.classList.toggle("flipped")
    
    // Show/hide front and back
    if (this.cardTarget.classList.contains("flipped")) {
      // Show back, hide front
      this.frontTarget.style.display = "none"
      this.backTarget.style.display = "flex"
      
      // Hide flip button and show difficulty buttons
      this.flipButtonTarget.style.display = "none"
      this.difficultyButtonsTarget.style.display = "flex"
    } else {
      // Show front, hide back
      this.frontTarget.style.display = "flex"
      this.backTarget.style.display = "none"
      
      // Show flip button and hide difficulty buttons
      this.flipButtonTarget.style.display = "block"
      this.difficultyButtonsTarget.style.display = "none"
    }
  }
}
