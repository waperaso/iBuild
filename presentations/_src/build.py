#!/usr/bin/env python3
"""Builds the iBuild audience decks (people, investors, government, companies)
in English, Russian and Uzbek.

    python3 build.py            # all decks, all languages
    python3 build.py en people  # one language / one deck

HTML goes to _src/html/<lang>/, PDFs to presentations/<lang>/.
Copy lives in copy_<lang>.py; every text on a slide comes from there.
"""
import importlib
import pathlib
import subprocess
import sys

SRC = pathlib.Path(__file__).resolve().parent
OUT = SRC.parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
LANGS = ["en", "ru", "uz"]
DECKS = ["people", "investors", "government", "companies"]

# ---------------------------------------------------------------- icons
_I = {
    "check": '<path d="M20 6 9 17l-5-5"/>',
    "x": '<path d="M18 6 6 18M6 6l12 12"/>',
    "fileup": '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/><path d="M12 18v-6M9 15l3-3 3 3"/>',
    "hardhat": '<path d="M2 18a1 1 0 0 0 1 1h18a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1v2z"/><path d="M10 10V5a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v5"/><path d="M4 15v-3a6 6 0 0 1 6-6"/><path d="M14 6a6 6 0 0 1 6 6v3"/>',
    "scale": '<path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10M12 3v18M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/>',
    "shield": '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z"/><path d="m9 12 2 2 4-4"/>',
    "inbox": '<path d="M22 12h-6l-2 3h-4l-2-3H2"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/>',
    "pie": '<path d="M21.21 15.89A10 10 0 1 1 8 2.83"/><path d="M22 12A10 10 0 0 0 12 2v10z"/>',
    "building": '<path d="M6 22V4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v18Z"/><path d="M6 12H4a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2h2"/><path d="M18 9h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-2"/><path d="M10 6h4M10 10h4M10 14h4M10 18h4"/>',
    "clipboard": '<rect width="8" height="4" x="8" y="2" rx="1"/><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><path d="m9 14 2 2 4-4"/>',
    "users": '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
    "chart": '<path d="M3 3v18h18"/><path d="M18 17V9M13 17V5M8 17v-3"/>',
    "sliders": '<path d="M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M2 14h4M10 8h4M18 16h4"/>',
    "history": '<path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l4 2"/>',
    "mail": '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>',
    "lock": '<rect width="18" height="11" x="3" y="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>',
    "globe": '<circle cx="12" cy="12" r="10"/><path d="M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20M2 12h20"/>',
    "phone": '<rect width="14" height="20" x="5" y="2" rx="2"/><path d="M12 18h.01"/>',
    "coins": '<circle cx="8" cy="8" r="6"/><path d="M18.09 10.37A6 6 0 1 1 10.34 18"/><path d="M7 6h1v4"/><path d="m16.71 13.88.7.71-2.82 2.82"/>',
    "server": '<rect width="20" height="8" x="2" y="2" rx="2"/><rect width="20" height="8" x="2" y="14" rx="2"/><path d="M6 6h.01M6 18h.01"/>',
    "alert": '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4M12 17h.01"/>',
    "home": '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    "eye": '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/>',
    "bank": '<path d="M3 22h18M6 18v-7M10 18v-7M14 18v-7M18 18v-7M12 2l8 5H4z"/>',
    "trend": '<path d="M22 7 13.5 15.5 8.5 10.5 2 17"/><path d="M16 7h6v6"/>',
    "route": '<circle cx="6" cy="19" r="3"/><path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/><circle cx="18" cy="5" r="3"/>',
    "list": '<path d="m3 17 2 2 4-4M3 7l2 2 4-4M13 6h8M13 12h8M13 18h8"/>',
    "calc": '<rect width="16" height="20" x="4" y="2" rx="2"/><path d="M8 6h8M16 14v4M16 10h.01M12 10h.01M8 10h.01M12 14h.01M8 14h.01M12 18h.01M8 18h.01"/>',
    "msg": '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
    "clock": '<circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/>',
    "layers": '<path d="m12.83 2.18a2 2 0 0 0-1.66 0L2.6 6.08a1 1 0 0 0 0 1.83l8.58 3.91a2 2 0 0 0 1.66 0l8.58-3.9a1 1 0 0 0 0-1.83Z"/><path d="m22 17.65-9.17 4.16a2 2 0 0 1-1.66 0L2 17.65M22 12.65l-9.17 4.16a2 2 0 0 1-1.66 0L2 12.65"/>',
    "card": '<rect width="18" height="18" x="3" y="3" rx="2"/><path d="M3 9h18M9 21V9"/>',
    "key": '<path d="m15.5 7.5 2.3 2.3a1 1 0 0 0 1.4 0l2.1-2.1a1 1 0 0 0 0-1.4L19 4M21 2l-9.6 9.6"/><circle cx="7.5" cy="15.5" r="5.5"/>',
}


def ic(name, cls=""):
    return (f'<svg class="{cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" '
            f'stroke-linecap="round" stroke-linejoin="round">{_I[name]}</svg>')


# ---------------------------------------------------------------- illustrations
INK, GREEN, RED, BLUE = "#0B1F33", "#1F7A4D", "#C23B2E", "#2563EB"


