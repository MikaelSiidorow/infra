// @ts-check

/**
 * @typedef {object} Departure
 * @property {number} serviceDay
 * @property {number} realtimeDeparture
 * @property {string} headsign
 * @property {{ route: { shortName: string } }} trip
 */

/**
 * @typedef {object} EntityAttributes
 * @property {Departure[]=} stoptimesWithoutPatterns
 * @property {string=} media_title
 * @property {string=} friendly_name
 * @property {string=} media_artist
 * @property {string=} media_series_title
 * @property {string=} app_name
 * @property {string=} source
 * @property {string=} entity_picture
 * @property {string=} media_image_url
 * @property {string=} unit_of_measurement
 * @property {number=} temperature
 * @property {string=} temperature_unit
 * @property {number=} apparent_temperature
 * @property {number|string=} high_temperature
 * @property {number|string=} low_temperature
 * @property {number|string=} precipitation_probability
 * @property {number|string=} precipitation
 */

/** @typedef {{ entity_id: string, state: string, last_changed: string, attributes: EntityAttributes }} HassEntity */
/** @typedef {{ states: Record<string, HassEntity>, callService: (domain: string, service: string, data: Record<string, unknown>) => Promise<unknown> }} HomeAssistant */
/** @typedef {{ entity: HassEntity, entityId: string, source: string, hasArtwork: boolean }} ActiveMedia */
/** @typedef {{ type: string, name: string, description: string, preview: boolean }} CustomCardRegistration */

const moduleUrl = new URL(import.meta.url);
const stylesheetUrl = new URL("./mythos-dashboard.css", moduleUrl);
stylesheetUrl.search = moduleUrl.search;

const ENTITY = {
  departures: "sensor.pohjantori_departures",
  weather: "weather.home",
  weatherToday: "sensor.home_weather_today",
  chromecast: "media_player.living_room_tv",
  sonos: "media_player.sonos_ray",
  vacuum: "vacuum.exterminator",
  vacuumStatus: "sensor.exterminator_status",
  vacuumBattery: "sensor.exterminator_battery",
  vacuumProgress: "sensor.exterminator_cleaning_progress",
  vacuumArea: "sensor.exterminator_cleaning_area",
  vacuumTime: "sensor.exterminator_cleaning_time",
  vacuumNextRun: "sensor.exterminator_next_scheduled_cleaning",
  bathroomTemperature: "sensor.bathroom_thermometer_temperature",
  bathroomHumidity: "sensor.bathroom_thermometer_humidity",
  washingMachinePower: "sensor.washing_machine_plug_power",
  washingMachineRunning: "binary_sensor.washing_machine_running",
  pcPower: "sensor.pc_plug_power",
  pcRunning: "binary_sensor.pc_running",
};

const MEDIA_ACTIVE_STATES = new Set(["playing", "paused", "buffering"]);
const MISSING_STATES = new Set(["unknown", "unavailable", "none", ""]);
const WALK_TO_STOP_SECONDS = 3 * 60;

class MythosDashboard extends HTMLElement {
  constructor() {
    super();
    const shadowRoot = this.attachShadow({ mode: "open" });
    shadowRoot.innerHTML = `
      <link rel="stylesheet" href="${stylesheetUrl.href}" />
      <div class="render-root"></div>
    `;
    /** @type {HomeAssistant | null} */
    this._hass = null;
    this._lastMarkup = "";
    /** @type {number | undefined} */
    this._relativeTimeTimer = undefined;
  }

  /** @param {Record<string, unknown>} config */
  setConfig(config) {
    this._config = config;
    this.toggleAttribute("cast-view", config.cast_view === true);
    this.render();
  }

  /** @param {HomeAssistant} hass */
  set hass(hass) {
    this._hass = hass;
    this.render();
  }

  connectedCallback() {
    this._relativeTimeTimer = window.setInterval(() => this.render(), 15_000);
    this.render();
  }

