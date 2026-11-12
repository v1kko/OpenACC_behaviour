// Turns the .quiz-section blocks on quiz.md into a one-section-at-a-time quiz with a running score.
document$.subscribe(() => {
  const secs = [...document.querySelectorAll(".quiz-section")];
  if (!secs.length) return;
  // Highlight OpenACC directives (!$acc ...) in red; Pygments gives them the same .c class as plain comments.
  document.querySelectorAll(".quiz-section .highlight .c").forEach((c) => /^!\$acc/i.test(c.textContent) && (c.style.color = "red"));
  const nq = document.querySelectorAll(".quiz-q").length;
  const OPTS = { ok: "✅ OK", crash: "❌ Compile/runtime crash", wrong: "🟡 Wrong result" };
  const COMPILERS = { cray: "Cray Fortran 19.0.0", nv: "nvfortran 25.3-0" };
  const points = (guess, actual) => (guess === actual ? 1 : actual === "wrong" ? -3 : 0);
  const CLAUDE_SCORE = 17; // Claude's score on the full quiz, see claude_guesses.md
  let current = 0, score = 0, answered = 0;
  const history = []; // one table row per answered question, for the final screen

  const bar = document.createElement("p");
  bar.style.cssText = "position:sticky;top:3rem;z-index:1;background:var(--md-default-bg-color);padding:.5em 0;font-weight:bold";
  secs[0].before(bar);
  const end = document.createElement("div");
  end.hidden = true;
  secs.at(-1).after(end);

  const show = () => {
    secs.forEach((sec, i) => (sec.hidden = i !== current));
    secs[current]?.querySelector("input")?.focus({ preventScroll: true });
    bar.textContent = current < secs.length ? `Section ${current + 1} / ${secs.length} · Score: ${score}` : `Score: ${score}`;
  };

  const finish = () => {
    end.innerHTML = `<h2>Final score: ${score} / ${answered * 2}</h2>` +
      (answered < nq
        ? `<p>You answered ${answered} of ${nq} questions. Claude scored ${CLAUDE_SCORE} / ${nq * 2} on the full quiz.</p>`
        : `<p>Claude scored ${CLAUDE_SCORE} / ${nq * 2}: you did ${score > CLAUDE_SCORE ? "better than" : score < CLAUDE_SCORE ? "worse than" : "exactly as well as"} Claude.</p>`) +
      `<table><thead><tr><th>Case</th>${Object.values(COMPILERS).map((n) => `<th>${n}</th><th>Your guess</th>`).join("")}` +
      `<th>Expected according to spec</th><th>Points</th></tr></thead><tbody>${history.join("")}</tbody></table>`;
    const again = document.createElement("button");
    again.className = "md-button";
    again.textContent = "Restart quiz";
    again.onclick = () => location.reload();
    end.append(again);
    end.hidden = false;
    current = secs.length;
    show();
    window.scrollTo(0, 0);
  };

  secs.forEach((sec) => {
    // Section view: title + spec + questions, each with a guess form. One "Guess" grades the whole section.
    const sq = [...sec.querySelectorAll(".quiz-q")];
    const forms = sq.map((q) => {
      const answer = q.querySelector(".quiz-answer");
      answer.hidden = true;
      const form = document.createElement("form");
      for (const [c, name] of Object.entries(COMPILERS)) {
        const fs = document.createElement("fieldset");
        fs.innerHTML = `<legend><strong>${name}</strong></legend>` +
          Object.entries(OPTS).map(([v, l]) => `<label style="margin-right:1em"><input type="radio" name="${c}" value="${v}" required> ${l}</label>`).join("");
        form.append(fs);
      }
      answer.before(form);
      return form;
    });
    const guessBtn = document.createElement("button");
    guessBtn.className = "md-button md-button--primary quiz-guess";
    guessBtn.textContent = "Guess";
    const nav = document.createElement("p");
    nav.hidden = true;
    sec.append(guessBtn, nav);

    const next = document.createElement("button");
    next.className = "md-button md-button--primary quiz-next";
    next.textContent = sec === secs.at(-1) ? "See final score" : "Next section";
    nav.append(next);

    guessBtn.onclick = () => {
      const bad = forms.find((f) => !f.checkValidity());
      if (bad) return bad.reportValidity();
      sq.forEach((q, i) => {
        const form = forms[i];
        let row = "", total = 0;
        const lines = Object.entries(COMPILERS).map(([c, name]) => {
          const guess = form.elements[c].value, actual = q.dataset[c], p = points(guess, actual);
          score += p;
          total += p;
          row += `<td>${OPTS[actual]}</td><td>${guess === actual ? "✔" : "✘"} ${OPTS[guess]}</td>`;
          return `<li><strong>${name}</strong>: you guessed ${OPTS[guess]}, actual ${OPTS[actual]}: ` +
            `<strong>${guess === actual ? "correct" : "wrong"} (${p >= 0 ? "+" : ""}${p})</strong></li>`;
        });
        const title = q.querySelector("h3").cloneNode(true);
        title.querySelector(".headerlink")?.remove();
        history.push(`<tr><td>${title.innerHTML}</td>${row}<td>${q.dataset.spec}</td><td>${total}</td></tr>`);
        const summary = document.createElement("ul");
        summary.innerHTML = lines.join("");
        form.replaceWith(summary);
        // Compact results: only the question title and guessed-vs-actual list, no code or notes.
        [...q.children].forEach((el) => (el.tagName === "H3" || el === summary || (el.style.display = "none")));
      });
      [...sec.children].forEach((el) => (el.tagName === "H2" || el === nav || sq.includes(el) || (el.style.display = "none")));
      answered += sq.length;
      guessBtn.hidden = true;
      nav.hidden = false;
      show();
      next.focus({ preventScroll: true });
      window.scrollTo(0, 0);
    };
    next.onclick = () => {
      current++;
      if (current === secs.length) return finish();
      show();
      window.scrollTo(0, 0);
    };
    if (sec !== secs.at(-1)) {
      const quit = document.createElement("button");
      quit.className = "md-button";
      quit.style.marginLeft = ".5em";
      quit.textContent = "Go to final result";
      quit.onclick = finish;
      nav.append(quit);
    }
  });
  // Keyboard: Tab/arrows walk every radio on the page without checking it, Space checks, Enter checks + jumps on.
  document.addEventListener("keydown", (e) => {
    const sec = secs[current];
    // Leave other inputs (e.g. site search) and focused buttons to the browser.
    if (!sec || e.target.matches("button, textarea, input:not([type=radio])")) return;
    if (e.key === "Enter") {
      e.preventDefault();
      // On a radio: tick it and jump to the next compiler's first option; after the last one, focus Guess (Enter there grades).
      const fs = e.target.closest?.("fieldset");
      if (fs) {
        e.target.checked = true;
        const sets = [...sec.querySelectorAll("fieldset")];
        const nextSet = sets[sets.indexOf(fs) + 1];
        return (nextSet?.querySelector("input") ?? sec.querySelector(".quiz-guess")).focus();
      }
      const guessBtn = sec.querySelector(".quiz-guess");
      (guessBtn.hidden ? sec.querySelector(".quiz-next") : guessBtn).click();
      return;
    }
    const step = { Tab: e.shiftKey ? -1 : 1, ArrowRight: 1, ArrowDown: 1, ArrowLeft: -1, ArrowUp: -1 }[e.key];
    const radios = [...sec.querySelectorAll("input[type=radio]")];
    const i = radios.indexOf(document.activeElement);
    if (!step || i < 0) return;
    e.preventDefault();
    radios[(i + step + radios.length) % radios.length].focus();
  });
  show();
});
