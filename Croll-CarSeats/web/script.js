const root = document.getElementById('root');
const seatList = document.getElementById('seat-list');
const btnClose = document.getElementById('btn-close');
const btnRefresh = document.getElementById('btn-refresh');
const uiTitle = document.getElementById('ui-title');
const hintBefore = document.getElementById('hint-before');
const hintAfter = document.getElementById('hint-after');
const kbdEsc = document.getElementById('kbd-esc');

const UI_VAR_MAP = {
    panelBackground: '--panel-bg',
    panelBorder: '--panel-border',
    panelShadow: '--panel-shadow',
    textPrimary: '--text-primary',
    headerBorder: '--header-border',
    iconBackground: '--icon-bg',
    iconColor: '--icon-color',
    iconHoverBackground: '--icon-hover-bg',
    hintText: '--hint-text',
    kbdBackground: '--kbd-bg',
    kbdBorder: '--kbd-border',
    seatBackground: '--seat-bg',
    seatHoverBackground: '--seat-hover-bg',
    seatHoverBorder: '--seat-hover-border',
    seatCurrentBorder: '--seat-current-border',
    seatCurrentBackground: '--seat-current-bg',
    subText: '--sub-text',
    footerBorder: '--footer-border',
    refreshBorder: '--refresh-border',
    refreshBackground: '--refresh-bg',
    refreshColor: '--refresh-color',
    refreshHoverBackground: '--refresh-hover-bg',
};

/** @type {Record<string, string>|null} */
let nuiStrings = null;

function applyUiConfig(ui) {
    const doc = document.documentElement.style;
    if (!ui || typeof ui !== 'object') return;
    for (const [key, cssVar] of Object.entries(UI_VAR_MAP)) {
        if (Object.prototype.hasOwnProperty.call(ui, key)) {
            const v = ui[key];
            if (typeof v === 'string' && v.length > 0 && v.length <= 128) {
                doc.setProperty(cssVar, v);
            }
        }
    }
}

/** @param {Record<string, string>|undefined} strings */
function applyNuiStrings(strings) {
    nuiStrings = strings && typeof strings === 'object' ? strings : null;
    if (!nuiStrings) return;

    if (typeof nuiStrings.title === 'string') {
        uiTitle.textContent = nuiStrings.title;
        document.title = nuiStrings.title;
    }
    if (typeof nuiStrings.hintBefore === 'string') hintBefore.textContent = nuiStrings.hintBefore;
    if (typeof nuiStrings.escKey === 'string') kbdEsc.textContent = nuiStrings.escKey;
    if (typeof nuiStrings.hintAfter === 'string') hintAfter.textContent = nuiStrings.hintAfter;
    if (typeof nuiStrings.refresh === 'string') btnRefresh.textContent = nuiStrings.refresh;
    if (typeof nuiStrings.closeAria === 'string') {
        btnClose.setAttribute('aria-label', nuiStrings.closeAria);
        btnClose.title = nuiStrings.closeAria;
    }
}

function formatOne(str, arg) {
    if (typeof str !== 'string') return '';
    let i = 0;
    const args = arg !== undefined ? [arg] : [];
    return str.replace(/%s/g, () => String(args[i++] ?? ''));
}

function post(name, data) {
    const res = GetParentResourceName();
    return fetch(`https://${res}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    });
}

function renderSeats(seats) {
    seatList.innerHTML = '';
    if (!Array.isArray(seats)) return;

    const sHere = (nuiStrings && nuiStrings.statusHere) || 'You are here';
    const sOcc = (nuiStrings && nuiStrings.statusOccupied) || 'Occupied';
    const sEmp = (nuiStrings && nuiStrings.statusEmpty) || 'Empty';
    const sFallback = (nuiStrings && nuiStrings.seatFallback) || 'Seat %s';

    for (const s of seats) {
        const li = document.createElement('li');
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'seat-item';
        if (s.current) btn.classList.add('current');
        btn.disabled = !s.free;

        const main = document.createElement('span');
        main.textContent =
            typeof s.label === 'string' && s.label.length > 0
                ? s.label
                : formatOne(sFallback, Number(s.index) + 2);
        btn.appendChild(main);

        const sub = document.createElement('span');
        sub.className = 'sub';
        if (s.current) sub.textContent = sHere;
        else if (!s.free) sub.textContent = sOcc;
        else sub.textContent = sEmp;
        btn.appendChild(sub);

        btn.addEventListener('click', () => {
            if (!s.free) return;
            post('selectSeat', { seat: s.index });
        });

        li.appendChild(btn);
        seatList.appendChild(li);
    }
}

window.addEventListener('message', (event) => {
    const d = event.data;
    if (!d || typeof d !== 'object') return;

    if (d.action === 'open') {
        applyUiConfig(d.ui);
        applyNuiStrings(d.strings);
        root.classList.remove('hidden');
        renderSeats(d.seats);
    }
    if (d.action === 'close') {
        root.classList.add('hidden');
        seatList.innerHTML = '';
    }
});

btnClose.addEventListener('click', () => post('close', {}));

btnRefresh.addEventListener('click', () => post('refresh', {}));

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !root.classList.contains('hidden')) {
        post('close', {});
    }
});