def building(L):
    """A tower whose floors show money states: paid, confirmed, on hold, not built."""
    W, H, ground, fh = 780, 820, 780, 60
    bx, bw = 330, 280
    state = lambda k: "paid" if k < 5 else "ok" if k < 7 else "hold" if k < 8 else "todo"
    lit = {(0, 1), (1, 3), (2, 0), (3, 2), (4, 1), (4, 3), (1, 0)}
    s = [f'<svg viewBox="0 0 {W} {H}" xmlns="http://www.w3.org/2000/svg" font-family="Onest">',
         '<defs><pattern id="hatch" width="12" height="12" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
         '<rect width="12" height="12" fill="#FBEBE9"/><line x1="0" y1="0" x2="0" y2="12" stroke="#C23B2E" stroke-width="3" opacity=".4"/></pattern></defs>']
    # crane (behind)
    mx = 668
    s.append(f'<g stroke="{INK}" stroke-width="3" fill="none" stroke-linecap="round">')
    s.append(f'<line x1="{mx}" y1="{ground}" x2="{mx}" y2="96"/><line x1="{mx+20}" y1="{ground}" x2="{mx+20}" y2="96"/>')
    y = ground
    while y > 120:
        s.append(f'<line x1="{mx}" y1="{y}" x2="{mx+20}" y2="{y-36}" stroke-width="1.6" opacity=".55"/>')
        y -= 36
    s.append(f'<line x1="270" y1="110" x2="{mx+90}" y2="110"/><line x1="{mx+10}" y1="56" x2="300" y2="110" stroke-width="2"/>'
             f'<line x1="{mx+10}" y1="56" x2="{mx+90}" y2="110" stroke-width="2"/><line x1="{mx+10}" y1="56" x2="{mx+10}" y2="96" />')
    s.append(f'<line x1="420" y1="110" x2="420" y2="148" stroke-width="2"/></g>')
    s.append(f'<rect x="{mx-6}" y="112" width="32" height="24" rx="3" fill="{INK}"/>')
    s.append(f'<rect x="398" y="148" width="44" height="12" rx="2" fill="#C5C9CF" stroke="{INK}" stroke-width="2"/>')
    # floors
    for k in range(10):
        y1 = ground - fh * (k + 1)
        st = state(k)
        h = fh - 6
        if st == "paid":
            s.append(f'<rect x="{bx}" y="{y1}" width="{bw}" height="{h}" rx="3" fill="{INK}"/>')
        elif st == "ok":
            s.append(f'<rect x="{bx+1.5}" y="{y1+1.5}" width="{bw-3}" height="{h-3}" rx="3" fill="#E5F3EB" stroke="{GREEN}" stroke-width="3"/>')
        elif st == "hold":
            s.append(f'<rect x="{bx+1.5}" y="{y1+1.5}" width="{bw-3}" height="{h-3}" rx="3" fill="url(#hatch)" stroke="{RED}" stroke-width="3"/>')
        else:
            s.append(f'<rect x="{bx+1.5}" y="{y1+1.5}" width="{bw-3}" height="{h-3}" rx="3" fill="none" stroke="#A3AFBE" stroke-width="2.5" stroke-dasharray="10 8"/>')
        for j in range(4):
            wx, wy = bx + 26 + j * 60, y1 + (h - 24) / 2
            if st == "paid":
                col = "#E9EFF6" if (k, j) in lit else "#244463"
                s.append(f'<rect x="{wx}" y="{wy}" width="38" height="24" rx="2" fill="{col}"/>')
            elif st == "ok":
                s.append(f'<rect x="{wx}" y="{wy}" width="38" height="24" rx="2" fill="#fff" stroke="{GREEN}" stroke-width="2"/>')
            elif st == "hold":
                s.append(f'<rect x="{wx}" y="{wy}" width="38" height="24" rx="2" fill="#fff" stroke="{RED}" stroke-width="2"/>')
            else:
                s.append(f'<rect x="{wx}" y="{wy}" width="38" height="24" rx="2" fill="none" stroke="#C4CDD8" stroke-width="2" stroke-dasharray="5 5"/>')
    s.append(f'<line x1="150" y1="{ground+2}" x2="770" y2="{ground+2}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>')
    # brackets with labels
    groups = [("paid", 0, 4, INK), ("ok", 5, 6, GREEN), ("hold", 7, 7, RED), ("todo", 8, 9, "#8A97A8")]
    for key, a, b, col in groups:
        yt = ground - fh * (b + 1) + 6
        yb = ground - fh * a - 10
        mid = (yt + yb) / 2
        s.append(f'<path d="M318 {yt} H306 V{yb} H318" fill="none" stroke="{col}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>')
        t, sub = L[key]
        s.append(f'<text x="290" y="{mid-3}" text-anchor="end" font-size="23" font-weight="700" fill="{col}">{t}</text>')
        s.append(f'<text x="290" y="{mid+23}" text-anchor="end" font-size="18" fill="#5F6F83">{sub}</text>')
    s.append("</svg>")
    return "".join(s)


def stage_pic(n):
    """Five construction stages, 0..4: foundation, frame, facade, utilities, finishing."""
    g = 226
    s = ['<svg viewBox="0 0 200 240" xmlns="http://www.w3.org/2000/svg">']
    s.append(f'<line x1="8" y1="{g}" x2="192" y2="{g}" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>')
    s.append(f'<rect x="28" y="{g-22}" width="144" height="22" rx="2" fill="{INK}"/>')
    if n == 0:
        for x in range(40, 166, 18):
            s.append(f'<line x1="{x}" y1="{g-22}" x2="{x}" y2="{g-52}" stroke="#8A97A8" stroke-width="3"/>')
        s.append(f'<line x1="36" y1="{g-44}" x2="166" y2="{g-44}" stroke="#8A97A8" stroke-width="2.5"/>')
    if n == 1:
        for x in (38, 96, 154):
            s.append(f'<rect x="{x}" y="70" width="9" height="{g-22-70}" fill="{INK}"/>')
        for y in (70, 116, 162):
            s.append(f'<rect x="32" y="{y}" width="136" height="7" fill="{INK}"/>')
    if n >= 2:
        top = 70 if n < 4 else 52
        s.append(f'<rect x="34" y="{top}" width="132" height="{g-22-top}" rx="2" fill="{INK}"/>')
        rows = list(range(top + 14, g - 34, 34))
        for ri, y in enumerate(rows):
            for ci, x in enumerate((48, 82, 116, 140 - 0)):
                if x > 140:
                    continue
                on = n == 4 or (n == 3 and (ri + ci) % 3 == 0)
                s.append(f'<rect x="{x}" y="{y}" width="{18 if ci < 3 else 14}" height="20" rx="1.5" fill="{"#E9EFF6" if on else "#244463"}"/>')
    if n == 3:
        s.append(f'<path d="M178 {g} V96 H166" fill="none" stroke="{BLUE}" stroke-width="5" stroke-linecap="round"/>')
        s.append(f'<path d="M22 {g} V120 L14 132 L24 138 L16 150" fill="none" stroke="#D99A2B" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>')
    if n == 4:
        s.append(f'<rect x="88" y="{g-46}" width="24" height="24" rx="2" fill="#E9EFF6"/>')
        s.append(f'<circle cx="182" cy="{g-34}" r="14" fill="{GREEN}"/><rect x="180" y="{g-22}" width="4" height="22" fill="{INK}"/>')
        s.append(f'<rect x="96" y="30" width="3" height="22" fill="{INK}"/><path d="M99 30 h20 l-5 6 5 6 h-20z" fill="{BLUE}"/>')
    s.append("</svg>")
    return "".join(s)


