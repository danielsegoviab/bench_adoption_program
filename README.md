# Van Cortlandt Park bench adoption

**Live site:** https://danielsegoviab.github.io/bench_adoption_program/

A single source of truth for the park's bench adoption program, backed by a shared database. Anyone can:

1. **View** all 512 benches, see which are adopted, by whom, and until when.
2. **Adopt** an available bench by entering a name, email, duration and optional plaque dedication (payment happens in person).
3. **Staff** (`staff.html`, login required) can see every adoption including emails, mark adoptions as paid, fix names or dedications, cancel or restore adoptions, and download everything as a CSV.

## How it works
- **One shared database (Supabase / Postgres).** All adoptions live in one `adoptions` table, so every visitor and every staff member sees the same data. The schema, rules and sample data are in `setup.sql`.
- **The database prevents double adoptions itself.** An exclusion constraint refuses two non-cancelled adoptions of the same bench with overlapping dates, even if two people click at the same moment.
- **Privacy is enforced by the database, not the page.** The page's key is public by design, so row-level security and column permissions decide what it can do: visitors can read adoptions without emails and create new ones (always as "pending payment"); only logged-in staff can read emails or edit. Fees are calculated by the database, so they can't be changed from a browser.
- **Payment workflow.** New adoptions are reserved as "awaiting payment". Staff mark them paid when the donor pays at the entrance; unpaid reservations are flagged as overdue after 14 days so staff can follow up or cancel.
- **Staff accounts** are created by the administrator in Supabase; public sign-ups are disabled.

## How to use it
- Benches are grouped by area of the park. Green tiles are available, brown tiles are adopted, and brown tiles with an orange border have adoptions ending within 60 days.
- Switch between **Grid** and **Map** views. Both show the same benches with the same filters.
- Filter by status or area, or search by bench number or adopter name.
- Click any bench (a tile or a dot on the map) to see its details, or to adopt it if it's available.

## Key decisions
- **Status is calculated, not stored.** A bench's status comes from its adoption dates every time the page loads. When an adoption ends, the bench becomes available automatically, with no manual cleanup. This avoids the "stale spreadsheet" problem the program has today.
- **No double adoptions.** Availability is re-checked at the moment of adoption, so a bench can only have one active adopter.
- **"Ending soon" view.** Staff can filter for adoptions ending within 60 days to contact donors about renewing.
- **Adoption history kept.** Past adoptions are never deleted, so an available bench shows who adopted it last.
- **Email is private.** Adopters' emails are collected for staff but never displayed publicly.
- **Map and grid share one data source.** One filter function feeds both views, so they can never disagree. The map is an illustrated sketch of the park's main features (lake, lawns, forests, paths, surrounding roads), traced from Google Maps screenshots and converted to real coordinates using landmarks with published coordinates (accurate to roughly 30 m). The walking paths were detected automatically from the trail lines in those screenshots, and benches are spaced evenly along them, with denser spacing by the lake and the House and sparser on golf paths. The grid opens by default because it's faster for scanning 512 benches; the map helps when location matters ("the bench by the lake").
- **Design.** A Columbia-blue palette with Source Serif and Source Sans type. Status is shown by fill as well as color (outlined = available, solid = adopted, amber ring = ending soon), so it stays readable for color-blind users.
- **Real fees.** The adoption form shows an estimated contribution based on the Van Cortlandt Park Alliance's actual price ($3,500 to adopt an existing bench for 10 years, per vancortlandt.org/bench), prorated for shorter terms. After adopting, the bench shows the amount due and where to pay.
- **One file, no build step.** Plain HTML, CSS and JavaScript keep the project simple to read, run and host.

## Assumptions
- One adopter (person or organization) per bench at a time.
- Adoptions start on the day they're made and last 6, 12, 24, 36, 60 or 120 months (the Alliance's standard term is 10 years).
- Payment is made in person (cash, card or check) at the Broadway & W 242nd St entrance within 14 days. This is a demo choice; the real Alliance takes payment online, by check or by Zelle.
- Renewals and early cancellations are out of scope.
- The park has 512 benches in 9 areas, placed on real paths (the Northeast Forest, which the screenshots didn't cover in detail, uses an approximate loop). Bench locations and existing adoptions are **generated sample data**. In production they would come from the Parks Department's inventory and current records.

## Limitations and next steps
- **Overdue reservations aren't cancelled automatically.** Staff see them flagged and decide; a scheduled job could cancel them after 14 days.
- **No spam protection yet.** Anyone can submit adoptions; a production version would add email verification or a CAPTCHA, and rate limits.
- **Renewals** from the staff page, and **confirmation emails** to adopters.
- Payment, confirmation emails and renewal reminders.

## Staff demo login
Reviewers can try the staff page at `/staff.html` with the demo account: **email:** `ADD-DEMO-EMAIL` / **password:** `ADD-DEMO-PASSWORD`. All existing data is sample data.

## Running locally
Download `index.html` and open it in any browser. No installation needed; the map needs an internet connection to load the Leaflet library.
