import { useState, useEffect, useRef } from "react";

const i18n = {
  en: { title: "What Did I Watch?", subtitle: "Describe a movie, TV show, cartoon, or anime in your own words\nand AI will find it for you", label: "DESCRIBE WHAT YOU REMEMBER", placeholder: "e.g. There was this cartoon I watched as a kid where kids had spinning tops that battled each other...", findBtn: "Find It", searching: "Searching...", examples: "Try an example:", chars: "characters", thinking: "AI is thinking...", thinkingSub: "Analyzing your description to find the best matches", found: "Here's what I found", match: "match", matches: "matches", noMatch: "Couldn't find a match", noMatchSub: "Try adding more details!", moreDetail: "Please write a bit more!", listening: "Listening... speak now", bestMatch: "BEST MATCH", noPoster: "No poster", pills: ["kids with spinning battle tops", "blue hedgehog collecting rings", "guy stuck in the same day over and over", "teenagers with notebooks that kill people", "small green alien teaches a farm boy", "fish looking for his son"] },
  es: { title: "\u00bfQu\u00e9 Vi?", subtitle: "Describe una pel\u00edcula, serie, caricatura o anime con tus propias palabras\ny la IA lo encontrar\u00e1 por ti", label: "DESCRIBE LO QUE RECUERDAS", placeholder: "ej. Hab\u00eda una caricatura donde los ni\u00f1os ten\u00edan trompos que peleaban...", findBtn: "Buscar", searching: "Buscando...", examples: "Prueba un ejemplo:", chars: "caracteres", thinking: "La IA est\u00e1 pensando...", thinkingSub: "Analizando tu descripci\u00f3n", found: "Esto es lo que encontr\u00e9", match: "resultado", matches: "resultados", noMatch: "No encontr\u00e9 coincidencias", noMatchSub: "\u00a1Intenta agregar m\u00e1s detalles!", moreDetail: "\u00a1Escribe un poco m\u00e1s!", listening: "Escuchando... habla ahora", bestMatch: "MEJOR RESULTADO", noPoster: "Sin p\u00f3ster", pills: ["ni\u00f1os con trompos de batalla", "erizo azul recogiendo anillos", "tipo atrapado en el mismo d\u00eda", "adolescentes con cuadernos que matan", "alien verde peque\u00f1o ense\u00f1a a un chico", "pez buscando a su hijo"] },
  ar: { title: "\u0634\u0648 \u0643\u0646\u062a \u0623\u062a\u0641\u0631\u062c\u061f", subtitle: "\u0648\u0635\u0641 \u0641\u064a\u0644\u0645 \u0623\u0648 \u0645\u0633\u0644\u0633\u0644 \u0623\u0648 \u0643\u0631\u062a\u0648\u0646 \u0623\u0648 \u0623\u0646\u0645\u064a \u0628\u0643\u0644\u0645\u0627\u062a\u0643\n\u0648\u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a \u0631\u062d \u064a\u0644\u0627\u0642\u064a\u0647 \u0644\u0643", label: "\u0648\u0635\u0641 \u0627\u0644\u0644\u064a \u062a\u062a\u0630\u0643\u0631\u0647", placeholder: "\u0645\u062b\u0644\u0627\u064b: \u0643\u0627\u0646 \u0641\u064a \u0643\u0631\u062a\u0648\u0646 \u0643\u0646\u062a \u0623\u062a\u0641\u0631\u062c \u0639\u0644\u064a\u0647 \u0641\u064a\u0647 \u0648\u0644\u0627\u062f \u0639\u0646\u062f\u0647\u0645 \u0628\u0644\u0627\u0628\u0644 \u0628\u062a\u062a\u0642\u0627\u062a\u0644...", findBtn: "\u0627\u0628\u062d\u062b", searching: "\u062c\u0627\u0631\u064a \u0627\u0644\u0628\u062d\u062b...", examples: "\u062c\u0631\u0628 \u0645\u062b\u0627\u0644:", chars: "\u062d\u0631\u0641", thinking: "\u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064a \u064a\u0641\u0643\u0631...", thinkingSub: "\u062c\u0627\u0631\u064a \u062a\u062d\u0644\u064a\u0644 \u0648\u0635\u0641\u0643", found: "\u0647\u0630\u0627 \u0627\u0644\u0644\u064a \u0644\u0642\u064a\u062a\u0647", match: "\u0646\u062a\u064a\u062c\u0629", matches: "\u0646\u062a\u0627\u0626\u062c", noMatch: "\u0645\u0627 \u0644\u0642\u064a\u062a \u0646\u062a\u0627\u0626\u062c", noMatchSub: "\u062d\u0627\u0648\u0644 \u062a\u0636\u064a\u0641 \u062a\u0641\u0627\u0635\u064a\u0644 \u0623\u0643\u062b\u0631!", moreDetail: "\u0627\u0643\u062a\u0628 \u0623\u0643\u062b\u0631 \u0634\u0648\u064a!", listening: "\u062c\u0627\u0631\u064a \u0627\u0644\u0627\u0633\u062a\u0645\u0627\u0639... \u062a\u0643\u0644\u0645 \u0627\u0644\u0622\u0646", bestMatch: "\u0623\u0641\u0636\u0644 \u0646\u062a\u064a\u062c\u0629", noPoster: "\u0628\u062f\u0648\u0646 \u0645\u0644\u0635\u0642", pills: ["\u0648\u0644\u0627\u062f \u0639\u0646\u062f\u0647\u0645 \u0628\u0644\u0627\u0628\u0644 \u0628\u062a\u062a\u0642\u0627\u062a\u0644", "\u0642\u0646\u0641\u0630 \u0623\u0632\u0631\u0642 \u064a\u062c\u0645\u0639 \u062d\u0644\u0642\u0627\u062a", "\u0648\u0627\u062d\u062f \u0639\u0627\u0644\u0642 \u0641\u064a \u0646\u0641\u0633 \u0627\u0644\u064a\u0648\u0645", "\u0645\u0631\u0627\u0647\u0642\u064a\u0646 \u0639\u0646\u062f\u0647\u0645 \u062f\u0641\u0627\u062a\u0631 \u062a\u0642\u062a\u0644", "\u0643\u0627\u0626\u0646 \u0641\u0636\u0627\u0626\u064a \u0623\u062e\u0636\u0631 \u064a\u0639\u0644\u0645 \u0648\u0644\u062f", "\u0633\u0645\u0643\u0629 \u062a\u062f\u0648\u0631 \u0639\u0644\u0649 \u0627\u0628\u0646\u0647\u0627"] },
  fa: { title: "\u0686\u06cc \u062f\u06cc\u062f\u0645\u061f", subtitle: "\u06cc\u0647 \u0641\u06cc\u0644\u0645\u060c \u0633\u0631\u06cc\u0627\u0644\u060c \u06a9\u0627\u0631\u062a\u0648\u0646 \u06cc\u0627 \u0627\u0646\u06cc\u0645\u0647 \u0631\u0648 \u0628\u0627 \u06a9\u0644\u0645\u0627\u062a \u062e\u0648\u062f\u062a \u062a\u0648\u0635\u06cc\u0641 \u06a9\u0646\n\u0648 \u0647\u0648\u0634 \u0645\u0635\u0646\u0648\u0639\u06cc \u067e\u06cc\u062f\u0627\u0634 \u0645\u06cc\u200c\u06a9\u0646\u0647", label: "\u0686\u06cc\u0632\u06cc \u06a9\u0647 \u06cc\u0627\u062f\u062a \u0645\u06cc\u0627\u062f \u0631\u0648 \u062a\u0648\u0635\u06cc\u0641 \u06a9\u0646", placeholder: "\u0645\u062b\u0644\u0627\u064b: \u06cc\u0647 \u06a9\u0627\u0631\u062a\u0648\u0646\u06cc \u0628\u0648\u062f \u0628\u0686\u06af\u06cc \u0645\u06cc\u200c\u062f\u06cc\u062f\u0645 \u06a9\u0647 \u0628\u0686\u0647\u200c\u0647\u0627 \u0641\u0631\u0641\u0631\u0647\u200c\u0647\u0627\u06cc\u06cc \u062f\u0627\u0634\u062a\u0646 \u06a9\u0647 \u0628\u0627 \u0647\u0645 \u0645\u0628\u0627\u0631\u0632\u0647 \u0645\u06cc\u200c\u06a9\u0631\u062f\u0646...", findBtn: "\u067e\u06cc\u062f\u0627 \u06a9\u0646", searching: "\u062f\u0631 \u062d\u0627\u0644 \u062c\u0633\u062a\u062c\u0648...", examples: "\u06cc\u0647 \u0645\u062b\u0627\u0644 \u0627\u0645\u062a\u062d\u0627\u0646 \u06a9\u0646:", chars: "\u062d\u0631\u0641", thinking: "\u0647\u0648\u0634 \u0645\u0635\u0646\u0648\u0639\u06cc \u062f\u0627\u0631\u0647 \u0641\u06a9\u0631 \u0645\u06cc\u200c\u06a9\u0646\u0647...", thinkingSub: "\u062f\u0631 \u062d\u0627\u0644 \u062a\u062d\u0644\u06cc\u0644 \u062a\u0648\u0635\u06cc\u0641 \u0634\u0645\u0627", found: "\u0627\u06cc\u0646 \u0686\u06cc\u0632\u06cc\u0647 \u06a9\u0647 \u067e\u06cc\u062f\u0627 \u06a9\u0631\u062f\u0645", match: "\u0646\u062a\u06cc\u062c\u0647", matches: "\u0646\u062a\u0627\u06cc\u062c", noMatch: "\u0646\u062a\u06cc\u062c\u0647\u200c\u0627\u06cc \u067e\u06cc\u062f\u0627 \u0646\u0634\u062f", noMatchSub: "\u062c\u0632\u0626\u06cc\u0627\u062a \u0628\u06cc\u0634\u062a\u0631\u06cc \u0627\u0636\u0627\u0641\u0647 \u06a9\u0646!", moreDetail: "\u0628\u06cc\u0634\u062a\u0631 \u0628\u0646\u0648\u06cc\u0633!", listening: "\u062f\u0631 \u062d\u0627\u0644 \u06af\u0648\u0634 \u062f\u0627\u062f\u0646...", bestMatch: "\u0628\u0647\u062a\u0631\u06cc\u0646 \u0646\u062a\u06cc\u062c\u0647", noPoster: "\u0628\u062f\u0648\u0646 \u067e\u0648\u0633\u062a\u0631", pills: ["\u0628\u0686\u0647\u200c\u0647\u0627 \u0628\u0627 \u0641\u0631\u0641\u0631\u0647\u200c\u0647\u0627\u06cc \u062c\u0646\u06af\u06cc", "\u062c\u0648\u062c\u0647 \u062a\u06cc\u063a\u06cc \u0622\u0628\u06cc \u06a9\u0647 \u062d\u0644\u0642\u0647 \u062c\u0645\u0639 \u0645\u06cc\u200c\u06a9\u0646\u0647", "\u06cc\u0627\u0631\u0648 \u06af\u06cc\u0631 \u06a9\u0631\u062f\u0647 \u062a\u0648\u06cc \u0647\u0645\u0648\u0646 \u0631\u0648\u0632", "\u0646\u0648\u062c\u0648\u0648\u0646\u0627 \u0628\u0627 \u062f\u0641\u062a\u0631\u0686\u0647\u200c\u0647\u0627\u06cc\u06cc \u06a9\u0647 \u0622\u062f\u0645 \u0645\u06cc\u200c\u06a9\u0634\u0646", "\u0645\u0648\u062c\u0648\u062f \u0641\u0636\u0627\u06cc\u06cc \u0633\u0628\u0632 \u06a9\u0648\u0686\u0648\u0644\u0648", "\u0645\u0627\u0647\u06cc \u06a9\u0647 \u062f\u0646\u0628\u0627\u0644 \u067e\u0633\u0631\u0634\u0647"] },
  ja: { title: "\u4f55\u3092\u89b3\u305f\uff1f", subtitle: "\u6620\u753b\u3001\u30c6\u30ec\u30d3\u756a\u7d44\u3001\u30a2\u30cb\u30e1\u3092\u81ea\u5206\u306e\u8a00\u8449\u3067\u8aac\u660e\u3057\u3066\u304f\u3060\u3055\u3044\nAI\u304c\u3042\u306a\u305f\u306e\u4ee3\u308f\u308a\u306b\u898b\u3064\u3051\u307e\u3059", label: "\u899a\u3048\u3066\u3044\u308b\u3053\u3068\u3092\u8aac\u660e\u3057\u3066\u304f\u3060\u3055\u3044", placeholder: "\u4f8b\uff1a\u5b50\u4f9b\u306e\u9803\u306b\u898b\u305f\u30a2\u30cb\u30e1\u3067\u3001\u5b50\u4f9b\u305f\u3061\u304c\u30b3\u30de\u3092\u4f7f\u3063\u3066\u6226\u3046\u756a\u7d44\u304c\u3042\u3063\u305f...", findBtn: "\u691c\u7d22", searching: "\u691c\u7d22\u4e2d...", examples: "\u4f8b\u3092\u8a66\u3057\u3066\u307f\u3066\u304f\u3060\u3055\u3044\uff1a", chars: "\u6587\u5b57", thinking: "AI\u304c\u8003\u3048\u3066\u3044\u307e\u3059...", thinkingSub: "\u6700\u9069\u306a\u7d50\u679c\u3092\u63a2\u3057\u3066\u3044\u307e\u3059", found: "\u898b\u3064\u304b\u3063\u305f\u7d50\u679c", match: "\u4ef6", matches: "\u4ef6", noMatch: "\u7d50\u679c\u304c\u898b\u3064\u304b\u308a\u307e\u305b\u3093\u3067\u3057\u305f", noMatchSub: "\u3082\u3046\u5c11\u3057\u8a73\u3057\u304f\u66f8\u3044\u3066\u307f\u3066\u304f\u3060\u3055\u3044\uff01", moreDetail: "\u3082\u3046\u5c11\u3057\u8a73\u3057\u304f\uff01", listening: "\u805e\u3044\u3066\u3044\u307e\u3059...", bestMatch: "\u30d9\u30b9\u30c8\u30de\u30c3\u30c1", noPoster: "\u30dd\u30b9\u30bf\u30fc\u306a\u3057", pills: ["\u56de\u8ee2\u3059\u308b\u30b3\u30de\u3067\u6226\u3046\u5b50\u4f9b\u305f\u3061", "\u30ea\u30f3\u30b0\u3092\u96c6\u3081\u308b\u9752\u3044\u30cf\u30ea\u30cd\u30ba\u30df", "\u540c\u3058\u65e5\u3092\u7e70\u308a\u8fd4\u3059\u7537", "\u4eba\u3092\u6bba\u3059\u30ce\u30fc\u30c8\u3092\u6301\u3064\u9ad8\u6821\u751f", "\u8fb2\u5bb6\u306e\u5c11\u5e74\u306b\u6559\u3048\u308b\u5c0f\u3055\u306a\u7dd1\u306e\u30a8\u30a4\u30ea\u30a2\u30f3", "\u606f\u5b50\u3092\u63a2\u3059\u9b5a"] },
};