# ---------------------------------------------------------------- mockups (app UI)
def m_stages(U, now):
    cells = []
    for i, lab in enumerate(U["stages"]):
        c = "done" if i < now else "now" if i == now else ""
        cells.append(f'<div class="{c}"><i></i><span>{lab}</span></div>')
    return f'<div class="m-stages" style="grid-template-columns:repeat({len(U["stages"])},1fr)">{"".join(cells)}</div>'


def m_tranche(T, checks=2, width=980):
    U, N = T["ui"], T["n"]
    tiles = [("", U["t_req"], N["req"]), ("", U["t_conf"], N["conf"]), ("hold", U["t_hold"], N["hold"]),
             ("pay", U["t_pay"], N["pay"]), ("", U["t_left"], N["left"])]
    t = "".join(f'<div class="{c}"><span>{lab}</span><b>{v}</b><em>{T["c"]["unit"]}</em></div>' for c, lab, v in tiles)
    ch = ""
    for dot, title, rule, sub, btn in U["checks"][:checks]:
        ch += (f'<div class="chk"><i class="d {dot}"></i><div><b>{title}</b><span class="rt">{rule}</span><p>{sub}</p></div>'
               f'<span class="btn">{btn}</span></div>')
    return f'''<div class="m m-pad" style="width:{width}px">
  <div class="m-top"><div><div class="m-h">{U["proj"]}</div><div class="m-s">{U["addr"]}</div></div>
   <div class="m-right"><div class="m-s">{U["limit_lbl"]}</div><b>{N["limit"]} {T["c"]["unit"]}</b></div></div>
  <div class="m-row"><span class="m-h2">{U["tranche"]}</span><span class="m-pill b">{U["stages"][3]}</span></div>
  <div class="m-meta">{U["meta"]}</div>
  {m_stages(U, 3)}
  <div class="m-tiles">{t}</div>
  <div class="m-checks"><div class="m-ch-h"><b>{U["checks_t"]}</b><span>{U["rules_v"]}</span></div>{ch}</div>
</div>'''


def m_route(T, width=640):
    U = T["ui"]
    rows = ""
    for st, role, name, sub, status in U["route"]:
        icon = ic("check") if st == "done" else ""
        rows += (f'<div class="rt-row {st}"><span class="rt-ic {st}">{icon}</span><div><b>{role}<small>{name}</small></b>'
                 f'<p>{sub}</p></div><span class="st {st}">{status}</span></div>')
    return f'<div class="m m-pad" style="width:{width}px"><div class="m-h" style="font-size:23px">{U["route_t"]}</div><div style="margin-top:6px">{rows}</div></div>'


def m_decision(T, width=420):
    U = T["ui"]
    rows = "".join(f'<div class="dc-row"><span>{a}</span><b class="{c}">{b}</b></div>' for a, b, c in U["decision"])
    return f'''<div class="m m-pad" style="width:{width}px"><div class="m-h" style="font-size:23px">{U["decision_t"]}</div>
<div style="margin-top:10px">{rows}</div>
<div style="display:flex;gap:10px;margin-top:18px"><span class="btn p">{U["approve"]}</span><span class="btn">{U["back"]}</span></div></div>'''


def m_decision_wide(T, width=900):
    U = T["ui"]
    cells = "".join(f'<div><span>{a}</span><b class="{c}">{b}</b></div>' for a, b, c in U["decision"])
    return f'''<div class="m m-pad" style="width:{width}px"><div class="m-h" style="font-size:23px">{U["decision_t"]}</div>
<div class="m-dec">{cells}<div style="display:flex;gap:10px"><span class="btn p">{U["approve"]}</span><span class="btn">{U["back"]}</span></div></div></div>'''


def m_journal(T, width=760, n=5):
    U = T["ui"]
    rows = "".join(f'<div class="jr"><time>{a}</time><div><b>{b}</b><span>{c}</span></div></div>' for a, b, c in U["journal"][:n])
    return f'<div class="m m-pad" style="width:{width}px"><div class="m-h" style="font-size:23px">{U["journal_t"]}</div><div style="margin-top:8px">{rows}</div></div>'


def m_portfolio(T, width=860, n=4):
    U = T["ui"]
    k = "".join(f'<div class="kpi"><span>{a}</span><b>{b}</b><em>{c}</em></div>' for a, b, c in U["kpis"])
    rows = ""
    for sev, lab, proj, txt, btn in U["attention"][:n]:
        rows += (f'<div class="att"><span class="sev {sev}">{lab}</span><div><b>{proj}</b><p>{txt}</p>'
                 f'<span class="btn">{btn}</span></div></div>')
    return f'''<div class="m m-pad" style="width:{width}px"><div class="m-h" style="font-size:23px">{U["portfolio_t"]}</div>
<div class="kpis" style="margin-top:14px">{k}</div>
<div style="font-size:17px;font-weight:700;margin-top:20px">{U["attention_t"]}</div><div>{rows}</div></div>'''


def m_rules(T, width=820):
    U = T["ui"]
    tabs = "".join(f'<span class="{"on" if i == 0 else ""}">{t}</span>' for i, t in enumerate(U["rule_tabs"]))
    f = "".join(f'<div class="fld"><span>{a}</span><span class="in">{b}<em>{c}</em></span></div>' for a, b, c in U["rule_fields"])
    terms = "".join(f'<div><span>{a}</span><b>{b}</b></div>' for a, b in U["rule_terms"])
    return f'''<div class="m m-pad" style="width:{width}px">
<div class="m-top"><div class="m-h" style="font-size:23px">{U["rules_t"]}</div><span class="m-pill">{U["rules_ver"]}</span></div>
<div class="tabs" style="margin-top:12px">{tabs}</div><div>{f}</div>
<div style="font-size:15px;font-weight:700;margin-top:16px">{U["terms_t"]}</div><div class="terms">{terms}</div>
<div class="m-foot"><p>{U["rules_note"]}</p><span class="btn p">{U["rules_save"]}</span></div></div>'''


