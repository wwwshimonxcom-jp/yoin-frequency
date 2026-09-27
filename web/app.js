(() => {
  "use strict";

  const BUSINESS_DATA = window.YOIN_BUSINESS_DATA;
  if (!BUSINESS_DATA || !Array.isArray(BUSINESS_DATA.pulseLayers) || BUSINESS_DATA.pulseLayers.length !== 2) {
    throw new Error("Business two-layer analysis data is unavailable.");
  }
  const RAW_MENU_DATA = window.YOIN_RAW_MENU_DATA;
  const CREATIVE_RAW_DATA = RAW_MENU_DATA && RAW_MENU_DATA.creativeRaw;
  const THOUGHTS_RAW_DATA = RAW_MENU_DATA && RAW_MENU_DATA.thoughtsMakeThingsRaw;
  if (!CREATIVE_RAW_DATA || !Array.isArray(CREATIVE_RAW_DATA.pulseLayers) || CREATIVE_RAW_DATA.pulseLayers.length !== 2) {
    throw new Error("Creative two-layer analysis data is unavailable.");
  }
  if (!THOUGHTS_RAW_DATA || !Array.isArray(THOUGHTS_RAW_DATA.pulseLayers) || THOUGHTS_RAW_DATA.pulseLayers.length !== 2) {
    throw new Error("Thoughts make things two-layer analysis data is unavailable.");
  }

  const BUSINESS_SECONDS = BUSINESS_DATA.durationSeconds;
  const BUSINESS_PULSE_LAYERS = BUSINESS_DATA.pulseLayers;
  const BUSINESS_PULSE_TIMELINE = BUSINESS_PULSE_LAYERS[0].rateTimeline;
  const BUSINESS_PITCH_TIMELINE = BUSINESS_DATA.originalPitchTimeline;
  const CREATIVE_RAW_SECONDS = CREATIVE_RAW_DATA.durationSeconds;
  const CREATIVE_RAW_PULSE_LAYERS = CREATIVE_RAW_DATA.pulseLayers;
  const CREATIVE_RAW_PULSE_TIMELINE = CREATIVE_RAW_PULSE_LAYERS[0].rateTimeline;
  const CREATIVE_RAW_PITCH_TIMELINE = CREATIVE_RAW_DATA.originalPitchTimeline;
  const THOUGHTS_RAW_SECONDS = THOUGHTS_RAW_DATA.durationSeconds;
  const THOUGHTS_RAW_PULSE_LAYERS = THOUGHTS_RAW_DATA.pulseLayers;
  const THOUGHTS_RAW_PULSE_TIMELINE = THOUGHTS_RAW_PULSE_LAYERS[0].rateTimeline;
  const THOUGHTS_RAW_PITCH_TIMELINE = THOUGHTS_RAW_DATA.originalPitchTimeline;
  const DEFAULT_TONE_VOLUME = 50;
  const DEFAULT_NOISE_VOLUME = 0;

  const MODES = {
    focus: {
      name: "Focus",
      description: "作業・読書・デザイン作業向け",
      left: 200,
      right: 200,
      difference: 14,
      noise: "pink",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    zone528: {
      name: "Zone 528",
      description: "528Hzをベースにした深い集中・ゾーン作業向け",
      left: 528,
      right: 528,
      difference: 14,
      noise: "pink",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    relax: {
      name: "Relax",
      description: "休憩・ストレッチ・夜のリラックス向け",
      left: 200,
      right: 200,
      difference: 10,
      noise: "brown",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    sleep: {
      name: "Sleep",
      description: "入眠・寝落ち向け",
      left: 200,
      right: 200,
      difference: 4,
      noise: "brown",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    schumann: {
      name: "Schumann",
      description: "シューマン共振7.83Hzをイメージした瞑想・リラックス向け",
      left: 200,
      right: 200,
      difference: 7.83,
      noise: "brown",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    business: {
      name: "Business",
      description: "ビジネス能力の向上",
      left: BUSINESS_PITCH_TIMELINE[0].pitch,
      right: BUSINESS_PITCH_TIMELINE[0].pitch,
      difference: 0,
      pitchTimeline: BUSINESS_PITCH_TIMELINE,
      pulseTimeline: BUSINESS_PULSE_TIMELINE,
      pulseLayers: BUSINESS_PULSE_LAYERS,
      durationSeconds: BUSINESS_SECONDS,
      noise: "pink",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    creative: {
      name: "Creative",
      description: "クリエイティブ能力の向上",
      left: CREATIVE_RAW_PITCH_TIMELINE[0].pitch,
      right: CREATIVE_RAW_PITCH_TIMELINE[0].pitch,
      difference: 0,
      pitchTimeline: CREATIVE_RAW_PITCH_TIMELINE,
      pulseTimeline: CREATIVE_RAW_PULSE_TIMELINE,
      pulseLayers: CREATIVE_RAW_PULSE_LAYERS,
      durationSeconds: CREATIVE_RAW_SECONDS,
      noise: "pink",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    thoughtsMakeThings: {
      name: "Thoughts make things",
      description: "思考の現実化",
      left: THOUGHTS_RAW_PITCH_TIMELINE[0].pitch,
      right: THOUGHTS_RAW_PITCH_TIMELINE[0].pitch,
      difference: 0,
      pitchTimeline: THOUGHTS_RAW_PITCH_TIMELINE,
      pulseTimeline: THOUGHTS_RAW_PULSE_TIMELINE,
      pulseLayers: THOUGHTS_RAW_PULSE_LAYERS,
      durationSeconds: THOUGHTS_RAW_SECONDS,
      noise: "brown",
      toneVolume: DEFAULT_TONE_VOLUME,
      noiseVolume: DEFAULT_NOISE_VOLUME
    },
    noiseOnly: {
      name: "Noise Only",
      description: "周波数なしでノイズだけ流すモード",
      left: null,
      right: null,
      difference: null,
      noise: "pink",
      toneVolume: 0,
      noiseVolume: DEFAULT_NOISE_VOLUME
    }
  };

  const MODE_ALIASES = {
    hadou2950: "business",
    hadou2950Pitch: "business",
    businessRaw: "business",
    creativePitch: "creative",
    creativeRaw: "creative",
    thoughtsMakeThingsRaw: "thoughtsMakeThings"
  };

  const MODE_ORDER = [
    "business",
    "creative",
    "thoughtsMakeThings",
    "schumann",
    "zone528",
    "focus",
    "relax",
    "sleep",
    "noiseOnly"
  ];

  const TIMER_OPTIONS = [
    { label: "15分", minutes: 15 },
    { label: "20分", minutes: 20 },
    { label: "30分", minutes: 30 },
    { label: "60分", minutes: 60 },
    { label: "90分", minutes: 90 },
    { label: "無制限", minutes: 0 }
  ];

  const STORAGE_KEY = "yoin-frequency-settings-v1";
  const DEFAULTS_VERSION = 5;
  const MASTER_VOLUME_CURVE = 1.15;
  const TONE_GAIN_MAX = 0.104;
  const NOISE_GAIN_MAX = 0.169;
  const SPEAKER_MODULATION_BASE = 0.56;
  const SPEAKER_MODULATION_DEPTH = 0.18;
  const PULSE_GATE_BASE = 0.5;
  const PULSE_GATE_DEPTH = 0.45;
  const PULSE_GATE_SMOOTHING_HZ = 32;
  const PULSE_TIMELINE_LOOKAHEAD_CYCLES = 1;
  const NORMAL_FADE_SECONDS = 1.2;
  const TIMER_FADE_SECONDS = 5;

  const defaultState = {
    defaultsVersion: DEFAULTS_VERSION,
    mode: "focus",
    layoutMode: "full",
    masterVolume: 70,
    toneVolume: MODES.focus.toneVolume,
    noiseVolume: MODES.focus.noiseVolume,
    timerMinutes: 0,
    noiseType: MODES.focus.noise,
    isPlaying: false
  };

  let state = loadState();
  let audioContext = null;
  let graph = null;
  let timerInterval = null;
  let timerDeadline = null;
  let loopProgressInterval = null;
  let playbackStartedAt = null;
  let loopOffsetSeconds = 0;
  let isStopping = false;
  let restartToken = 0;

  const elements = {
    body: document.body,
    fullLayoutButton: document.getElementById("fullLayoutButton"),
    compactLayoutButton: document.getElementById("compactLayoutButton"),
    modeGrid: document.getElementById("modeGrid"),
    currentModeName: document.getElementById("currentModeName"),
    currentModeDescription: document.getElementById("currentModeDescription"),
    primaryFrequencyLabel: document.getElementById("primaryFrequencyLabel"),
    differenceFrequencyLabel: document.getElementById("differenceFrequencyLabel"),
    leftFrequency: document.getElementById("leftFrequency"),
    differenceFrequency: document.getElementById("differenceFrequency"),
    noiseLabel: document.getElementById("noiseLabel"),
    loopStatus: document.getElementById("loopStatus"),
    loopTime: document.getElementById("loopTime"),
    loopProgressSlider: document.getElementById("loopProgressSlider"),
    playbackStatus: document.getElementById("playbackStatus"),
    playButton: document.getElementById("playButton"),
    stopButton: document.getElementById("stopButton"),
    masterVolume: document.getElementById("masterVolume"),
    masterVolumeValue: document.getElementById("masterVolumeValue"),
    toneVolume: document.getElementById("toneVolume"),
    toneVolumeValue: document.getElementById("toneVolumeValue"),
    noiseVolume: document.getElementById("noiseVolume"),
    noiseVolumeValue: document.getElementById("noiseVolumeValue"),
    pinkNoiseButton: document.getElementById("pinkNoiseButton"),
    brownNoiseButton: document.getElementById("brownNoiseButton"),
    whiteNoiseButton: document.getElementById("whiteNoiseButton"),
    mixedNoiseButton: document.getElementById("mixedNoiseButton"),
    timerOptions: document.getElementById("timerOptions"),
    remainingTime: document.getElementById("remainingTime")
  };

  renderModeButtons();
  renderTimerButtons();
  bindEvents();
  applyStateToView();
  registerServiceWorker();

  function loadState() {
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "{}");
      const mode = normalizeModeKey(saved.mode) || defaultState.mode;
      const noiseType = isNoiseType(saved.noiseType) ? saved.noiseType : MODES[mode].noise;
      const shouldApplyUpdatedDefaults = (Number(saved.defaultsVersion) || 1) < DEFAULTS_VERSION;
      const savedTimerMinutes = TIMER_OPTIONS.some((item) => item.minutes === Number(saved.timerMinutes))
        ? Number(saved.timerMinutes)
        : defaultState.timerMinutes;
      const savedToneVolume = clampNumber(saved.toneVolume, 0, 100, MODES[mode].toneVolume);
      const savedNoiseVolume = clampNumber(saved.noiseVolume, 0, 100, MODES[mode].noiseVolume);

      return {
        ...defaultState,
        ...saved,
        defaultsVersion: DEFAULTS_VERSION,
        mode,
        layoutMode: saved.layoutMode === "compact" ? "compact" : "full",
        noiseType: shouldApplyUpdatedDefaults ? MODES[mode].noise : noiseType,
        masterVolume: clampNumber(saved.masterVolume, 0, 100, defaultState.masterVolume),
        toneVolume: shouldApplyUpdatedDefaults ? MODES[mode].toneVolume : savedToneVolume,
        noiseVolume: shouldApplyUpdatedDefaults ? MODES[mode].noiseVolume : savedNoiseVolume,
        timerMinutes: shouldApplyUpdatedDefaults ? defaultState.timerMinutes : savedTimerMinutes,
        isPlaying: false
      };
    } catch {
      return { ...defaultState };
    }
  }

  function saveState() {
    const persisted = {
      defaultsVersion: DEFAULTS_VERSION,
      mode: state.mode,
      layoutMode: state.layoutMode,
      masterVolume: state.masterVolume,
      toneVolume: state.toneVolume,
      noiseVolume: state.noiseVolume,
      timerMinutes: state.timerMinutes,
      noiseType: state.noiseType
    };
    localStorage.setItem(STORAGE_KEY, JSON.stringify(persisted));
  }

  function bindEvents() {
    elements.playButton.addEventListener("click", () => {
      startAudio();
    });

    elements.stopButton.addEventListener("click", () => {
      stopAudio(NORMAL_FADE_SECONDS);
    });

    elements.fullLayoutButton.addEventListener("click", () => {
      selectLayoutMode("full");
    });

    elements.compactLayoutButton.addEventListener("click", () => {
      selectLayoutMode("compact");
    });

    const handleMasterVolumeChange = (event) => {
      state.masterVolume = Number(event.target.value);
      saveState();
      applyVolumeToView();
      updateLiveGains();
    };

    elements.masterVolume.addEventListener("input", handleMasterVolumeChange);
    elements.masterVolume.addEventListener("change", handleMasterVolumeChange);

    const handleToneVolumeChange = (event) => {
      state.toneVolume = Number(event.target.value);
      saveState();
      applyVolumeToView();
      updateLiveGains();
    };

    elements.toneVolume.addEventListener("input", handleToneVolumeChange);
    elements.toneVolume.addEventListener("change", handleToneVolumeChange);

    const handleNoiseVolumeChange = (event) => {
      state.noiseVolume = Number(event.target.value);
      saveState();
      applyVolumeToView();
      updateLiveGains();
    };

    elements.noiseVolume.addEventListener("input", handleNoiseVolumeChange);
    elements.noiseVolume.addEventListener("change", handleNoiseVolumeChange);

    elements.pinkNoiseButton.addEventListener("click", () => {
      selectNoiseType("pink");
    });

    elements.brownNoiseButton.addEventListener("click", () => {
      selectNoiseType("brown");
    });

    elements.whiteNoiseButton.addEventListener("click", () => {
      selectNoiseType("white");
    });

    elements.mixedNoiseButton.addEventListener("click", () => {
      selectNoiseType("mixed");
    });

    elements.loopProgressSlider.addEventListener("input", handleLoopProgressInput);
    elements.loopProgressSlider.addEventListener("change", handleLoopProgressCommit);
  }

  function selectLayoutMode(layoutMode) {
    if (!["full", "compact"].includes(layoutMode) || state.layoutMode === layoutMode) {
      return;
    }

    state.layoutMode = layoutMode;
    saveState();
    applyLayoutToView();
  }

  function renderModeButtons() {
    elements.modeGrid.innerHTML = "";

    MODE_ORDER.forEach((key) => {
      const mode = MODES[key];
      const button = document.createElement("button");
      const frequencyLabel = getModeFrequencyLabel(mode);

      button.type = "button";
      button.className = "mode-button";
      button.dataset.mode = key;
      button.setAttribute("aria-pressed", "false");
      button.innerHTML = `<strong>${mode.name}</strong><span>${mode.description}<br>${frequencyLabel}</span>`;
      button.addEventListener("click", () => selectMode(key));
      elements.modeGrid.appendChild(button);
    });
  }

  function getModeFrequencyLabel(mode) {
    if (mode.left === null || mode.right === null) {
      return `${formatNoiseName(mode.noise)} noise`;
    }

    const toneLabel = mode.pitchTimeline ? `pitch ${formatPitchRange(mode.pitchTimeline)}` : formatHz(mode.left);
    const durationLabel = mode.durationSeconds ? ` / ${formatDurationSeconds(mode.durationSeconds)}` : "";
    return `${toneLabel} / pulse ${formatModePulseRange(mode)}${durationLabel}`;
  }

  function renderTimerButtons() {
    elements.timerOptions.innerHTML = "";

    TIMER_OPTIONS.forEach((option) => {
      const button = document.createElement("button");
      button.type = "button";
      button.dataset.minutes = String(option.minutes);
      button.setAttribute("aria-pressed", "false");
      button.textContent = option.label;
      button.addEventListener("click", () => {
        state.timerMinutes = option.minutes;
        saveState();
        if (state.isPlaying) {
          startTimer();
        }
        applyTimerToView();
      });
      elements.timerOptions.appendChild(button);
    });
  }

  async function selectMode(modeKey) {
    if (!MODES[modeKey] || modeKey === state.mode) {
      return;
    }

    const wasPlaying = state.isPlaying || Boolean(graph);
    state.mode = modeKey;
    loopOffsetSeconds = 0;
    state.toneVolume = MODES[modeKey].toneVolume;
    state.noiseVolume = MODES[modeKey].noiseVolume;
    state.noiseType = MODES[modeKey].noise;
    saveState();
    applyStateToView();

    if (wasPlaying) {
      await restartAudio();
    }
  }

  async function selectNoiseType(noiseType) {
    if (!isNoiseType(noiseType) || state.noiseType === noiseType) {
      return;
    }

    const wasPlaying = state.isPlaying || Boolean(graph);
    state.noiseType = noiseType;
    saveState();
    applyStateToView();

    if (wasPlaying) {
      await restartAudio();
    }
  }

  function handleLoopProgressInput(event) {
    const mode = MODES[state.mode];
    if (!mode.durationSeconds) {
      return;
    }

    loopOffsetSeconds = getLoopOffsetFromSlider(mode, event.target.value);
    playbackStartedAt = state.isPlaying ? Date.now() - (loopOffsetSeconds * 1000) : null;
    applyLoopProgressToView();
  }

  async function handleLoopProgressCommit(event) {
    const mode = MODES[state.mode];
    if (!mode.durationSeconds) {
      return;
    }

    loopOffsetSeconds = getLoopOffsetFromSlider(mode, event.target.value);
    playbackStartedAt = state.isPlaying ? Date.now() - (loopOffsetSeconds * 1000) : null;

    if (state.isPlaying || graph) {
      await restartAudio();
    } else {
      applyLoopProgressToView();
    }
  }

  async function restartAudio() {
    const token = ++restartToken;
    await stopAudio(0.45, { keepContext: true });
    if (token === restartToken) {
      await startAudio();
    }
  }

  async function startAudio() {
    if (state.isPlaying || graph || isStopping) {
      return;
    }

    try {
      const context = await getAudioContext();
      const now = context.currentTime;
      const mode = MODES[state.mode];

      graph = createAudioGraph(context, mode, loopOffsetSeconds);
      state.isPlaying = true;
      isStopping = false;
      startTimer();
      startLoopProgress();
      applyStateToView();

      const startAt = now + 0.03;
      graph.sources.forEach((source) => source.start(startAt));
      rampGain(graph.toneGain.gain, getToneGainValue(), now, 0.9);
      rampGain(graph.noiseGain.gain, getNoiseGainValue(), now, 0.9);
      rampGain(graph.masterGain.gain, 1, now, 1.4);
    } catch (error) {
      state.isPlaying = false;
      clearLoopProgress();
      cleanupGraph(graph);
      graph = null;
      applyStateToView();
      console.warn("YOIN frequency could not start audio.", error);
    }
  }

  async function stopAudio(fadeSeconds = NORMAL_FADE_SECONDS, options = {}) {
    if (isStopping) {
      return;
    }

    clearTimer();
    clearLoopProgress({ resetOffset: !options.keepContext });

    if (!graph) {
      state.isPlaying = false;
      applyStateToView();
      return;
    }

    isStopping = true;
    state.isPlaying = false;
    applyStateToView();

    const currentGraph = graph;
    graph = null;
    const context = currentGraph.context;
    const now = context.currentTime;
    const safeFade = Math.max(0.08, fadeSeconds);

    rampGain(currentGraph.masterGain.gain, 0, now, safeFade);
    rampGain(currentGraph.toneGain.gain, 0, now, safeFade);
    rampGain(currentGraph.noiseGain.gain, 0, now, safeFade);

    await wait((safeFade * 1000) + 80);

    cleanupGraph(currentGraph);
    isStopping = false;

    if (!options.keepContext && audioContext && audioContext.state === "running") {
      try {
        await audioContext.suspend();
      } catch {
        // Some mobile browsers may reject suspend during page lifecycle changes.
      }
    }

    applyStateToView();
  }

  async function getAudioContext() {
    const AudioContextConstructor = window.AudioContext || window.webkitAudioContext;

    if (!AudioContextConstructor) {
      throw new Error("Web Audio API is not supported in this browser.");
    }

    if (!audioContext) {
      audioContext = new AudioContextConstructor();
    }

    if (audioContext.state === "suspended") {
      await audioContext.resume();
    }

    return audioContext;
  }

  function createAudioGraph(context, mode, offsetSeconds = 0) {
    const masterGain = context.createGain();
    const toneGain = context.createGain();
    const noiseGain = context.createGain();
    const sources = [];
    const cleanupTasks = [];

    masterGain.gain.setValueAtTime(0, context.currentTime);
    toneGain.gain.setValueAtTime(0, context.currentTime);
    noiseGain.gain.setValueAtTime(0, context.currentTime);

    toneGain.connect(masterGain);
    noiseGain.connect(masterGain);
    masterGain.connect(context.destination);

    if (mode.left !== null && mode.right !== null && state.toneVolume > 0) {
      createSpeakerTone(context, mode, toneGain, sources, cleanupTasks, offsetSeconds);
    }

    const noiseSource = context.createBufferSource();
    noiseSource.buffer = createNoiseBuffer(context, state.noiseType);
    noiseSource.loop = true;
    noiseSource.connect(noiseGain);
    sources.push(noiseSource);

    return {
      context,
      masterGain,
      toneGain,
      noiseGain,
      sources,
      cleanupTasks
    };
  }

  function createSpeakerTone(context, mode, destination, sources, cleanupTasks, offsetSeconds = 0) {
    const carrier = context.createOscillator();

    carrier.type = "sine";
    carrier.frequency.setValueAtTime(mode.left, context.currentTime);

    if (mode.pitchTimeline) {
      applyPitchTimeline(context, [carrier.frequency], mode.pitchTimeline, cleanupTasks, offsetSeconds);
    }

    if (mode.pulseLayers) {
      mode.pulseLayers.forEach((layer) => {
        const pulseGain = context.createGain();
        const mixGain = context.createGain();

        applyPulseTimeline(context, [pulseGain.gain], layer.rateTimeline, sources, cleanupTasks, offsetSeconds);
        applyGainTimeline(context, [mixGain.gain], layer.gainTimeline, cleanupTasks, offsetSeconds);
        carrier.connect(pulseGain);
        pulseGain.connect(mixGain);
        mixGain.connect(destination);
      });
    } else {
      const modulationGain = context.createGain();

      modulationGain.gain.setValueAtTime(SPEAKER_MODULATION_BASE, context.currentTime);
      if (mode.pulseTimeline) {
        applyPulseTimeline(context, [modulationGain.gain], mode.pulseTimeline, sources, cleanupTasks, offsetSeconds);
      }

      carrier.connect(modulationGain);
      modulationGain.connect(destination);

      if (mode.difference > 0 && !mode.pulseTimeline) {
        const lfo = context.createOscillator();
        const lfoDepth = context.createGain();

        lfo.type = "sine";
        lfo.frequency.setValueAtTime(mode.difference, context.currentTime);
        lfoDepth.gain.setValueAtTime(SPEAKER_MODULATION_DEPTH, context.currentTime);
        lfo.connect(lfoDepth);
        lfoDepth.connect(modulationGain.gain);
        sources.push(lfo);
      }
    }

    sources.push(carrier);
  }

  function applyPitchTimeline(context, targets, timeline, cleanupTasks, offsetSeconds = 0) {
    targets.forEach((target) => {
      const cleanupSchedule = scheduleLoopingTimeline(target, timeline, context, offsetSeconds);
      cleanupTasks.push(cleanupSchedule);
    });
  }

  function applyGainTimeline(context, targets, timeline, cleanupTasks, offsetSeconds = 0) {
    targets.forEach((target) => {
      const cleanupSchedule = scheduleLoopingTimeline(target, timeline, context, offsetSeconds);
      cleanupTasks.push(cleanupSchedule);
    });
  }

  function applyPulseTimeline(context, targets, timeline, sources, cleanupTasks, offsetSeconds = 0) {
    const lfo = context.createOscillator();
    const lfoDepth = context.createGain();
    const lfoSmoother = context.createBiquadFilter();

    lfo.type = "square";
    const cleanupSchedule = scheduleLoopingTimeline(lfo.frequency, timeline, context, offsetSeconds);
    cleanupTasks.push(cleanupSchedule);
    lfoDepth.gain.setValueAtTime(PULSE_GATE_DEPTH, context.currentTime);
    lfoSmoother.type = "lowpass";
    lfoSmoother.frequency.setValueAtTime(PULSE_GATE_SMOOTHING_HZ, context.currentTime);

    targets.forEach((target) => {
      target.setValueAtTime(PULSE_GATE_BASE, context.currentTime);
      lfoSmoother.connect(target);
    });

    lfo.connect(lfoDepth);
    lfoDepth.connect(lfoSmoother);
    sources.push(lfo);
  }

  function scheduleLoopingTimeline(param, timeline, context, offsetSeconds = 0) {
    if (!timeline.length) {
      return () => {};
    }

    const duration = timeline[timeline.length - 1].time;
    const startTime = context.currentTime;
    const safeOffset = duration ? normalizeTimelineTime(offsetSeconds, duration) : 0;

    if (!duration) {
      param.cancelScheduledValues(startTime);
      param.setValueAtTime(getTimelinePointValue(timeline[0]), startTime);
      return () => {};
    }

    let scheduledCycle = -1;
    const scheduleAhead = () => {
      const elapsed = Math.max(0, context.currentTime - startTime) + safeOffset;
      const currentCycle = Math.floor(elapsed / duration);
      const targetCycle = currentCycle + PULSE_TIMELINE_LOOKAHEAD_CYCLES;

      for (let cycle = scheduledCycle + 1; cycle <= targetCycle; cycle += 1) {
        if (cycle === 0) {
          scheduleTimelineCycleFromOffset(param, timeline, startTime, safeOffset);
        } else {
          const cycleStartTime = startTime + ((cycle * duration) - safeOffset);
          scheduleTimelineCycle(param, timeline, cycleStartTime);
        }
      }

      scheduledCycle = Math.max(scheduledCycle, targetCycle);
    };

    param.cancelScheduledValues(startTime);
    scheduleAhead();

    const refreshMilliseconds = Math.min(Math.max((duration * 1000) / 2, 10000), 60000);
    const refreshTimer = window.setInterval(scheduleAhead, refreshMilliseconds);
    return () => window.clearInterval(refreshTimer);
  }

  function scheduleTimelineCycleFromOffset(param, timeline, startTime, offsetSeconds) {
    param.setValueAtTime(getTimelineValueAtTime(timeline, offsetSeconds), startTime);

    timeline
      .filter((point) => point.time > offsetSeconds)
      .forEach((point) => {
        param.linearRampToValueAtTime(getTimelinePointValue(point), startTime + (point.time - offsetSeconds));
      });
  }

  function scheduleTimelineCycle(param, timeline, startTime) {
    param.setValueAtTime(getTimelinePointValue(timeline[0]), startTime);

    timeline.slice(1).forEach((point) => {
      param.linearRampToValueAtTime(getTimelinePointValue(point), startTime + point.time);
    });
  }

  function getTimelinePointValue(point) {
    return point.rate ?? point.pitch ?? point.gain;
  }

  function getTimelineValueAtTime(timeline, time) {
    if (time <= timeline[0].time) {
      return getTimelinePointValue(timeline[0]);
    }

    for (let index = 1; index < timeline.length; index += 1) {
      const current = timeline[index];
      if (time <= current.time) {
        const previous = timeline[index - 1];
        const previousValue = getTimelinePointValue(previous);
        const currentValue = getTimelinePointValue(current);
        const segmentDuration = current.time - previous.time;
        const ratio = segmentDuration ? (time - previous.time) / segmentDuration : 0;
        return previousValue + ((currentValue - previousValue) * ratio);
      }
    }

    return getTimelinePointValue(timeline[timeline.length - 1]);
  }

  function normalizeTimelineTime(time, duration) {
    return ((time % duration) + duration) % duration;
  }

  function getLoopOffsetFromSlider(mode, sliderValue) {
    const durationSeconds = Math.max(1, mode.durationSeconds || 1);
    const normalized = clampNumber(sliderValue, 0, 1000, 0) / 1000;
    return durationSeconds * normalized;
  }

  function cleanupGraph(targetGraph) {
    if (!targetGraph) {
      return;
    }

    targetGraph.cleanupTasks.forEach((task) => {
      try {
        task();
      } catch {
        // Ignore cleanup races from quick UI changes.
      }
    });

    targetGraph.sources.forEach((source) => {
      try {
        source.stop();
      } catch {
        // Already stopped sources throw in some browsers.
      }
      try {
        source.disconnect();
      } catch {
        // Ignore disconnect races from quick UI changes.
      }
    });

    [targetGraph.toneGain, targetGraph.noiseGain, targetGraph.masterGain].forEach((node) => {
      try {
        node.disconnect();
      } catch {
        // Node may already be disconnected.
      }
    });
  }

  function createNoiseBuffer(context, noiseType) {
    const durationSeconds = 5;
    const length = Math.floor(context.sampleRate * durationSeconds);
    const buffer = context.createBuffer(2, length, context.sampleRate);

    for (let channel = 0; channel < buffer.numberOfChannels; channel += 1) {
      const data = buffer.getChannelData(channel);
      if (noiseType === "brown") {
        fillBrownNoise(data);
      } else if (noiseType === "white") {
        fillWhiteNoise(data);
      } else if (noiseType === "mixed") {
        fillMixedNoise(data);
      } else {
        fillPinkNoise(data);
      }
    }

    return buffer;
  }

  function fillPinkNoise(data) {
    let b0 = 0;
    let b1 = 0;
    let b2 = 0;
    let b3 = 0;
    let b4 = 0;
    let b5 = 0;
    let b6 = 0;

    for (let i = 0; i < data.length; i += 1) {
      const white = Math.random() * 2 - 1;
      b0 = 0.99886 * b0 + white * 0.0555179;
      b1 = 0.99332 * b1 + white * 0.0750759;
      b2 = 0.969 * b2 + white * 0.153852;
      b3 = 0.8665 * b3 + white * 0.3104856;
      b4 = 0.55 * b4 + white * 0.5329522;
      b5 = -0.7616 * b5 - white * 0.016898;
      data[i] = clampSample((b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.08);
      b6 = white * 0.115926;
    }
  }

  function fillBrownNoise(data) {
    let lastOut = 0;

    for (let i = 0; i < data.length; i += 1) {
      const white = Math.random() * 2 - 1;
      lastOut = (lastOut + (0.02 * white)) / 1.02;
      data[i] = clampSample(lastOut * 2.8);
    }
  }

  function fillWhiteNoise(data) {
    for (let i = 0; i < data.length; i += 1) {
      data[i] = clampSample((Math.random() * 2 - 1) * 0.42);
    }
  }

  function fillMixedNoise(data) {
    const pink = new Float32Array(data.length);
    const brown = new Float32Array(data.length);
    const white = new Float32Array(data.length);

    fillPinkNoise(pink);
    fillBrownNoise(brown);
    fillWhiteNoise(white);

    for (let i = 0; i < data.length; i += 1) {
      data[i] = clampSample((pink[i] + brown[i] + white[i]) * 0.42);
    }
  }

  function updateLiveGains() {
    if (!graph || !audioContext) {
      return;
    }

    const now = audioContext.currentTime;
    smoothGain(graph.masterGain.gain, 1, now);
    smoothGain(graph.toneGain.gain, getToneGainValue(), now);
    smoothGain(graph.noiseGain.gain, getNoiseGainValue(), now);
  }

  function rampGain(param, target, now, seconds) {
    holdGainAtCurrentTime(param, now);
    param.linearRampToValueAtTime(target, now + seconds);
  }

  function smoothGain(param, target, now) {
    holdGainAtCurrentTime(param, now);
    param.setTargetAtTime(target, now, 0.045);
  }

  function holdGainAtCurrentTime(param, now) {
    if (typeof param.cancelAndHoldAtTime === "function") {
      param.cancelAndHoldAtTime(now);
      return;
    }

    param.cancelScheduledValues(now);
    param.setValueAtTime(Math.max(0, param.value), now);
  }

  function getMasterVolumeScale() {
    const normalized = clampNumber(state.masterVolume, 0, 100, 0) / 100;
    return Math.pow(normalized, MASTER_VOLUME_CURVE);
  }

  function getToneGainValue() {
    if (MODES[state.mode].left === null) {
      return 0;
    }

    return scaleGain(state.toneVolume, TONE_GAIN_MAX) * getMasterVolumeScale();
  }

  function getNoiseGainValue() {
    return scaleGain(state.noiseVolume, NOISE_GAIN_MAX) * getMasterVolumeScale();
  }

  function scaleGain(value, maxGain) {
    const normalized = clampNumber(value, 0, 100, 0) / 100;
    return Math.pow(normalized, 1.35) * maxGain;
  }

  function startTimer() {
    clearTimer();

    if (!state.timerMinutes) {
      timerDeadline = null;
      applyTimerToView();
      return;
    }

    timerDeadline = Date.now() + (state.timerMinutes * 60 * 1000);
    applyTimerToView();
    timerInterval = window.setInterval(() => {
      const remaining = timerDeadline - Date.now();
      if (remaining <= 0) {
        elements.remainingTime.textContent = "終了中";
        stopAudio(TIMER_FADE_SECONDS);
        return;
      }
      elements.remainingTime.textContent = formatRemainingTime(remaining);
    }, 1000);
  }

  function clearTimer() {
    if (timerInterval) {
      window.clearInterval(timerInterval);
      timerInterval = null;
    }
    timerDeadline = null;
  }

  function startLoopProgress() {
    clearLoopProgress({ resetOffset: false });
    playbackStartedAt = Date.now() - (loopOffsetSeconds * 1000);
    applyLoopProgressToView();
    loopProgressInterval = window.setInterval(applyLoopProgressToView, 500);
  }

  function clearLoopProgress(options = {}) {
    if (loopProgressInterval) {
      window.clearInterval(loopProgressInterval);
      loopProgressInterval = null;
    }
    if (options.resetOffset) {
      loopOffsetSeconds = 0;
    }
    playbackStartedAt = null;
    applyLoopProgressToView();
  }

  function applyLoopProgressToView() {
    const mode = MODES[state.mode];
    if (!mode.durationSeconds) {
      elements.loopStatus.textContent = "通常再生";
      elements.loopTime.textContent = "--";
      elements.loopProgressSlider.value = "0";
      elements.loopProgressSlider.disabled = true;
      return;
    }

    const durationSeconds = Math.max(1, mode.durationSeconds);
    const elapsedSeconds = state.isPlaying && playbackStartedAt
      ? Math.max(0, (Date.now() - playbackStartedAt) / 1000)
      : loopOffsetSeconds;
    const cycleIndex = Math.floor(elapsedSeconds / durationSeconds) + 1;
    const cycleElapsed = elapsedSeconds % durationSeconds;
    const progress = Math.min(1, Math.max(0, cycleElapsed / durationSeconds));

    elements.loopStatus.textContent = `${cycleIndex}周目`;
    elements.loopTime.textContent = `${formatDurationSeconds(cycleElapsed)} / ${formatDurationSeconds(durationSeconds)}`;
    elements.loopProgressSlider.disabled = false;
    elements.loopProgressSlider.value = String(Math.round(progress * 1000));
  }

  function applyStateToView() {
    const mode = MODES[state.mode];
    const hasTone = mode.left !== null && mode.right !== null;

    elements.body.classList.toggle("is-playing", state.isPlaying);
    elements.currentModeName.textContent = mode.name;
    elements.currentModeDescription.textContent = mode.description;

    if (mode.pulseTimeline || mode.pulseLayers) {
      elements.primaryFrequencyLabel.textContent = mode.pitchTimeline ? "Pitch" : "Tone";
      elements.differenceFrequencyLabel.textContent = mode.pulseLayers ? `Pulse x${mode.pulseLayers.length}` : "Pulse";
      elements.leftFrequency.textContent = mode.pitchTimeline ? formatPitchRange(mode.pitchTimeline) : formatHz(mode.left);
      elements.differenceFrequency.textContent = formatModePulseRange(mode);
    } else {
      elements.primaryFrequencyLabel.textContent = "Tone";
      elements.differenceFrequencyLabel.textContent = "Pulse";
      elements.leftFrequency.textContent = hasTone ? formatHz(mode.left) : "--";
      elements.differenceFrequency.textContent = hasTone ? formatHz(mode.difference) : "--";
    }

    elements.noiseLabel.textContent = state.noiseVolume > 0 ? `${formatNoiseName(state.noiseType)} noise` : "Noise off";
    elements.playbackStatus.textContent = state.isPlaying ? "再生中" : isStopping ? "停止中" : "停止中";
    elements.playButton.disabled = state.isPlaying || isStopping;
    elements.stopButton.disabled = (!state.isPlaying && !graph) || isStopping;
    elements.toneVolume.disabled = !hasTone;

    document.querySelectorAll(".mode-button").forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.mode === state.mode));
    });

    document.querySelectorAll("[data-noise]").forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.noise === state.noiseType));
    });

    applyLoopProgressToView();
    applyVolumeToView();
    applyTimerToView();
    applyLayoutToView();
  }

  function applyLayoutToView() {
    const isCompact = state.layoutMode === "compact";

    elements.body.classList.toggle("is-compact-ui", isCompact);
    elements.fullLayoutButton.setAttribute("aria-pressed", String(!isCompact));
    elements.compactLayoutButton.setAttribute("aria-pressed", String(isCompact));
  }

  function applyVolumeToView() {
    elements.masterVolume.value = String(state.masterVolume);
    elements.toneVolume.value = String(state.toneVolume);
    elements.noiseVolume.value = String(state.noiseVolume);
    elements.masterVolumeValue.textContent = `${state.masterVolume}%`;
    elements.toneVolumeValue.textContent = `${state.toneVolume}%`;
    elements.noiseVolumeValue.textContent = `${state.noiseVolume}%`;
  }

  function applyTimerToView() {
    document.querySelectorAll("#timerOptions button").forEach((button) => {
      button.setAttribute("aria-pressed", String(Number(button.dataset.minutes) === state.timerMinutes));
    });

    if (timerDeadline) {
      elements.remainingTime.textContent = formatRemainingTime(timerDeadline - Date.now());
    } else if (!state.timerMinutes) {
      elements.remainingTime.textContent = "∞";
    } else {
      elements.remainingTime.textContent = formatRemainingTime(state.timerMinutes * 60 * 1000);
    }
  }

  function registerServiceWorker() {
    if (!("serviceWorker" in navigator)) {
      return;
    }

    window.addEventListener("load", () => {
      navigator.serviceWorker.register("./service-worker.js").catch(() => {
        // file:// previews and some private browsing modes do not allow service workers.
      });
    });
  }

  function formatHz(value) {
    if (value === null || value === undefined) {
      return "--";
    }

    const rounded = Number.isInteger(value) ? String(value) : value.toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
    return `${rounded}Hz`;
  }

  function formatPulseRange(timeline) {
    return formatTimelineRange(timeline, "rate");
  }

  function formatModePulseRange(mode) {
    if (!mode.pulseLayers) {
      if (mode.pulseTimeline) {
        return formatPulseRange(mode.pulseTimeline);
      }
      return formatHz(mode.difference);
    }

    return formatPulseRange(mode.pulseLayers.flatMap((layer) => layer.rateTimeline));
  }

  function formatPitchRange(timeline) {
    return formatTimelineRange(timeline, "pitch");
  }

  function formatTimelineRange(timeline, property) {
    if (!timeline || !timeline.length) {
      return "--";
    }

    const values = timeline.map((point) => point[property]);
    const min = Math.min(...values);
    const max = Math.max(...values);
    if (Math.abs(max - min) < 0.005) {
      return `${formatNumber((min + max) / 2)}Hz`;
    }
    return `${formatNumber(min)}-${formatNumber(max)}Hz`;
  }

  function formatNumber(value) {
    return value.toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
  }

  function formatDurationSeconds(seconds) {
    if (seconds === null || seconds === undefined) {
      return "--";
    }

    const safeSeconds = Math.max(0, Math.round(seconds));
    const minutes = Math.floor(safeSeconds / 60);
    const remainingSeconds = safeSeconds % 60;
    return `${String(minutes).padStart(2, "0")}:${String(remainingSeconds).padStart(2, "0")}`;
  }

  function formatNoiseName(noiseType) {
    if (noiseType === "brown") {
      return "Brown";
    }
    if (noiseType === "white") {
      return "White";
    }
    if (noiseType === "mixed") {
      return "Mixed";
    }
    return "Pink";
  }

  function normalizeModeKey(modeKey) {
    if (MODES[modeKey]) {
      return modeKey;
    }
    return MODE_ALIASES[modeKey] || null;
  }

  function isNoiseType(noiseType) {
    return ["pink", "brown", "white", "mixed"].includes(noiseType);
  }

  function formatRemainingTime(milliseconds) {
    const safeMilliseconds = Math.max(0, milliseconds);
    const totalSeconds = Math.ceil(safeMilliseconds / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
  }

  function clampNumber(value, min, max, fallback) {
    const numeric = Number(value);
    if (!Number.isFinite(numeric)) {
      return fallback;
    }
    return Math.min(max, Math.max(min, numeric));
  }

  function clampSample(value) {
    return Math.max(-1, Math.min(1, value));
  }

  function wait(milliseconds) {
    return new Promise((resolve) => {
      window.setTimeout(resolve, milliseconds);
    });
  }
})();
