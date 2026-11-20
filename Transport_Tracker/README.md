# Public Transport Timetable and Delay Tracker

A terminal application for the **Scripting Workshop**, built with Bash, AWK, sort and standard command-line utilities. Manage daily bus, train and metro timetables, enter delay estimates, and generate readable reports.

## Run

Requires Bash 3.2+ (the default macOS Bash is supported), AWK and standard Unix tools. No installation or external packages are needed.

```bash
git clone https://github.com/shanusrigowtham17-del/SWS_ASSIGNMENT.git
cd SWS_ASSIGNMENT
bash Transport_Tracker/main.sh
```

The first launch creates example services using a here-document. Your changes are saved automatically in `Transport_Tracker/data/`. Run the program from any directory; its data paths are resolved relative to the scripts. Exit with option `0`.

## Five-person module division

| Member | File | Responsibility |
| --- | --- | --- |
| 1 | `Transport_Tracker/main.sh` | Main menu, module integration, session lock |
| 2 | `Transport_Tracker/data_manager.sh` | Initialize CSV files, validate input, add/remove services |
| 3 | `Transport_Tracker/timetable.sh` | Display sorted timetable and search services |
| 4 | `Transport_Tracker/delay_tracker.sh` | Save delay updates, calculate arrivals, display history |
| 5 | `Transport_Tracker/reports.sh` | Statistics and saved text reports |

## Menu

1. View timetable, sorted by departure time.
2. Search by ID, transport type, origin or destination (case insensitive).
3. Add a service with a unique ID and valid 24-hour times.
4. Remove a service after confirmation; retain its historical records.
5. Record or replace today's delay for a service: `0` means on time, `1–1440` means delayed.
6. View today's status and expected arrival, including next-day rollover.
7. View historical observations for one service or all services.
8. Show and save a summary report.

## Example

Choose `5`, enter `B101`, delay `20`, and reason `Traffic`. Choose `6`: the service's scheduled arrival of `09:30` becomes an expected arrival of `09:50`. Choose `8` to save a report.

## Data and assumptions

- This is a **manual tracker**; updates are entered by the user. There is no live GPS or transport API connection.
- Services repeat daily. Times and service dates use the computer's local timezone.
- An arrival earlier than departure belongs to the next day. Equal times represent a same-day arrival. The same delay is applied to the scheduled arrival as an estimate.
- An overnight trip is recorded under its departure date. This version accepts updates for today's departure date only.
- One latest observation is retained per service per date. Updating it replaces that day's previous observation; history is not an audit log of every edit.
- Missing updates display **No update**, not on time. Reports calculate rates only from reported observations.
- CSV values cannot contain commas, tabs or newlines. IDs are case sensitive; accepted types are `Bus`, `Train`, `Metro`.
- Delay records contain a route snapshot so removing or reusing a service ID does not rewrite historical routes.
- Reports are saved under `Transport_Tracker/data/reports/`. Runtime data is excluded from Git.
- Only one interactive session can use a data directory at a time. After a forced termination such as `kill -9`, remove the stale `Transport_Tracker/data/.session_lock` directory after checking that no session is running.

For a separate data directory:

```bash
TRANSPORT_DATA_DIR="$HOME/transport-data" bash Transport_Tracker/main.sh
```

## Check the project

```bash
bash tests/smoke.sh
```

The checks use a temporary data directory and cover validation, persistence, search, delay replacement, midnight rollover, removal/history, reports, and menu exit. They leave your application data untouched.