def m_devform(T, width=640):
    U = T["ui"]
    docs = "".join(f'<div><span>{a}</span><em class="{c}">{b}</em></div>' for a, b, c in U["dev_docs"])
    return f'''<div class="m m-pad" style="width:{width}px"><div class="m-s">{U["proj"]}</div><div class="m-h" style="margin-top:2px">{U["dev_t"]}</div>
<div class="fbox"><span>{U["dev_item_l"]}</span><b>{U["dev_item"]}</b></div>
<div class="f-hint">{U["dev_avail"]}</div>
<div class="fbox"><span>{U["dev_amt_l"]}</span><b>{U["dev_amt"]}</b></div>
<div class="fbox t"><span>{U["dev_done_l"]}</span><b>{U["dev_done"]}</b></div>
<div class="thumbs"><i style="background:linear-gradient(135deg,#8C99A8,#C9D1DA)"></i><i style="background:linear-gradient(135deg,#6E7F92,#AEB9C6)"></i><i style="background:linear-gradient(135deg,#9AA6B4,#DCE2E9)"></i><i class="pdf">PDF</i></div>
<div style="font-size:15px;font-weight:700;margin-top:16px">{U["dev_docs_t"]}</div><div class="docl">{docs}</div>
<div class="sendbtn">{U["dev_send"]}</div></div>'''


def m_app(T, width=1040, height=640):
    U = T["ui"]
    navs = ""
    icons = ["inbox", "pie", "building", "clipboard", "users", "chart", "history", "mail"]
    for i, (lab, cnt) in enumerate(U["nav"]):
        badge = f"<em>{cnt}</em>" if cnt else ""
        navs += f'<div class="nav {"on" if i == 0 else ""}">{ic(icons[i])}<span>{lab}</span>{badge}</div>'
    tabs = "".join(f'<span class="{"on" if i == 0 else ""}">{t}</span>' for i, t in enumerate(U["q_tabs"]))
    head = "".join(f"<span>{c}</span>" for c in U["q_cols"])
    rows = ""
    for proj, tr, amt, step, time_, flag, ft in U["q_rows"]:
        rows += (f'<div class="qr"><div><b>{proj}</b><small>{tr}</small></div><div class="amt">{amt}</div>'
                 f'<div><b style="font-weight:500">{step}</b><small>{time_}</small></div><div><span class="flag {flag}"><i></i>{ft}</span></div></div>')
    return f'''<div class="m" style="width:{width}px;height:{height}px"><div class="app">
<div class="side"><div class="lg"><img src="../../logo.png"><div><b>iBuild</b><span>{U["ws"]}</span></div></div>{navs}
<div class="lang">{"".join(f"<b>{c}</b>" if c.lower() == T["lang"] else f"<span>{c}</span>" for c in ("RU", "EN", "UZ"))}</div></div>
<div class="mainp"><div class="qhead"><div><div class="m-h" style="font-size:24px">{U["nav"][0][0]}</div><div class="m-s">{U["q_sub"]}</div></div><div class="cur"><span class="on">UZS</span><span>USD</span></div></div>
<div class="qtabs">{tabs}</div><div class="qt"><div class="qr h">{head}</div>{rows}</div></div></div></div>'''


# ---------------------------------------------------------------- slide frame
def frame(T, deck, i, n, body, kicker="", theme="", cls=""):
    segs = "".join(f'<i class="{"done" if k < i else "now" if k == i else ""}"></i>' for k in range(n))
    return f'''<section class="slide {theme} {cls}">
<header class="top"><div class="kicker">{kicker}</div><div class="steps">{segs}<span>{i+1:02d} / {n:02d}</span></div></header>
<div class="body">{body}</div>
<footer class="bot"><div class="brand"><img src="../../logo.png"><b>iBuild</b><span>{T["c"]["decks"][deck]}</span></div><div>ibuild.uz</div></footer>
</section>'''


def points(items, icons):
    out = ""
    for (h, p), name in zip(items, icons):
        out += f'<div class="pt"><span class="ic">{ic(name)}</span><h4>{h}</h4><p>{p}</p></div>'
    return f'<div class="pts">{out}</div>'


def ticks(items):
    return '<ul class="ticks">' + "".join(f"<li>{ic('check')}<span>{x}</span></li>" for x in items) + "</ul>"


def tiers_table(T, P):
    head = "".join(f'<th class="{"r" if i >= 2 else ""}">{h}</th>' for i, h in enumerate(P["cols"]))
    rows = ""
    for i, r in enumerate(P["tiers"]):
        rows += f'<tr class="{"hl" if i == 2 else ""}">' + "".join(
            f'<td class="{"r" if j >= 2 else ""}">{c}</td>' for j, c in enumerate(r)) + "</tr>"
    return f'<table class="tbl"><thead><tr>{head}</tr></thead><tbody>{rows}</tbody></table>'


