/**
 * cmg-integration.js
 *
 * Everything needed to satisfy CoolmathGames' publishing requirements,
 * kept separate from the generated usagi.js runtime so that file never
 * has to be hand-edited (and re-diffed) when the emscripten build is
 * regenerated.
 *
 * Responsibilities:
 *   1. Show the CMG splash screen (cmg800x600.png) for a couple of
 *      seconds on load, before the game's own click-to-play overlay
 *      is shown. The splash is not clickable.
 *   2. Watch the game's stdout (via Module.print, which raylib/usagi's
 *      web build routes console output through) for the "PLAYING AD"
 *      marker that main.lua prints every 3rd death, and use it to
 *      trigger CMG's midroll ad API (cmgAdBreak()).
 *   3. Wire up the adBreakStart / adBreakComplete listeners to pause
 *      and resume the game+audio, and send the required
 *      cm_game_event postMessage calls for level start/replay.
 *
 * Load this script BEFORE usagi.js, and make sure `Module` already
 * exists (index.html declares `var Module = {...}` first) so our
 * Module.print hook is in place before the runtime boots.
 */
(function () {
  "use strict";

  var SPLASH_DURATION_MS = 2500;
  var SPLASH_IMAGE_URL = "cmg800x600.png";
  var AD_MARKER = "PLAYING AD";

  // ---------------------------------------------------------------
  // 1. Splash screen
  // ---------------------------------------------------------------

  function showSplash() {
    var splash = document.createElement("div");
    splash.id = "cmg-splash";
    splash.style.cssText = [
      "position:fixed",
      "inset:0",
      "z-index:1000",
      "background:#000",
      "display:flex",
      "align-items:center",
      "justify-content:center",
      "pointer-events:none", // explicitly non-clickable
    ].join(";");

    var img = document.createElement("img");
    img.src = SPLASH_IMAGE_URL;
    img.alt = "";
    img.style.cssText =
      "max-width:100%;max-height:100%;width:auto;height:auto;";
    splash.appendChild(img);

    // Hide the game's own UI underneath while the splash is up so
    // nothing (audio, overlay clicks) can happen behind it.
    document.documentElement.classList.add("cmg-splash-active");

    document.body.appendChild(splash);

    return new Promise(function (resolve) {
      setTimeout(function () {
        splash.remove();
        document.documentElement.classList.remove("cmg-splash-active");
        resolve();
      }, SPLASH_DURATION_MS);
    });
  }

  // Expose so index.html can gate loading the rest of the game on it.
  window.cmgShowSplash = showSplash;

  // ---------------------------------------------------------------
  // 2. Ad hook — watch Module.print for the "PLAYING AD" marker
  // ---------------------------------------------------------------

  window.Module = window.Module || {};
  var _prevPrint = window.Module["print"];

  window.Module["print"] = function (text) {
    try {
      var line = Array.prototype.slice
        .call(arguments)
        .join(" ");
      if (line.indexOf(AD_MARKER) !== -1) {
        triggerMidrollAd();
      }
    } catch (e) {
      // Never let ad-detection errors break normal stdout handling.
      console.error("cmg-integration: print hook error", e);
    }
    if (typeof _prevPrint === "function") {
      return _prevPrint.apply(this, arguments);
    }
    console.log.apply(console, arguments);
  };

  function triggerMidrollAd() {
    if (typeof window.cmgAdBreak === "function") {
      window.cmgAdBreak();
    } else {
      console.warn(
        "cmg-integration: cmgAdBreak() not found (cmg-ads.js not loaded?)",
      );
    }
  }

  // ---------------------------------------------------------------
  // 3. adBreakStart / adBreakComplete -> pause/resume game & audio
  // ---------------------------------------------------------------

  function pauseGameAndAudio() {
    if (window.Module && window.Module.audioContext) {
      var ctx = window.Module.audioContext;
      if (ctx.state === "running") ctx.suspend();
    }
    document.dispatchEvent(new CustomEvent("cmg-game-pause"));
  }

  function resumeGameAndAudio() {
    if (window.Module && window.Module.audioContext) {
      var ctx = window.Module.audioContext;
      if (ctx.state === "suspended") ctx.resume();
    }
    document.dispatchEvent(new CustomEvent("cmg-game-resume"));
  }

  document.addEventListener("adBreakStart", function () {
    console.log("AdBreak Started");
    pauseGameAndAudio();
  });

  document.addEventListener("adBreakComplete", function () {
    console.log("adBreak Complete");
    resumeGameAndAudio();
  });

  // ---------------------------------------------------------------
  // CMG level-start / replay events
  // ---------------------------------------------------------------
  // usagi has one continuous arena/level, so "level" is always 0;
  // call this once the play button is pressed / game (re)starts.

  window.cmgSendStartEvent = function (level) {
    window.parent.postMessage(
      {
        cm_game_event: true,
        cm_game_evt: "start",
        cm_game_lvl: level || 0,
      },
      "*",
    );
  };

  window.cmgSendReplayEvent = function (level) {
    window.parent.postMessage(
      {
        cm_game_event: true,
        cm_game_evt: "replay",
        cm_game_lvl: level || 0,
      },
      "*",
    );
  };
})();