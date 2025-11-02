// Mobile enhancements for Kleinanzeigen ad posting form

(function() {
  'use strict';

  // Detect if device is mobile
  function isMobile() {
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ||
           (window.innerWidth <= 768 && window.innerHeight <= 1024);
  }

  // Only apply mobile enhancements on mobile devices
  if (!isMobile()) {
    return;
  }

  // Prevent zoom on input focus for iOS Safari
  function preventZoomOnFocus() {
    const viewport = document.querySelector('meta[name=viewport]');
    if (viewport) {
      const content = viewport.getAttribute('content');
      if (!content.includes('user-scalable=no')) {
        viewport.setAttribute('content', content + ', user-scalable=no');
      }
    }
  }

  // Re-enable zoom after input blur
  function enableZoomOnBlur() {
    const viewport = document.querySelector('meta[name=viewport]');
    if (viewport) {
      const content = viewport.getAttribute('content');
      const newContent = content.replace(', user-scalable=no', '');
      viewport.setAttribute('content', newContent);
    }
  }

  // Apply zoom prevention to form inputs
  function setupInputZoomPrevention() {
    const inputs = document.querySelectorAll('input, textarea, select');

    inputs.forEach(function(input) {
      input.addEventListener('focus', preventZoomOnFocus);
      input.addEventListener('blur', function() {
        // Delay re-enabling zoom to prevent immediate zoom
        setTimeout(enableZoomOnBlur, 100);
      });
    });
  }

  // Improve touch targets for small elements
  function enhanceTouchTargets() {
    // Make sure all interactive elements have minimum touch target size
    const interactiveElements = document.querySelectorAll('button, a, [role="button"], input[type="checkbox"], input[type="radio"]');

    interactiveElements.forEach(function(element) {
      const computedStyle = window.getComputedStyle(element);
      const minWidth = parseInt(computedStyle.minWidth) || 0;
      const minHeight = parseInt(computedStyle.minHeight) || 0;

      if (minWidth < 44 || minHeight < 44) {
        element.style.minWidth = Math.max(minWidth, 44) + 'px';
        element.style.minHeight = Math.max(minHeight, 44) + 'px';
      }
    });
  }

  // Improve scrolling on mobile
  function setupSmoothScrolling() {
    // Add momentum scrolling for iOS
    document.body.style.webkitOverflowScrolling = 'touch';

    // Prevent rubber band scrolling on iOS
    document.addEventListener('touchmove', function(e) {
      if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA' && e.target.tagName !== 'SELECT') {
        e.preventDefault();
      }
    }, { passive: false });
  }

  // Handle orientation changes
  function handleOrientationChange() {
    // Force viewport recalculation on orientation change
    setTimeout(function() {
      const viewport = document.querySelector('meta[name=viewport]');
      if (viewport) {
        const content = viewport.getAttribute('content');
        viewport.setAttribute('content', content);
      }
    }, 100);
  }

  // Initialize mobile enhancements when DOM is ready
  function init() {
    setupInputZoomPrevention();
    enhanceTouchTargets();
    setupSmoothScrolling();

    // Handle orientation changes
    window.addEventListener('orientationchange', handleOrientationChange);

    // Re-apply enhancements after dynamic content loads
    const observer = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
          enhanceTouchTargets();
        }
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
    
    // Additional DOM rearrangements for improved mobile UX
    try {
      applyMobileRearrange();
    } catch (e) {
      console.warn('Mobile rearrange failed', e);
    }
  }

  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();

// ---------- Mobile DOM rearrangement helpers (separate from init) ----------
function applyMobileRearrange() {
  if (!(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) || window.innerWidth <= 768)) {
    return; // only apply on mobile
  }

  // Collapse non-primary fieldsets to reduce scrolling
  const fieldsets = document.querySelectorAll('form#adForm fieldset');
  fieldsets.forEach(function(fs, idx) {
    // Keep the first fieldset expanded (usually Anzeigendetails)
    if (idx > 0) {
      fs.classList.add('fieldset-collapsed');
    }

    // Make legend clickable to toggle collapse
    const legend = fs.querySelector('legend');
    if (legend) {
      legend.setAttribute('role', 'button');
      legend.setAttribute('tabindex', '0');
      legend.addEventListener('click', function() {
        fs.classList.toggle('fieldset-collapsed');
      });
      legend.addEventListener('keypress', function(e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          fs.classList.toggle('fieldset-collapsed');
        }
      });
    }
  });

  // Move the action bar to be a direct child of body so it can be sticky across the screen width
  const frmActns = document.getElementById('pstad-frmactns');
  if (frmActns) {
    // If not already direct child of body, reparent
    if (frmActns.parentNode !== document.body) {
      // create a placeholder where it used to be
      const placeholder = document.createElement('div');
      placeholder.style.display = 'none';
      frmActns.parentNode.insertBefore(placeholder, frmActns);
      document.body.appendChild(frmActns);
    }

    // Ensure buttons have appropriate aria labels
    const submit = document.getElementById('pstad-submit');
    if (submit) {
      submit.setAttribute('aria-label', submit.textContent.trim() || 'Submit ad');
    }
    const preview = document.getElementById('pstad-frmprview');
    if (preview) {
      preview.setAttribute('aria-label', preview.textContent.trim() || 'Preview ad');
    }
  }

  // Move header logo into a compact wrapper to free vertical space
  const header = document.getElementById('site-header');
  const logo = document.querySelector('#site-logo');
  if (header && logo) {
    logo.style.flex = '0 0 auto';
    logo.style.marginRight = '8px';
  }

  // Make sure the primary input is visible when focusing (avoid sticky bar overlap)
  document.addEventListener('focusin', function(e) {
    const target = e.target;
    if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.tagName === 'SELECT')) {
      setTimeout(function() {
        try {
          target.scrollIntoView({ behavior: 'smooth', block: 'center' });
        } catch (err) {}
      }, 260);
    }
  });
}
