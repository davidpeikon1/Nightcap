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

  // ---------- Countdown Timer ----------
  function initCountdown() {
    var container = document.getElementById('launch-countdown');
    if (!container) return;

    function update() {
      var now = new Date();
      var diff = CONFIG.launchDate - now;
      if (diff <= 0) {
        container.innerHTML = '<div class="nc-countdown__block"><span class="nc-countdown__number">Live!</span></div>';
        return;
      }

      var days = Math.floor(diff / 86400000);
      var hours = Math.floor((diff % 86400000) / 3600000);
      var minutes = Math.floor((diff % 3600000) / 60000);
      var seconds = Math.floor((diff % 60000) / 1000);

      var blocks = container.querySelectorAll('.nc-countdown__number');
      if (blocks.length === 4) {
        blocks[0].textContent = days;
        blocks[1].textContent = String(hours).padStart(2, '0');
        blocks[2].textContent = String(minutes).padStart(2, '0');
        blocks[3].textContent = String(seconds).padStart(2, '0');
      }
    }

    update();
    setInterval(update, 1000);
  }
  initCountdown();

  // ---------- Phone Auto-Format ----------
  var phoneInput = document.getElementById('signup-phone');
  if (phoneInput) {
    phoneInput.addEventListener('input', function (e) {
      var val = e.target.value.replace(/\D/g, '');
      if (val.length === 0) {
        e.target.value = '';
      } else if (val.length <= 3) {
        e.target.value = '(' + val;
      } else if (val.length <= 6) {
        e.target.value = '(' + val.slice(0, 3) + ') ' + val.slice(3);
      } else {
        e.target.value = '(' + val.slice(0, 3) + ') ' + val.slice(3, 6) + '-' + val.slice(6, 10);
      }
    });
  }

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

  if (phoneInput) {
    phoneInput.addEventListener('blur', function () {
      var val = phoneInput.value.trim();
      clearFieldError('signup-phone');
      if (val.length > 0 && !validatePhone(val)) {
        showError('signup-phone', 'Please enter a valid 10-digit phone number');
      } else if (val.length > 0 && validatePhone(val)) {
        phoneInput.classList.add('valid');
      }
    });
  }

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
    var phone = document.getElementById('signup-phone').value.trim();
    var smsConsent = document.getElementById('sms-consent').checked;
    var emailConsent = document.getElementById('email-consent').checked;

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

    if (phone && !validatePhone(phone)) {
      showError('signup-phone', 'Please enter a valid phone number');
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
        evening_drink: quizData.evening_drink,
        daily_sugary_drinks: quizData.daily_sugary_drinks,
        sleep_quality: quizData.sleep_quality,
        motivation: quizData.motivation,
        checks_sugar: quizData.checks_sugar,
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

  // ---------- Generate Referral Code ----------
  function generateReferralCode(email) {
    var hash = 0;
    for (var i = 0; i < email.length; i++) {
      hash = ((hash << 5) - hash) + email.charCodeAt(i);
      hash |= 0;
    }
    return 'NC' + Math.abs(hash).toString(36).toUpperCase().slice(0, 6);
  }

  function generatePosition() {
    return Math.floor(Math.random() * 500) + 2800;
  }

  // ---------- Show Results ----------
  function showResults(payload, serverData) {
    var quizData = payload.quiz_data;
    var dailySugar = quizData.estimated_daily_sugar || 0;

    // Transition sections
    signupSection.classList.remove('active');
    signupSection.style.display = 'none';
    resultsSection.classList.add('active');

    window.scrollTo({ top: 0, behavior: 'smooth' });

    // Fire confetti!
    setTimeout(fireConfetti, 400);

    // Animate ring with delay
    setTimeout(function () { animateRing(dailySugar); }, 600);

    // Animate comparison chart
    setTimeout(function () { animateComparisonChart(dailySugar); }, 1200);

    // Populate share card
    populateShareCard(quizData);

    // Animated counter for sugar grams
    animateCounter('results-sugar-grams', 0, dailySugar, 1500);

    // Set stat numbers with counter animations
    var weeklySugar = quizData.estimated_weekly_sugar || 0;
    var yearlySugarLbs = quizData.estimated_yearly_sugar_lbs || 0;

    animateCounterText('results-daily-sugar', dailySugar, 'g');
    animateCounterText('results-weekly-sugar', weeklySugar, 'g');

    var yearlyEl = document.getElementById('results-yearly-sugar');
    if (yearlyEl) yearlyEl.textContent = yearlySugarLbs + ' lbs';

    // Personalized title & subtitle
    var title = document.getElementById('results-title');
    var subtitle = document.getElementById('results-subtitle');

    if (dailySugar <= 25) {
      title.textContent = payload.first_name + ", you're ahead of the curve";
      subtitle.textContent = "At " + dailySugar + "g per day, you're well below the national average of 190g. You're already doing what most Americans haven't figured out yet. Keep going.";
    } else if (dailySugar <= 75) {
      title.textContent = payload.first_name + ", there's room to improve";
      subtitle.textContent = "You're consuming about " + dailySugar + "g of processed sugar daily — that's " + yearlySugarLbs + " lbs per year. Better than average, but still above the recommended 25g. The Nightcap app can help you close the gap.";
    } else if (dailySugar <= 150) {
      title.textContent = payload.first_name + ", this number might surprise you";
      subtitle.textContent = "At " + dailySugar + "g per day, you're consuming " + yearlySugarLbs + " lbs of processed sugar per year. That's " + Math.round(dailySugar / 25) + "x the recommended daily limit. The good news? Now you know — and that's the first step.";
    } else {
      title.textContent = payload.first_name + ", let's talk about your number";
      subtitle.textContent = "You're consuming roughly " + dailySugar + "g of processed sugar per day — " + yearlySugarLbs + " lbs per year. That's close to the national average that's driving the metabolic health crisis. But awareness is where change starts.";
    }

    // Insight
    var insightText = document.getElementById('results-insight-text');
    if (insightText) insightText.textContent = getPersonalizedInsight(quizData);

    // Position
    var position = serverData.position || generatePosition();
    var positionEl = document.getElementById('results-position');
    if (positionEl) positionEl.textContent = position.toLocaleString();

    // SMS note
    var smsNote = document.getElementById('results-sms-note');
    if (smsNote) {
      if (payload.sms_consent && payload.phone) {
        smsNote.textContent = "We just texted " + maskPhone(payload.phone) + " with a link to start tracking.";
      } else {
        smsNote.textContent = 'Check your email for your link to the Nightcap app.';
      }
    }

    // ---------- Referral System ----------
    var refCode = generateReferralCode(payload.email);
    var refUrl = CONFIG.baseUrl + '?ref=' + refCode;

    var refInput = document.getElementById('referral-url');
    if (refInput) refInput.value = refUrl;

    var refCopyBtn = document.getElementById('referral-copy-btn');
    if (refCopyBtn) {
      refCopyBtn.addEventListener('click', function () {
        copyToClipboard(refUrl);
        refCopyBtn.textContent = 'Copied!';
        showToast('Referral link copied!', 'success');
        setTimeout(function () { refCopyBtn.textContent = 'Copy'; }, 2000);
        track('referral_copied');
      });
    }

    // Social share buttons for referral
    var twitterShare = document.getElementById('share-twitter');
    if (twitterShare) {
      twitterShare.addEventListener('click', function () {
        var text = 'I just found out I consume ' + dailySugar + 'g of sugar per day just from drinks. Wild. Take the quiz:';
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text) + '&url=' + encodeURIComponent(refUrl), '_blank', 'width=550,height=420');
        track('referral_shared', { platform: 'twitter' });
      });
    }

    var smsShare = document.getElementById('share-sms');
    if (smsShare) {
      smsShare.addEventListener('click', function () {
        var text = 'Hey! I just took this sugar quiz and found out I drink ' + dailySugar + 'g of sugar per day. You should try it: ' + refUrl;
        window.open('sms:?body=' + encodeURIComponent(text));
        track('referral_shared', { platform: 'sms' });
      });
    }

    var emailShare = document.getElementById('share-email');
    if (emailShare) {
      emailShare.addEventListener('click', function () {
        var subject = 'You need to take this sugar quiz';
        var body = "Hey, I just found out I'm consuming " + dailySugar + "g of sugar per day just from drinks. It was a real wake-up call.\n\nTake the 60-second quiz: " + refUrl;
        window.open('mailto:?subject=' + encodeURIComponent(subject) + '&body=' + encodeURIComponent(body));
        track('referral_shared', { platform: 'email' });
      });
    }

    // Quiz share button (Web Share API)
    var shareBtn = document.getElementById('share-quiz-btn');
    if (shareBtn) {
      shareBtn.addEventListener('click', function () {
        if (navigator.share) {
          navigator.share({
            title: 'Nightcap Sugar Quiz',
            text: 'I just found out I consume ' + dailySugar + 'g of sugar per day from drinks. Take the quiz!',
            url: refUrl,
          });
        } else {
          copyToClipboard(refUrl);
          shareBtn.textContent = 'Link Copied!';
          setTimeout(function () { shareBtn.textContent = 'Share the Quiz'; }, 2000);
        }
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

  // ---------- Ring Animation ----------
  function animateRing(grams) {
    var ring = document.getElementById('results-ring');
    if (!ring) return;

    var svg = ring.closest('svg');
    if (svg && !svg.querySelector('#ring-gradient')) {
      var defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
      var gradient = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
      gradient.setAttribute('id', 'ring-gradient');
      gradient.innerHTML = '<stop offset="0%" stop-color="#C8B89A"/><stop offset="100%" stop-color="#A89878"/>';
      defs.appendChild(gradient);
      svg.insertBefore(defs, svg.firstChild);
    }

    var circumference = 339.292;
    var percent = Math.min(grams / 200, 1);
    var offset = circumference * (1 - percent);

    ring.style.strokeDashoffset = offset;
  }

  // ---------- Share Card ----------
  function populateShareCard(quizData) {
    var el = document.getElementById('share-card-sugar');
    if (el) el.textContent = (quizData.estimated_daily_sugar || 0) + 'g';

    var weeklyEl = document.getElementById('share-card-weekly');
    if (weeklyEl) weeklyEl.textContent = (quizData.estimated_weekly_sugar || 0) + 'g';

    var yearlyEl = document.getElementById('share-card-yearly');
    if (yearlyEl) yearlyEl.textContent = (quizData.estimated_yearly_sugar_lbs || 0) + ' lbs';

    // Save button — uses html2canvas if available, else prompts screenshot
    var saveBtn = document.getElementById('save-share-card');
    if (saveBtn) {
      saveBtn.addEventListener('click', function () {
        var cardInner = document.getElementById('share-card-inner');
        if (!cardInner) return;

        // Try html2canvas (if loaded externally)
        if (window.html2canvas) {
          window.html2canvas(cardInner, {
            backgroundColor: '#0a0a12',
            scale: 2,
          }).then(function (canvas) {
            var link = document.createElement('a');
            link.download = 'nightcap-sugar-results.png';
            link.href = canvas.toDataURL();
            link.click();
            track('share_card_saved', { method: 'html2canvas' });
          });
        } else {
          // Fallback: prompt user to screenshot
          cardInner.style.outline = '2px solid rgba(124, 58, 237, 0.5)';
          showToast('Long-press or screenshot this card to save!', 'success');
          setTimeout(function () {
            cardInner.style.outline = 'none';
          }, 3000);
          track('share_card_saved', { method: 'screenshot_prompt' });
        }
      });
    }
  }

  // ---------- Comparison Chart Animation ----------
  function animateComparisonChart(userGrams) {
    var maxGrams = 250; // scale max
    var avgGrams = 190; // average American daily processed sugar (152 lbs/year / 365 * 453g)

    var youBar = document.getElementById('compare-bar-you');
    var avgBar = document.querySelector('.nc-compare__bar--avg');
    var ncBar = document.querySelector('.nc-compare__bar--nc');
    var youValue = document.getElementById('compare-value-you');

    if (!youBar) return;

    // Set value text
    if (youValue) youValue.textContent = userGrams + 'g';

    // Animate bars
    var youPercent = Math.min((userGrams / maxGrams) * 100, 100);
    var avgPercent = Math.min((avgGrams / maxGrams) * 100, 100);
    var ncPercent = Math.min((25 / maxGrams) * 100, 100); // 25g recommended

    youBar.style.width = Math.max(youPercent, 3) + '%';
    if (avgBar) avgBar.style.width = avgPercent + '%';
    if (ncBar) ncBar.style.width = ncPercent + '%';
  }

  // ---------- Confetti ----------
  function fireConfetti() {
    var canvas = document.getElementById('confetti-canvas');
    if (!canvas) {
      canvas = document.createElement('canvas');
      canvas.id = 'confetti-canvas';
      canvas.className = 'nc-confetti-canvas';
      document.body.appendChild(canvas);
    }

    var ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    var particles = [];
    var colors = ['#C8B89A', '#D4C8AE', '#A89878', '#E8E0D0', '#8B7D6B', '#B0A48E', '#fff'];

    for (var i = 0; i < 150; i++) {
      particles.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height * -1,
        w: Math.random() * 8 + 4,
        h: Math.random() * 4 + 2,
        color: colors[Math.floor(Math.random() * colors.length)],
        vx: (Math.random() - 0.5) * 4,
        vy: Math.random() * 3 + 2,
        rotation: Math.random() * 360,
        rotationSpeed: (Math.random() - 0.5) * 10,
        opacity: 1,
      });
    }

    var frame = 0;
    var maxFrames = 180;

    function animate() {
      frame++;
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      particles.forEach(function (p) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.05;
        p.rotation += p.rotationSpeed;
        if (frame > maxFrames * 0.6) {
          p.opacity -= 0.02;
        }

        if (p.opacity <= 0) return;

        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate((p.rotation * Math.PI) / 180);
        ctx.globalAlpha = Math.max(0, p.opacity);
        ctx.fillStyle = p.color;
        ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
        ctx.restore();
      });

      if (frame < maxFrames) {
        requestAnimationFrame(animate);
      } else {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        canvas.remove();
      }
    }

    requestAnimationFrame(animate);
  }

  // ---------- Personalized Insights ----------
  function getPersonalizedInsight(quizData) {
    var parts = [];
    var daily = quizData.estimated_daily_sugar || 0;

    // Context on their number
    if (daily > 100) {
      parts.push("At " + daily + "g per day, you're consuming more processed sugar than 88% of health experts recommend as a maximum. This level is associated with increased risk of metabolic dysfunction, insulin resistance, and chronic inflammation.");
    } else if (daily > 50) {
      parts.push("200 years ago, your entire year's sugar intake would have been less than what you now consume in a week. That's not a willpower problem — it's an environment problem. And it's fixable.");
    }

    // Motivation-based insight
    var motivationInsights = {
      prevent_disease: "You're making the right move. 88% of Americans are already metabolically unhealthy, and processed sugar is the #1 driver. Acting now — before symptoms appear — is the most powerful thing you can do for your long-term health.",
      energy: "Blood sugar spikes from processed sugar cause the crashes, brain fog, and afternoon slumps most people accept as normal. Reducing your intake to under 25g/day can stabilize your energy within the first week.",
      weight: "Processed sugar drives fat storage through insulin spikes. Cutting " + daily + "g per day eliminates " + quizData.estimated_yearly_sugar_lbs + " lbs of sugar per year — that's a massive metabolic shift without counting a single calorie.",
      family: "Kids today consume more sugar by age 8 than adults did in an entire lifetime 200 years ago. By changing your own habits, you're changing what your family sees as normal. That's the most powerful intervention there is.",
      curiosity: "Now you know your number. Most people are surprised — and that surprise is the beginning of change. The Nightcap app helps you track and reduce from here.",
    };

    parts.push(motivationInsights[quizData.motivation] || "Awareness is the first step. Now that you know your number, you can start making changes that compound over time.");

    // Label awareness
    if (quizData.checks_labels === 'never' || quizData.checks_labels === 'rarely') {
      parts.push("Sugar goes by 60+ names on labels — dextrose, maltose, HFCS, \"evaporated cane juice.\" The Nightcap app helps you spot them all.");
    }

    return parts.join(' ');
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

  // ---------- Helpers ----------
  function maskPhone(phone) {
    var digits = String(phone).replace(/\D/g, '');
    return '***-***-' + digits.slice(-4);
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
