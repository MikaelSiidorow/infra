# Hestia Information Display Plan

## Goal

Build a reusable household information dashboard, starting with nearby public
transport departures. Develop and test it in a normal browser before buying a
dedicated display.

Possible displays, in order of evaluation:

1. Existing laptop or phone browser during development.
2. An old tablet running a dedicated Home Assistant dashboard.
3. The TV through the existing Chromecast for short, scheduled sessions.
4. A TRMNL or another e-ink display if the result proves useful enough.

The data model must not depend on any particular display.

## Decisions already made

- Hestia remains the service host.
- Home Assistant owns the household-facing dashboard and automations.
- HSL/Digitransit is the source for scheduled and real-time departures.
- API credentials must be managed with SOPS and must not enter the Nix store.
- Build the departure data and browser dashboard before purchasing hardware.
- Use HDMI-CEC or the TV's native integration for power control. Do not
  routinely hard-power-cycle the TV with a smart plug.
- A smart plug may still be used for energy measurement.
- Chromecast support will use a publicly trusted certificate for
  `ha.miksu.app`, while Home Assistant remains reachable only from the LAN and
  tailnet. Do not add an internet-facing port forward merely for casting.
- Any automatic TV display must yield to active video or music casting.

## Phase 1: Define the departure view

Collect the following user choices before implementing the query:

- Nearby stop or station names, or an approximate home location.
- Which directions and destinations matter.
- Normal weekday departure window.
- Walking time from home to each stop.
- Number of departures to show.
- Whether cancelled, delayed, or non-real-time departures need special
  highlighting.

Initial display target:

- Current time.
- The next three to five useful departures.
- Route number and destination.
- Scheduled and real-time departure where available.
- Minutes until departure.
- A derived `leave in N minutes` value after subtracting walking time and a
  small safety margin.
- Clear stale-data and API-error states.

## Phase 2: Digitransit data on Hestia

1. Register a Digitransit API subscription key.
2. Add the key to the repository's existing SOPS workflow.
3. Identify stable Digitransit stop IDs; do not query by a display name during
   normal operation.
4. Test the smallest useful GraphQL query manually.
5. Choose the least complex maintainable ingestion method after seeing the
   response:
   - Home Assistant REST sensors if GraphQL POST, authentication, parsing, and
     error handling remain readable; or
   - a small Nix-managed fetcher publishing retained state through the existing
     MQTT broker if HA templates become awkward.
6. Poll at a responsible interval, initially 30-60 seconds.
7. Preserve the last successful result but mark it stale when updates fail.
8. Expose normalized Home Assistant entities independent of the raw API shape.

The normalized data should make changing the visual display possible without
rewriting the Digitransit client.

## Phase 3: Home Assistant dashboard

Create a separate, non-admin household display dashboard rather than modifying
the main administrative dashboard.

Start with built-in Home Assistant cards and a high-contrast layout. Avoid HACS
or a custom frontend component unless built-in cards cannot express the final
departure view.

Candidate sections:

- Departures and leave-by time.
- Current weather and near-term rain.
- Indoor temperature and humidity.
- Shopping list.
- Household calendar.
- A small number of useful light and plug controls.
- Prominent leak warnings.

Test at phone, tablet, and TV aspect ratios. The e-ink layout may later be a
separate simplified rendering of the same entities.

## Phase 4: Old-tablet trial

1. Check the available tablet model, OS version, battery condition, and browser
   compatibility.
2. Create a dedicated non-admin Home Assistant user.
3. Open the display dashboard in kiosk or full-screen mode.
4. Dim or turn off the screen overnight and avoid OLED burn-in.
5. If the tablet reports battery level to Home Assistant, optionally use a
   charger smart plug to maintain an approximate 40-80% charge range instead
   of holding an old battery at 100% continuously.
6. Run the trial long enough to learn whether the information is genuinely
   useful and where the display belongs.

## Phase 5: Trusted HTTPS and Chromecast

This phase is unnecessary for browser development and should follow a useful
working dashboard.

1. Add a Cloudflare DNS-only record for `ha.miksu.app` resolving publicly to
   Hestia's private LAN address. The record must not be Cloudflare-proxied.
2. Obtain a publicly trusted certificate using an ACME DNS-01 challenge and a
   narrowly scoped Cloudflare API token stored with SOPS.
3. Prefer the NixOS ACME module with Caddy reading the resulting certificate if
   that is simpler than building Caddy with a DNS-provider plugin.
4. Serve `https://ha.miksu.app` through Caddy and open TCP 443 only on Hestia's
   LAN interface.
5. Do not forward ports 80 or 443 from the internet-facing router.
6. Set the Home Assistant URL through Settings -> System -> Network, since this
   setting is UI-managed in the installed Home Assistant version.
7. Verify the public DNS answer through Google DNS and confirm the Chromecast
   can reach the private address and validate the certificate.
8. Test `cast.show_lovelace_view` manually before adding automation.

Morning automation outline:

1. Trigger on selected weekdays and time, or eventually from a work calendar.
2. Require that someone is home.
3. Require that the TV and Chromecast are not already in active use.
4. Cast the information dashboard; allow HDMI-CEC to wake the TV.
5. End the dashboard session after the configured morning window only if it is
   still the active Cast application. Never stop media that replaced it.
6. Return the TV to standby through CEC or its native Home Assistant
   integration.

## Phase 6: Optional e-ink display

Reconsider TRMNL or a DIY ESPHome/Waveshare display only after the tablet trial.

TRMNL advantages:

- Finished enclosure and stand.
- Very low power consumption and long battery life.
- Calm, readable display.
- Existing Home Assistant screenshot support and custom plugin options.

Tradeoffs:

- Purchase cost and possible cloud dependency.
- Slow refresh compared with a tablet.
- Bus departures need a deliberate refresh interval and stale-data indicator.
- A normal Home Assistant dashboard should be redesigned for e-ink rather than
  merely scaled down.

A DIY e-ink device may be cheaper in parts but adds enclosure, power, firmware,
and rendering work. Treat it as a separate hobby project rather than a required
part of the dashboard.

## Verification and safety

- Never expose Digitransit or Cloudflare credentials in Git, the Nix store, HA
  entity attributes, logs, or dashboard URLs.
- API failure must not break Home Assistant activation or startup.
- Do not make household internet or DNS depend on the display service.
- Do not deploy router changes without an explicit outage warning and immediate
  user confirmation.
- Do not let a scheduled dashboard cast interrupt active entertainment.
- Keep the original `ha.home.arpa` route available until HTTPS and all clients
  have been verified.

## Immediate next step

Obtain the relevant stop names or approximate location, directions, walking
times, and weekday time window. Then prototype the Digitransit query without
changing the running Hestia configuration.
