(function () {
  "use strict";

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
