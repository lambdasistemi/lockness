document.addEventListener('DOMContentLoaded', () => {
  const players = [...document.querySelectorAll('.voice-audition audio')];
  if (!players.length) return;
  const speed = document.getElementById('audition-speed');
  const selector = document.getElementById('kokoro-voice');
  const kokoro = document.getElementById('kokoro-player');
  const continuous = document.getElementById('kokoro-continuous');
  const status = document.getElementById('kokoro-status');
  const previous = document.getElementById('kokoro-previous');
  const next = document.getElementById('kokoro-next');
  speed.addEventListener('change', () => {
    players.forEach(player => { player.playbackRate = Number(speed.value); });
  });
  players.forEach(player => {
    player.addEventListener('play', () => {
      players.forEach(other => { if (other !== player) other.pause(); });
      if (continuous && player !== kokoro) continuous.checked = false;
      window.speechSynthesis?.cancel();
    });
  });
  if (!selector || !kokoro) return;
  function describe() {
    const option = selector.selectedOptions[0];
    document.getElementById('kokoro-label').textContent = option.textContent;
    kokoro.setAttribute('aria-label', 'Listen to Kokoro: ' + option.textContent);
    previous.disabled = selector.selectedIndex === 0;
    next.disabled = selector.selectedIndex === selector.options.length - 1;
    status.textContent = `${selector.selectedIndex + 1} of ${selector.options.length}`;
  }
  function choose(play) {
    kokoro.pause();
    kokoro.src = selector.value;
    kokoro.load();
    kokoro.playbackRate = Number(speed.value);
    describe();
    if (play) kokoro.play().catch(() => { status.textContent = 'Press play to hear this voice.'; });
  }
  selector.addEventListener('change', () => choose(!kokoro.paused));
  for (const [button, step] of [[previous, -1], [next, 1]]) {
    button.addEventListener('click', () => {
      const play = !kokoro.paused;
      selector.selectedIndex += step;
      choose(play);
    });
  }
  document.getElementById('kokoro-play-all').addEventListener('click', () => {
    selector.selectedIndex = 0;
    continuous.checked = true;
    choose(true);
  });
  kokoro.addEventListener('ended', () => {
    if (!continuous.checked) return;
    if (selector.selectedIndex + 1 === selector.options.length) {
      continuous.checked = false;
      status.textContent = 'Finished all remaining voices.';
      return;
    }
    selector.selectedIndex += 1;
    choose(true);
  });
  kokoro.addEventListener('error', () => {
    continuous.checked = false;
    status.textContent = 'This recording could not load. Choose another voice or try again.';
  });
  describe();
});
