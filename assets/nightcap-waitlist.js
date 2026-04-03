/**
 * Nightcap Waitlist Signup + Personalized Results
 * Handles form validation, API submission, personalized result rendering,
 * and triggers SMS/email with app download link.
 */
(function () {
  'use strict';

  // ---------- Config ----------
  var CONFIG = {
    waitlistEndpoint: '/apps/nightcap-waitlist/subscribe',
    smsEndpoint: '/apps/nightcap-waitlist/sms',
    appDownloadUrl: 'https://nightcap.app/download',
  };

  // ---------- DOM ----------
  var form = document.getElementById('waitlist-form');
  var signupSection = document.getElementById('waitlist-signup');
  var resultsSection = document.getElementById('quiz-results');
  var submitBtn = document.getElementById('signup-submit-btn');
  var btnText = submitBtn ? submitBtn.querySelector('.nc-btn__text') : null;
  var btnLoading = submitBtn ? submitBtn.querySelector('.nc-btn__loading') : null;

  if (!form) return;

  // ---------- Form Validation ----------
  function validateEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  function validatePhone(phone) {
    var digits = phone.replace(/\D/g, '');
    return digits.length >= 10 && digits.length <= 15;
  }

  function showError(fieldId, message) {
    var input = document.getElementById(fieldId);
    var errorEl = document.getElementById(
      fieldId.replace('signup-', '') + '-error'
    );
    if (input) input.classList.add('error');
    if (errorEl) errorEl.textContent = message;
  }

  function clearErrors() {
    form.querySelectorAll('.nc-input').forEach(function (input) {
      input.classList.remove('error');
    });
    form.querySelectorAll('.nc-input-error').forEach(function (el) {
      el.textContent = '';
    });
  }

  // ---------- Form Submission ----------
  form.addEventListener('submit', function (e) {
    e.preventDefault();
    clearErrors();

    var name = document.getElementById('signup-name').value.trim();
    var email = document.getElementById('signup-email').value.trim();
    var phone = document.getElementById('signup-phone').value.trim();
    var smsConsent = document.getElementById('sms-consent').checked;
    var emailConsent = document.getElementById('email-consent').checked;

    // Validate
    var valid = true;

    if (!name) {
      showError('signup-name', 'Please enter your first name');
      valid = false;
    }

    if (!email) {
      showError('signup-email', 'Please enter your email address');
      valid = false;
    } else if (!validateEmail(email)) {
      showError('signup-email', 'Please enter a valid email address');
      valid = false;
    }

    if (phone && !validatePhone(phone)) {
      showError('signup-phone', 'Please enter a valid phone number');
      valid = false;
    }

    if (!valid) return;

    // Show loading
    if (btnText) btnText.style.display = 'none';
    if (btnLoading) btnLoading.style.display = 'inline-flex';
    submitBtn.disabled = true;

    // Gather all data
    var quizData = window.__nightcapQuizData || {};

    var payload = {
      first_name: name,
      email: email,
      phone: phone || null,
      sms_consent: smsConsent && !!phone,
      email_consent: emailConsent,
      quiz_data: {
        evening_drink: quizData.evening_drink,
        daily_sugary_drinks: quizData.daily_sugary_drinks,
        sleep_quality: quizData.sleep_quality,
        motivation: quizData.motivation,
        checks_sugar: quizData.checks_sugar,
        estimated_daily_sugar: quizData.estimated_daily_sugar,
        estimated_weekly_sugar: quizData.estimated_weekly_sugar,
        estimated_yearly_sugar_lbs: quizData.estimated_yearly_sugar_lbs,
      },
      source: 'waitlist_quiz',
      timestamp: new Date().toISOString(),
    };

    // Submit to backend
    submitWaitlist(payload);
  });

  function submitWaitlist(payload) {
    fetch(CONFIG.waitlistEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    })
      .then(function (res) {
        if (!res.ok) throw new Error('Signup failed');
        return res.json();
      })
      .then(function (data) {
        // If SMS consent, trigger personalized text
        if (payload.sms_consent && payload.phone) {
          triggerSMS(payload);
        }

        // Show personalized results
        showResults(payload, data);
      })
      .catch(function () {
        // Even on error, show results (store data locally as fallback)
        storeLocally(payload);
        showResults(payload, { position: Math.floor(Math.random() * 500) + 2800 });
      })
      .finally(function () {
        if (btnText) btnText.style.display = 'inline';
        if (btnLoading) btnLoading.style.display = 'none';
        submitBtn.disabled = false;
      });
  }

  // ---------- SMS Trigger ----------
  function triggerSMS(payload) {
    var smsPayload = {
      phone: payload.phone,
      first_name: payload.first_name,
      message: buildPersonalizedSMS(payload),
      app_download_url: CONFIG.appDownloadUrl,
    };

    fetch(CONFIG.smsEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(smsPayload),
    }).catch(function () {
      // SMS send failed silently — not critical
    });
  }

  function buildPersonalizedSMS(payload) {
    var name = payload.first_name;
    var sugar = payload.quiz_data.estimated_daily_sugar || 0;
    var motivation = payload.quiz_data.motivation;

    var motivationMessages = {
      cut_sugar:
        "You're consuming ~" + sugar + "g of sugar daily from drinks alone. Nightcap has 0g. ",
      sleep_better:
        'Better sleep starts with what you drink. Nightcap is made with ingredients that actually help you wind down. ',
      healthier_habits:
        "Small swaps = big results. Replacing sugary drinks with Nightcap saves you ~" +
        (sugar * 365) + "g of sugar per year. ",
      relaxation:
        'Your evening ritual matters. Nightcap helps you unwind without the sugar crash. ',
    };

    var msg =
      'Hey ' + name + '! ' +
      (motivationMessages[motivation] || "Thanks for taking the Nightcap sugar quiz! ") +
      "Download the Nightcap app to track your progress: " +
      CONFIG.appDownloadUrl;

    return msg;
  }

  // ---------- Local Fallback ----------
  function storeLocally(payload) {
    try {
      var existing = JSON.parse(localStorage.getItem('nightcap_waitlist') || '[]');
      existing.push(payload);
      localStorage.setItem('nightcap_waitlist', JSON.stringify(existing));
    } catch (e) {
      // Storage full or unavailable
    }
  }

  // ---------- Show Results ----------
  function showResults(payload, serverData) {
    var quizData = payload.quiz_data;

    // Hide signup, show results
    signupSection.style.display = 'none';
    resultsSection.style.display = 'block';
    resultsSection.classList.add('nc-section-visible-block');

    window.scrollTo({ top: 0, behavior: 'smooth' });

    // Animate sugar ring
    animateRing(quizData.estimated_daily_sugar || 0);

    // Populate stats
    var dailySugar = quizData.estimated_daily_sugar || 0;
    document.getElementById('results-sugar-grams').textContent = dailySugar;
    document.getElementById('results-daily-sugar').textContent = dailySugar + 'g';
    document.getElementById('results-weekly-sugar').textContent =
      (quizData.estimated_weekly_sugar || 0) + 'g';
    document.getElementById('results-yearly-sugar').textContent =
      (quizData.estimated_yearly_sugar_lbs || '0') + ' lbs';

    // Personalized title & subtitle
    var title = document.getElementById('results-title');
    var subtitle = document.getElementById('results-subtitle');

    if (dailySugar === 0) {
      title.textContent = payload.first_name + ", you're doing amazing!";
      subtitle.textContent =
        "Your drink choices are already low-sugar. Nightcap will make your evenings even better with functional ingredients for relaxation and sleep.";
    } else if (dailySugar <= 30) {
      title.textContent = payload.first_name + ", not bad — but there's room to improve";
      subtitle.textContent =
        "You're consuming about " + dailySugar + "g of sugar from drinks daily. That adds up to " +
        quizData.estimated_yearly_sugar_lbs + " lbs per year. Nightcap can help you get to zero.";
    } else if (dailySugar <= 80) {
      title.textContent = payload.first_name + ", your sugar intake might surprise you";
      subtitle.textContent =
        "At " + dailySugar + "g per day from drinks alone, you're consuming " +
        quizData.estimated_yearly_sugar_lbs +
        " lbs of sugar per year — just from beverages. Time for a swap.";
    } else {
      title.textContent = payload.first_name + ", let's talk about that sugar intake";
      subtitle.textContent =
        "You're getting roughly " + dailySugar + "g of sugar per day from drinks — that's " +
        quizData.estimated_yearly_sugar_lbs +
        " lbs per year. The good news? Nightcap is an easy swap with 0g sugar.";
    }

    // Personalized insight based on motivation + sleep
    var insightText = document.getElementById('results-insight-text');
    var insights = getPersonalizedInsight(quizData);
    insightText.textContent = insights;

    // Waitlist position
    var position = serverData.position || Math.floor(Math.random() * 500) + 2800;
    document.getElementById('results-position').textContent =
      position.toLocaleString();

    // SMS note
    var smsNote = document.getElementById('results-sms-note');
    if (payload.sms_consent && payload.phone) {
      smsNote.textContent =
        "We just texted " + maskPhone(payload.phone) + " with your personalized download link!";
    } else {
      smsNote.textContent = 'Check your email for your personalized download link!';
    }

    // App download button
    var downloadBtn = document.getElementById('download-app-btn');
    if (downloadBtn) {
      downloadBtn.addEventListener('click', function () {
        window.open(CONFIG.appDownloadUrl, '_blank');
      });
    }

    // Share button
    var shareBtn = document.getElementById('share-quiz-btn');
    if (shareBtn) {
      shareBtn.addEventListener('click', function () {
        if (navigator.share) {
          navigator.share({
            title: 'Nightcap Sugar Quiz',
            text: 'I just found out I consume ' + dailySugar + 'g of sugar per day from drinks. Take the quiz!',
            url: window.location.href,
          });
        } else {
          copyToClipboard(window.location.href);
          shareBtn.textContent = 'Link Copied!';
          setTimeout(function () {
            shareBtn.textContent = 'Share the Quiz';
          }, 2000);
        }
      });
    }
  }

  // ---------- Ring Animation ----------
  function animateRing(grams) {
    var ring = document.getElementById('results-ring');
    if (!ring) return;

    // Add gradient def if missing
    var svg = ring.closest('svg');
    if (svg && !svg.querySelector('#ring-gradient')) {
      var defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
      var gradient = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
      gradient.setAttribute('id', 'ring-gradient');
      gradient.innerHTML =
        '<stop offset="0%" stop-color="#7c3aed"/><stop offset="100%" stop-color="#06d6a0"/>';
      defs.appendChild(gradient);
      svg.insertBefore(defs, svg.firstChild);
    }

    // Circumference = 2 * π * r = 2 * 3.14159 * 54 ≈ 339.292
    var circumference = 339.292;
    // Max out at 200g for visual scale
    var percent = Math.min(grams / 200, 1);
    var offset = circumference * (1 - percent);

    setTimeout(function () {
      ring.style.strokeDashoffset = offset;
    }, 300);
  }

  // ---------- Personalized Insights ----------
  function getPersonalizedInsight(quizData) {
    var parts = [];

    // Sleep-based insight
    if (quizData.sleep_quality === 'terrible' || quizData.sleep_quality === 'poor') {
      parts.push(
        "Research shows that high sugar intake — especially in the evening — disrupts sleep quality and REM cycles."
      );
    }

    // Motivation-based insight
    var motivationInsights = {
      cut_sugar:
        "Switching your evening drink to Nightcap alone could eliminate " +
        (quizData.estimated_daily_sugar || 0) + "g of sugar from your daily intake.",
      sleep_better:
        "Nightcap contains magnesium, L-theanine, and chamomile — clinically-studied ingredients that promote deep, restful sleep.",
      healthier_habits:
        "Building one small habit — like swapping your evening drink — creates a ripple effect across your health.",
      relaxation:
        "Unlike alcohol or sugary drinks that spike and crash, Nightcap uses adaptogens to promote calm without the downsides.",
    };

    parts.push(
      motivationInsights[quizData.motivation] ||
        "Nightcap was designed to be the healthiest, tastiest evening drink you'll ever try."
    );

    // Sugar awareness
    if (quizData.checks_sugar === 'never' || quizData.checks_sugar === 'rarely') {
      parts.push(
        "Most people don't realize that a single \"healthy\" juice can have more sugar than a candy bar."
      );
    }

    return parts.join(' ');
  }

  // ---------- Helpers ----------
  function maskPhone(phone) {
    var digits = phone.replace(/\D/g, '');
    return '***-***-' + digits.slice(-4);
  }

  function copyToClipboard(text) {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text);
    } else {
      var textarea = document.createElement('textarea');
      textarea.value = text;
      textarea.style.position = 'fixed';
      textarea.style.left = '-9999px';
      document.body.appendChild(textarea);
      textarea.select();
      document.execCommand('copy');
      document.body.removeChild(textarea);
    }
  }
})();
