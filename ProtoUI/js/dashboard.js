document.getElementById('notifBtn').addEventListener('click', () => {
  const dropdown = document.getElementById('notifDropdown');
  dropdown.classList.toggle('active');
});

document.addEventListener('click', (e) => {
  const dropdown = document.getElementById('notifDropdown');
  const btn = document.getElementById('notifBtn');
  if (!btn.contains(e.target) && !dropdown.contains(e.target)) {
    dropdown.classList.remove('active');
  }
});