# ---------------------------------------------------------------- decks
def deck_people(T):
    D, n = T["people"], 7
    S = []
    # 1 cover
    s = D[0]
    S.append(frame(T, "people", 0, n, f'''
<div style="display:grid;grid-template-columns:1fr 760px;gap:40px;align-items:center;height:100%">
  <div><div class="lockup"><img src="../../logo.png"><b>iBuild</b></div>
   <h1 style="margin-top:56px">{s["title"]}</h1><p class="lead">{s["lead"]}</p>
   <div class="chips"><span class="chip b">{s["chips"][0]}</span><span class="chip">{s["chips"][1]}</span></div></div>
  <div style="height:820px">{building(T["bld"])}</div>
</div>''', cls="cover"))
    # 2 tranches explained
    s = D[1]
    stg = ""
    for k in range(5):
        gate = f'<span class="gate">{ic("check")}{s["gate"]}</span>' if k < 4 else ""
        stg += (f'<div class="stg"><div class="pic">{gate}{stage_pic(k)}</div>'
                f'<div class="tn">{s["tn"]} {k+1}</div><h4>{s["stages"][k]}</h4></div>')
    S.append(frame(T, "people", 1, n, f'''
<h2>{s["title"]}</h2><p class="lead">{s["lead"]}</p>
<div class="stages5" style="margin-top:56px">{stg}</div>
<p class="note" style="margin-top:auto;padding:20px 0 26px;font-size:22px;color:var(--ink2)">{s["note"]}</p>''', s["kicker"]))
    # 3 before / with
    s = D[2]
    was = "".join(f'<div class="it">{ic("x")}<b>{h}</b><p>{p}</p></div>' for h, p in s["was"])
    now = "".join(f'<div class="it">{ic("check")}<b>{h}</b><p>{p}</p></div>' for h, p in s["now"])
    S.append(frame(T, "people", 2, n, f'''
<h2>{s["title"]}</h2>
<div class="vs fill" style="margin-top:46px"><div class="was"><h3>{s["was_t"]}</h3>{was}</div><div class="now"><h3>{s["now_t"]}</h3>{now}</div></div>''', s["kicker"]))
    # 4 four people
    s = D[3]
    fl = ""
    for k, (who, h, p) in enumerate(s["steps"]):
        name = ["fileup", "hardhat", "scale", "shield"][k]
        fl += (f'<div class="st"><div class="n">{k+1:02d}</div><div class="box"><span class="bi">{ic(name)}</span>'
               f'<span class="tag {["amber","green","","grey"][k]}">{who}</span><h4>{h}</h4><p>{p}</p></div></div>')
    S.append(frame(T, "people", 3, n, f'<h2>{s["title"]}</h2><p class="lead">{s["lead"]}</p><div class="flow fill" style="margin-top:46px">{fl}</div>', s["kicker"]))
    # 5 example
    s, N = D[4], T["n"]
    S.append(frame(T, "people", 4, n, f'''
<div style="display:grid;grid-template-columns:700px 1fr;gap:60px;align-items:center;height:100%">
 <div><h2 class="s">{s["title"]}</h2><p class="lead" style="font-size:26px">{s["lead"]}</p>
  <div class="ledger" style="margin-top:34px">
   <div class="r"><div class="big">{N["req"]}</div><span>{s["l_req"]}</span></div>
   <div class="r"><div class="big blue">{N["conf"]}</div><span>{s["l_conf"]}</span></div>
   <div class="r"><div class="big green">{N["pay"]}</div><span>{s["l_pay"]}</span></div></div></div>
 <div style="display:flex;justify-content:flex-end">{m_tranche(T, checks=2, width=920)}</div>
</div>'''.replace("<br>", " "), s["kicker"]))
    # 6 what it means
    s = D[5]
    cards = ""
    for k, (h, p) in enumerate(s["cards"]):
        name = ["home", "building", "hardhat", "bank"][k]
        cards += f'<div class="card"><span class="bi">{ic(name)}</span><h3 style="margin-top:auto">{h}</h3><p>{p}</p></div>'
    S.append(frame(T, "people", 5, n, f'<h2>{s["title"]}</h2><div class="cards-fill g4" style="margin-top:50px">{cards}</div>', s["kicker"]))
    # 7 closing
    s = D[6]
    facts = "".join(f'<span>{ic(nm)}{t}</span>' for nm, t in zip(["globe", "phone", "coins"], s["facts"]))
    S.append(frame(T, "people", 6, n, f'''
<div style="display:grid;grid-template-columns:1fr 780px;gap:70px;align-items:center;height:100%">
 <div><h1 style="font-size:110px">{s["title"]}</h1><p class="lead" style="font-size:32px">{s["lead"]}</p>
 <div class="facts" style="margin-top:50px">{facts}</div></div>
 <div>{m_journal(T, width=780, n=6)}</div>
</div>''', s["kicker"], cls="white"))
    return S


