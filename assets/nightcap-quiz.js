/**
 * Nightcap Sugar Usage Quiz v2
 * Multi-step quiz with ARIA accessibility, keyboard navigation,
 * smooth transitions, UTM capture, and sugar calculation engine.
 */
(function () {
  'use strict';

  var TOTAL_STEPS = 5;
  var currentStep = 1;
  var quizData = {};
  var isTransitioning = false;

  // Sugar gram estimates per breakfast type
  var BREAKFAST_MAP = {
    cereal_toast: 28,
    yogurt_smoothie: 24,
    coffee_pastry: 52,
    eggs_protein: 3,
    skip: 0,
  };

  // Sugar from sweetened drinks per day
  var DRINKS_MAP = {
    '0': 0,
    '1': 32,
    '2-3': 75,
    '4+': 130,
  };

  // Hidden sugar from processed/packaged foods
  var PROCESSED_MAP = {
    rarely: 8,
    some: 22,
    most: 40,
    almost_all: 65,
  };

  // DOM refs
  var heroSection = document.getElementById('hero');
  var quizSection = document.getElementById('sugar-quiz');
  var signupSection = document.getElementById('waitlist-signup');
  var startBtn = document.getElementById('start-quiz-btn');
  var backBtn = document.getElementById('quiz-back-btn');

  if (!quizSection) return;

  // ---------- Capture UTM / Source Params ----------
  function captureUTM() {
    var params = new URLSearchParams(window.location.search);
    var utmKeys = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_content', 'utm_term', 'ref'];
    var utm = {};
    utmKeys.forEach(function (key) {
      var val = params.get(key);
      if (val) utm[key] = val;
    });
    if (Object.keys(utm).length > 0) {
      quizData._utm = utm;
    }
  }
  captureUTM();

  // ---------- Start Quiz ----------
  // Hero CTA goes straight to quiz (no friction)
  if (startBtn) {
    startBtn.addEventListener('click', function () {
      startQuizFromAnywhere();
    });
  }

  // Pre-commitment screen handlers (bound once)
  var precommit = document.getElementById('precommit');
  var precommitYes = document.getElementById('precommit-yes');
  var precommitNo = document.getElementById('precommit-no');
  var precommitNoClicked = false;

  if (precommitYes) {
    precommitYes.addEventListener('click', function () {
      if (precommit) { precommit.classList.remove('active'); precommit.style.display = 'none'; }
      startQuizDirect();
      trackEvent('precommit_yes');
    });
  }

  if (precommitNo) {
    precommitNo.addEventListener('click', function () {
      if (!precommitNoClicked) {
        precommitNo.textContent = 'Are you sure? It only takes 60 seconds.';
        precommitNoClicked = true;
        trackEvent('precommit_no');
      } else {
        if (precommit) { precommit.classList.remove('active'); precommit.style.display = 'none'; }
        startQuizDirect();
        trackEvent('precommit_no_then_yes');
      }
    });
  }

  function showPrecommit() {
    if (!precommit) { startQuizFromAnywhere(); return; }

    var sections = ['hero', 'pullquote', 'how-it-works', 'social-proof', 'faq'];
    sections.forEach(function (id) {
      var el = document.getElementById(id);
      if (el) el.style.display = 'none';
    });
    var sticky = document.getElementById('sticky-cta');
    if (sticky) sticky.classList.remove('visible');

    precommit.style.display = '';
    precommit.classList.add('active');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function startQuizDirect() {
    quizSection.classList.add('active');
    updateProgress();
    trackEvent('quiz_started');
    window.scrollTo({ top: 0, behavior: 'smooth' });
    var firstOption = quizSection.querySelector('.nc-quiz__step.active .nc-quiz__option');
    if (firstOption) setTimeout(function () { firstOption.focus(); }, 100);
  }

  function startQuizFromAnywhere() {
    var sections = ['hero', 'pullquote', 'how-it-works', 'social-proof', 'midcta', 'faq', 'precommit'];
    sections.forEach(function (id) {
      var el = document.getElementById(id);
      if (el) el.style.display = 'none';
    });
    // Hide sticky CTA during quiz
    var sticky = document.getElementById('sticky-cta');
    if (sticky) sticky.classList.remove('visible');
    // Show quiz
    quizSection.classList.add('active');
    updateProgress();
    trackEvent('quiz_started');
    window.scrollTo({ top: 0, behavior: 'smooth' });
    var firstOption = quizSection.querySelector('.nc-quiz__step.active .nc-quiz__option');
    if (firstOption) setTimeout(function () { firstOption.focus(); }, 100);
  }

  // ---------- Option Selection (click) ----------
  quizSection.addEventListener('click', function (e) {
    var option = e.target.closest('.nc-quiz__option');
    if (!option || isTransitioning) return;
    selectOption(option);
  });

  // ---------- Keyboard Navigation ----------
  quizSection.addEventListener('keydown', function (e) {
    var activeStep = quizSection.querySelector('.nc-quiz__step.active');
    if (!activeStep) return;

    var options = Array.from(activeStep.querySelectorAll('.nc-quiz__option'));
    var focused = document.activeElement;
    var idx = options.indexOf(focused);

    if (e.key === 'ArrowDown' || e.key === 'ArrowRight') {
      e.preventDefault();
      var next = idx < options.length - 1 ? idx + 1 : 0;
      options[next].focus();
    } else if (e.key === 'ArrowUp' || e.key === 'ArrowLeft') {
      e.preventDefault();
      var prev = idx > 0 ? idx - 1 : options.length - 1;
      options[prev].focus();
    } else if (e.key === 'Enter' || e.key === ' ') {
      if (focused && focused.classList.contains('nc-quiz__option')) {
        e.preventDefault();
        if (!isTransitioning) selectOption(focused);
      }
    } else if (e.key >= '1' && e.key <= '9') {
      // Number keys select option directly
      var numIdx = parseInt(e.key, 10) - 1;
      if (numIdx < options.length && !isTransitioning) {
        e.preventDefault();
        selectOption(options[numIdx]);
      }
    }
  });

  function selectOption(option) {
    var step = option.closest('.nc-quiz__step');
    var optionsContainer = step.querySelector('.nc-quiz__options');
    var field = optionsContainer.dataset.field;
    var value = option.dataset.value;

    // Mark selected + update ARIA
    step.querySelectorAll('.nc-quiz__option').forEach(function (opt) {
      opt.classList.remove('selected');
      opt.setAttribute('aria-checked', 'false');
    });
    option.classList.add('selected');
    option.setAttribute('aria-checked', 'true');

    // Store answer
    quizData[field] = value;

    // Track
    trackEvent('quiz_answer', { question: field, answer: value, step: currentStep });

    // Auto-advance
    isTransitioning = true;
    setTimeout(function () {
      try {
        if (currentStep < TOTAL_STEPS) {
          goToStep(currentStep + 1);
        } else {
          finishQuiz();
        }
      } catch (e) {
        console.error('Quiz navigation error:', e);
      }
      isTransitioning = false;
    }, 400);
  }

  // ---------- Back Button ----------
  if (backBtn) {
    backBtn.addEventListener('click', function () {
      if (currentStep > 1 && !isTransitioning) {
        goToStep(currentStep - 1);
      }
    });
  }

  // ---------- Navigation ----------
  function goToStep(step) {
    var currentEl = quizSection.querySelector('.nc-quiz__step[data-step="' + currentStep + '"]');
    var direction = step > currentStep ? 'forward' : 'backward';

    // Exit animation on current
    if (currentEl) {
      currentEl.classList.remove('active');
    }

    currentStep = step;

    // Enter new step
    var nextEl = quizSection.querySelector('.nc-quiz__step[data-step="' + currentStep + '"]');
    if (nextEl) {
      nextEl.classList.add('active');

      // Restore previous selection state if going back
      var field = nextEl.querySelector('.nc-quiz__options').dataset.field;
      if (quizData[field]) {
        var prevOption = nextEl.querySelector('[data-value="' + quizData[field] + '"]');
        if (prevOption) {
          prevOption.classList.add('selected');
          prevOption.setAttribute('aria-checked', 'true');
        }
      }

      // Focus first option
      var firstOption = nextEl.querySelector('.nc-quiz__option');
      if (firstOption) {
        setTimeout(function () { firstOption.focus(); }, 100);
      }
    }

    updateProgress();

    // Back button visibility with transition
    if (currentStep > 1) {
      backBtn.style.display = 'inline-flex';
      requestAnimationFrame(function () {
        backBtn.classList.add('visible');
      });
    } else {
      backBtn.classList.remove('visible');
      setTimeout(function () {
        backBtn.style.display = 'none';
      }, 300);
    }
  }

  function updateProgress() {
    // Step dots
    var dots = quizSection.querySelectorAll('.nc-quiz__dot');
    dots.forEach(function (dot, i) {
      var dotStep = i + 1;
      dot.classList.remove('active', 'completed');
      if (dotStep === currentStep) {
        dot.classList.add('active');
      } else if (dotStep < currentStep) {
        dot.classList.add('completed');
      }
    });
  }

  function finishQuiz() {
    calculateSugarEstimate();
    window.__nightcapQuizData = quizData;


    trackEvent('quiz_completed', {
      estimated_daily_sugar: quizData.estimated_daily_sugar,
      motivation: quizData.motivation,
    });

    // Hide quiz, show calculating transition
    quizSection.classList.remove('active');
    quizSection.style.display = 'none';

    var calcScreen = document.getElementById('calculating-screen');
    if (calcScreen) {
      calcScreen.classList.add('active');
      window.scrollTo({ top: 0, behavior: 'smooth' });
      runCalculatingAnimation(function () {
        calcScreen.classList.remove('active');
        // Populate teaser number before showing signup
        var teaserNum = document.getElementById('signup-teaser-number');
        if (teaserNum && quizData.estimated_daily_sugar) {
          teaserNum.textContent = quizData.estimated_daily_sugar + 'g';
        }
        signupSection.classList.add('active');
        window.scrollTo({ top: 0, behavior: 'smooth' });
        var nameInput = document.getElementById('signup-name');
        if (nameInput) setTimeout(function () { nameInput.focus(); }, 400);
      });
    } else {
      // Fallback: skip animation
      signupSection.classList.add('active');
      window.scrollTo({ top: 0, behavior: 'smooth' });
      var nameInput = document.getElementById('signup-name');
      if (nameInput) setTimeout(function () { nameInput.focus(); }, 300);
    }
  }

  function runCalculatingAnimation(callback) {
    var steps = document.querySelectorAll('.nc-calculating__step');
    var delay = 0;
    steps.forEach(function (step, i) {
      setTimeout(function () {
        // Mark previous as done
        if (i > 0) steps[i - 1].classList.remove('active');
        if (i > 0) steps[i - 1].classList.add('done');
        step.classList.add('active');
      }, delay);
      delay += 500;
    });
    // After all steps, mark last done and callback
    setTimeout(function () {
      if (steps.length > 0) {
        steps[steps.length - 1].classList.remove('active');
        steps[steps.length - 1].classList.add('done');
      }
    }, delay);
    setTimeout(callback, delay + 400);
  }

  // ---------- Sugar Calculation ----------
  function calculateSugarEstimate() {
    var breakfast = BREAKFAST_MAP[quizData.breakfast] || 15;
    var drinks = DRINKS_MAP[quizData.daily_sweet_drinks] || 20;
    var processed = PROCESSED_MAP[quizData.processed_foods] || 20;

    var dailyTotal = breakfast + drinks + processed;

    quizData.sugar_from_breakfast = breakfast;
    quizData.sugar_from_drinks = drinks;
    quizData.sugar_from_processed = processed;
    quizData.estimated_daily_sugar = Math.round(dailyTotal);
    quizData.estimated_weekly_sugar = Math.round(dailyTotal * 7);
    quizData.estimated_yearly_sugar_lbs = parseFloat(
      ((dailyTotal * 365) / 453.592).toFixed(1)
    );
  }

  // ---------- Analytics Abstraction ----------
  function trackEvent(name, data) {
    // Push to dataLayer (GTM), fbq, or custom analytics
    if (window.dataLayer) {
      window.dataLayer.push({ event: 'nightcap_' + name, nightcap_data: data || {} });
    }
    // Facebook Pixel
    if (window.fbq) {
      window.fbq('trackCustom', 'Nightcap_' + name, data || {});
    }
    // Custom event for any listener
    window.dispatchEvent(new CustomEvent('nightcap:' + name, { detail: data || {} }));
  }

  // ---------- Secondary Quiz Buttons ----------
  // "Find Out Your Number" button in Why section
  // All secondary CTAs go through pre-commitment
  ['why-quiz-btn', 'sticky-quiz-btn', 'bottom-quiz-btn', 'benefits-quiz-btn', 'mid-quiz-btn', 'nav-quiz-btn'].forEach(function (id) {
    var btn = document.getElementById(id);
    if (btn) btn.addEventListener('click', showPrecommit);
  });

  // ---------- Top Nav scroll state ----------
  var nav = document.getElementById('nc-nav');
  if (nav) {
    var scrollThreshold = 40;
    var updateNav = function () {
      if (window.scrollY > scrollThreshold) {
        nav.classList.add('is-scrolled');
      } else {
        nav.classList.remove('is-scrolled');
      }
    };
    updateNav();
    window.addEventListener('scroll', updateNav, { passive: true });
  }

  // ---------- Sticky CTA on Scroll ----------
  var stickyCta = document.getElementById('sticky-cta');
  if (stickyCta && heroSection) {
    var stickyShown = false;
    window.addEventListener('scroll', function () {
      var heroBottom = heroSection.getBoundingClientRect().bottom;
      var quizActive = quizSection.classList.contains('active');
      var signupActive = signupSection && signupSection.classList.contains('active');
      var resultsActive = document.getElementById('quiz-results') &&
                          document.getElementById('quiz-results').classList.contains('active');

      // Show sticky only when scrolled past hero AND not in quiz/signup/results
      if (heroBottom < 0 && !quizActive && !signupActive && !resultsActive) {
        if (!stickyShown) {
          stickyCta.classList.add('visible');
          stickyShown = true;
        }
      } else {
        if (stickyShown) {
          stickyCta.classList.remove('visible');
          stickyShown = false;
        }
      }
    }, { passive: true });
  }

  // Expose
  window.__nightcapQuizData = quizData;
  window.__nightcapTrack = trackEvent;
  window.__nightcapStartQuiz = startQuizFromAnywhere;
})();
