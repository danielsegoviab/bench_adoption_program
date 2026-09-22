# Van Cortlandt Park bench adoption

**Live site:** https://YOUR-USERNAME.github.io/bench-adoption/

A single source of truth for the park's bench adoption program. Anyone can:

1. **View** all 512 benches, see which are adopted, by whom, and until when.
2. **Adopt** an available bench by entering a name, email, duration and optional plaque dedication (no payment).

## How to use it
- Benches are grouped by area of the park. Green tiles are available, brown tiles are adopted, and brown tiles with an orange border have adoptions ending within 60 days.
- Filter by status or area, or search by bench number or adopter name.
- Click any bench to see its details, or to adopt it if it's available.

## Key decisions
- **Status is calculated, not stored.** A bench's status comes from its adoption dates every time the page loads. When an adoption ends, the bench becomes available automatically, with no manual cleanup. This avoids the "stale spreadsheet" problem the program has today.
- **No double adoptions.** Availability is re-checked at the moment of adoption, so a bench can only have one active adopter.
- **"Ending soon" view.** Staff can filter for adoptions ending within 60 days to contact donors about renewing.
- **Adoption history kept.** Past adoptions are never deleted, so an available bench shows who adopted it last.
- **Email is private.** Adopters' emails are collected for staff but never displayed publicly.
- **One file, no build step.** Plain HTML, CSS and JavaScript keep the project simple to read, run and host.

## Assumptions
- One adopter (person or organization) per bench at a time.
- Adoptions start on the day they're made and last 6, 12, 24, 36 or 60 months.
- Renewals and early cancellations are out of scope.
- The park has 512 benches in 8 areas. Bench locations and existing adoptions are **generated sample data**. In production they would come from the Parks Department's inventory and current records.

## Limitations and next steps
- **Data is stored in each visitor's browser (localStorage).** Adoptions you make are visible only to you. A real version would use a shared database (e.g. Supabase or Firebase) so every visitor sees the same data.
- **Staff admin view** to edit or cancel adoptions and export records to CSV.
- **Map view.** Each bench already has coordinates, so a Leaflet map could be added without changing the data.
- Payment, confirmation emails and renewal reminders.

## Running locally
Download `index.html` and open it in any browser. No installation needed.
