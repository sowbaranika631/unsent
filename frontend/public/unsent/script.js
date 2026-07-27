const API_URL = "http://localhost:5000/letter";
const placeholders = [
  "someone you lost",
  "someone who hurt you",
  "someone you never stopped loving",
  "the version of yourself you miss",
  "someone you never forgave",
  "yourself",
  "no one in particular",
];

const sceneEnvelope = document.getElementById("scene-envelope");
const sceneLetter = document.getElementById("scene-letter");
const sceneWitness = document.getElementById("scene-witness");
const letterEmerge = document.getElementById("letterEmerge");
const appLogo = document.getElementById("appLogo");

const recipient = document.getElementById("recipient");
const letterBody = document.getElementById("letterBody");
const sealBtn = document.getElementById("sealBtn");
const letterDate = null;
const letterSheet = document.querySelector(".letter-sheet");
const waxSealHeart = document.getElementById("waxSealHeart");
const ropeScrollbar = document.getElementById("ropeScrollbar");
const textareaRope = document.getElementById("textareaRope");

const listening = document.getElementById("listening");
const witnessText = document.getElementById("witnessText");
const witnessAfter = document.getElementById("witnessAfter");
const dissolveLine = document.getElementById("dissolveLine");
const noCopyLine = document.getElementById("noCopyLine");
const writeAgainBtn = document.getElementById("writeAgainBtn");

let phIndex = 0;
let placeholderTimer = null;
let isDragging = false;
let startY = 0;
let startScrollTop = 0;
let isTextareaDragging = false;
let textareaStartY = 0;
let textareaStartScrollTop = 0;

function updateRopePosition() {
  if (!letterSheet || !ropeScrollbar) return;
  const maxScroll = letterSheet.scrollHeight - letterSheet.clientHeight;
  const scrollPercent = maxScroll > 0 ? letterSheet.scrollTop / maxScroll : 0;
  const maxRopeMove = letterSheet.clientHeight - ropeScrollbar.offsetHeight;
  ropeScrollbar.style.top = `${scrollPercent * maxRopeMove}px`;
}

function updateTextareaRopePosition() {
  if (!letterBody || !textareaRope) return;
  const maxScroll = letterBody.scrollHeight - letterBody.clientHeight;
  const scrollPercent = maxScroll > 0 ? letterBody.scrollTop / maxScroll : 0;
  const maxRopeMove = letterBody.clientHeight - textareaRope.offsetHeight;
  textareaRope.style.top = `${scrollPercent * maxRopeMove}px`;
}

function initRopeScrollbar() {
  if (!letterSheet || !ropeScrollbar) return;

  const visibleRatio = letterSheet.clientHeight / letterSheet.scrollHeight;
  const ropeHeight = Math.max(
    60,
    Math.min(
      letterSheet.clientHeight - 20,
      visibleRatio * letterSheet.clientHeight,
    ),
  );
  ropeScrollbar.style.height = `${ropeHeight}px`;

  updateRopePosition();

  ropeScrollbar.addEventListener("mousedown", (e) => {
    e.preventDefault();
    isDragging = true;
    startY = e.clientY;
    startScrollTop = letterSheet.scrollTop;
    ropeScrollbar.style.cursor = "grabbing";
  });

  window.addEventListener("mousemove", (e) => {
    if (!isDragging) return;
    const deltaY = e.clientY - startY;
    const maxScroll = letterSheet.scrollHeight - letterSheet.clientHeight;
    const scrollRatio =
      deltaY / (letterSheet.clientHeight - ropeScrollbar.offsetHeight);
    const newScrollTop = startScrollTop + scrollRatio * maxScroll;
    letterSheet.scrollTop = Math.max(0, Math.min(maxScroll, newScrollTop));
    updateRopePosition();
  });

  window.addEventListener("mouseup", () => {
    isDragging = false;
    ropeScrollbar.style.cursor = "grab";
  });

  letterSheet.addEventListener("scroll", updateRopePosition);
}

