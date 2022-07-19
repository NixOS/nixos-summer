window.addEventListener("DOMContentLoaded", () => {
  document.querySelector(".menu-toggle").addEventListener("click", () => {
    let nav = document.querySelector("body > header nav")
    if (nav.style.display === "none") {
      nav.style.display = ""
    } else {
      nav.style.display = "none"
    }
  }, false)
})
