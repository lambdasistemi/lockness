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

  const object = value => value !== null && typeof value === 'object' && !Array.isArray(value);
  const hash = value => typeof value === 'string' && /^[a-f0-9]{64}$/.test(value);
  const pause = value => typeof value === 'number' && Number.isFinite(value) && value >= 0;
  const json = async url => {
    const response = await fetch(url, { cache: 'no-cache' });
    if (!response.ok) throw new Error('Narration input unavailable');
    return response.json();
  };
  const textHash = async text => {
    const bytes = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
    return Array.from(new Uint8Array(bytes), byte => byte.toString(16).padStart(2, '0')).join('');
  };
  if (typeof here.source !== 'string' || !here.source.startsWith('docs/') || !here.source.endsWith('.md')) return;
  const speechUrl = here.base + here.source.slice(5).replace(/\.md$/, '.speech.json');

  Promise.all([json(here.base + 'audio/manifest.json'), json(speechUrl)]).then(async ([manifest, speech]) => {
    if (!object(manifest) || !object(manifest.clips) || !object(speech) ||
        !object(speech._source) || !hash(speech._source.sha256)) throw new Error('Invalid narration input');
    Object.entries(speech).forEach(([id, segments]) => {
      if (id.startsWith('_')) return;
      if (!Array.isArray(segments) || !segments.length || segments.some(segment =>
        !object(segment) || typeof segment.text !== 'string' || !segment.text.trim() ||
        !pause(segment.pause === undefined ? 200 : segment.pause) || (segment.skip !== undefined && typeof segment.skip !== 'boolean'))) {
        throw new Error('Invalid speech section');
      }
    });
    const sections = new Map();
    Object.entries(manifest.clips).forEach(([name, clip]) => {
      if (!object(clip) || typeof clip.page !== 'string' || typeof clip.section !== 'string' ||
          !Number.isInteger(clip.index) || clip.index < 0 || !pause(clip.pause_ms) ||
          !hash(clip.text_sha256) || !hash(clip.audio_sha256) || !/^[a-z0-9-]+\/[a-z0-9-]+$/.test(name)) {
        throw new Error('Invalid narration clip');
      }
      if (clip.page !== here.source) return;
      if (!sections.has(clip.section)) sections.set(clip.section, []);
      sections.get(clip.section).push({ name, index: clip.index, pause_ms: clip.pause_ms,
        text_sha256: clip.text_sha256, version: clip.audio_sha256.slice(0, 16) });
    });
    // Validate every section before exposing any controls; hash failures never play stale clips.
    const checked = await Promise.all(Array.from(sections, async ([id, clips]) => {
      if (!Object.hasOwn(speech, id) || id.startsWith('_')) return null;
      const expected = speech[id].map((segment, index) => ({ segment, index })).filter(({ segment }) => !segment.skip);
      if (!expected.length || clips.length !== expected.length) return null;
      clips.sort((a, b) => a.index - b.index);
      const matches = await Promise.all(expected.map(async ({ segment, index }, position) => {
        const clip = clips[position];
        return clip.index === index && clip.pause_ms === (segment.pause === undefined ? 200 : segment.pause) &&
          clip.text_sha256 === await textHash(segment.text);
      }));
      return matches.every(Boolean) ? { id, clips } : null;
    }));
    let playable = 0;
    checked.filter(Boolean).forEach(({ id, clips }) => {
      const heading = document.getElementById(id);
      if (!heading) return;
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'narration-play';
      show(button, PLAY);
      button.setAttribute('aria-pressed', 'false');
      button.addEventListener('click', () => play(button, clips));
      heading.appendChild(button);
      playable++;
    });
    if (!playable) return;
    const speed = document.createElement('button');
    speed.type = 'button';
    speed.id = 'narration-speed';
    const GAUGE = '<svg viewBox="0 0 16 16" width="1.1em" height="1.1em" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M2 12a6 6 0 1 1 12 0"/><path d="M8 12l3-4"/></svg>';
    const label = () => { speed.innerHTML = GAUGE + '<span>' + rate + '×</span>'; speed.title = 'Narration speed ' + rate + '×'; };
    label();
    speed.setAttribute('aria-label', 'Change narration speed');
    speed.addEventListener('click', () => {
      rate = rates[(rates.indexOf(rate) + 1) % rates.length];
      label();
      if (current) current.audio.playbackRate = rate;
    });
    const toggle = document.getElementById('lockness-palette-toggle');
    const item = toggle && toggle.closest('li');
    if (item) {
      const entry = document.createElement('li');
      entry.appendChild(speed);
      item.before(entry);
    } else {
      (document.getElementById('terminal-mkdocs-main-content') || document.body).prepend(speed);
    }
  }).catch(() => { /* No narration available on this page. */ });
})();
