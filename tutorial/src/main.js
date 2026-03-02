// Sidebar toggle (mobile)
const hamburger = document.querySelector('.hamburger');
const sidebar = document.querySelector('.sidebar');

if (hamburger && sidebar) {
  hamburger.addEventListener('click', () => {
    sidebar.classList.toggle('open');
  });

  // Close sidebar when clicking a nav link (mobile)
  sidebar.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      if (window.innerWidth <= 768) {
        sidebar.classList.remove('open');
      }
    });
  });

  // Close sidebar when clicking outside (mobile)
  document.addEventListener('click', (e) => {
    if (window.innerWidth <= 768 &&
        sidebar.classList.contains('open') &&
        !sidebar.contains(e.target) &&
        !hamburger.contains(e.target)) {
      sidebar.classList.remove('open');
    }
  });
}

// Scroll spy
const sections = document.querySelectorAll('.tutorial-section');
const navLinks = document.querySelectorAll('.sidebar-nav a');
const progressBar = document.querySelector('.scroll-progress-bar');

function updateScrollSpy() {
  const scrollPos = window.scrollY + 120;
  const docHeight = document.documentElement.scrollHeight - window.innerHeight;
  const scrollPercent = Math.min(100, (window.scrollY / docHeight) * 100);

  if (progressBar) {
    progressBar.style.width = scrollPercent + '%';
  }

  let current = '';
  sections.forEach(section => {
    if (section.offsetTop <= scrollPos) {
      current = section.id;
    }
  });

  navLinks.forEach(link => {
    link.classList.toggle('active', link.getAttribute('href') === '#' + current);
  });
}

let ticking = false;
window.addEventListener('scroll', () => {
  if (!ticking) {
    requestAnimationFrame(() => {
      updateScrollSpy();
      ticking = false;
    });
    ticking = true;
  }
});

updateScrollSpy();

// Keyboard navigation for details elements
document.querySelectorAll('details summary').forEach(summary => {
  summary.setAttribute('tabindex', '0');
});