function initTextareaRopeScrollbar() {
  if (!letterBody || !textareaRope) return;

  const visibleRatio = letterBody.clientHeight / letterBody.scrollHeight;
  const ropeHeight = Math.max(
    60,
    Math.min(
      letterBody.clientHeight - 20,
      visibleRatio * letterBody.clientHeight,
    ),
  );
  textareaRope.style.height = `${ropeHeight}px`;

  updateTextareaRopePosition();

  textareaRope.addEventListener("mousedown", (e) => {
    e.preventDefault();
    isTextareaDragging = true;
    textareaStartY = e.clientY;
    textareaStartScrollTop = letterBody.scrollTop;
    textareaRope.style.cursor = "grabbing";
  });

  window.addEventListener("mousemove", (e) => {
    if (!isTextareaDragging) return;
    const deltaY = e.clientY - textareaStartY;
    const maxScroll = letterBody.scrollHeight - letterBody.clientHeight;
    const scrollRatio =
      deltaY / (letterBody.clientHeight - textareaRope.offsetHeight);
    const newScrollTop = textareaStartScrollTop + scrollRatio * maxScroll;
    letterBody.scrollTop = Math.max(0, Math.min(maxScroll, newScrollTop));
    updateTextareaRopePosition();
  });

  window.addEventListener("mouseup", () => {
    isTextareaDragging = false;
    textareaRope.style.cursor = "grab";
  });

  letterBody.addEventListener("scroll", updateTextareaRopePosition);
}

function runPlaceholderCycle() {
  const word = placeholders[phIndex];
  let charIndex = 0;
  let deleting = false;

  function tick() {
    if (recipient.value !== "") {
      recipient.placeholder = "";
      return;
    }

    if (!deleting) {
      charIndex++;
      recipient.placeholder = word.slice(0, charIndex);
      if (charIndex === word.length) {
        placeholderTimer = setTimeout(() => {
          deleting = true;
          tick();
        }, 1400);
        return;
      }
      placeholderTimer = setTimeout(tick, 65);
    } else {
      charIndex--;
      recipient.placeholder = word.slice(0, charIndex);
      if (charIndex === 0) {
        phIndex = (phIndex + 1) % placeholders.length;
        placeholderTimer = setTimeout(runPlaceholderCycle, 400);
        return;
      }
      placeholderTimer = setTimeout(tick, 35);
    }
  }
  tick();
}
runPlaceholderCycle();

recipient.addEventListener("focus", () => {
  clearTimeout(placeholderTimer);
  recipient.placeholder = "";
});
recipient.addEventListener("blur", () => {
  if (recipient.value === "") {
    runPlaceholderCycle();
  }
});

function addHeartBulge(e) {
  e.stopPropagation();
  waxSealHeart.classList.add("bulge-effect");
  setTimeout(() => {
    waxSealHeart.classList.remove("bulge-effect");
  }, 420);

  if (
    !sceneEnvelope.classList.contains("opening") &&
    !sceneEnvelope.classList.contains("hidden")
  ) {
    setTimeout(() => {
      if (
        !sceneEnvelope.classList.contains("opening") &&
        !sceneEnvelope.classList.contains("hidden")
      ) {
        openEnvelope();
      }
    }, 150);
  }
}

waxSealHeart.addEventListener("click", addHeartBulge);

function openEnvelope() {
  if (sceneEnvelope.classList.contains("opening")) return;

  sceneEnvelope.classList.add("opening");
  appLogo.classList.add("hidden-logo");

  const rect = sceneEnvelope
    .querySelector(".envelope-wrap")
    .getBoundingClientRect();
  letterEmerge.style.left = rect.left + rect.width / 2 + "px";
  letterEmerge.style.top = rect.top + rect.height / 2 + "px";
  letterEmerge.style.opacity = "1";

  setTimeout(() => {
    letterEmerge.style.left = "50%";
    letterEmerge.style.top = "50%";
    letterEmerge.classList.add("unfolding-h");
  }, 350);

  setTimeout(() => {
    letterEmerge.classList.add("rise");
  }, 1050);

  setTimeout(() => {
    sceneEnvelope.classList.add("hidden");
    sceneLetter.classList.remove("hidden");
    letterEmerge.style.opacity = "0";
    setTimeout(() => {
      initRopeScrollbar();
      initTextareaRopeScrollbar();
    }, 100);
    letterBody.focus();
  }, 1950);
}

sceneEnvelope.addEventListener("click", (e) => {
  if (waxSealHeart.contains(e.target)) return;
  if (!sceneEnvelope.classList.contains("opening")) {
    openEnvelope();
  }
});

sceneEnvelope.addEventListener("keydown", (e) => {
  if (
    (e.key === "Enter" || e.key === " ") &&
    !sceneEnvelope.classList.contains("opening")
  ) {
    e.preventDefault();
    openEnvelope();
  }
});