def deck_investors(T):
    D, n, N = T["investors"], 7, T["n"]
    S = []
    s = D[0]
    casc = ""
    for lab, val, w, col in [(s["c_req"], N["req"], 100, "#E9EFF6"), (s["c_conf"], N["conf"], 92.2, "#6C98FF"), (s["c_pay"], N["pay"], 76.3, "#3DA56F")]:
        casc += f'<div class="r"><div class="h"><span>{lab}</span><b>{val}</b></div><div class="bar"><i style="width:{w}%;background:{col}"></i></div></div>'
    S.append(frame(T, "investors", 0, n, f'''
<div style="display:grid;grid-template-columns:1fr 720px;gap:80px;align-items:center;height:100%">
 <div><div class="lockup"><img src="../../logo.png"><b>iBuild</b></div>
  <h1 style="margin-top:56px">{s["title"]}</h1><p class="lead">{s["lead"]}</p>
  <div class="chips"><span class="chip b">{s["chips"][0]}</span><span class="chip">{s["chips"][1]}</span></div></div>
 <div class="cascade"><div style="font-size:26px;font-weight:700;margin-bottom:34px;line-height:1.3">{s["c_title"]}</div>{casc}<div class="foot">{s["c_foot"]}</div></div>
</div>''', theme="dark", cls="cover"))
    # 2 problem
    s = D[1]
    cards = ""
    for (tag, col), h, p, st, sl in zip([(s["tags"][0], "red"), (s["tags"][1], "amber"), (s["tags"][2], "grey")], s["h"], s["p"], s["stat"], s["stat_l"]):
        cards += (f'<div class="card"><span class="tag {col}" style="align-self:flex-start">{tag}</span><h3 style="margin-top:26px">{h}</h3><p>{p}</p>'
                  f'<div class="stat"><b class="{ {"red": "red", "amber": "amber"}.get(col, "")}">{st}</b><span>{sl}</span></div></div>')
    S.append(frame(T, "investors", 1, n, f'<h2>{s["title"]}</h2><p class="lead">{s["lead"]}</p><div class="cards-fill g3" style="margin-top:44px">{cards}</div>', s["kicker"]))
    # 3 product
    s = D[2]
    S.append(frame(T, "investors", 2, n, f'''
<div style="display:grid;grid-template-columns:600px 1fr;gap:64px;height:100%">
 <div><h2 class="s">{s["title"]}</h2><div style="margin-top:44px">{points(s["pts"], ["list", "alert", "users", "history"])}</div></div>
 <div style="display:flex;align-items:center;justify-content:flex-end">{m_tranche(T, checks=3, width=1000)}</div>
</div>''', s["kicker"]))
    # 4 moat
    s = D[3]
    cards = ""
    for k, (h, p) in enumerate(s["cards"]):
        cards += f'<div class="card"><div class="ghost">0{k+1}</div><h3 style="margin-top:auto">{h}</h3><p>{p}</p></div>'
    strip = "".join(f"<span>{x}</span>" for x in s["mods"])
    S.append(frame(T, "investors", 3, n, f'''<h2>{s["title"]}</h2>
<div class="cards-fill g4" style="margin-top:44px;margin-bottom:30px">{cards}</div>
<div style="padding-bottom:34px"><div class="note" style="font-size:17px;letter-spacing:.16em;text-transform:uppercase;font-weight:600;margin-bottom:14px">{s["mods_t"]}</div><div class="strip">{strip}</div></div>''', s["kicker"]))
    # 5 business model
    s = D[4]
    ex = "".join(f'<div class="dc-row" style="font-size:21px;padding:13px 0;border-bottom:1px solid var(--line)"><span>{a}</span><b style="font-size:23px">{b}</b></div>' for a, b in s["ex"])
    S.append(frame(T, "investors", 4, n, f'''
<h2 class="s">{s["title"]}</h2>
<div style="display:grid;grid-template-columns:1.25fr 1fr;gap:40px;margin-top:32px;flex:1;min-height:0;margin-bottom:24px">
 <div style="display:flex;flex-direction:column">{tiers_table(T, s)}
  <div class="card" style="margin-top:22px;padding:24px 30px;display:flex;justify-content:space-between;align-items:center;gap:30px"><div><h3 style="font-size:25px">{s["impl_t"]}</h3><p style="margin-top:6px;font-size:19px">{s["impl_p"]}</p></div><b style="font-size:32px;white-space:nowrap">{s["impl_v"]}</b></div>
  <p class="note" style="margin-top:16px">{s["foot"]}</p></div>
 <div class="card" style="background:var(--ink);border-color:var(--ink);color:#fff;display:flex;flex-direction:column">
  <span class="tag" style="background:rgba(108,152,255,.18);color:#A9C4FF;align-self:flex-start">{s["ex_t"]}</span>
  <div style="margin-top:16px" class="exl">{ex}</div>
  <div class="yr">{"".join(f"<div><span>{a}</span><b>{b}</b><em>{c}</em></div>" for a, b, c in s["yr"])}</div>
  <div style="margin-top:auto;display:flex;align-items:flex-end;gap:22px"><div class="big" style="font-size:112px;color:#fff">0.04%</div><div style="font-size:21px;color:#A9B8CA;padding-bottom:12px;line-height:1.4">{s["bp"]}</div></div>
 </div>
</div>'''.replace("0.04%", s["bp_v"]).replace('class="exl"', 'class="exl" style="--line:rgba(255,255,255,.12);color:#DCE4EE"'), s["kicker"]))
    # 6 market
    s = D[5]
    path = ""
    for lab, val, w, col in s["path"]:
        path += f'<div class="pr"><div class="h"><span>{lab}</span><b>{val}</b></div><div class="bar"><i style="width:{w}%;background:{col}"></i></div></div>'
    S.append(frame(T, "investors", 5, n, f'''
<div style="display:grid;grid-template-columns:1fr 820px;gap:80px;align-items:center;height:100%">
 <div><h1 style="font-size:92px">{s["title"]}</h1><p class="lead" style="font-size:28px">{s["lead"]}</p>
  <div class="card" style="margin-top:34px;padding:26px 30px"><span class="tag">{s["why_t"]}</span><p style="font-size:21px;margin-top:14px">{s["why"]}</p></div>
  <p class="note" style="margin-top:20px">{s["src"]}</p></div>
 <div class="card path" style="padding:44px 46px"><div style="font-size:30px;font-weight:700;margin-bottom:34px">{s["path_t"]}</div>{path}<p class="note" style="margin-top:6px">{s["path_note"]}</p></div>
</div>''', s["kicker"], theme="dark"))
    # 7 ask
    s = D[6]
    proves = "".join(f'<div class="card"><span class="bi g">{ic(nm)}</span><h3 style="margin-top:28px;font-size:30px">{h}</h3><p style="font-size:22px">{p}</p></div>'
                     for nm, (h, p) in zip(["clock", "coins", "history"], s["proves"]))
    S.append(frame(T, "investors", 6, n, f'''
<h1 style="font-size:116px;max-width:1500px">{s["title"]}</h1><p class="lead" style="font-size:32px;max-width:1300px">{s["lead"]}</p>
<div style="margin-top:auto;padding-bottom:40px"><div class="note" style="font-size:17px;letter-spacing:.16em;text-transform:uppercase;font-weight:600;margin-bottom:16px">{s["proves_t"]}</div>
<div class="grid g3">{proves}</div></div>''', s["kicker"]))
    return S


