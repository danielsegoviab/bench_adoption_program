# Van Cortlandt Park bench adoption

Live: https://danielsegoviab.github.io/bench_adoption_program/  
Staff page: https://danielsegoviab.github.io/bench_adoption_program/staff.html

Take-home for Columbia Software Solutions (option 2, Bench Adoption Program).

The park has 500+ benches and no single place that says which ones are adopted, by whom, or until when. This app is that place. Visitors can browse every bench and adopt an available one; staff get a logged-in view to manage the records.

## Staff demo login

- Email: `css_staff_user@gmail.com`
- Password: `ColumbiaUniversity`

It's a demo account and everything in the database is sample data, so feel free to click around (mark things paid, cancel, edit).

## What it does

**Public site (`index.html`)**
- All 512 benches, as a grid grouped by area or on a map of the park
- Filter by status (available / adopted / ending soon) and area, search by bench number or adopter name
- Click a bench to see who adopted it and until when, or to adopt it
- The adoption form shows the fee estimate and where to pay

**Staff page (`staff.html`)**
- Every adoption, including emails (which the public never sees)
- Mark as paid, edit name/email/plaque text, cancel, restore
- Totals for outstanding and collected payments, and adoptions ending soon (renewal calls)
- Download the current view as a CSV

## How it's built

Plain HTML/CSS/JS, no build step. Leaflet for the map, Supabase (Postgres) for the database. Hosted on GitHub Pages.

The benches themselves are fixed and live in the code. Adoptions are the only thing that changes, so they're the only thing in the database: one `adoptions` table. `setup.sql` has the schema, permissions and sample data.

A few decisions worth explaining:

- **Status is calculated from dates, never stored.** A bench is adopted if it has a non-cancelled adoption that hasn't ended yet. When an adoption ends, the bench frees up on its own; nobody has to remember to update anything.
- **The database blocks double adoptions, not just the page.** The page checks availability first, but two people could click at the same moment. An exclusion constraint on (bench, date range) makes overlapping adoptions impossible at the database level, and the page shows the visitor a clear message if it happens.
- **Permissions live in the database.** The Supabase key in the page is public by design, so row-level security and column grants decide what it can do. Anonymous visitors can read adoptions (minus email and fee) and insert new ones, always as "pending". Only logged-in staff can read emails or update rows. Public sign-ups are off, so staff accounts are created by hand.
- **The fee is computed by the database** from the duration, so it can't be edited from the browser.
- **Payment is a status, not a feature.** The brief said no payments, so new adoptions are reserved as "awaiting payment" and staff mark them paid. A scheduled job in the database (pg_cron) runs every morning and releases reservations that are still unpaid after 14 days, so benches never stay blocked by abandoned reservations.
- **Dates follow New York time.** The database stores start dates in the park's own time zone, and any adoption that hasn't ended (including ones starting later) reserves the bench, so a reserved bench is never offered to someone else.
- **Map and grid use the same filter function**, so they can't disagree.

## Where the data comes from

- **Fees** follow the real Van Cortlandt Park Alliance program: $3,500 to adopt an existing bench for 10 years (vancortlandt.org/bench). Shorter terms are prorated.
- **The map** is my own drawing of the park, traced from Google Maps screenshots and lined up with real coordinates using landmarks with known positions (Van Cortlandt House and the 242 St, Woodlawn and Mosholu Pkwy stations). It's accurate to about 30 m. The walking paths were pulled out of the screenshots by detecting the trail lines, and benches are spaced along them. For a real deployment I'd use NYC Open Data or OpenStreetMap instead, since Google's map data isn't free to reuse.
- **Bench locations and existing adoptions are made up.** The real bench inventory would come from NYC Parks.

## Assumptions

- One adopter (person or group) per bench at a time.
- Adoptions start the day they're made and last 6 months to 10 years.
- Payment happens in person at the Broadway & W 242nd St entrance within 14 days. That's a demo choice; the real Alliance takes payments online, by check or Zelle.
- 512 benches across 9 areas.

## Possible extensions

- Confirmation emails to adopters
- Renewals directly from the staff page
- A CAPTCHA or email verification on the adoption form

## Running it

Open `index.html` in a browser; it talks to the hosted database, so there's nothing to install. To point it at your own database, run `setup.sql` in a new Supabase project and swap the URL and publishable key at the top of the script in `index.html` and `staff.html`.