  disconnectedCallback() {
    if (this._relativeTimeTimer !== undefined) window.clearInterval(this._relativeTimeTimer);
  }

  getCardSize() {
    return 1;
  }

  /** @param {string} entityId */
  entity(entityId) {
    return this._hass?.states?.[entityId];
  }

  /**
   * @param {HassEntity | undefined} entity
   * @returns {entity is HassEntity}
   */
  isAvailable(entity) {
    return entity !== undefined && !MISSING_STATES.has(entity.state);
  }

  /** @param {unknown} value */
  escape(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  /** @param {Date} now */
  renderDepartures(now) {
    const sensor = this.entity(ENTITY.departures);
    const departures = sensor?.attributes?.stoptimesWithoutPatterns ?? [];
    const buses = departures
      .filter((departure) => ["111", "113"].includes(departure?.trip?.route?.shortName))
      .slice(0, 3);

    if (buses.length === 0) {
      return '<div class="empty-state">No upcoming 111 or 113 departures</div>';
    }

    const firstCatchableIndex = buses.findIndex((departure) => {
      const timestamp = (departure.serviceDay + departure.realtimeDeparture) * 1000;
      return (timestamp - now.getTime()) / 1000 >= WALK_TO_STOP_SECONDS;
    });

    return buses
      .map((departure, index) => {
        const timestamp = (departure.serviceDay + departure.realtimeDeparture) * 1000;
        const seconds = Math.max(0, Math.round((timestamp - now.getTime()) / 1000));
        const minutes = Math.ceil(seconds / 60);
        const relative = seconds <= 30 ? "Now" : seconds < 90 ? "~1 min" : `${minutes} min`;
        const absolute = new Intl.DateTimeFormat("en-FI", {
          hour: "2-digit",
          minute: "2-digit",
          hour12: false,
        })
          .format(timestamp)
          .replace(":", ".");
        const destination = departure.headsign.replaceAll(" (M)", "");
        const unreachable = seconds < WALK_TO_STOP_SECONDS;
        const recommended = index === firstCatchableIndex;

        return `
          <div class="departure-row ${unreachable ? "unreachable" : ""} ${recommended ? "recommended" : ""}">
            <div class="route-block">
              <div class="route">${this.escape(departure.trip.route.shortName)}</div>
              <div class="destination">${this.escape(destination)}</div>
            </div>
            <div class="departure-time">
              <strong>${relative}</strong>
              <span>${absolute}</span>
            </div>
          </div>
        `;
      })
      .join("");
  }

  renderWeather() {
    const weather = this.entity(ENTITY.weather);
    if (!this.isAvailable(weather) || weather.attributes.temperature === undefined) return "";

    const today = this.entity(ENTITY.weatherToday);
    const temperature = Number(weather.attributes.temperature).toLocaleString("en-FI", {
      maximumFractionDigits: 0,
    });
    const unit = weather.attributes.temperature_unit ?? "°C";
    const condition = weather.state.replaceAll("-", " ");
    const displayCondition = condition.charAt(0).toLocaleUpperCase() + condition.slice(1);
    const high = Number(today?.attributes.high_temperature);
    const low = Number(today?.attributes.low_temperature);
    const rainProbability = Number(today?.attributes.precipitation_probability);
    const precipitation = Number(today?.attributes.precipitation);
    const hasRange = Number.isFinite(high) && Number.isFinite(low);
    const hasRainProbability = Number.isFinite(rainProbability);
    const hasPrecipitation = Number.isFinite(precipitation) && precipitation > 0;
    /** @type {Record<string, string>} */
    const conditionIcons = {
      "clear-night": "mdi:weather-night",
      cloudy: "mdi:weather-cloudy",
      fog: "mdi:weather-fog",
      hail: "mdi:weather-hail",
      lightning: "mdi:weather-lightning",
      "lightning-rainy": "mdi:weather-lightning-rainy",
      partlycloudy: "mdi:weather-partly-cloudy",
      pouring: "mdi:weather-pouring",
      rainy: "mdi:weather-rainy",
      snowy: "mdi:weather-snowy",
      "snowy-rainy": "mdi:weather-snowy-rainy",
      sunny: "mdi:weather-sunny",
      windy: "mdi:weather-windy",
      "windy-variant": "mdi:weather-windy-variant",
    };
    const conditionIcon = conditionIcons[weather.state] ?? "mdi:weather-cloudy-alert";

    return `
      <section class="weather-feature" aria-label="Today's weather">
        <div class="weather-current">
          <div class="weather-current-line">
            <ha-icon class="weather-condition-icon" icon="${conditionIcon}"></ha-icon>
            <strong>${this.escape(temperature)}<span>${this.escape(unit)}</span></strong>
          </div>
          <div class="weather-condition">${this.escape(displayCondition)}</div>
        </div>
        ${
          hasRange
            ? `<div class="weather-range"><span><strong>${high.toLocaleString("en-FI", { maximumFractionDigits: 0 })}°</strong> high</span><span><strong>${low.toLocaleString("en-FI", { maximumFractionDigits: 0 })}°</strong> low</span></div>`
            : ""
        }
        ${
          hasRainProbability
            ? `<div class="weather-rain"><ha-icon icon="mdi:weather-rainy"></ha-icon><span><strong>${rainProbability.toLocaleString("en-FI", { maximumFractionDigits: 0 })} %</strong> rain today${hasPrecipitation ? ` · ${precipitation.toLocaleString("en-FI", { maximumFractionDigits: 1 })} mm` : ""}</span></div>`
            : ""
        }
      </section>
    `;
  }

  /** @returns {ActiveMedia | null} */
  activeMedia() {
    const chromecast = this.entity(ENTITY.chromecast);
    if (chromecast && MEDIA_ACTIVE_STATES.has(chromecast.state)) {
      return {
        entity: chromecast,
        entityId: ENTITY.chromecast,
        source: "Chromecast",
        hasArtwork: Boolean(
          chromecast.attributes.entity_picture || chromecast.attributes.media_image_url,
        ),
      };
    }

    const sonos = this.entity(ENTITY.sonos);
    if (sonos && this.isAvailable(sonos) && !["off", "idle"].includes(sonos.state)) {
      return {
        entity: sonos,
        entityId: ENTITY.sonos,
        source: "Sonos Ray",
        hasArtwork: Boolean(sonos.attributes.entity_picture || sonos.attributes.media_image_url),
      };
    }

    return null;
  }

  /** @param {ActiveMedia | null} media */
  renderMedia(media) {
    if (!media) return "";

    const attributes = media.entity.attributes ?? {};
    const title = attributes.media_title || attributes.friendly_name || "Now playing";
    const detail =
      attributes.media_artist ||
      attributes.media_series_title ||
      attributes.app_name ||
      attributes.source ||
      "";
    const image = attributes.entity_picture || attributes.media_image_url;
    const distinctDetail = detail.toLocaleLowerCase() === title.toLocaleLowerCase() ? "" : detail;
    const playing = media.entity.state === "playing";

    return `
      <section class="media ${media.hasArtwork ? "with-artwork" : "compact"} panel">
        ${image ? `<div class="artwork"><img src="${this.escape(image)}" alt="" /></div>` : ""}
        <div class="media-copy">
          <div class="eyebrow">Now playing · ${this.escape(media.source)}</div>
          <div class="media-title">${this.escape(title)}</div>
          ${distinctDetail ? `<div class="media-detail">${this.escape(distinctDetail)}</div>` : ""}
        </div>
        <button class="media-toggle" data-media-toggle="${this.escape(media.entityId)}" aria-label="${playing ? "Pause" : "Play"}">
          ${playing ? "Ⅱ" : "▶"}
        </button>
      </section>
    `;
  }

  renderVacuum() {
    const statusEntity = this.entity(ENTITY.vacuumStatus);
    const batteryEntity = this.entity(ENTITY.vacuumBattery);
    const vacuumEntity = this.entity(ENTITY.vacuum);
    const nextRunEntity = this.entity(ENTITY.vacuumNextRun);
    const status = this.isAvailable(statusEntity)
      ? statusEntity.state.replaceAll("_", " ")
      : "Offline";
    const displayStatus = status.charAt(0).toLocaleUpperCase() + status.slice(1);
    const battery = this.isAvailable(batteryEntity) ? `${batteryEntity.state}%` : "";
    const isCleaning = vacuumEntity?.state === "cleaning";

    let cleaningDetail = "";
    if (isCleaning) {
      const progress = this.entity(ENTITY.vacuumProgress)?.state;
      const area = this.entity(ENTITY.vacuumArea)?.state;
      const time = this.entity(ENTITY.vacuumTime)?.state;
      cleaningDetail = [progress && `${progress}%`, area && `${area} m²`, time]
        .filter(Boolean)
        .join(" · ");
    }

    let nextRun = "Schedule unavailable";
    if (this.isAvailable(nextRunEntity)) {
      const parsed = new Date(nextRunEntity.state);
      if (!Number.isNaN(parsed.getTime())) {
        nextRun = new Intl.DateTimeFormat("en-FI", {
          weekday: "long",
          hour: "2-digit",
          minute: "2-digit",
          hour12: false,
        }).format(parsed);
      }
    }

    const attention = !["charging", "docked", "idle"].includes(status.toLocaleLowerCase());
    const detail = cleaningDetail || `Next ${nextRun}`;

    return `
      <article class="metric vacuum-compact ${attention ? "attention" : ""}">
        <div>
          <div class="metric-label">Exterminator${battery ? ` · ${this.escape(battery)}` : ""}</div>
          <div class="metric-value">${this.escape(displayStatus)}</div>
          <div class="metric-detail">${this.escape(detail)}</div>
        </div>
      </article>
    `;
  }

  renderBathroom() {
    const temperature = this.entity(ENTITY.bathroomTemperature);
    const humidity = this.entity(ENTITY.bathroomHumidity);
    if (!this.isAvailable(temperature) && !this.isAvailable(humidity)) return "";

    const temperatureValue = this.isAvailable(temperature)
      ? `${Number(temperature.state).toLocaleString("en-FI", { maximumFractionDigits: 1 })} ${temperature.attributes.unit_of_measurement ?? "°C"}`
      : "Temperature unavailable";
    const humidityValue = this.isAvailable(humidity)
      ? `${Number(humidity.state).toLocaleString("en-FI", { maximumFractionDigits: 0 })} ${humidity.attributes.unit_of_measurement ?? "%"} humidity`
      : "";

    return `
      <article class="metric">
        <div>
          <div class="metric-label">Bathroom</div>
          <div class="metric-value">${this.escape(temperatureValue)}</div>
          ${humidityValue ? `<div class="metric-detail">${this.escape(humidityValue)}</div>` : ""}
        </div>
      </article>
    `;
  }

  /**
   * @param {string} powerEntityId
   * @param {string} runningEntityId
   * @param {string} label
   * @param {number} fallbackThreshold
   */
  renderPowerMetric(powerEntityId, runningEntityId, label, fallbackThreshold) {
    const powerEntity = this.entity(powerEntityId);
    const runningEntity = this.entity(runningEntityId);
    if (!this.isAvailable(powerEntity)) return "";

    const power = Number(powerEntity.state);
    const unit = powerEntity.attributes.unit_of_measurement ?? "W";
    const running = this.isAvailable(runningEntity)
      ? runningEntity.state === "on"
      : Number.isFinite(power) && power > fallbackThreshold;
    if (!running) return "";

    const elapsed = this.formatElapsed(
      this.isAvailable(runningEntity) ? runningEntity.last_changed : null,
    );
    const value = `${power.toLocaleString("en-FI", { maximumFractionDigits: 1 })} ${unit}`;

    return `
      <article class="metric attention">
        <div>
          <div class="metric-label">${this.escape(label)}</div>
          <div class="metric-value">${this.escape(value)}</div>
          ${elapsed ? `<div class="metric-detail">Running ${this.escape(elapsed)}</div>` : ""}
        </div>
      </article>
    `;
  }

  /** @param {string | null} changedAt */
  formatElapsed(changedAt) {
    if (!changedAt) return "";
    const minutes = Math.max(0, Math.floor((Date.now() - new Date(changedAt).getTime()) / 60_000));
    if (minutes < 1) return "<1 min";
    if (minutes < 60) return `${minutes} min`;
    const hours = Math.floor(minutes / 60);
    const remainder = minutes % 60;
    return remainder ? `${hours} h ${remainder} min` : `${hours} h`;
  }

  render() {
    if (!this.shadowRoot) return;
    const renderRoot = this.shadowRoot.querySelector(".render-root");
    if (!(renderRoot instanceof HTMLDivElement)) return;

    const now = new Date();
    const timeParts = new Intl.DateTimeFormat("en-FI", {
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }).formatToParts(now);
    /** @param {string} type */
    const timePart = (type) => timeParts.find((item) => item.type === type)?.value ?? "00";
    const hoursMinutes = `${timePart("hour")}.${timePart("minute")}`;
    const weekday = new Intl.DateTimeFormat("en-FI", { weekday: "long" }).format(now);
    const date = new Intl.DateTimeFormat("en-FI", {
      day: "numeric",
      month: "long",
      year: "numeric",
    }).format(now);
    const media = this.activeMedia();

    const markup = `
      <div class="ambient-background" aria-hidden="true"></div>
      <main class="dashboard ${media ? "has-media" : ""}">
        <section class="primary-column">
          <header class="clock">
            <time>${hoursMinutes}</time>
            <div class="weekday">${this.escape(weekday)}</div>
            <div class="date">${this.escape(date)}</div>
          </header>

          <section class="departures panel">
            <header>
              <div class="departures-title">
                <ha-icon icon="mdi:bus-clock"></ha-icon>
                <div>
                <h1>Pohjantori</h1>
                <p>Louhentie · E2052</p>
                </div>
              </div>
            </header>
            <div class="departure-list">${this.renderDepartures(now)}</div>
          </section>
        </section>

        <section class="secondary-column">
          ${this.renderWeather()}
          <aside class="wifi-card panel">
            <div class="eyebrow">Wi-Fi</div>
            <img src="/local/mythos-wifi.png" alt="Mythos Wi-Fi QR code" />
          </aside>
          <section class="status-strip">
            ${this.renderVacuum()}
            ${this.renderBathroom()}
            ${this.renderPowerMetric(ENTITY.washingMachinePower, ENTITY.washingMachineRunning, "Washing machine", 3)}
            ${this.renderPowerMetric(ENTITY.pcPower, ENTITY.pcRunning, "PC", 15)}
          </section>
          ${this.renderMedia(media)}
        </section>
      </main>
    `;

    if (markup === this._lastMarkup) return;
    this._lastMarkup = markup;
    renderRoot.innerHTML = markup;
    const mediaToggle = renderRoot.querySelector("[data-media-toggle]");
    if (mediaToggle instanceof HTMLButtonElement) {
      mediaToggle.addEventListener("click", () => {
        const entityId = mediaToggle.dataset.mediaToggle;
        if (entityId && this._hass) {
          void this._hass.callService("media_player", "media_play_pause", {
            entity_id: entityId,
          });
        }
      });
    }
  }
}

if (!customElements.get("mythos-dashboard")) {
  customElements.define("mythos-dashboard", MythosDashboard);
}

/** @type {Window & typeof globalThis & { customCards?: CustomCardRegistration[] }} */
const dashboardWindow = window;
dashboardWindow.customCards ??= [];
dashboardWindow.customCards.push({
  type: "mythos-dashboard",
  name: "Mythos information display",
  description: "Read-only household information display",
  preview: false,
});
