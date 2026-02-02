You **don’t need to set up a server** in the “running code” sense. Sparkle just needs:

* a **static URL** to an **appcast feed** (`appcast.xml`)
* static URLs to your **update archives** (`.zip` or `.dmg`)
* your app to be **signed/notarized**, and your updates to be **signed (Sparkle signatures)**

That static hosting can be **your website** (any static host) or **GitHub Releases + GitHub Pages**. Sparkle explicitly works off an appcast URL (`SUFeedURL`) and uses an embedded public EdDSA key (`SUPublicEDKey`) for verifying updates. ([Sparkle Project][1])

Below is an **agent-executable task breakdown** for adding Sparkle.

---

# Sparkle Integration Task Breakdown (Direct-download macOS app)

## SP-0 — Prereqs (you)

* [ ] Confirm your **Bundle ID is final** (changing it later breaks update continuity).
* [ ] Decide update artifact format:

  * [ ] **.zip** for Sparkle updates (very common)
  * [ ] keep **.dmg** for first-time install (optional for updates)

---

## SP-1 — Add Sparkle to the Xcode project (agent)

**Goal:** Sparkle.framework is in your app bundle.

Two common ways:

### Option A: Swift Package Manager (if available in your Xcode setup)

* [ ] Add package dependency pointing to Sparkle repo (Xcode → File → Add Packages…)
* [ ] Link Sparkle to your app target

### Option B: Framework integration (Sparkle docs show Carthage-based steps too)

* [ ] Follow Sparkle’s “Add Sparkle framework to your project” documentation path ([Sparkle Project][2])
* [ ] Ensure Sparkle.framework is copied into the app bundle

**Success criteria**

* App builds and runs with Sparkle linked.

---

## SP-2 — Configure Sparkle keys (agent)

**Goal:** your app can verify updates cryptographically.

* [ ] Generate EdDSA keypair using Sparkle’s tooling (`generate_keys`) ([Sparkle Project][1])
* [ ] Store **private key** securely (NOT in git; keep locally or in CI secrets)
* [ ] Add **public key** to your app (Info.plist):

  * `SUPublicEDKey` = base64 public key ([Sparkle Project][1])

**Success criteria**

* Public key is embedded in the built app.
* Private key is stored securely for signing releases.

---

## SP-3 — Set your appcast feed URL (agent)

**Goal:** Sparkle knows where to check for updates.

* [x] Feed URL location: GitHub repository `zaiderikat/solif-speech-to-text-updates`
* [x] Host the appcast in the repo under `releases/`
* [ ] Add to Info.plist:

  * `SUFeedURL` = `https://.../appcast.xml` ([Sparkle Project][1])

**Success criteria**

* App has a stable feed URL pointing to your published appcast.

---

## SP-4 — Add “Check for Updates…” + updater controller (agent)

**Goal:** you can trigger updates from the menubar, and optionally auto-check.

* [ ] Add `SPUStandardUpdaterController` initialization at app start (typical Sparkle pattern; Sparkle docs + examples reference this approach) ([GitHub][3])
* [ ] Menubar menu item:

  * “Check for Updates…” → call updater’s check method
* [x] Auto-check policy: ON by default (no user-facing toggle)

**Success criteria**

* Clicking “Check for Updates…” hits the feed and reports status.
* Update UI appears when a newer version exists.

---

## SP-5 — Hosting: appcast + update archives (chosen)

**You do NOT need a server.** You need **static hosting**.

### Option A (selected): GitHub Releases + GitHub repository path

* [x] Upload each release’s update archive (`Solif-1.0.1.zip`) to **GitHub Releases**
* [x] Host `appcast.xml` in repo path: `releases/appcast.xml`
* [x] Feed URL will be the raw GitHub URL:
  * `https://raw.githubusercontent.com/zaiderikat/solif-speech-to-text-updates/main/releases/appcast.xml`
* [x] Appcast `<enclosure url="...">` points to the GitHub Release asset download URL

If you don’t want to maintain appcast manually, you can use an automation service that generates appcasts from GitHub Releases (SparkleHub exists as a GitHub Marketplace app). ([GitHub][4])

### Option B: Your website (static files)

* [ ] Create `/downloads/` directory
* [ ] Upload:

  * update archives (`.zip`)
  * `appcast.xml`
  * release notes (optional)
* [ ] Keep `SUFeedURL` pointing to your domain’s `appcast.xml`

**Success criteria**

* `https://.../appcast.xml` is publicly reachable
* update archive URLs in the appcast are publicly reachable over HTTPS

---

## SP-6 — Release workflow: generate appcast + signatures (agent)

**Goal:** make updates “real”: publish new version, Sparkle sees it, installs it.

Sparkle recommends using `generate_appcast` which can create appcasts and correct signatures (and delta updates if you keep old versions). ([GitHub][3])

* [x] Create a `releases/` folder structure, e.g.:

  * `releases/archives/` → update zips
  * `releases/appcast/appcast.xml` → feed
* [ ] For each release:

  1. Build Release `.app`
  2. Package update archive (`ditto -c -k --keepParent Solif.app Solif-1.0.1.zip`)
  3. Run Sparkle tooling to generate/update `appcast.xml` and sign entries (`generate_appcast`) ([GitHub][3])
  4. Upload archive + updated appcast to hosting

**Success criteria**

* Appcast includes the new version entry with a valid signature.
* Sparkle detects the update.

---

## SP-7 — Signing + notarization alignment (agent)

Sparkle updates go much smoother if your app and shipped archives are properly signed and notarized. Apple recommends notarizing distributed macOS software. ([Apple Developer][5])

* [ ] Ensure your **installed app** is Developer ID signed + notarized
* [ ] Ensure update archives are produced from the signed build (and follow Sparkle signing)
* [ ] Test updates using a **standalone exported build** (not “Run from Xcode”)

**Success criteria**

* Update installs without Gatekeeper/permission surprises.

---

## SP-8 — Test plan (manual) (you)

* [ ] Install v1.0.0 from DMG
* [ ] Publish v1.0.1 update archive + appcast
* [ ] In v1.0.0: “Check for Updates…” → should find v1.0.1
* [ ] Update → app relaunches into v1.0.1
* [ ] Verify microphone/accessibility still works after update

---

# Direct answers to your questions

### Do I need to set up a server?

No. You just need **static hosting** for:

* `appcast.xml`
* update archives (`.zip`/`.dmg`)
  Sparkle reads `SUFeedURL` and downloads the archive from the URLs in that feed. ([Sparkle Project][1])

### GitHub vs website hosting?

* **GitHub Releases + repo-hosted appcast** = selected for this plan (appcast in `releases/appcast.xml`).
* **Website** = more control, cleaner URLs, same technical complexity (still static hosting).

---

* what URLs to put in `SUFeedURL` and the enclosure entries.

[1]: https://sparkle-project.org/documentation/customization/?utm_source=chatgpt.com "Customizing Sparkle"
[2]: https://sparkle-project.org/documentation/?utm_source=chatgpt.com "Documentation - Sparkle: open source software update ..."
[3]: https://github.com/sparkle-project/Sparkle?utm_source=chatgpt.com "sparkle-project/Sparkle: A software update framework for ..."
[4]: https://github.com/marketplace/sparklehub-appcast?utm_source=chatgpt.com "Sparklehub Appcast · GitHub Marketplace"
[5]: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution?utm_source=chatgpt.com "Notarizing macOS software before distributi
