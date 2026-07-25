"use client";

import Script from "next/script";

export default function UnsentPage() {
  return (
    <>
      {/* Fonts + extracted stylesheet — hoisted into <head> automatically by Next.js */}
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
      <link
        href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;1,400&family=EB+Garamond:ital@0;1&display=swap"
        rel="stylesheet"
      />
      <link rel="stylesheet" href="/unsent/style.css" />

      <div className="app-logo" id="appLogo">
        <img
          src="/unsent/unsent_logo.jpeg"
          alt="UNSENT Logo"
          className="logo-img"
          onError={(e) => {
            e.currentTarget.style.display = "none";
          }}
        />
        <span className="logo-text">UNSENT</span>
        <span className="logo-tagline">WORDS THAT NEVER LEFT</span>
      </div>

      <div
        className="scene"
        id="scene-envelope"
        role="button"
        tabIndex={0}
        aria-label="Open the letter"
      >
        <div className="envelope-wrap">
          <div className="envelope-glow"></div>
          <div className="envelope-body"></div>
          <div className="envelope-flap"></div>
          <div className="wax-seal" id="waxSealHeart">
            <div className="seal-heart"></div>
          </div>
        </div>
        <div className="envelope-text">
          <p className="lead">Some words never found a place to go.</p>
          <p className="sub">Open when ready</p>
        </div>
      </div>

      <div className="letter-emerge" id="letterEmerge">
        <div className="crease one"></div>
        <div className="crease two"></div>
      </div>

      <div className="scene hidden" id="scene-letter">
        <div className="letter-sheet">
          <div className="rope-track"></div>
          <div id="ropeScrollbar"></div>

          <div className="letter-head-wrapper">
            <img
              src="/unsent/unsent_logo.jpeg"
              alt="symbol"
              className="letter-symbol-img"
            />
            <div className="letter-head">UNSENT</div>
          </div>
          <div className="letter-meta">
            <div className="letter-to">
              <span className="to-word">To</span>
              <input
                type="text"
                id="recipient"
                placeholder=""
                autoComplete="off"
              />
            </div>
          </div>

          <div className="textarea-wrapper">
            <textarea
              className="letter-body"
              id="letterBody"
              placeholder={`What stayed unsaid?

Write the thing you rehearsed but never spoke.
Write the apology. The anger. The goodbye.
The gratitude. The grief. The truth.

No one will interrupt.
No one will ask questions.
Just write.`}
            ></textarea>
            <div className="textarea-rope-track"></div>
            <div id="textareaRope"></div>
          </div>

          <div className="letter-footer">
            <p className="promise">
              This will be witnessed once.
              <br />
              Then forgotten.
            </p>
            <button className="seal-btn" id="sealBtn">
              SEND INTO THE DARK
            </button>
          </div>
        </div>
      </div>

      <div className="scene hidden" id="scene-witness">
        <div className="candle"></div>
        <div className="witness-label">The witness reads</div>
        <div className="listening" id="listening">
          listening&hellip;
        </div>
        <div className="witness-text" id="witnessText"></div>
        <div className="witness-after" id="witnessAfter">
          <div className="heard-line">You were heard.</div>
          <div className="dissolve-line" id="dissolveLine">
            Letter dissolving&hellip;
          </div>
          <div className="no-copy-line" id="noCopyLine">
            No copy was kept.
          </div>
        </div>
        <button className="write-again" id="writeAgainBtn">
          Write another
        </button>
      </div>

      {/* Original script, untouched, loaded once the DOM above exists */}
      <Script src="/unsent/script.js" strategy="afterInteractive" />
    </>
  );
}
