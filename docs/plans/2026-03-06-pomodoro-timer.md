# Pomodoro Timer v2 Implementation Plan

> **For Claude:** This is a single-file vanilla HTML/CSS/JS project. No build tools, no tests, no git. Execute sequentially.

**Goal:** Build an ultra-minimal 25-minute Pomodoro timer with full-screen alert overlay and audio notification.

**Architecture:** Single `index.html` containing inline CSS + JS. Two UI states managed by toggling a CSS class. Timer uses `setInterval` + `Date.now()` delta for drift-proof accuracy. Audio via Web Audio API.

**Tech Stack:** Vanilla HTML5, CSS3, JavaScript (ES6+), Web Audio API

**Design Reference:** See Pencil design file — Timer Screen (white bg, black 144px Outfit 900 digits, black pill button) and Alert Screen (red #E74C3C bg, white text).

---

### Task 1: HTML Structure

**Files:**
- Create: `index.html`

**Step 1: Create the HTML skeleton**

Write the complete HTML document with:
- `<!DOCTYPE html>` + meta viewport
- Google Fonts link for Outfit (900, 300) — no Inter needed (system font fallback)
- `<div id="app">` containing:
  - `<div class="timer-display" id="timerDisplay">25:00</div>`
  - `<button id="actionBtn">START</button>`
- `<div id="overlay" class="overlay hidden">` containing:
  - `<div class="overlay-title">时间到！</div>`
  - `<div class="overlay-sub">休息一下</div>`
  - `<div class="overlay-hint">按任意键返回</div>`

**Step 2: Verify in browser**

Open `index.html` in browser. Should see raw unstyled elements.

---

### Task 2: CSS — Timer Screen

**Files:**
- Modify: `index.html` (add `<style>` block)

**Step 1: Add base styles**

```css
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: 'Outfit', sans-serif;
  background: #FFFFFF;
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
}
#app {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 48px;
}
```

**Step 2: Add timer display styles**

```css
.timer-display {
  font-size: 144px;
  font-weight: 900;
  color: #000000;
  letter-spacing: -6px;
  line-height: 0.85;
  font-variant-numeric: tabular-nums;
}
```

Note: `font-variant-numeric: tabular-nums` ensures digits have equal width, preventing layout jitter during countdown.

**Step 3: Add button styles**

```css
#actionBtn {
  font-family: 'Outfit', sans-serif;
  font-size: 16px;
  font-weight: 700;
  letter-spacing: 3px;
  color: #FFFFFF;
  background: #000000;
  border: none;
  padding: 16px 48px;
  border-radius: 40px;
  cursor: pointer;
  transition: opacity 0.2s;
}
#actionBtn:hover { opacity: 0.8; }
```

**Step 4: Verify**

Browser should show centered "25:00" + black pill "START" button matching design.

---

### Task 3: CSS — Alert Overlay

**Files:**
- Modify: `index.html` (extend `<style>`)

**Step 1: Add overlay styles**

```css
.overlay {
  position: fixed;
  inset: 0;
  background: #E74C3C;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 24px;
  z-index: 9999;
  transition: opacity 0.3s;
}
.overlay.hidden {
  opacity: 0;
  pointer-events: none;
}
.overlay-title {
  font-size: 120px;
  font-weight: 900;
  color: #FFFFFF;
  letter-spacing: -4px;
  line-height: 0.9;
}
.overlay-sub {
  font-size: 40px;
  font-weight: 300;
  color: #FFFFFF;
  letter-spacing: -1px;
}
.overlay-hint {
  font-family: system-ui, sans-serif;
  font-size: 16px;
  font-weight: 400;
  color: rgba(255,255,255,0.5);
  letter-spacing: 1px;
}
```

**Step 2: Verify**

Temporarily remove `hidden` class from overlay div → should see red full-screen with white text. Add `hidden` back.

---

### Task 4: JavaScript — Timer Logic

**Files:**
- Modify: `index.html` (add `<script>` block)

**Step 1: Implement state management and timer**

Core variables:
- `DURATION = 25 * 60` (seconds)
- `remaining` — seconds left
- `state` — 'idle' | 'running' | 'paused'
- `intervalId` — for setInterval
- `endTime` — Date.now() target for drift correction

State machine:
- idle → click → running (start countdown)
- running → click → paused
- paused → click → running (resume)
- running → remaining=0 → alert overlay shown

**Step 2: Implement `updateDisplay()`**

Format `remaining` as `MM:SS` with zero-padding, set to `timerDisplay.textContent`.

**Step 3: Implement `startTimer()`**

```javascript
function startTimer() {
  endTime = Date.now() + remaining * 1000;
  intervalId = setInterval(() => {
    remaining = Math.max(0, Math.round((endTime - Date.now()) / 1000));
    updateDisplay();
    if (remaining <= 0) {
      clearInterval(intervalId);
      showAlert();
    }
  }, 200); // 200ms for responsive display without battery drain
}
```

Key: Using `Date.now()` delta instead of `remaining--` prevents drift from browser timer throttling.

**Step 4: Implement button click handler**

```javascript
actionBtn.addEventListener('click', () => {
  if (state === 'idle') {
    state = 'running';
    remaining = DURATION;
    actionBtn.textContent = 'PAUSE';
    startTimer();
  } else if (state === 'running') {
    state = 'paused';
    clearInterval(intervalId);
    actionBtn.textContent = 'RESUME';
  } else if (state === 'paused') {
    state = 'running';
    actionBtn.textContent = 'PAUSE';
    startTimer();
  }
});
```

**Step 5: Verify**

Start timer, confirm countdown runs. Pause/resume works. (Temporarily set DURATION=5 for quick test.)

---

### Task 5: JavaScript — Alert & Audio

**Files:**
- Modify: `index.html` (extend `<script>`)

**Step 1: Implement `playAlertSound()`**

```javascript
function playAlertSound() {
  const ctx = new (window.AudioContext || window.webkitAudioContext)();
  [0, 0.6, 1.2].forEach(delay => {
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = 880;
    osc.type = 'sine';
    gain.gain.setValueAtTime(0.3, ctx.currentTime + delay);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + delay + 0.5);
    osc.start(ctx.currentTime + delay);
    osc.stop(ctx.currentTime + delay + 0.5);
  });
}
```

Three 880Hz beeps with fade-out, spaced 600ms apart.

**Step 2: Implement `showAlert()`**

```javascript
function showAlert() {
  overlay.classList.remove('hidden');
  playAlertSound();
}
```

**Step 3: Implement dismiss handler**

```javascript
function dismissAlert() {
  overlay.classList.add('hidden');
  state = 'idle';
  remaining = DURATION;
  updateDisplay();
  actionBtn.textContent = 'START';
}

document.addEventListener('keydown', () => {
  if (!overlay.classList.contains('hidden')) dismissAlert();
});
overlay.addEventListener('click', dismissAlert);
```

**Step 4: Final verification**

Set DURATION=3, full flow: START → countdown → red overlay + beep → press any key → back to 25:00. Then restore DURATION=25*60.

---

### Task 6: Polish & Final Check

**Step 1: Add page title**

`<title>Pomodoro Timer</title>`

**Step 2: Add favicon (optional, inline SVG data URI)**

Red circle emoji as favicon for tab identification.

**Step 3: Final verification checklist**

- [ ] Double-click index.html opens correctly
- [ ] START begins countdown from 25:00
- [ ] PAUSE stops countdown, RESUME continues
- [ ] Timer hits 00:00 → red overlay appears with fade
- [ ] Three beeps play
- [ ] Any key or click dismisses overlay
- [ ] Returns to 25:00 + START state
- [ ] No console errors
