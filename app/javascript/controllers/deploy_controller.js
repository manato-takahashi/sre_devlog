import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  launch(event) {
    // +1 を表示して浮き上がらせる
    const plusOne = document.createElement("span")
    plusOne.textContent = "+1"
    plusOne.classList.add("deploy-plus-one")

    // ボタンの位置に追加
    const button = event.currentTarget
    button.appendChild(plusOne)

    // アニメーション後に削除
    setTimeout(() => plusOne.remove(), 1000)

    // ボタンを一瞬光らせる
    button.classList.add("active")
    setTimeout(() => button.classList.remove("active"), 200)
  }
}
