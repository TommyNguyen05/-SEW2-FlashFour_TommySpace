import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    // Bind the outside click listener
    this.outsideClickListener = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    // Clean up event listener
    document.removeEventListener("click", this.outsideClickListener)
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.menuTarget.classList.contains("show")
    
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("show")
    this.toggleTarget.classList.add("active")
    document.addEventListener("click", this.outsideClickListener)
  }

  close() {
    this.menuTarget.classList.remove("show")
    this.toggleTarget.classList.remove("active")
    document.removeEventListener("click", this.outsideClickListener)
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