let salutationInserted = false;
recipient.addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    e.preventDefault();
    const name = recipient.value.trim();
    if (name && !salutationInserted && letterBody.value.trim() === "") {
      letterBody.value = `Dear ${name},\n\n`;
      salutationInserted = true;
    }
    letterBody.focus();
    letterBody.setSelectionRange(
      letterBody.value.length,
      letterBody.value.length,
    );
    setTimeout(() => updateTextareaRopePosition(), 10);
  }
});

letterBody.addEventListener("input", () => {
  setTimeout(() => updateTextareaRopePosition(), 10);
});

function typewrite(text, el, speed = 32) {
  return new Promise((resolve) => {
    el.innerHTML = '<span class="cursor"></span>';
    let i = 0;
    const cursor = el.querySelector(".cursor");
    function step() {
      if (i < text.length) {
        cursor.insertAdjacentText("beforebegin", text[i]);
        i++;
        setTimeout(step, speed);
      } else {
        cursor.remove();
        resolve();
      }
    }
    step();
  });
}

// Reads a streamed fetch Response chunk by chunk and appends each chunk
// into `el` as it arrives, keeping the same blinking cursor look as
// typewrite() above. Falls back to a default line if nothing streams in.
async function streamWitnessResponse(res, el) {
  el.innerHTML = '<span class="cursor"></span>';
  const cursor = el.querySelector(".cursor");
  let received = "";

  if (!res.body || !res.body.getReader) {
    // Environment without streaming support — fall back to a full read.
    const data = await res.json().catch(() => null);
    const fallback =
      (data && data.response) ||
      "Some things are heard simply by being written down.";
    cursor.remove();
    await typewrite(fallback, el);
    return;
  }

  const reader = res.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    const chunk = decoder.decode(value, { stream: true });
    if (chunk) {
      received += chunk;
      cursor.insertAdjacentText("beforebegin", chunk);
    }
  }

  if (!received.trim()) {
    cursor.insertAdjacentText(
      "beforebegin",
      "Some things are heard simply by being written down.",
    );
  }

  cursor.remove();
}

sealBtn.addEventListener("click", async () => {
  const text = letterBody.value.trim();
  if (!text) {
    letterBody.focus();
    return;
  }

  sealBtn.disabled = true;

  letterSheet.style.transition =
    "transform 0.9s cubic-bezier(0.6,0,0.2,1), opacity 0.9s ease";
  letterSheet.style.transform = "scale(0.85) translateY(30px)";
  letterSheet.style.opacity = "0";

  setTimeout(() => {
    sceneLetter.classList.add("hidden");
    sceneWitness.classList.remove("hidden");
    listening.classList.add("visible");
  }, 750);

  try {
    const res = await fetch(API_URL, {
      signal: AbortSignal.timeout(30000),
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        to: recipient.value.trim(),
        text: text,
      }),
    });

    if (!res.ok) throw new Error("request failed");

    setTimeout(async () => {
      listening.classList.remove("visible");
      await streamWitnessResponse(res, witnessText);

      setTimeout(() => {
        witnessAfter.classList.add("visible");
      }, 600);

      setTimeout(() => {
        dissolveLine.style.opacity = "0.4";
      }, 1800);

      setTimeout(() => {
        noCopyLine.classList.add("visible");
        writeAgainBtn.classList.add("visible");
      }, 3000);
    }, 900);
  } catch (err) {
    setTimeout(async () => {
      listening.classList.remove("visible");
      await typewrite(
        "Something kept this from reaching the witness. Nothing was saved — try again when ready.",
        witnessText,
      );
      witnessAfter.classList.add("visible");
      dissolveLine.style.opacity = "0";
      noCopyLine.classList.add("visible");
      writeAgainBtn.classList.add("visible");
    }, 900);
  }
});

writeAgainBtn.addEventListener("click", () => {
  recipient.value = "";
  letterBody.value = "";
  salutationInserted = false;
  sealBtn.disabled = false;
  letterSheet.style.transition = "none";
  letterSheet.style.transform = "";
  letterSheet.style.opacity = "";
  witnessText.innerHTML = "";
  witnessAfter.classList.remove("visible");
  dissolveLine.style.opacity = "";
  noCopyLine.classList.remove("visible");
  writeAgainBtn.classList.remove("visible");

  sceneWitness.classList.add("hidden");
  sceneLetter.classList.remove("hidden");
  runPlaceholderCycle();
  setTimeout(() => {
    letterBody.focus();
    setTimeout(() => {
      initRopeScrollbar();
      initTextareaRopeScrollbar();
    }, 100);
  }, 400);
});
