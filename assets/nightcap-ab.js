/**
 * Nightcap Lightweight A/B Testing
 *
 * Usage:
 *   <element data-ab-test="hero_headline"
 *            data-ab-a="Wind Down Without the Sugar Crash"
 *            data-ab-b="How Much Sugar Are You Really Drinking?">
 *
 * Assigns visitor to variant A or B (50/50), persists in localStorage.
 * Fires analytics event with variant assignment.
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'nc_ab_variants';

  function getVariants() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY)) || {};
    } catch (e) {
      return {};
    }
  }

  function saveVariants(variants) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(variants));
    } catch (e) {}
  }

  function assignVariant(testName) {
    var variants = getVariants();
    if (variants[testName]) return variants[testName];

    var variant = Math.random() < 0.5 ? 'a' : 'b';
    variants[testName] = variant;
    saveVariants(variants);

    // Track assignment
    if (window.__nightcapTrack) {
      window.__nightcapTrack('ab_assigned', { test: testName, variant: variant });
    }

    return variant;
  }

  function runTests() {
    var elements = document.querySelectorAll('[data-ab-test]');
    elements.forEach(function (el) {
      var testName = el.dataset.abTest;
      var variant = assignVariant(testName);
      var content = variant === 'a' ? el.dataset.abA : el.dataset.abB;
      if (content) {
        el.textContent = content;
      }
      el.dataset.abVariant = variant;
    });
  }

  // Run on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', runTests);
  } else {
    runTests();
  }

  // Expose for manual use
  window.__nightcapAB = {
    getVariant: function (testName) {
      return assignVariant(testName);
    },
    getAll: getVariants,
    reset: function () {
      try { localStorage.removeItem(STORAGE_KEY); } catch (e) {}
    },
  };
})();
