function openPopup(index) {
  // Close any open popups first
  closeAllPopups();

  // Show overlay and popup
  document.getElementById('popup-overlay').classList.add('active');
  document.getElementById('popup-' + index).style.display = 'block';
}

function closePopup(index) {
  document.getElementById('popup-overlay').classList.remove('active');
  document.getElementById('popup-' + index).style.display = 'none';
}

function closeAllPopups() {
  var overlay = document.getElementById('popup-overlay');
  if (overlay) {
    overlay.classList.remove('active');
  }
  document.querySelectorAll('.enrollment-popup').forEach(function(popup) {
    popup.style.display = 'none';
  });
}

// Event delegation for clickable rows
document.addEventListener('click', function(e) {
  // Handle row clicks
  var row = e.target.closest('.clickable-row');
  if (row) {
    var index = row.getAttribute('data-popup-index');
    if (index !== null) {
      openPopup(index);
    }
    return;
  }

  // Handle close button clicks
  var closeBtn = e.target.closest('.popup-close');
  if (closeBtn) {
    var index = closeBtn.getAttribute('data-popup-index');
    if (index !== null) {
      closePopup(index);
    }
    return;
  }

  // Handle overlay clicks
  if (e.target.id === 'popup-overlay') {
    closeAllPopups();
  }
});

// Close popup on Escape key
document.addEventListener('keydown', function(e) {
  if (e.key === 'Escape') {
    closeAllPopups();
  }
});
