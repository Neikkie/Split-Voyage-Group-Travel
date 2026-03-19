const form = document.getElementById("signupForm");
const emailInput = document.getElementById("email");
const message = document.getElementById("message");

form.addEventListener("submit", function (e) {
  e.preventDefault();

  const email = emailInput.value.trim();

  if (email === "") {
    message.textContent = "Please enter your email.";
    return;
  }

  message.textContent = `Thanks! ${email} has been added to Travel Buddy updates.`;
  form.reset();
});
