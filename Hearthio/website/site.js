(() => {
  "use strict";

  const languageKey = "hearthio-site-language";
  const supportedLanguages = new Set(["zh", "en"]);
  const page = document.body.dataset.page || "home";
  let activeLanguage = "zh";

  const pageMetadata = {
    home: {
      zh: {
        title: "家务志 Hearthio — 家庭物品与保养记录",
        description:
          "家务志 Hearthio 是一款本地优先的家庭物品档案与保养记录 App：安排保养计划、按步骤执行、记录真实费用与照片，并在下一周期到来前提醒你。",
      },
      en: {
        title: "Hearthio — Home Inventory & Maintenance Journal",
        description:
          "A local-first home inventory and maintenance journal for plans, guided steps, actual costs, photos, and on-device reminders.",
      },
    },
    privacy: {
      zh: {
        title: "家务志 Hearthio 隐私政策",
        description:
          "了解家务志如何在设备本地处理物品档案、保养记录、照片、本地通知、导出与备份。",
      },
      en: {
        title: "Hearthio Privacy Policy",
        description:
          "Learn how Hearthio handles item archives, maintenance records, photos, local notifications, exports, and backups on your device.",
      },
    },
  };

  function getInitialLanguage() {
    const queryLanguage = new URLSearchParams(window.location.search).get("lang");
    if (supportedLanguages.has(queryLanguage)) return queryLanguage;

    try {
      const saved = window.localStorage.getItem(languageKey);
      if (supportedLanguages.has(saved)) return saved;
    } catch (_) {
      // The page remains usable when storage is unavailable.
    }

    return navigator.language.toLowerCase().startsWith("zh") ? "zh" : "en";
  }

  function updateInternalLinks(language) {
    document.querySelectorAll("[data-language-link]").forEach((link) => {
      const href = link.getAttribute("href");
      if (!href || href.startsWith("#") || href.startsWith("mailto:")) return;

      try {
        const url = new URL(href, window.location.href);
        const isLocalFile = url.protocol === "file:";
        const isSameOrigin = url.origin === window.location.origin;
        if (!isLocalFile && !isSameOrigin) return;
        url.searchParams.set("lang", language);
        link.href = url.href;
      } catch (_) {
        // Keep unsupported or malformed links unchanged.
      }
    });
  }

  function setLanguage(language, persist = true) {
    if (!supportedLanguages.has(language)) return;

    activeLanguage = language;
    document.documentElement.lang = language === "zh" ? "zh-CN" : "en";

    document.querySelectorAll("[data-zh][data-en]").forEach((element) => {
      element.textContent = element.dataset[language];
    });

    document.querySelectorAll("[data-alt-zh][data-alt-en]").forEach((element) => {
      element.setAttribute("alt", element.dataset[`alt${language === "zh" ? "Zh" : "En"}`]);
    });

    document.querySelectorAll("[data-aria-zh][data-aria-en]").forEach((element) => {
      element.setAttribute(
        "aria-label",
        element.dataset[`aria${language === "zh" ? "Zh" : "En"}`],
      );
    });

    document.querySelectorAll("[data-lang-choice]").forEach((button) => {
      button.setAttribute(
        "aria-pressed",
        String(button.dataset.langChoice === language),
      );
    });

    document.querySelectorAll("[data-policy-language]").forEach((block) => {
      block.hidden = block.dataset.policyLanguage !== language;
    });

    const metadata = pageMetadata[page]?.[language];
    if (metadata) {
      document.title = metadata.title;
      const description = document.querySelector('meta[name="description"]');
      if (description) description.content = metadata.description;
    }

    updateInternalLinks(language);

    if (persist) {
      try {
        window.localStorage.setItem(languageKey, language);
      } catch (_) {
        // The selected language still applies to the current page.
      }
    }
  }

  setLanguage(getInitialLanguage(), false);

  document.querySelectorAll("[data-lang-choice]").forEach((button) => {
    button.addEventListener("click", () => setLanguage(button.dataset.langChoice));
  });

  document.querySelectorAll("[data-current-year]").forEach((element) => {
    element.textContent = String(new Date().getFullYear());
  });

  const header = document.querySelector("[data-header]");
  const updateHeader = () => {
    if (!header || page === "privacy") return;
    header.classList.toggle("is-scrolled", window.scrollY > 18);
  };
  updateHeader();
  window.addEventListener("scroll", updateHeader, { passive: true });

  const menuButton = document.querySelector("[data-menu-button]");
  const navigation = document.querySelector("[data-nav]");

  function closeMenu() {
    menuButton?.setAttribute("aria-expanded", "false");
    navigation?.classList.remove("is-open");
    document.body.classList.remove("menu-open");
  }

  menuButton?.addEventListener("click", () => {
    const willOpen = menuButton.getAttribute("aria-expanded") !== "true";
    menuButton.setAttribute("aria-expanded", String(willOpen));
    navigation?.classList.toggle("is-open", willOpen);
    document.body.classList.toggle("menu-open", willOpen);
  });

  navigation?.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", closeMenu);
  });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 860) closeMenu();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") closeMenu();
  });

  function fallbackCopy(text) {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();
    if (!copied) throw new Error("Copy command unavailable");
  }

  document.querySelectorAll("[data-copy-email]").forEach((button) => {
    let resetTimer = 0;
    const label = button.querySelector("[data-copy-label]");
    const container = button.parentElement;
    const status = container?.querySelector("[data-copy-status]");

    button.addEventListener("click", async () => {
      const email = button.dataset.copyEmail;
      if (!email) return;

      try {
        if (navigator.clipboard?.writeText) {
          try {
            await navigator.clipboard.writeText(email);
          } catch (_) {
            fallbackCopy(email);
          }
        } else {
          fallbackCopy(email);
        }

        if (label) label.textContent = activeLanguage === "zh" ? "已复制" : "Copied";
        if (status) {
          status.textContent = activeLanguage === "zh"
            ? "邮箱已复制。正式发布前请先替换占位地址。"
            : "Email copied. Replace the placeholder before publishing.";
        }
        window.clearTimeout(resetTimer);
        resetTimer = window.setTimeout(() => {
          if (label) {
            label.textContent = activeLanguage === "zh" ? "复制邮箱" : "Copy email";
          }
        }, 1800);
      } catch (_) {
        if (status) {
          status.textContent = activeLanguage === "zh"
            ? "复制失败，请手动选择上方邮箱。"
            : "Copy failed. Select the email address above manually.";
        }
      }
    });
  });
})();