def deck_government(T):
    D, n = T["government"], 7
    S = []
    s = D[0]
    S.append(frame(T, "government", 0, n, f'''
<div style="display:grid;grid-template-columns:1fr 760px;gap:40px;align-items:center;height:100%">
  <div><div class="lockup"><img src="../../logo.png"><b>iBuild</b></div>
   <h1 style="margin-top:56px">{s["title"]}</h1><p class="lead">{s["lead"]}</p>
   <div class="chips"><span class="chip b">{s["chips"][0]}</span><span class="chip">{s["chips"][1]}</span></div></div>
  <div style="height:820px">{building(T["bld"])}</div>
</div>''', cls="cover"))
    # 2 why
    s = D[1]
    cards = "".join(f'<div class="card"><div style="display:flex;justify-content:space-between;align-items:flex-start"><span class="bi r">{ic(nm)}</span><div class="ghost" style="font-size:72px">0{k+1}</div></div><h3 style="margin-top:auto;font-size:31px">{h}</h3></div>'
                    for k, (nm, h) in enumerate(zip(["coins", "home", "building", "alert"], s["risks"])))
    S.append(frame(T, "government", 1, n, f'''<h2>{s["title"]}</h2><p class="lead">{s["lead"]}</p>
<div class="cards-fill g4" style="margin-top:44px;margin-bottom:26px">{cards}</div>
<div class="bar-note" style="margin-top:0;margin-bottom:36px">{ic("trend")}<span>{s["bar"]}</span></div>''', s["kicker"]))
    # 3 escrow
    s = D[2]
    arrow = '<div class="arrow"><svg viewBox="0 0 80 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12h70M64 4l10 8-10 8"/></svg></div>'
    a, b, c, d, e = s["boxes"]
    S.append(frame(T, "government", 2, n, f'''<h2 class="s">{s["title"]}</h2>
<div class="esc" style="margin-top:50px">
 <div class="estack"><div class="ebox lock"><div class="t">{a[0]}</div><h4>{a[1]}</h4><p>{a[2]}</p></div>
   <div class="ebox"><div class="t">{b[0]}</div><h4>{b[1]}</h4><p>{b[2]}</p></div></div>
 {arrow}
 <div class="ebox ib"><div class="t" style="color:var(--blue)">{c[0]}</div><h4>{c[1]}</h4><p>{c[2]}</p></div>
 {arrow}
 <div class="estack"><div class="ebox"><div class="t">{d[0]}</div><h4>{d[1]}</h4><p>{d[2]}</p></div>
   <div class="ebox" style="background:var(--green-soft);border-color:#CBE6D6"><div class="t" style="color:var(--green)">{e[0]}</div><h4>{e[1]}</h4><p>{e[2]}</p></div></div>
</div>
<div class="grid g2 mt-auto" style="padding-bottom:36px">
 <div class="card" style="padding:26px 32px"><span class="tag">{s["roles"][0][0]}</span><p style="font-size:21px;margin-top:12px;color:var(--ink2)">{s["roles"][0][1]}</p></div>
 <div class="card" style="padding:26px 32px"><span class="tag green">{s["roles"][1][0]}</span><p style="font-size:21px;margin-top:12px;color:var(--ink2)">{s["roles"][1][1]}</p></div>
</div>''', s["kicker"]))
    # 4 supervision
    s = D[3]
    S.append(frame(T, "government", 3, n, f'''
<div style="display:grid;grid-template-columns:680px 1fr;gap:70px;height:100%">
 <div><h2 class="s">{s["title"]}</h2><div style="margin-top:44px">{points(s["pts"], ["clipboard", "alert", "trend"])}</div></div>
 <div style="display:flex;align-items:center;justify-content:flex-end">{m_portfolio(T, width=900, n=4)}</div>
</div>''', s["kicker"]))
    # 5 accountability
    s = D[4]
    S.append(frame(T, "government", 4, n, f'''
<div style="display:grid;grid-template-columns:1fr 760px;gap:70px;height:100%;align-items:center">
 <div><h2 class="s">{s["title"]}</h2><p class="lead" style="font-size:27px">{s["lead"]}</p><div style="margin-top:40px">{ticks(s["ticks"])}</div></div>
 <div>{m_journal(T, width=760, n=6)}</div>
</div>''', s["kicker"]))
    # 6 fit
    s = D[5]
    lanes = ""
    for k, (t, h, items) in enumerate(s["lanes"]):
        lis = "".join(f"<li>{x}</li>" for x in items)
        lanes += f'<div class="lane {"mid" if k == 1 else ""}"><div class="t">{t}</div><h3>{h}</h3><ul>{lis}</ul></div>'
    S.append(frame(T, "government", 5, n, f'<h2>{s["title"]}</h2><div class="lanes fill" style="margin-top:48px">{lanes}</div>', s["kicker"]))
    # 7 closing
    s = D[6]
    facts = "".join(f'<span>{ic(nm)}{t}</span>' for nm, t in zip(["globe", "coins", "server", "lock"], s["facts"]))
    S.append(frame(T, "government", 6, n, f'''
<img class="wm" src="../../logo.png">
<div style="display:flex;flex-direction:column;justify-content:center;height:100%;padding-bottom:30px;position:relative">
 <h1 style="font-size:104px;max-width:1300px">{s["title"]}</h1><p class="lead" style="font-size:32px;max-width:1300px">{s["lead"]}</p>
 <div class="facts" style="margin-top:56px">{facts}</div></div>''', s["kicker"], theme="dark"))
    return S


