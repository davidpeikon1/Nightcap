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

  // Sugar gram estimates per drink choice
  var SUGAR_MAP = {
    soda: 39,
    juice: 28,
    wine_beer: 9,
    tea_coffee: 12,
    water: 0,
    energy_sports: 34,
  };

  // Multiplier by daily drink count
  var FREQUENCY_MAP = {
    '0': 0,
    '1': 1,
    '2-3': 2.5,
    '4+': 4.5,
  };

  // DOM refs
  var heroSection = document.getElementById('hero');
  var quizSection = document.getElementById('sugar-quiz');
  var signupSection = document.getElementById('waitlist-signup');
  var startBtn = document.getElementById('start-quiz-btn');
  var backBtn = document.getElementById('quiz-back-btn');
  var progressBar = document.getElementById('quiz-progress-bar');
  var progressText = document.getElementById('quiz-progress-text');

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
  if (startBtn) {
    startBtn.addEventListener('click', function () {
      heroSection.style.display = 'none';
      quizSection.classList.add('active');
      updateProgress();

      // Track event
      trackEvent('quiz_started');

      // Focus first option for keyboard users
      var firstOption = quizSection.querySelector('.nc-quiz__step.active .nc-quiz__option');
      if (firstOption) {
        setTimeout(function () { firstOption.focus(); }, 100);
      }

      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
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
      if (currentStep < TOTAL_STEPS) {
        goToStep(currentStep + 1);
      } else {
        finishQuiz();
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
    var percent = (currentStep / TOTAL_STEPS) * 100;
    progressBar.style.width = percent + '%';
    progressText.textContent = 'Question ' + currentStep + ' of ' + TOTAL_STEPS;

    // ARIA
    progressBar.setAttribute('aria-valuenow', currentStep);
    progressBar.setAttribute('aria-valuetext', 'Question ' + currentStep + ' of ' + TOTAL_STEPS);
  }

  function finishQuiz() {
    calculateSugarEstimate();
    window.__nightcapQuizData = quizData;

    // Complete progress
    progressBar.style.width = '100%';
    progressBar.setAttribute('aria-valuenow', TOTAL_STEPS);

    trackEvent('quiz_completed', {
      estimated_daily_sugar: quizData.estimated_daily_sugar,
      motivation: quizData.motivation,
    });

    // Transition to signup
    quizSection.classList.remove('active');
    quizSection.style.display = 'none';
    signupSection.classList.add('active');

    window.scrollTo({ top: 0, behavior: 'smooth' });

    // Auto-focus name input
    var nameInput = document.getElementById('signup-name');
    if (nameInput) {
      setTimeout(function () { nameInput.focus(); }, 300);
    }
  }

  // ---------- Sugar Calculation ----------
  function calculateSugarEstimate() {
    var baseSugar = SUGAR_MAP[quizData.evening_drink] || 20;
    var multiplier = FREQUENCY_MAP[quizData.daily_sugary_drinks] || 1;

    quizData.estimated_daily_sugar = Math.round(baseSugar * multiplier);
    quizData.estimated_weekly_sugar = Math.round(baseSugar * multiplier * 7);
    quizData.estimated_yearly_sugar_lbs = parseFloat(
      ((baseSugar * multiplier * 365) / 453.592).toFixed(1)
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

  // Expose
  window.__nightcapQuizData = quizData;
  window.__nightcapTrack = trackEvent;
})();
