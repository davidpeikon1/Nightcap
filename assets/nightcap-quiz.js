/**
 * Nightcap Sugar Usage Quiz
 * Multi-step quiz that collects sugar consumption data,
 * then transitions to the waitlist signup form.
 */
(function () {
  'use strict';

  const TOTAL_STEPS = 5;
  let currentStep = 1;
  const quizData = {};

  // Sugar gram estimates per drink choice
  const SUGAR_MAP = {
    soda: 39,
    juice: 28,
    wine_beer: 9,
    tea_coffee: 12,
    water: 0,
    energy_sports: 34,
  };

  // Multiplier by daily drink count
  const FREQUENCY_MAP = {
    '0': 0,
    '1': 1,
    '2-3': 2.5,
    '4+': 4.5,
  };

  // DOM Elements
  const heroSection = document.getElementById('hero');
  const quizSection = document.getElementById('sugar-quiz');
  const signupSection = document.getElementById('waitlist-signup');
  const startBtn = document.getElementById('start-quiz-btn');
  const backBtn = document.getElementById('quiz-back-btn');
  const progressBar = document.getElementById('quiz-progress-bar');
  const progressText = document.getElementById('quiz-progress-text');

  if (!quizSection) return;

  // ---------- Start Quiz ----------
  if (startBtn) {
    startBtn.addEventListener('click', function () {
      heroSection.style.display = 'none';
      quizSection.classList.add('active');
      quizSection.style.display = 'flex';
      updateProgress();
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  // ---------- Option Selection ----------
  quizSection.addEventListener('click', function (e) {
    const option = e.target.closest('.nc-quiz__option');
    if (!option) return;

    const step = option.closest('.nc-quiz__step');
    const field = step.querySelector('.nc-quiz__options').dataset.field;
    const value = option.dataset.value;

    // Mark selected
    step.querySelectorAll('.nc-quiz__option').forEach(function (opt) {
      opt.classList.remove('selected');
    });
    option.classList.add('selected');

    // Store answer
    quizData[field] = value;

    // Update hidden field
    const hiddenFields = {
      evening_drink: 'quiz-evening-drink',
      daily_sugary_drinks: 'quiz-daily-drinks',
      sleep_quality: 'quiz-sleep-quality',
      motivation: 'quiz-motivation',
      checks_sugar: 'quiz-checks-sugar',
    };

    var hiddenInput = document.getElementById(hiddenFields[field]);
    if (hiddenInput) {
      hiddenInput.value = value;
    }

    // Auto-advance after short delay
    setTimeout(function () {
      if (currentStep < TOTAL_STEPS) {
        goToStep(currentStep + 1);
      } else {
        // Quiz complete — show signup
        finishQuiz();
      }
    }, 350);
  });

  // ---------- Back Button ----------
  if (backBtn) {
    backBtn.addEventListener('click', function () {
      if (currentStep > 1) {
        goToStep(currentStep - 1);
      }
    });
  }

  // ---------- Navigation ----------
  function goToStep(step) {
    // Hide current
    var currentEl = quizSection.querySelector('.nc-quiz__step[data-step="' + currentStep + '"]');
    if (currentEl) currentEl.classList.remove('active');

    currentStep = step;

    // Show next
    var nextEl = quizSection.querySelector('.nc-quiz__step[data-step="' + currentStep + '"]');
    if (nextEl) nextEl.classList.add('active');

    updateProgress();

    // Show/hide back button
    backBtn.style.display = currentStep > 1 ? 'inline-flex' : 'none';
  }

  function updateProgress() {
    var percent = ((currentStep - 1) / TOTAL_STEPS) * 100;
    progressBar.style.width = percent + '%';
    progressText.textContent = 'Question ' + currentStep + ' of ' + TOTAL_STEPS;
  }

  function finishQuiz() {
    // Calculate sugar estimate before showing signup
    calculateSugarEstimate();

    // Store quiz data globally for the waitlist form to access
    window.__nightcapQuizData = quizData;

    // Transition to signup
    quizSection.style.display = 'none';
    signupSection.style.display = 'flex';
    signupSection.classList.add('nc-section-visible');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // ---------- Sugar Calculation ----------
  function calculateSugarEstimate() {
    var baseSugar = SUGAR_MAP[quizData.evening_drink] || 20;
    var multiplier = FREQUENCY_MAP[quizData.daily_sugary_drinks] || 1;

    quizData.estimated_daily_sugar = Math.round(baseSugar * multiplier);
    quizData.estimated_weekly_sugar = Math.round(baseSugar * multiplier * 7);
    quizData.estimated_yearly_sugar_lbs = (
      (baseSugar * multiplier * 365) /
      453.592
    ).toFixed(1);
  }

  // Make quizData accessible
  window.__nightcapQuizData = quizData;
})();