def deck_companies(T):
    D, n = T["companies"], 7
    S = []
    s = D[0]
    S.append(frame(T, "companies", 0, n, f'''
<div style="display:grid;grid-template-columns:620px 1fr;gap:60px;align-items:center;height:100%">
 <div><div class="lockup"><img src="../../logo.png"><b>iBuild</b></div>
  <h1 style="margin-top:56px;font-size:96px">{s["title"]}</h1><p class="lead" style="font-size:28px">{s["lead"]}</p>
  <div class="chips"><span class="chip b">{s["chips"][0]}</span><span class="chip">{s["chips"][1]}</span></div></div>
 <div style="display:flex;justify-content:flex-end">{m_app(T, width=1040, height=660)}</div>
</div>''', cls="cover"))
    # 2 modules
    s = D[1]
    mods = "".join(f'<div class="mod"><span class="ic">{ic(nm)}</span><h4>{h}</h4><p>{p}</p></div>'
                   for nm, (h, p) in zip(["inbox", "card", "clipboard", "pie", "users", "chart", "sliders", "history"], s["mods"]))
    S.append(frame(T, "companies", 1, n, f'<h2>{s["title"]}</h2><div class="mods fill" style="margin-top:44px">{mods}</div>', s["kicker"]))
    # 3 rules
    s = D[2]
    S.append(frame(T, "companies", 2, n, f'''
<div style="display:grid;grid-template-columns:1fr 840px;gap:64px;height:100%">
 <div><h2 class="s">{s["title"]}</h2><div style="margin-top:40px">{points(s["pts"], ["sliders", "list", "users", "layers"])}</div></div>
 <div style="display:flex;align-items:center;justify-content:flex-end">{m_rules(T, width=840)}</div>
</div>''', s["kicker"]))
    # 4 decision
    s = D[3]
    S.append(frame(T, "companies", 3, n, f'''
<div style="display:grid;grid-template-columns:600px 1fr;gap:56px;height:100%">
 <div><h2 class="s">{s["title"]}</h2><div style="margin-top:40px">{points(s["pts"], ["calc", "split" if False else "list", "msg", "route"])}</div></div>
 <div style="display:flex;flex-direction:column;gap:22px;align-items:flex-end;justify-content:center">{m_route(T, width=980)}{m_decision_wide(T, width=980)}</div>
</div>''', s["kicker"]))
    # 5 developers
    s = D[4]
    S.append(frame(T, "companies", 4, n, f'''
<div style="display:grid;grid-template-columns:1fr 640px;gap:70px;height:100%">
 <div><h2 class="s">{s["title"]}</h2><div style="margin-top:40px">{points(s["pts"], ["coins", "fileup", "clock", "msg"])}</div></div>
 <div style="display:flex;align-items:center">{m_devform(T, width=640)}</div>
</div>''', s["kicker"]))
    # 6 pricing
    s = D[5]
    inc = ticks(s["incl"])
    S.append(frame(T, "companies", 5, n, f'''
<h2 class="s">{s["title"]}</h2>
<div style="display:grid;grid-template-columns:1.25fr 1fr;gap:40px;margin-top:40px;flex:1;min-height:0">
 <div>{tiers_table(T, s)}
  <div class="card" style="margin-top:22px;padding:24px 30px;display:flex;justify-content:space-between;align-items:center;gap:30px"><div><h3 style="font-size:25px">{s["impl_t"]}</h3><p style="margin-top:6px;font-size:19px">{s["impl_p"]}</p></div><b style="font-size:32px;white-space:nowrap">{s["impl_v"]}</b></div>
  <p class="note" style="margin-top:16px">{s["foot"]}</p></div>
 <div style="display:flex;flex-direction:column;gap:22px">
  <div class="card" style="padding:30px 34px"><div style="font-size:16px;font-weight:600;letter-spacing:.14em;text-transform:uppercase;color:var(--faint);margin-bottom:18px">{s["incl_t"]}</div>{inc}</div>
  <div class="card" style="background:var(--green-soft);border-color:#CBE6D6;padding:30px 34px"><h3 style="font-size:27px;color:var(--green)">{s["roi_t"]}</h3><p style="color:var(--ink2);font-size:23px">{s["roi"]}</p></div>
 </div>
</div>'''.replace('class="ticks"', 'class="ticks" style="gap:14px"').replace("<li>", '<li style="font-size:23px">'), s["kicker"]))
    # 7 start
    s = D[6]
    st = "".join(f'<div class="card"><div class="seg"></div><div class="no">0{k+1}</div><h3>{h}</h3><p style="font-size:23px">{p}</p></div>' for k, (h, p) in enumerate(s["steps"]))
    trust = "".join(f'<span>{ic(nm)}{t}</span>' for nm, t in zip(["key", "lock", "server", "history"], s["trust"]))
    S.append(frame(T, "companies", 6, n, f'''<h2>{s["title"]}</h2>
<div class="steps4 tall" style="margin-top:46px">{st}</div>
<div class="facts" style="margin-top:26px;gap:10px">{trust.replace('<span>', '<span style="font-size:19px;padding:12px 18px">')}</div>
<div class="mt-auto" style="display:flex;justify-content:space-between;align-items:center;background:var(--ink);color:#fff;border-radius:22px;padding:34px 44px;margin-bottom:34px">
 <div style="font-size:38px;font-weight:800;letter-spacing:-.02em">{s["cta"]}</div><div style="font-size:24px;color:#A9C4FF">{s["cta_sub"]}</div></div>''', s["kicker"]))
    return S


BUILDERS = {"people": deck_people, "investors": deck_investors, "government": deck_government, "companies": deck_companies}


def page(T, slides, title):
    return f'''<!doctype html><html lang="{T["lang"]}"><head><meta charset="utf-8"><title>{title}</title>
<link rel="stylesheet" href="../../style.css"></head><body>{"".join(slides)}<script src="../../fit.js"></script></body></html>'''


def build(lang, deck):
    T = importlib.import_module(f"copy_{lang}").T
    html_dir = SRC / "html" / lang
    html_dir.mkdir(parents=True, exist_ok=True)
    pdf_dir = OUT / lang
    pdf_dir.mkdir(parents=True, exist_ok=True)
    slides = BUILDERS[deck](T)
    name = T["c"]["files"][deck]
    hp = html_dir / f"{deck}.html"
    hp.write_text(page(T, slides, f'iBuild — {T["c"]["decks"][deck]}'), encoding="utf-8")
    pdf = pdf_dir / f"{name}.pdf"
    cmd = [CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--hide-scrollbars",
           "--allow-file-access-from-files", "--virtual-time-budget=4000", f"--print-to-pdf={pdf}", hp.as_uri()]
    for attempt in range(3):  # headless Chrome occasionally exits non-zero on a busy machine
        if subprocess.run(cmd, capture_output=True).returncode == 0 and pdf.exists():
            break
    else:
        raise SystemExit(f"Chrome could not print {hp}")
    print(f"{lang}/{deck}: {len(slides)} slides -> {pdf.relative_to(OUT)}")
    return pdf


if __name__ == "__main__":
    sys.path.insert(0, str(SRC))
    langs = [a for a in sys.argv[1:] if a in LANGS] or LANGS
    decks = [a for a in sys.argv[1:] if a in DECKS] or DECKS
    for lg in langs:
        for dk in decks:
            build(lg, dk)
