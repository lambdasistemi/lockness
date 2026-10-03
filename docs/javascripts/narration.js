/* Play the recorded narration of one section at a time. Clips come from audio/manifest.json. */
(() => {
  const here = window.lockness;
  if (!here) return;
  const rates = [1, 1.25, 1.5, 0.85];
  const svg = body => '<svg viewBox="0 0 16 16" width="1em" height="1em" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 6h2.5L8 3v10L4.5 10H2z" fill="currentColor"/>' + body + '</svg>';
  const PLAY = svg('<path d="M10.5 5.5a3.5 3.5 0 0 1 0 5M12.5 3.5a6.5 6.5 0 0 1 0 9"/>');
  const PAUSE = svg('<path d="M11 5v6M13.5 5v6"/>');
  const LABELS = new Map([[PLAY, 'Play narration of this section'], [PAUSE, 'Pause narration']]);
  const show = (button, icon) => { button.innerHTML = icon; button.setAttribute('aria-label', LABELS.get(icon)); };
  let rate = 1, current = null;

  const stop = () => {
    if (!current) return;
    clearTimeout(current.timer);
    current.audio.pause();
    show(current.button, PLAY);
    current.button.setAttribute('aria-pressed', 'false');
    current = null;
  };

  const play = (button, clips) => {
    if (current && current.button === button) { stop(); return; }
    stop();
    const audio = new Audio();
    const state = { button, audio, timer: null };
    current = state;
    show(button, PAUSE);
    button.setAttribute('aria-pressed', 'true');
    let position = 0;
    const next = () => {
      if (current !== state) return;
      if (position >= clips.length) { stop(); return; }
      const clip = clips[position++];
      audio.src = here.base + 'audio/clips/' + clip.name + '.mp3?v=' + clip.version;
      audio.playbackRate = rate;
      audio.onended = () => { state.timer = setTimeout(next, clip.pause_ms / rate); };
      audio.play().catch(error => {
        button.textContent = '!';
        button.setAttribute('aria-label', 'Narration failed');
        button.title = String(error);
        current = null;
      });
    };
    next();
  };

  fetch(here.base + 'audio/manifest.json', { cache: 'no-cache' }).then(r => r.json()).then(manifest => {
    const sections = {};
    Object.entries(manifest.clips).forEach(([name, clip]) => {
      if (clip.page !== here.source) return;
      (sections[clip.section] = sections[clip.section] || []).push({ name, index: clip.index, pause_ms: clip.pause_ms, version: clip.audio_sha256.slice(0, 16) });
    });
    Object.entries(sections).forEach(([id, clips]) => {
      const heading = document.getElementById(id);
      if (!heading) return;
      clips.sort((a, b) => a.index - b.index);
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'narration-play';
      show(button, PLAY);
      button.setAttribute('aria-pressed', 'false');
      button.addEventListener('click', () => play(button, clips));
      heading.appendChild(button);
    });
    if (!Object.keys(sections).length) return;
    const speed = document.createElement('button');
    speed.type = 'button';
    speed.id = 'narration-speed';
    speed.textContent = '1×';
    speed.setAttribute('aria-label', 'Change narration speed');
    speed.addEventListener('click', () => {
      rate = rates[(rates.indexOf(rate) + 1) % rates.length];
      speed.textContent = rate + '×';
      if (current) current.audio.playbackRate = rate;
    });
    (document.getElementById('terminal-mkdocs-main-content') || document.body).prepend(speed);
  }).catch(() => { /* No narration available on this page. */ });
})();
