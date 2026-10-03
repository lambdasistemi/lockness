document.addEventListener('DOMContentLoaded', () => {
  const players = [...document.querySelectorAll('.voice-audition audio')];
  if (!players.length) return;
  const speed = document.getElementById('audition-speed');
  speed.addEventListener('change', () => {
    players.forEach(player => { player.playbackRate = Number(speed.value); });
  });
  players.forEach(player => {
    player.addEventListener('play', () => {
      players.forEach(other => { if (other !== player) other.pause(); });
      window.speechSynthesis?.cancel();
    });
  });
});