const rtlLangs = ["ar", "fa"];
const typeEmoji = { movie: "\uD83C\uDFA5", tv: "\uD83D\uDCFA", cartoon: "\uD83D\uDD8D\uFE0F", anime: "\u26E9\uFE0F" };

const MOCK = {
  "kids with spinning battle tops": [
    { title: "Beyblade", year: 2001, type: "anime", confidence: "high", explanation: "This matches perfectly - Beyblade is about kids battling with spinning tops called Beyblades in stadiums.", rating: 7.2, overview: "A group of kids battle with high-tech spinning tops called Beyblades." },
    { title: "Beyblade Burst", year: 2016, type: "anime", confidence: "medium", explanation: "A newer version of the Beyblade franchise.", rating: 6.8, overview: "Next generation Beyblade battles with a burst mechanic." },
  ],
  "default": [
    { title: "Groundhog Day", year: 1993, type: "movie", confidence: "high", explanation: "The classic time loop movie where Bill Murray relives the same day over and over.", rating: 8.0, overview: "A weatherman finds himself living the same day over and over again." },
    { title: "Palm Springs", year: 2020, type: "movie", confidence: "medium", explanation: "A modern time loop romantic comedy.", rating: 7.4, overview: "Two wedding guests develop a romance while stuck in a time loop." },
  ],
};

