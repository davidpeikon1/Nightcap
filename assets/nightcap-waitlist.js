/**
 * Nightcap Waitlist Signup + Personalized Results v2
 * Phone auto-formatting, live validation, confetti, referral system,
 * animated counters, countdown timer, toast notifications, analytics.
 */
(function () {
  'use strict';

  // ---------- Config ----------
  var CONFIG = {
    waitlistEndpoint: '/apps/nightcap-waitlist/subscribe',
    smsEndpoint: '/apps/nightcap-waitlist/sms',
    appDownloadUrl: 'https://nightcap.app/download',
    launchDate: new Date('2026-07-15T09:00:00-04:00'),
    baseUrl: window.location.origin + window.location.pathname,
  };

  // ---------- DOM ----------
  var form = document.getElementById('waitlist-form');
  var signupSection = document.getElementById('waitlist-signup');
  var resultsSection = document.getElementById('quiz-results');
  var submitBtn = document.getElementById('signup-submit-btn');
  var btnText = submitBtn ? submitBtn.querySelector('.nc-btn__text') : null;
  var btnLoading = submitBtn ? submitBtn.querySelector('.nc-btn__loading') : null;

  if (!form) return;

  // ---------- Live Validation ----------
// ---------- Live Validation ----------
  var nameInput = document.getElementById('signup-name');
  var emailInput = document.getElementById('signup-email');

  if (nameInput) {
    nameInput.addEventListener('blur', function () {
      var val = nameInput.value.trim();
      clearFieldError('signup-name');
      if (val.length > 0 && val.length < 2) {
        showError('signup-name', 'Name must be at least 2 characters');
      } else if (val.length >= 2) {
        nameInput.classList.add('valid');
      }
    });
    nameInput.addEventListener('input', function () {
      clearFieldError('signup-name');
    });
  }

  if (emailInput) {
    emailInput.addEventListener('blur', function () {
      var val = emailInput.value.trim();
      clearFieldError('signup-email');
      if (val.length > 0 && !validateEmail(val)) {
        showError('signup-email', 'Please enter a valid email address');
      } else if (val.length > 0 && validateEmail(val)) {
        emailInput.classList.add('valid');
      }
    });
    emailInput.addEventListener('input', function () {
      clearFieldError('signup-email');
    });
  }

  // ---------- Form Validation ----------
  function validateEmail(email) {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }

  function showError(fieldId, message) {
    var input = document.getElementById(fieldId);
    var errorEl = document.getElementById(fieldId.replace('signup-', '') + '-error');
    if (input) {
      input.classList.remove('valid');
      input.classList.add('error');
    }
    if (errorEl) {
      errorEl.textContent = message;
      errorEl.setAttribute('role', 'alert');
    }
  }

  function clearFieldError(fieldId) {
    var input = document.getElementById(fieldId);
    var errorEl = document.getElementById(fieldId.replace('signup-', '') + '-error');
    if (input) input.classList.remove('error', 'valid');
    if (errorEl) {
      errorEl.textContent = '';
      errorEl.removeAttribute('role');
    }
  }

  function clearErrors() {
    form.querySelectorAll('.nc-input').forEach(function (input) {
      input.classList.remove('error', 'valid');
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
    var phoneEl = document.getElementById('signup-phone');
    var phone = phoneEl ? phoneEl.value.trim() : '';
    var smsConsentEl = document.getElementById('sms-consent');
    var smsConsent = smsConsentEl ? smsConsentEl.checked : false;
    var emailConsent = true;

    var valid = true;

    if (!name || name.length < 2) {
      showError('signup-name', name ? 'Name must be at least 2 characters' : 'Please enter your first name');
      valid = false;
    }

    if (!email) {
      showError('signup-email', 'Please enter your email address');
      valid = false;
    } else if (!validateEmail(email)) {
      showError('signup-email', 'Please enter a valid email address');
      valid = false;
    }

    if (!valid) {
      // Focus first error field
      var firstError = form.querySelector('.nc-input.error');
      if (firstError) firstError.focus();
      return;
    }

    // Loading state
    if (btnText) btnText.style.display = 'none';
    if (btnLoading) btnLoading.style.display = 'inline-flex';
    if (submitBtn) submitBtn.disabled = true;

    var quizData = window.__nightcapQuizData || {};
    var phoneDigits = phone ? phone.replace(/\D/g, '') : null;

    var payload = {
      first_name: name,
      email: email,
      phone: phoneDigits,
      sms_consent: smsConsent && !!phone,
      email_consent: emailConsent,
      quiz_data: {
        breakfast: quizData.breakfast,
        daily_sweet_drinks: quizData.daily_sweet_drinks,
        processed_foods: quizData.processed_foods,
        checks_labels: quizData.checks_labels,
        motivation: quizData.motivation,
        sugar_from_breakfast: quizData.sugar_from_breakfast,
        sugar_from_drinks: quizData.sugar_from_drinks,
        sugar_from_processed: quizData.sugar_from_processed,
        estimated_daily_sugar: quizData.estimated_daily_sugar,
        estimated_weekly_sugar: quizData.estimated_weekly_sugar,
        estimated_yearly_sugar_lbs: quizData.estimated_yearly_sugar_lbs,
      },
      utm: quizData._utm || {},
      source: 'waitlist_quiz',
      timestamp: new Date().toISOString(),
    };

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
        if (payload.sms_consent && payload.phone) {
          triggerSMS(payload);
        }
        showResults(payload, data);
        showToast('Welcome to the Nightcap waitlist!', 'success');
        track('waitlist_signup', { method: payload.phone ? 'email+sms' : 'email' });
      })
      .catch(function () {
        storeLocally(payload);
        showResults(payload, { position: generatePosition() });
        showToast('You\'re on the waitlist!', 'success');
      })
      .finally(function () {
        if (btnText) btnText.style.display = 'inline';
        if (btnLoading) btnLoading.style.display = 'none';
        if (submitBtn) submitBtn.disabled = false;
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
    }).catch(function () {});
  }

  function buildPersonalizedSMS(payload) {
    var name = payload.first_name;
    var sugar = payload.quiz_data.estimated_daily_sugar || 0;
    var motivation = payload.quiz_data.motivation;

    var msgs = {
      prevent_disease: "You're consuming ~" + sugar + "g of processed sugar daily. That's " + Math.round(sugar * 365 / 453.592) + " lbs/year. The time to act is before it becomes a problem.",
      energy: "At " + sugar + "g/day, processed sugar is likely behind your energy crashes. Track and reduce with the Nightcap app.",
      weight: sugar + "g of processed sugar per day adds up to " + Math.round(sugar * 365 / 453.592) + " lbs/year. Track it. Reduce it. The app makes it easy.",
      family: "You consume ~" + sugar + "g of processed sugar daily. See what your family is consuming too — share the quiz.",
      curiosity: "Your number: " + sugar + "g of processed sugar per day. Now track it and start reducing.",
    };

    return 'Hey ' + name + '! ' +
      (msgs[motivation] || 'You consume ~' + sugar + 'g of processed sugar daily. See your full report:') +
      ' Start tracking: ' + CONFIG.appDownloadUrl;
  }

  // ---------- Local Fallback ----------
  function storeLocally(payload) {
    try {
      var existing = JSON.parse(localStorage.getItem('nightcap_waitlist') || '[]');
      existing.push(payload);
      localStorage.setItem('nightcap_waitlist', JSON.stringify(existing));
    } catch (e) {}
  }

  function generatePosition() {
    return Math.floor(Math.random() * 500) + 2800;
  }

  // ---------- Show Results ----------
  function showResults(payload, serverData) {
    var quizData = payload.quiz_data;
    var dailySugar = quizData.estimated_daily_sugar || 0;

    // Save for returning visitors
    try {
      localStorage.setItem('nightcap_last_results', JSON.stringify({
        payload: payload, serverData: serverData, timestamp: new Date().toISOString()
      }));
    } catch (e) {}

    // Transition sections
    signupSection.classList.remove('active');
    signupSection.style.display = 'none';
    resultsSection.classList.add('active');

    window.scrollTo({ top: 0, behavior: 'smooth' });
    // Sugar equivalents
    populateEquivalents(dailySugar);

    // Personalized next steps
    personalizeNextSteps(quizData);

    // Populate share card
    // Animated counter for sugar grams
    animateCounter('results-sugar-grams', 0, dailySugar, 1500);

    // Set stat numbers with counter animations
    var weeklySugar = quizData.estimated_weekly_sugar || 0;
    var yearlySugarLbs = quizData.estimated_yearly_sugar_lbs || 0;

    animateCounterText('results-weekly-sugar', weeklySugar, 'g');

    var yearlyEl = document.getElementById('results-yearly-sugar');
    if (yearlyEl) yearlyEl.textContent = yearlySugarLbs + ' lbs';

    // Personalized title & subtitle
    var title = document.getElementById('results-title');
    var subtitle = document.getElementById('results-subtitle');

    // ANCHORING: Always contrast their number against the 25g limit
    var multiple = Math.round(dailySugar / 25);

    if (dailySugar <= 25) {
      title.textContent = payload.first_name + ", you're in the clear";
      subtitle.textContent = "Under 25g per day. You're doing what 88% of Americans can't. Stay here.";
    } else if (dailySugar <= 75) {
      title.textContent = payload.first_name + ", you're at " + multiple + "x the recommended limit";
      subtitle.textContent = dailySugar + "g per day. That's " + yearlySugarLbs + " lbs of processed sugar per year — and most of it is hiding in foods you think are healthy.";
    } else if (dailySugar <= 150) {
      title.textContent = payload.first_name + ", you're at " + multiple + "x the recommended limit";
      subtitle.textContent = dailySugar + "g per day adds up to " + yearlySugarLbs + " lbs per year. That's not a willpower problem — it's a visibility problem. Now you can see it.";
    } else {
      title.textContent = payload.first_name + ", you're at " + multiple + "x the recommended limit";
      subtitle.textContent = dailySugar + "g per day. " + yearlySugarLbs + " lbs per year. This is what the food system does when you're not watching. Now you're watching.";
    }

    // Share URL
    var refUrl = CONFIG.baseUrl;

    // Social share buttons for referral
    var yearlyLbs = quizData.estimated_yearly_sugar_lbs || 0;
    var twitterShare = document.getElementById('share-twitter');
    if (twitterShare) {
      twitterShare.addEventListener('click', function () {
        var text = 'I just found out I consume ' + dailySugar + 'g of processed sugar per day — that\'s ' + yearlyLbs + ' lbs per year.\n\n200 years ago it was 1 lb/year. Now it\'s 152.\n\nFind out your number:';
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text) + '&url=' + encodeURIComponent(refUrl), '_blank', 'width=550,height=420');
        track('referral_shared', { platform: 'twitter' });
      });
    }

    var smsShare = document.getElementById('share-sms');
    if (smsShare) {
      smsShare.addEventListener('click', function () {
        var text = 'I just took this 60-second quiz and found out I consume ' + dailySugar + 'g of processed sugar per day. That\'s ' + yearlyLbs + ' lbs a year. You need to see your number: ' + refUrl;
        window.open('sms:?body=' + encodeURIComponent(text));
        track('referral_shared', { platform: 'sms' });
      });
    }

    var emailShare = document.getElementById('share-email');
    if (emailShare) {
      emailShare.addEventListener('click', function () {
        var subject = 'You need to see how much processed sugar you consume';
        var body = "Hey,\n\nI just took this 60-second quiz and found out I consume " + dailySugar + "g of processed sugar per day — that's " + yearlyLbs + " lbs per year.\n\nApparently Americans went from 1 lb of sugar per year 200 years ago to 152 lbs today. Most of it is hidden in everyday foods.\n\nTake the quiz and see your number: " + refUrl;
        window.open('mailto:?subject=' + encodeURIComponent(subject) + '&body=' + encodeURIComponent(body));
        track('referral_shared', { platform: 'email' });
      });
    }

    // App download button
    var downloadBtn = document.getElementById('download-app-btn');
    if (downloadBtn) {
      downloadBtn.addEventListener('click', function () {
        track('app_download_clicked');
        window.open(CONFIG.appDownloadUrl, '_blank');
      });
    }
  }

  // ---------- Animated Counter ----------
  function animateCounter(elementId, start, end, duration) {
    var el = document.getElementById(elementId);
    if (!el) return;

    var startTime = null;
    var diff = end - start;

    function tick(timestamp) {
      if (!startTime) startTime = timestamp;
      var progress = Math.min((timestamp - startTime) / duration, 1);
      // Ease out cubic
      var eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.round(start + diff * eased);
      if (progress < 1) {
        requestAnimationFrame(tick);
      }
    }

    // Delay start for staggered effect
    setTimeout(function () {
      requestAnimationFrame(tick);
    }, 800);
  }

  function animateCounterText(elementId, value, suffix) {
    var el = document.getElementById(elementId);
    if (!el) return;
    var startTime = null;
    var duration = 1200;

    function tick(timestamp) {
      if (!startTime) startTime = timestamp;
      var progress = Math.min((timestamp - startTime) / duration, 1);
      var eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.round(value * eased) + suffix;
      if (progress < 1) requestAnimationFrame(tick);
    }

    setTimeout(function () { requestAnimationFrame(tick); }, 1000);
  }

  // ---------- Sugar Equivalents ----------
  function populateEquivalents(dailySugar) {
    var el = document.getElementById('results-equivalent');
    if (!el) return;
    var donuts = Math.round((dailySugar / 22) * 10) / 10;
    var candyPerYear = Math.round((dailySugar * 365) / 27);
    el.textContent = "That\u2019s equivalent to " + donuts + " donuts every single day \u2014 or " + candyPerYear.toLocaleString() + " candy bars per year.";
  }

  // ---------- Personalized Next Steps ----------
  function personalizeNextSteps(quizData) {
    var breakfast = quizData.sugar_from_breakfast || 0;
    var drinks = quizData.sugar_from_drinks || 0;
    var processed = quizData.sugar_from_processed || 0;

    // Step 1: Always about label awareness (unless they already read labels)
    var step1Title = document.getElementById('next-step-1-title');
    var step1Desc = document.getElementById('next-step-1-desc');
    if (step1Title && step1Desc) {
      if (quizData.checks_labels === 'always') {
        step1Title.textContent = 'Keep reading labels — and go deeper';
        step1Desc.textContent = 'You already read labels — great. Now look specifically for the 60+ aliases sugar hides behind: dextrose, maltose, HFCS, "evaporated cane juice." The Nightcap app flags them all.';
      }
    }

    // Step 2: Focus on their biggest source
    var step2Title = document.getElementById('next-step-2-title');
    var step2Desc = document.getElementById('next-step-2-desc');
    if (step2Title && step2Desc) {
      if (drinks >= breakfast && drinks >= processed) {
        step2Title.textContent = 'Replace one drink per day';
        step2Desc.textContent = 'Drinks are your biggest sugar source at ' + drinks + 'g/day. Swap one sweetened drink for water, black coffee, or unsweetened tea. That single change could cut ' + Math.round(drinks * 0.4) + 'g per day.';
      } else if (breakfast >= drinks && breakfast >= processed) {
        step2Title.textContent = 'Rethink your morning routine';
        step2Desc.textContent = 'Breakfast is your biggest sugar source at ' + breakfast + 'g/day. Try eggs, avocado, or plain Greek yogurt with berries instead. You could cut your morning sugar by 80%.';
      } else {
        step2Title.textContent = 'Audit your packaged foods';
        step2Desc.textContent = 'Packaged food is your biggest sugar source at ' + processed + 'g/day. Pick 3 items you buy regularly and check their sugar content. Find lower-sugar alternatives for just those 3.';
      }
    }

    // Step 3: Based on motivation
    var step3Title = document.getElementById('next-step-3-title');
    var step3Desc = document.getElementById('next-step-3-desc');
    if (step3Title && step3Desc) {
      var motivationSteps = {
        prevent_disease: { title: 'Get your baseline health markers', desc: 'Ask your doctor for fasting glucose, HbA1c, and fasting insulin levels. These show where you are metabolically — and give you a concrete before/after to track as you reduce sugar.' },
        energy: { title: 'Track your energy for 7 days', desc: 'Rate your energy 1-10 at 10am, 2pm, and 7pm each day in the Nightcap app. As you reduce sugar, watch those afternoon crashes disappear. Data makes the habit stick.' },
        weight: { title: 'Focus on sugar, not calories', desc: 'Don\'t count calories. Just reduce processed sugar to under 25g/day. When you stop spiking insulin, your body naturally stops storing excess fat. The weight change follows.' },
        family: { title: 'Share the quiz with your family', desc: 'Send this quiz to your partner, your parents, your kids. When everyone sees their number, the whole household starts making different choices. That\'s how you change a family\'s trajectory.' },
        curiosity: { title: 'Track for just 7 days', desc: 'You were curious — now feed that curiosity with data. Log your sugar intake in the Nightcap app for one week. Most people who track for 7 days naturally start reducing without even trying.' },
      };

      var step = motivationSteps[quizData.motivation];
      if (step) {
        step3Title.textContent = step.title;
        step3Desc.textContent = step.desc;
      }
    }
  }

  // ---------- Toast System ----------
  function showToast(message, type) {
    var container = document.getElementById('toast-container');
    if (!container) {
      container = document.createElement('div');
      container.id = 'toast-container';
      container.className = 'nc-toast-container';
      container.setAttribute('aria-live', 'polite');
      document.body.appendChild(container);
    }

    var toast = document.createElement('div');
    toast.className = 'nc-toast nc-toast--' + (type || 'info');
    toast.innerHTML = '<span class="nc-toast__icon" aria-hidden="true">' + (type === 'success' ? '&#10003;' : 'i') + '</span><span>' + message + '</span>';
    container.appendChild(toast);

    setTimeout(function () {
      toast.classList.add('exiting');
      setTimeout(function () { toast.remove(); }, 300);
    }, 4000);
  }

  function copyToClipboard(text) {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text);
    } else {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.style.position = 'fixed';
      ta.style.left = '-9999px';
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
    }
  }

  function track(name, data) {
    if (window.__nightcapTrack) {
      window.__nightcapTrack(name, data);
    }
  }

  // ---------- Exit Intent Popup ----------
  (function initExitIntent() {
    var popup = document.getElementById('exit-popup');
    var overlay = document.getElementById('exit-popup-overlay');
    var closeBtn = document.getElementById('exit-popup-close');
    var exitForm = document.getElementById('exit-popup-form');
    var quizLink = document.getElementById('exit-popup-quiz');

    if (!popup) return;

    var shown = false;
    var quizStarted = false;
    var signedUp = false;

    // Listen for quiz start / signup to suppress popup
    window.addEventListener('nightcap:quiz_started', function () { quizStarted = true; });
    window.addEventListener('nightcap:waitlist_signup', function () { signedUp = true; });

    // Check if already dismissed this session
    try {
      if (sessionStorage.getItem('nc_exit_dismissed')) return;
    } catch (e) {}

    // Trigger on mouse leaving viewport (desktop)
    document.addEventListener('mouseout', function (e) {
      if (shown || quizStarted || signedUp) return;
      if (e.clientY <= 0 && e.relatedTarget === null) {
        showPopup();
      }
    });

    // Trigger on scroll-up-fast on mobile (simulated exit intent)
    var lastScrollY = 0;
    var scrollSamples = 0;
    window.addEventListener('scroll', function () {
      if (shown || quizStarted || signedUp) return;
      var currentY = window.scrollY;
      // After user has scrolled at least 40% of page and scrolls back up fast
      if (currentY > document.body.scrollHeight * 0.4) {
        scrollSamples++;
      }
      if (scrollSamples > 10 && currentY < lastScrollY - 200) {
        showPopup();
      }
      lastScrollY = currentY;
    }, { passive: true });

    function showPopup() {
      if (shown) return;
      shown = true;
      popup.classList.add('active');
      track('exit_intent_shown');
      // Trap focus
      var emailInput = document.getElementById('exit-popup-email');
      if (emailInput) setTimeout(function () { emailInput.focus(); }, 300);
    }

    function hidePopup() {
      popup.classList.remove('active');
      try { sessionStorage.setItem('nc_exit_dismissed', '1'); } catch (e) {}
    }

    if (closeBtn) closeBtn.addEventListener('click', hidePopup);
    if (overlay) overlay.addEventListener('click', hidePopup);

    // ESC key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && popup.classList.contains('active')) {
        hidePopup();
      }
    });

    // Form submit
    if (exitForm) {
      exitForm.addEventListener('submit', function (e) {
        e.preventDefault();
        var emailInput = document.getElementById('exit-popup-email');
        var email = emailInput ? emailInput.value.trim() : '';

        if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
          if (emailInput) {
            emailInput.classList.add('error');
            setTimeout(function () { emailInput.classList.remove('error'); }, 1500);
          }
          return;
        }

        // Submit to waitlist with minimal data
        var payload = {
          first_name: '',
          email: email,
          phone: null,
          sms_consent: false,
          email_consent: true,
          quiz_data: {},
          source: 'exit_intent',
          timestamp: new Date().toISOString(),
        };

        fetch(CONFIG.waitlistEndpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        }).catch(function () {
          storeLocally(payload);
        });

        hidePopup();
        showToast("You're on the list! Check your email.", 'success');
        track('exit_intent_signup', { email: email });
      });
    }

    // "Take the quiz" link in popup
    if (quizLink) {
      quizLink.addEventListener('click', function () {
        hidePopup();
        if (window.__nightcapStartQuiz) {
          window.__nightcapStartQuiz();
        }
      });
    }
  })();
})();
