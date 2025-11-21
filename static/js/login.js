document.addEventListener("DOMContentLoaded", () => {
  const usernameInput = document.getElementById("username");
  const passwordInput = document.getElementById("password");

  if (usernameInput) {
    usernameInput.focus();

    usernameInput.addEventListener("keydown", (event) => {
      if (event.key === "Enter" && passwordInput) {
        event.preventDefault();
        passwordInput.focus();
      }
    });
  }
});
