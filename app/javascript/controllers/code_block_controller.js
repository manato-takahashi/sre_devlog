import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // 処理済みならスキップ（無限ループ防止）
    if (this.element.dataset.processed === "true") return
    this.element.dataset.processed = "true"

    this.wrapCodeBlock()
    this.addCopyButton()
  }

  wrapCodeBlock() {
    if (this.element.dataset.terminal !== "true") return

    const wrapper = document.createElement("div")
    wrapper.className = "terminal-block"

    const header = document.createElement("div")
    header.className = "terminal-header"
    header.innerHTML = `<span class="terminal-prompt">~/project &gt;</span>`

    this.element.parentNode.insertBefore(wrapper, this.element)
    wrapper.appendChild(header)
    wrapper.appendChild(this.element)
    this.element.classList.add("terminal-pre")
  }

  addCopyButton() {
    const button = document.createElement("button")
    button.className = "code-copy-btn"
    button.innerHTML = this.copyIcon
    button.setAttribute("aria-label", "コードをコピー")
    button.addEventListener("click", () => this.copy(button))

    if (this.element.dataset.terminal === "true") {
      this.element.previousElementSibling.appendChild(button)
    } else {
      const wrapper = document.createElement("div")
      wrapper.className = "code-block-wrapper"
      this.element.parentNode.insertBefore(wrapper, this.element)
      wrapper.appendChild(this.element)
      wrapper.appendChild(button)
    }
  }

  async copy(button) {
    const code = this.element.querySelector("code")
    const text = code ? code.textContent : this.element.textContent

    try {
      await navigator.clipboard.writeText(text)
      button.innerHTML = this.checkIcon
      button.classList.add("copied")
      setTimeout(() => {
        button.innerHTML = this.copyIcon
        button.classList.remove("copied")
      }, 2000)
    } catch (err) {
      console.error("Failed to copy:", err)
    }
  }

  get copyIcon() {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>`
  }

  get checkIcon() {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>`
  }
}
