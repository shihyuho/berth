(function () {
  "use strict";

  var root = document.documentElement;
  var themeMedia = window.matchMedia("(prefers-color-scheme: dark)");
  var themeButtons = document.querySelectorAll("[data-theme-option]");
  var themeChoice = "system";

  try {
    var savedTheme = localStorage.getItem("berth-theme");
    if (savedTheme === "light" || savedTheme === "dark" || savedTheme === "system") {
      themeChoice = savedTheme;
    }
  } catch (error) {}

  function updateThemeColor() {
    var meta = document.querySelector('meta[name="theme-color"]');
    if (!meta) return;
    var dark = themeChoice === "dark" || (themeChoice === "system" && themeMedia.matches);
    meta.setAttribute("content", dark ? "#0c1217" : "#f5f8fa");
  }

  function applyTheme(choice, persist) {
    themeChoice = choice;
    if (choice === "light" || choice === "dark") {
      root.setAttribute("data-theme", choice);
    } else {
      root.removeAttribute("data-theme");
    }

    themeButtons.forEach(function (button) {
      button.setAttribute("aria-pressed", String(button.getAttribute("data-theme-option") === choice));
    });
    updateThemeColor();

    if (persist) {
      try { localStorage.setItem("berth-theme", choice); } catch (error) {}
    }
  }

  themeButtons.forEach(function (button) {
    button.addEventListener("click", function () {
      applyTheme(button.getAttribute("data-theme-option"), true);
    });
  });

  themeMedia.addEventListener("change", function () {
    if (themeChoice === "system") updateThemeColor();
  });

  applyTheme(themeChoice, false);

  document.querySelectorAll("[data-demo]").forEach(function (demo) {
    var displays = demo.querySelectorAll("[data-display]");
    var buttons = demo.querySelectorAll("[data-select]");

    buttons.forEach(function (button) {
      button.addEventListener("click", function () {
        var target = button.getAttribute("data-select");
        displays.forEach(function (display) {
          display.classList.toggle("selected", display.getAttribute("data-display") === target);
        });
        buttons.forEach(function (candidate) {
          candidate.setAttribute("aria-pressed", String(candidate === button));
        });
      });
    });
  });

  document.querySelectorAll("[data-copy]").forEach(function (button) {
    button.addEventListener("click", function () {
      var code = button.closest(".command-block").querySelector("code");
      var original = button.textContent;
      var copied = button.getAttribute("data-copied") || "Copied";
      navigator.clipboard.writeText(code.textContent).then(function () {
        button.textContent = copied;
        window.setTimeout(function () { button.textContent = original; }, 1400);
      });
    });
  });
})();
