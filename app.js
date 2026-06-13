(() => {
  "use strict";

  const HADOU_2950_SECONDS = (29 * 60) + 50;
  const HADOU_2950_MINUTES = HADOU_2950_SECONDS / 60;
  const HADOU_2950_CARRIER_FREQUENCY = 200;
  const HADOU_2950_PULSE_TIMELINE = [
    { time: 0, rate: 3.79 },
    { time: 60, rate: 2.32 },
    { time: 2 * 60, rate: 8.32 },
    { time: 3 * 60, rate: 6.05 },
    { time: 4 * 60, rate: 9.25 },
    { time: 5 * 60, rate: 7.8 },
    { time: 10 * 60, rate: 5.63 },
    { time: 11 * 60, rate: 6.55 },
    { time: 12 * 60, rate: 8.83 },
    { time: 13 * 60, rate: 5.85 },
    { time: 14 * 60, rate: 2.68 },
    { time: 15 * 60, rate: 4.53 },
    { time: 16 * 60, rate: 10.65 },
    { time: 17 * 60, rate: 10.47 },
    { time: 18 * 60, rate: 2.5 },
    { time: 19 * 60, rate: 6.52 },
    { time: 20 * 60, rate: 2.32 },
    { time: 21 * 60, rate: 7.97 },
    { time: 22 * 60, rate: 2.35 },
    { time: 23 * 60, rate: 8.97 },
    { time: 24 * 60, rate: 10.65 },
    { time: 25 * 60, rate: 8.05 },
    { time: 26 * 60, rate: 8.83 },
    { time: 27 * 60, rate: 6.82 },
    { time: 28 * 60, rate: 7.58 },
    { time: 29 * 60, rate: 10.61 },
    { time: HADOU_2950_SECONDS, rate: 10.61 }
  ];

  const MODES = {
    focus: {
      name: "Focus",
      description: "作業・読書・デザイン作業向け",
      left: 200,
      right: 214,
      difference: 14,
      noise: "pink",
      toneVolume: 24,
      noiseVolume: 18
    },
    zone528: {
      name: "Zone 528",
      description: "528Hzをベースにした深い集中・ゾーン作業向け",
      left: 528,
      right: 542,
      difference: 14,
      noise: "pink",
      toneVolume: 14,
      noiseVolume: 16
    },
    relax: {
      name: "Relax",
      description: "休憩・ストレッチ・夜のリラックス向け",
      left: 200,
      right: 210,
      difference: 10,
      noise: "brown",
      toneVolume: 22,
      noiseVolume: 20
    },
    sleep: {
      name: "Sleep",
      description: "入眠・寝落ち向け",
      left: 200,
      right: 204,
      difference: 4,
      noise: "brown",
      toneVolume: 12,
      noiseVolume: 16
    },
    schumann: {
      name: "Schumann",
      description: "シューマン共振7.83Hzをイメージした瞑想・リラックス向け",
      left: 200,
      right: 207.83,
      difference: 7.83,
      noise: "brown",
      toneVolume: 20,
      noiseVolume: 18
    },
    hadou2950: {
      name: "ビジネス",
      description: "解析音声の00:00-29:50のトトト間隔を再現",
      left: HADOU_2950_CARRIER_FREQUENCY,
      right: HADOU_2950_CARRIER_FREQUENCY,
      difference: 0,
      pulseTimeline: HADOU_2950_PULSE_TIMELINE,
      durationSeconds: HADOU_2950_SECONDS,
      timerMinutes: HADOU_2950_MINUTES,
      noise: "pink",
      toneVolume: 10,
      noiseVolume: 14
    },
    noiseOnly: {
      name: "Noise Only",
      description: "周波数なしでノイズだけ流すモード",
      left: null,
      right: null,
      difference: null,
      noise: "pink",
      toneVolume: 0,
      noiseVolume: 34
    }
  };

  const TIMER_OPTIONS = [
    { label: "15分", minutes: 15 },
    { label: "29:50", minutes: HADOU_2950_MINUTES },
    { label: "30分", minutes: 30 },
    { label: "60分", minutes: 60 },
    { label: "90分", minutes: 90 },
    { label: "無制限", minutes: 0 }
  ];

  const STORAGE_KEY = "yoin-frequency-settings-v1";
  const MASTER_VOLUME_CURVE = 1.15;
  const TONE_GAIN_MAX = 0.08;
  const NOISE_GAIN_MAX = 0.13;
  const SPEAKER_MODULATION_BASE = 0.56;
  const SPEAKER_MODULATION_DEPTH = 0.18;
  const PULSE_GATE_BASE = 0.5;
  const PULSE_GATE_DEPTH = 0.45;
  const PULSE_GATE_SMOOTHING_HZ = 32;
  const NORMAL_FADE_SECONDS = 1.2;
  const TIMER_FADE_SECONDS = 5;

  const defaultState = {
    mode: "focus",
    layoutMode: "full",
    listeningMode: "headphones",
    masterVolume: 70,
    toneVolume: MODES.focus.toneVolume,
    noiseVolume: MODES.focus.noiseVolume,
    timerMinutes: 30,
    noiseType: MODES.focus.noise,
    isPlaying: false
  };

  let state = loadState();
  let audioContext = null;
  let graph = null;
  let timerInterval = null;
  let timerDeadline = null;
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
    secondaryFrequencyLabel: document.getElementById("secondaryFrequencyLabel"),
    differenceFrequencyLabel: document.getElementById("differenceFrequencyLabel"),
    leftFrequency: document.getElementById("leftFrequency"),
    rightFrequency: document.getElementById("rightFrequency"),
    differenceFrequency: document.getElementById("differenceFrequency"),
    noiseLabel: document.getElementById("noiseLabel"),
    playbackStatus: document.getElementById("playbackStatus"),
    headphoneStatus: document.getElementById("headphoneStatus"),
    headphonesModeButton: document.getElementById("headphonesModeButton"),
    speakerModeButton: document.getElementById("speakerModeButton"),
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
      const mode = MODES[saved.mode] ? saved.mode : defaultState.mode;
      const noiseType = ["pink", "brown", "mixed"].includes(saved.noiseType) ? saved.noiseType : MODES[mode].noise;

      return {
        ...defaultState,
        ...saved,
        mode,
        layoutMode: saved.layoutMode === "compact" ? "compact" : "full",
        listeningMode: saved.listeningMode === "speaker" ? "speaker" : "headphones",
        noiseType,
        masterVolume: clampNumber(saved.masterVolume, 0, 100, defaultState.masterVolume),
        toneVolume: clampNumber(saved.toneVolume, 0, 100, MODES[mode].toneVolume),
        noiseVolume: clampNumber(saved.noiseVolume, 0, 100, MODES[mode].noiseVolume),
        timerMinutes: TIMER_OPTIONS.some((item) => item.minutes === Number(saved.timerMinutes)) ? Number(saved.timerMinutes) : defaultState.timerMinutes,
        isPlaying: false
      };
    } catch {
      return { ...defaultState };
    }
  }

  function saveState() {
    const persisted = {
      mode: state.mode,
      layoutMode: state.layoutMode,
      listeningMode: state.listeningMode,
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

    elements.headphonesModeButton.addEventListener("click", () => {
      selectListeningMode("headphones");
    });

    elements.speakerModeButton.addEventListener("click", () => {
      selectListeningMode("speaker");
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

    elements.mixedNoiseButton.addEventListener("click", () => {
      selectNoiseType("mixed");
    });
  }

  function selectLayoutMode(layoutMode) {
    if (!["full", "compact"].includes(layoutMode) || state.layoutMode === layoutMode) {
      return;
    }

    state.layoutMode = layoutMode;
    saveState();
    applyLayoutToView();
  }

  async function selectListeningMode(listeningMode) {
    if (!["headphones", "speaker"].includes(listeningMode) || state.listeningMode === listeningMode) {
      return;
    }

    const wasPlaying = state.isPlaying || Boolean(graph);
    state.listeningMode = listeningMode;
    saveState();
    renderModeButtons();
    applyStateToView();

    if (wasPlaying) {
      await restartAudio();
    }
  }

  function renderModeButtons() {
    elements.modeGrid.innerHTML = "";

    Object.entries(MODES).forEach(([key, mode]) => {
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
    if (mode.difference === null) {
      return `${formatNoiseName(mode.noise)} noise`;
    }

    if (mode.pulseTimeline) {
      return `${formatHz(mode.left)} / pulse ${formatPulseRange(mode.pulseTimeline)} / ${formatDurationSeconds(mode.durationSeconds)}`;
    }

    if (state.listeningMode === "speaker") {
      return `${formatHz(mode.left)} mono / pulse ${formatHz(mode.difference)}`;
    }

    return `${formatHz(mode.left)} / ${formatHz(mode.right)} / diff ${formatHz(mode.difference)}`;
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
    state.toneVolume = MODES[modeKey].toneVolume;
    state.noiseVolume = MODES[modeKey].noiseVolume;
    state.noiseType = MODES[modeKey].noise;
    if (MODES[modeKey].timerMinutes) {
      state.timerMinutes = MODES[modeKey].timerMinutes;
    }
    saveState();
    applyStateToView();

    if (wasPlaying) {
      await restartAudio();
    }
  }

  async function selectNoiseType(noiseType) {
    if (!["pink", "brown", "mixed"].includes(noiseType)) {
      return;
    }

    if (noiseType === state.noiseType) {
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

      graph = createAudioGraph(context, mode);
      state.isPlaying = true;
      isStopping = false;
      startTimer();
      applyStateToView();

      const startAt = now + 0.03;
      graph.sources.forEach((source) => source.start(startAt));
      rampGain(graph.toneGain.gain, getToneGainValue(), now, 0.9);
      rampGain(graph.noiseGain.gain, getNoiseGainValue(), now, 0.9);
      rampGain(graph.masterGain.gain, 1, now, 1.4);
    } catch (error) {
      state.isPlaying = false;
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

  function createAudioGraph(context, mode) {
    const masterGain = context.createGain();
    const toneGain = context.createGain();
    const noiseGain = context.createGain();
    const sources = [];

    masterGain.gain.setValueAtTime(0, context.currentTime);
    toneGain.gain.setValueAtTime(0, context.currentTime);
    noiseGain.gain.setValueAtTime(0, context.currentTime);

    toneGain.connect(masterGain);
    noiseGain.connect(masterGain);
    masterGain.connect(context.destination);

    if (mode.left !== null && mode.right !== null && state.toneVolume > 0) {
      if (state.listeningMode === "speaker") {
        createSpeakerTone(context, mode, toneGain, sources);
      } else {
        createHeadphoneTone(context, mode, toneGain, sources);
      }
    }

    if (state.noiseVolume > 0) {
      const noiseSource = context.createBufferSource();
      noiseSource.buffer = createNoiseBuffer(context, state.noiseType);
      noiseSource.loop = true;
      noiseSource.connect(noiseGain);
      sources.push(noiseSource);
    }

    return {
      context,
      masterGain,
      toneGain,
      noiseGain,
      sources
    };
  }

  function createHeadphoneTone(context, mode, destination, sources) {
    const merger = context.createChannelMerger(2);
    const leftOscillator = context.createOscillator();
    const rightOscillator = context.createOscillator();
    const leftGain = context.createGain();
    const rightGain = context.createGain();

    leftOscillator.type = "sine";
    rightOscillator.type = "sine";
    leftOscillator.frequency.setValueAtTime(mode.left, context.currentTime);
    rightOscillator.frequency.setValueAtTime(mode.right, context.currentTime);
    leftGain.gain.setValueAtTime(1, context.currentTime);
    rightGain.gain.setValueAtTime(1, context.currentTime);

    if (mode.pulseTimeline) {
      applyPulseTimeline(context, [leftGain.gain, rightGain.gain], mode.pulseTimeline, sources);
    }

    leftOscillator.connect(leftGain);
    rightOscillator.connect(rightGain);
    leftGain.connect(merger, 0, 0);
    rightGain.connect(merger, 0, 1);
    merger.connect(destination);

    sources.push(leftOscillator, rightOscillator);
  }

  function createSpeakerTone(context, mode, destination, sources) {
    const carrier = context.createOscillator();
    const modulationGain = context.createGain();

    carrier.type = "sine";
    carrier.frequency.setValueAtTime(mode.left, context.currentTime);
    modulationGain.gain.setValueAtTime(SPEAKER_MODULATION_BASE, context.currentTime);

    if (mode.pulseTimeline) {
      modulationGain.gain.setValueAtTime(PULSE_GATE_BASE, context.currentTime);
      applyPulseTimeline(context, [modulationGain.gain], mode.pulseTimeline, sources);
    }

    carrier.connect(modulationGain);
    modulationGain.connect(destination);
    sources.push(carrier);

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

  function applyPulseTimeline(context, targets, timeline, sources) {
    const lfo = context.createOscillator();
    const lfoDepth = context.createGain();
    const lfoSmoother = context.createBiquadFilter();

    lfo.type = "square";
    schedulePulseTimeline(lfo.frequency, timeline, context.currentTime);
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

  function schedulePulseTimeline(param, timeline, now) {
    if (!timeline.length) {
      return;
    }

    param.cancelScheduledValues(now);
    param.setValueAtTime(timeline[0].rate, now);

    timeline.slice(1).forEach((point) => {
      param.linearRampToValueAtTime(point.rate, now + point.time);
    });
  }

  function cleanupGraph(targetGraph) {
    if (!targetGraph) {
      return;
    }

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

  function fillMixedNoise(data) {
    const pink = new Float32Array(data.length);
    const brown = new Float32Array(data.length);

    fillPinkNoise(pink);
    fillBrownNoise(brown);

    for (let i = 0; i < data.length; i += 1) {
      data[i] = clampSample((pink[i] + brown[i]) * 0.58);
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

  function applyStateToView() {
    const mode = MODES[state.mode];
    const isNoiseOnly = mode.left === null;
    const isSpeakerMode = state.listeningMode === "speaker";

    elements.body.classList.toggle("is-playing", state.isPlaying);
    elements.body.classList.toggle("is-speaker-mode", isSpeakerMode);
    elements.currentModeName.textContent = mode.name;
    elements.currentModeDescription.textContent = mode.description;

    if (mode.pulseTimeline) {
      elements.primaryFrequencyLabel.textContent = "Tone";
      elements.secondaryFrequencyLabel.textContent = "Output";
      elements.differenceFrequencyLabel.textContent = "Pulse";
      elements.leftFrequency.textContent = formatHz(mode.left);
      elements.rightFrequency.textContent = isSpeakerMode ? "Mono" : "L/R";
      elements.differenceFrequency.textContent = formatPulseRange(mode.pulseTimeline);
    } else {
      elements.primaryFrequencyLabel.textContent = isSpeakerMode ? "Tone" : "Left";
      elements.secondaryFrequencyLabel.textContent = isSpeakerMode ? "Output" : "Right";
      elements.differenceFrequencyLabel.textContent = isSpeakerMode ? "Pulse" : "Diff";
      elements.leftFrequency.textContent = isNoiseOnly ? "--" : formatHz(mode.left);
      elements.rightFrequency.textContent = isNoiseOnly ? "--" : isSpeakerMode ? "Mono" : formatHz(mode.right);
      elements.differenceFrequency.textContent = isNoiseOnly ? "--" : formatHz(mode.difference);
    }

    elements.noiseLabel.textContent = `${formatNoiseName(state.noiseType)} noise`;
    elements.playbackStatus.textContent = state.isPlaying ? "再生中" : isStopping ? "停止中" : "停止中";
    elements.headphoneStatus.textContent = isNoiseOnly
      ? "スピーカー可"
      : isSpeakerMode ? "スピーカー用" : "イヤホン用";
    elements.playButton.disabled = state.isPlaying || isStopping;
    elements.stopButton.disabled = (!state.isPlaying && !graph) || isStopping;
    elements.toneVolume.disabled = isNoiseOnly;

    document.querySelectorAll(".mode-button").forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.mode === state.mode));
    });

    [elements.pinkNoiseButton, elements.brownNoiseButton, elements.mixedNoiseButton].forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.noise === state.noiseType));
    });

    [elements.headphonesModeButton, elements.speakerModeButton].forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.listeningMode === state.listeningMode));
    });

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
    if (!timeline || !timeline.length) {
      return "--";
    }

    const rates = timeline.map((point) => point.rate);
    const min = Math.min(...rates);
    const max = Math.max(...rates);
    return `${formatNumber(min)}-${formatNumber(max)}Hz`;
  }

  function formatNumber(value) {
    return value.toFixed(2).replace(/0+$/, "").replace(/\.$/, "");
  }

  function formatDurationSeconds(seconds) {
    if (!seconds) {
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
    if (noiseType === "mixed") {
      return "Mixed";
    }
    return "Pink";
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
