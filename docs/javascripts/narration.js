/* Play the recorded narration of one section at a time. Clips come from audio/manifest.json. */
(() => {
  const here = window.lockness;
  if (!here) return;
  const rates = [1, 1.25, 1.5, 0.85];
  let rate = 1, current = null;

  const stop = () => {
    if (!current) return;
    clearTimeout(current.timer);
    current.audio.pause();
    current.button.textContent = 'Play';
    current.button.setAttribute('aria-pressed', 'false');
    current = null;
  };

  const play = (button, clips) => {
    if (current && current.button === button) { stop(); return; }
    stop();
    const audio = new Audio();
    const state = { button, audio, timer: null };
    current = state;
    button.textContent = 'Pause';
    button.setAttribute('aria-pressed', 'true');
    let position = 0;
    const next = () => {
      if (current !== state) return;
      if (position >= clips.length) { stop(); return; }
      const clip = clips[position++];
      audio.src = here.base + 'audio/clips/' + clip.name + '.mp3';
      audio.playbackRate = rate;
      audio.onended = () => { state.timer = setTimeout(next, clip.pause_ms / rate); };
      audio.play().catch(error => {
        button.textContent = 'Audio failed';
        button.title = String(error);
        current = null;
      });
    };
    next();
  };

  fetch(here.base + 'audio/manifest.json').then(r => r.json()).then(manifest => {
    const sections = {};
    Object.entries(manifest.clips).forEach(([name, clip]) => {
      if (clip.page !== here.source) return;
      (sections[clip.section] = sections[clip.section] || []).push({ name, index: clip.index, pause_ms: clip.pause_ms });
    });
    Object.entries(sections).forEach(([id, clips]) => {
      const heading = document.getElementById(id);
      if (!heading) return;
      clips.sort((a, b) => a.index - b.index);
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'narration-play';
      button.textContent = 'Play';
      button.setAttribute('aria-pressed', 'false');
      button.setAttribute('aria-label', 'Play narration of this section');
      button.addEventListener('click', () => play(button, clips));
      heading.appendChild(button);
    });
    if (!Object.keys(sections).length) return;
    const speed = document.createElement('button');
    speed.type = 'button';
    speed.id = 'narration-speed';
    speed.textContent = 'Speed 1×';
    speed.setAttribute('aria-label', 'Change narration speed');
    speed.addEventListener('click', () => {
      rate = rates[(rates.indexOf(rate) + 1) % rates.length];
      speed.textContent = 'Speed ' + rate + '×';
      if (current) current.audio.playbackRate = rate;
    });
    (document.getElementById('terminal-mkdocs-main-content') || document.body).prepend(speed);
  }).catch(() => { /* No narration available on this page. */ });
})();
