/* Desktop-only company controls. The server validates role, terminal and revision. */
(() => {
  "use strict";
  if (window.ALSPMCCompany) return;
  const root = document.getElementById("pmc-company");
  let current = null, request = null, sequence = Math.floor(Date.now() % 900000000);
  let feedback = "", timer, shown = "", confirming = null, stale = false;
  // Engine strings cross as toArray values. Values above 255 are Unicode code
  // points; otherwise UTF-8 bytes, the form our own name editor always sends.
  const text = values => {
    const list = (Array.isArray(values) ? values : []).filter(n => Number.isInteger(n) && n > 0 && n <= 0x10ffff);
    if (list.some(n => n > 255)) return String.fromCodePoint(...list);
    try { return new TextDecoder("utf-8", {fatal: true}).decode(new Uint8Array(list)); }
    catch (_) { return String.fromCodePoint(...list); }
  };
  const money = n => Math.round(n || 0).toLocaleString("ru-RU") + " \u20ac";
  const roleNames = {owner:"\u0412\u043b\u0430\u0434\u0435\u043b\u0435\u0446", manager:"\u0423\u043f\u0440\u0430\u0432\u043b\u044f\u044e\u0449\u0438\u0439", member:"\u0421\u043e\u0442\u0440\u0443\u0434\u043d\u0438\u043a"};
  const labels = {join:"\u0412\u0441\u0442\u0443\u043f\u043b\u0435\u043d\u0438\u0435", companyInvite:"\u041f\u0440\u0438\u0433\u043b\u0430\u0448\u0435\u043d\u0438\u0435", companyPromote:"\u041d\u0430\u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435 \u0443\u043f\u0440\u0430\u0432\u043b\u044f\u044e\u0449\u0435\u0433\u043e",
    companyDemote:"\u041d\u0430\u0437\u043d\u0430\u0447\u0435\u043d\u0438\u0435 \u0441\u043e\u0442\u0440\u0443\u0434\u043d\u0438\u043a\u0430", companyRemove:"\u0418\u0441\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u0435", companyLeave:"\u0412\u044b\u0445\u043e\u0434",
    companyDeposit:"\u0412\u043d\u0435\u0441\u0435\u043d\u0438\u0435 \u0441\u0440\u0435\u0434\u0441\u0442\u0432", companyWithdraw:"\u0412\u044b\u0432\u043e\u0434 \u0441\u0440\u0435\u0434\u0441\u0442\u0432", contract:"\u041d\u0430\u0433\u0440\u0430\u0434\u0430 \u0437\u0430 \u043a\u043e\u043d\u0442\u0440\u0430\u043a\u0442",
    contractCancel:"\u041e\u0442\u043c\u0435\u043d\u0430 \u043a\u043e\u043d\u0442\u0440\u0430\u043a\u0442\u0430", careerRestart:"\u0412\u044b\u0445\u043e\u0434: \u043a\u0430\u0440\u044c\u0435\u0440\u0430 \u043d\u0430\u0447\u0430\u0442\u0430 \u0437\u0430\u043d\u043e\u0432\u043e"};
  const el = (tag, value, cls) => {
    const node = document.createElement(tag);
    if (value !== undefined) node.textContent = value;
    if (cls) node.className = cls;
    return node;
  };
  const nameOf = uid => text(((current && current.names) || {})[uid]) || uid;
  // Active seconds change on every poll; alone they must not rebuild the panel.
  const keyOf = company => JSON.stringify(company ? {...company, seconds: 0} : null);
  const activeTime = () => "\u0410\u043a\u0442\u0438\u0432\u043d\u043e\u0435 \u0432\u0440\u0435\u043c\u044f: " + Math.floor((current.seconds || 0) / 60) + " \u043c\u0438\u043d";
  function act(op, value) {
    if (request || !current) return;
    const token = ++sequence;
    request = {token, op, value};
    confirming = null;
    send({a:"alspmc", op, token, companyArg:[current.revision, value]});
    clearTimeout(timer);
    timer = setTimeout(() => {
      if (request && request.token === token) {
        request = null;
        feedback = "\u041e\u0442\u0432\u0435\u0442 \u0437\u0430\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442\u0441\u044f. \u041e\u0431\u043d\u043e\u0432\u0438\u0442\u0435 \u0441\u0442\u0430\u0442\u0443\u0441 \u043f\u0435\u0440\u0435\u0434 \u043f\u043e\u0432\u0442\u043e\u0440\u043e\u043c.";
        render();
      }
    }, 10000);
    render();
  }
  function button(label, op, value, disabled = false) {
    const b = el("button", label, "btn ghost");
    b.disabled = disabled || !!request;
    b.addEventListener("click", () => act(op, value));
    return b;
  }
  // Two-step actions: the armed state survives server polls until confirmed or dropped.
  function guarded(label, confirmLabel, op, value) {
    const armed = confirming && confirming.op === op && confirming.value === value;
    const b = el("button", armed ? confirmLabel : label, "btn danger");
    b.disabled = !!request;
    b.addEventListener("click", () => {
      if (!armed) {confirming = {op, value}; return render();}
      act(op, value);
    });
    if (!armed) return [b];
    const back = el("button", "\u041e\u0442\u043c\u0435\u043d\u0430", "btn ghost");
    back.addEventListener("click", () => {confirming = null; render();});
    return [b, back];
  }
  function render() {
    shown = keyOf(current); stale = false;
    // Preserve typed amounts and candidate selection across server polls.
    const focusID = root.contains(document.activeElement) ? document.activeElement.id : "";
    const amount = root.querySelector("input")?.value || "";
    const selected = root.querySelector("select")?.value || "";
    root.replaceChildren();
    root.append(el("h2", "\u041a\u043e\u043c\u043f\u0430\u043d\u0438\u044f \u0438 \u043a\u0430\u0437\u043d\u0430"));
    root.append(el("p", feedback || "\u0423\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u0438\u0435 \u0434\u043e\u0441\u0442\u0443\u043f\u043d\u043e \u0442\u043e\u043b\u044c\u043a\u043e \u043d\u0430 \u043a\u043e\u043c\u043f\u044c\u044e\u0442\u0435\u0440\u0435 \u0431\u0430\u0437\u044b.", "note"));
    if (!current?.ready) return root.append(el("p", "\u0414\u0430\u043d\u043d\u044b\u0435 \u043a\u043e\u043c\u043f\u0430\u043d\u0438\u0438 \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u044b. \u041e\u043f\u0435\u0440\u0430\u0446\u0438\u0438 \u0437\u0430\u0431\u043b\u043e\u043a\u0438\u0440\u043e\u0432\u0430\u043d\u044b.", "note"));
    if (!current.id) return root.append(el("p", "\u041a\u043e\u043c\u043f\u0430\u043d\u0438\u044f \u043f\u043e\u044f\u0432\u0438\u0442\u0441\u044f \u043f\u043e\u0441\u043b\u0435 \u043e\u0441\u043d\u043e\u0432\u0430\u043d\u0438\u044f \u0427\u0412\u041a. \u041f\u0440\u0438\u0433\u043b\u0430\u0448\u0435\u043d\u0438\u044f \u043f\u0440\u0438\u043d\u0438\u043c\u0430\u044e\u0442\u0441\u044f \u0432 \u043f\u0440\u0438\u043b\u043e\u0436\u0435\u043d\u0438\u0438 \u0442\u0435\u043b\u0435\u0444\u043e\u043d\u0430.", "note"));
    root.append(el("p", "\u0412\u0430\u0448\u0430 \u0440\u043e\u043b\u044c: " + roleNames[current.role], "cargo"));
    root.append(el("p", "\u041a\u0430\u0437\u043d\u0430: " + money(current.balance) + " \u00b7 \u0421\u0432\u043e\u0431\u043e\u0434\u043d\u043e: " + money(current.free), "cargo"));
    const time = el("span", activeTime()); time.id = "pmc-company-time";
    const reserve = el("p", "\u0414\u043e\u043b\u0433: " + money(current.debt) + " \u00b7 \u0420\u0435\u0437\u0435\u0440\u0432: " + money(current.reserve) + " \u00b7 ", "note");
    reserve.append(time); root.append(reserve);
    const funds = el("div", undefined, "meta");
    const input = el("input"); input.type = "number"; input.min = "1"; input.max = "10000000";
    input.step = "1"; input.placeholder = "\u0421\u0443\u043c\u043c\u0430 \u0432 \u0435\u0432\u0440\u043e"; input.value = amount; input.id = "pmc-company-amount";
    input.setAttribute("aria-label", "\u0421\u0443\u043c\u043c\u0430 \u0432 \u0435\u0432\u0440\u043e");
    funds.append(input);
    for (const [label, op] of [["\u0412\u043d\u0435\u0441\u0442\u0438 \u0438\u0437 \u043b\u0438\u0447\u043d\u043e\u0433\u043e \u0431\u0430\u043d\u043a\u0430", "companyDeposit"], ["\u0412\u044b\u0432\u0435\u0441\u0442\u0438 \u0432 \u043b\u0438\u0447\u043d\u044b\u0439 \u0431\u0430\u043d\u043a", "companyWithdraw"]]) {
      if (op === "companyWithdraw" && current.role !== "owner") continue;
      const b = el("button", label, "btn ghost"); b.disabled = !!request;
      b.addEventListener("click", () => {
        const n = Number(input.value);
        if (!Number.isSafeInteger(n) || n < 1 || n > 10000000) {
          feedback = "\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0446\u0435\u043b\u0443\u044e \u0441\u0443\u043c\u043c\u0443 \u043e\u0442 1 \u0434\u043e 10 000 000 \u20ac."; return render();
        }
        act(op, n);
      }); funds.append(b);
    }
    root.append(funds);
    if (focusID === input.id) input.focus();
    root.append(el("h3", "\u0420\u0435\u0430\u043b\u044c\u043d\u044b\u0435 \u0443\u0447\u0430\u0441\u0442\u043d\u0438\u043a\u0438"));
    if (["owner", "manager"].includes(current.role)) {
      const select = el("select"); select.id = "pmc-company-candidate";
      select.setAttribute("aria-label", "\u0418\u0433\u0440\u043e\u043a \u0434\u043b\u044f \u043f\u0440\u0438\u0433\u043b\u0430\u0448\u0435\u043d\u0438\u044f");
      for (const candidate of current.candidates || []) {
        const option = el("option", text(candidate.name) || candidate.uid); option.value = candidate.uid; select.append(option);
      }
      if ([...select.options].some(o => o.value === selected)) select.value = selected;
      root.append(select);
      if (focusID === select.id) select.focus();
      const invite = el("button", "\u041f\u0440\u0438\u0433\u043b\u0430\u0441\u0438\u0442\u044c \u0438\u0433\u0440\u043e\u043a\u0430", "btn ghost"); invite.disabled = !!request || !select.options.length;
      invite.addEventListener("click", () => act("companyInvite", select.value)); root.append(invite);
      root.append(el("p", "\u041f\u0440\u0438\u0433\u043b\u0430\u0448\u0435\u043d\u0438\u0435 \u0434\u0435\u0439\u0441\u0442\u0432\u0443\u0435\u0442 10 \u043c\u0438\u043d\u0443\u0442. \u0418\u0433\u0440\u043e\u043a \u0434\u043e\u043b\u0436\u0435\u043d \u043f\u0440\u0438\u043d\u044f\u0442\u044c \u0435\u0433\u043e \u0432 \u0442\u0435\u043b\u0435\u0444\u043e\u043d\u0435. \u0412\u043b\u0430\u0434\u0435\u043b\u0435\u0446 \u0434\u0440\u0443\u0433\u043e\u0439 \u0427\u0412\u041a \u0432\u0441\u0442\u0443\u043f\u0438\u0442\u044c \u043d\u0435 \u043c\u043e\u0436\u0435\u0442.", "note"));
    }
    for (const member of current.members || []) {
      const row = el("div", undefined, "alspmc-site");
      row.append(el("p", (text(member.name) || member.uid) + " \u00b7 " + roleNames[member.role] + " \u00b7 " + (member.online ? "\u0412 \u0441\u0435\u0442\u0438" : "\u041d\u0435 \u0432 \u0441\u0435\u0442\u0438")));
      if (current.role === "owner" && member.role !== "owner") {
        row.append(button(member.role === "manager" ? "\u0421\u0434\u0435\u043b\u0430\u0442\u044c \u0441\u043e\u0442\u0440\u0443\u0434\u043d\u0438\u043a\u043e\u043c" : "\u0421\u0434\u0435\u043b\u0430\u0442\u044c \u0443\u043f\u0440\u0430\u0432\u043b\u044f\u044e\u0449\u0438\u043c",
          member.role === "manager" ? "companyDemote" : "companyPromote", member.uid));
        // Removal requires a local confirmation, avoiding accidental personnel changes.
        row.append(...guarded("\u0418\u0441\u043a\u043b\u044e\u0447\u0438\u0442\u044c\u2026", "\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u0438\u0441\u043a\u043b\u044e\u0447\u0435\u043d\u0438\u0435", "companyRemove", member.uid));
      }
      root.append(row);
    }
    if (current.role !== "owner") root.append(...guarded("\u0412\u044b\u0439\u0442\u0438 \u0438\u0437 \u0427\u0412\u041a\u2026", "\u041f\u043e\u0434\u0442\u0432\u0435\u0440\u0434\u0438\u0442\u044c \u0432\u044b\u0445\u043e\u0434", "companyLeave", ""));
    root.append(el("h3", "\u0416\u0443\u0440\u043d\u0430\u043b \u043e\u043f\u0435\u0440\u0430\u0446\u0438\u0439"));
    for (const row of current.ledger || []) {
      const [date, actor, delta, kind, ref] = row;
      root.append(el("p", `${date[2]}.${date[1]} ${date[3]}:${String(date[4]).padStart(2,"0")} \u00b7 ${nameOf(actor)} \u00b7 ${labels[kind] || kind} \u00b7 ${money(delta)} \u00b7 ${ref}`, "note"));
    }
    if (!current.ledger?.length) root.append(el("p", "\u041e\u043f\u0435\u0440\u0430\u0446\u0438\u0439 \u043f\u043e\u043a\u0430 \u043d\u0435\u0442.", "note"));
  }
  // An open candidate list is rebuilt only after it loses focus.
  root.addEventListener("focusout", () => setTimeout(() => {
    if (stale && !(root.contains(document.activeElement) && document.activeElement.tagName === "SELECT")) render();
  }));
  window.ALSPMCCompany = {set(state) {
    current = state.company;
    const resolved = !!(request && state.reply === request.token);
    if (resolved) {
      feedback = state.ok ? "\u041e\u043f\u0435\u0440\u0430\u0446\u0438\u044f \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u0430." : "\u041e\u043f\u0435\u0440\u0430\u0446\u0438\u044f \u043e\u0442\u043a\u043b\u043e\u043d\u0435\u043d\u0430. \u041f\u0440\u043e\u0432\u0435\u0440\u044c\u0442\u0435 \u0431\u0430\u043b\u0430\u043d\u0441, \u043f\u0440\u0430\u0432\u0430 \u0438 \u0430\u043a\u0442\u0443\u0430\u043b\u044c\u043d\u043e\u0441\u0442\u044c \u0434\u0430\u043d\u043d\u044b\u0445.";
      request = null; clearTimeout(timer);
    }
    if (!resolved && keyOf(current) === shown) {
      const time = document.getElementById("pmc-company-time");
      if (time && current) time.textContent = activeTime();
      return;
    }
    if (!resolved && root.contains(document.activeElement) && document.activeElement.tagName === "SELECT") {stale = true; return;}
    render();
  }};
})();