const LANG_OPTIONS = [
  { code: "en", label: "English" }, { code: "es", label: "Espa\u00f1ol" },
  { code: "ar", label: "\u0627\u0644\u0639\u0631\u0628\u064a\u0629" }, { code: "fa", label: "\u0641\u0627\u0631\u0633\u06cc" },
  { code: "ja", label: "\u65e5\u672c\u8a9e" },
];

export default function WhatDidIWatch() {
  const [lang, setLang] = useState("en");
  const [query, setQuery] = useState("");
  const [results, setResults] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [recording, setRecording] = useState(false);

  const t = i18n[lang] || i18n.en;
  const isRtl = rtlLangs.includes(lang);

  const search = () => {
    if (!query.trim() || query.length < 10) { setError(t.moreDetail); return; }
    setLoading(true); setError(""); setResults(null);
    setTimeout(() => {
      const key = Object.keys(MOCK).find(k => query.toLowerCase().includes(k));
      setResults(MOCK[key] || MOCK["default"]);
      setLoading(false);
    }, 2000);
  };

  const fakeVoice = () => {
    if (recording) { setRecording(false); return; }
    setRecording(true);
    setTimeout(() => {
      setQuery(prev => prev + (prev ? " " : "") + t.pills[0]);
      setRecording(false);
    }, 2500);
  };

  return (
    <div dir={isRtl ? "rtl" : "ltr"} style={{ minHeight: "100vh", background: "#0a0a0f", color: "#f0f0f5", fontFamily: "'Inter', sans-serif", position: "relative", overflow: "hidden" }}>
      {/* BG orbs */}
      <div style={{ position: "fixed", top: -100, right: -100, width: 400, height: 400, borderRadius: "50%", background: "#8b5cf6", filter: "blur(80px)", opacity: 0.12 }} />
      <div style={{ position: "fixed", bottom: -50, left: -50, width: 300, height: 300, borderRadius: "50%", background: "#ec4899", filter: "blur(80px)", opacity: 0.1 }} />

      {/* Language picker */}
      <div style={{ position: "fixed", top: 20, [isRtl ? "left" : "right"]: 24, zIndex: 100, display: "flex", alignItems: "center", gap: 8 }}>
        <span style={{ fontSize: "1.2rem" }}>{"\uD83C\uDF0D"}</span>
        <select value={lang} onChange={e => setLang(e.target.value)} style={{
          background: "#12121a", color: "#f0f0f5", border: "1px solid #2a2a3a", borderRadius: 10,
          padding: "8px 14px", fontSize: "0.85rem", cursor: "pointer", outline: "none",
        }}>
          {LANG_OPTIONS.map(l => <option key={l.code} value={l.code}>{l.label}</option>)}
        </select>
      </div>

      <div style={{ position: "relative", zIndex: 1, maxWidth: 900, margin: "0 auto", padding: "40px 24px" }}>
        {/* Header */}
        <div style={{ textAlign: "center", marginBottom: 48 }}>
          <div style={{ width: 56, height: 56, margin: "0 auto 16px", background: "linear-gradient(135deg, #8b5cf6, #ec4899)", borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, boxShadow: "0 8px 32px rgba(139,92,246,0.3)" }}>{"\uD83C\uDFAC"}</div>
          <h1 style={{ fontFamily: "'Space Grotesk', sans-serif", fontSize: "2.5rem", fontWeight: 700, background: "linear-gradient(135deg, #8b5cf6, #ec4899)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>{t.title}</h1>
          <p style={{ color: "#9898a8", fontSize: "1.1rem", marginTop: 12, whiteSpace: "pre-line" }}>{t.subtitle}</p>
        </div>

        {/* Search */}
        <div style={{ background: "#12121a", border: "1px solid #2a2a3a", borderRadius: 20, padding: 24, marginBottom: 48 }}>
          <label style={{ display: "block", fontSize: "0.85rem", fontWeight: 600, color: "#a78bfa", letterSpacing: 1.5, marginBottom: 12 }}>{t.label}</label>
          <div style={{ position: "relative" }}>
            <textarea value={query} onChange={e => setQuery(e.target.value)} onKeyDown={e => { if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) search(); }} placeholder={t.placeholder} rows={4} style={{
              width: "100%", background: "transparent", border: "none", color: "#f0f0f5", fontFamily: "'Inter', sans-serif",
              fontSize: "1.05rem", lineHeight: 1.6, resize: "none", outline: "none", paddingRight: isRtl ? 0 : 50, paddingLeft: isRtl ? 50 : 0,
            }} />
            {/* Voice button */}
            <button onClick={fakeVoice} style={{
              position: "absolute", top: 8, [isRtl ? "left" : "right"]: 4, width: 42, height: 42, borderRadius: "50%",
              border: `2px solid ${recording ? "#ef4444" : "#2a2a3a"}`, background: recording ? "rgba(239,68,68,0.15)" : "#1a1a26",
              color: recording ? "#ef4444" : "#9898a8", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center",
              animation: recording ? "pulse 1.5s ease-in-out infinite" : "none",
            }}>
              {recording ? (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><rect x="6" y="6" width="12" height="12" rx="2"/></svg>
              ) : (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/><path d="M19 10v2a7 7 0 0 1-14 0v-2"/><line x1="12" y1="19" x2="12" y2="23"/><line x1="8" y1="23" x2="16" y2="23"/>
                </svg>
              )}
            </button>
          </div>
          {/* Voice status */}
          {recording && (
            <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "8px 16px", marginTop: 8, borderRadius: 10, fontSize: "0.82rem", background: "rgba(239,68,68,0.1)", color: "#fca5a5", border: "1px solid rgba(239,68,68,0.2)" }}>
              <div style={{ display: "flex", gap: 2, alignItems: "center", height: 16 }}>
                {[6,12,8,14,6].map((h,i) => <span key={i} style={{ display: "block", width: 3, height: h, background: "#ef4444", borderRadius: 3, animation: `wave 0.8s ease-in-out infinite ${i*0.1}s` }} />)}
              </div>
              <span>{t.listening}</span>
            </div>
          )}
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 16, paddingTop: 16, borderTop: "1px solid #2a2a3a", flexDirection: isRtl ? "row-reverse" : "row" }}>
            <span style={{ fontSize: "0.8rem", color: "#6b6b7b" }}>{query.length} {t.chars}</span>
            <button onClick={search} disabled={loading} style={{
              background: "linear-gradient(135deg, #8b5cf6, #ec4899)", color: "white", border: "none",
              padding: "12px 32px", borderRadius: 12, fontWeight: 600, fontSize: "1rem",
              cursor: loading ? "not-allowed" : "pointer", opacity: loading ? 0.6 : 1,
            }}>{loading ? t.searching : t.findBtn}</button>
          </div>
        </div>

        {/* Pills */}
        <div style={{ marginTop: -32, marginBottom: 40 }}>
          <div style={{ fontSize: "0.8rem", color: "#6b6b7b", marginBottom: 10 }}>{t.examples}</div>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            {t.pills.map(p => <button key={p} onClick={() => setQuery(p)} style={{ background: "#1a1a26", border: "1px solid #2a2a3a", color: "#9898a8", padding: "8px 16px", borderRadius: 100, fontSize: "0.85rem", cursor: "pointer" }}>{p}</button>)}
          </div>
        </div>

        {error && <div style={{ background: "rgba(239,68,68,0.1)", border: "1px solid rgba(239,68,68,0.3)", borderRadius: 16, padding: "16px 20px", color: "#fca5a5", marginBottom: 24, display: "flex", alignItems: "center", gap: 12 }}>{"\u26A0\uFE0F"} {error}</div>}

        {loading && (
          <div style={{ textAlign: "center", padding: "60px 24px" }}>
            <div style={{ display: "flex", justifyContent: "center", gap: 8, marginBottom: 24 }}>
              {[0,1,2].map(i => <div key={i} style={{ width: 12, height: 12, background: "#8b5cf6", borderRadius: "50%", animation: `bounce 1.4s ease-in-out infinite ${i*0.16}s` }} />)}
            </div>
            <div style={{ fontSize: "1.1rem", color: "#9898a8" }}>{t.thinking}</div>
            <div style={{ fontSize: "0.85rem", color: "#6b6b7b", marginTop: 8 }}>{t.thinkingSub}</div>
          </div>
        )}

        {results && (
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 24 }}>
              <h2 style={{ fontSize: "1.5rem", fontWeight: 600 }}>{t.found}</h2>
              <span style={{ background: "#8b5cf6", color: "white", fontSize: "0.75rem", fontWeight: 600, padding: "2px 10px", borderRadius: 100 }}>{results.length} {results.length === 1 ? t.match : t.matches}</span>
            </div>
            {results.map((m, i) => {
              const isBest = i === 0 && m.confidence === "high";
              const te = typeEmoji[m.type] || "\uD83C\uDFAC";
              return (
                <div key={i} style={{ background: "#1a1a26", border: `1px solid ${isBest ? "rgba(139,92,246,0.4)" : "#2a2a3a"}`, borderRadius: 20, marginBottom: 20, overflow: "hidden", position: "relative" }}>
                  {isBest && <div style={{ position: "absolute", top: 16, [isRtl ? "left" : "right"]: 16, background: "linear-gradient(135deg, #8b5cf6, #ec4899)", color: "white", fontSize: "0.65rem", fontWeight: 700, padding: "4px 12px", borderRadius: 100, letterSpacing: 1, zIndex: 2 }}>{"\uD83C\uDFAF"} {t.bestMatch}</div>}
                  <div style={{ padding: 24 }}>
                    <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 12, marginBottom: 8 }}>
                      <div style={{ fontSize: "1.35rem", fontWeight: 700 }}>{m.title}</div>
                      <span style={{ padding: "4px 12px", borderRadius: 100, fontSize: "0.7rem", fontWeight: 700, textTransform: "uppercase", flexShrink: 0,
                        background: m.confidence === "high" ? "rgba(34,197,94,0.15)" : m.confidence === "medium" ? "rgba(234,179,8,0.15)" : "rgba(239,68,68,0.15)",
                        color: m.confidence === "high" ? "#22c55e" : m.confidence === "medium" ? "#eab308" : "#ef4444",
                        border: `1px solid ${m.confidence === "high" ? "rgba(34,197,94,0.3)" : m.confidence === "medium" ? "rgba(234,179,8,0.3)" : "rgba(239,68,68,0.3)"}`,
                      }}>{m.confidence}</span>
                    </div>
                    <div style={{ display: "flex", gap: 12, marginBottom: 12, flexWrap: "wrap" }}>
                      <span style={{ background: "#12121a", border: "1px solid #2a2a3a", padding: "2px 10px", borderRadius: 6, fontSize: "0.75rem", fontWeight: 600, color: "#a78bfa", textTransform: "uppercase" }}>{te} {m.type}</span>
                      {m.year && <span style={{ fontSize: "0.8rem", color: "#9898a8" }}>{"\uD83D\uDCC5"} {m.year}</span>}
                      {m.rating && <span style={{ fontSize: "0.8rem", color: "#9898a8" }}>{"\u2B50"} {m.rating}/10</span>}
                    </div>
                    <div style={{ color: "#f0f0f5", fontSize: "0.95rem", lineHeight: 1.6, marginBottom: 12, padding: "12px 16px", background: "rgba(139,92,246,0.08)", borderRadius: 12, [isRtl ? "borderRight" : "borderLeft"]: "3px solid #8b5cf6" }}>{"\uD83D\uDCA1"} {m.explanation}</div>
                    {m.overview && <div style={{ color: "#9898a8", fontSize: "0.88rem", lineHeight: 1.6 }}>{m.overview}</div>}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <div style={{ textAlign: "center", padding: "40px 24px", color: "#6b6b7b", fontSize: "0.8rem" }}>Powered by Claude AI & TMDB</div>
      </div>

      <style>{`
        @keyframes bounce { 0%, 80%, 100% { transform: scale(0.6); opacity: 0.4; } 40% { transform: scale(1); opacity: 1; } }
        @keyframes wave { 0%, 100% { transform: scaleY(1); } 50% { transform: scaleY(1.8); } }
        @keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(239,68,68,0.4); } 70% { box-shadow: 0 0 0 12px rgba(239,68,68,0); } 100% { box-shadow: 0 0 0 0 rgba(239,68,68,0); } }
      `}</style>
    </div>
  );
}
