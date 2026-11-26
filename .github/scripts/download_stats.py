"""Download counts of the suite's releases, per app.

Every package the launcher installs or updates is a release asset of this repository, so GitHub's
download count is a signal of interest: installs plus updates, not distinct people (an app updated
three times counts four). GitHub only keeps a running total per asset, and a deleted release takes its
count with it: run weekly by .github/workflows/download-stats.yml, which keeps every snapshot in
downloads.csv on the "stats" branch, so the trend survives.

    python3 .github/scripts/download_stats.py [downloads.csv]

Without a file it only prints the totals. With one it appends today's totals to it and prints the
change since the previous snapshot. GITHUB_TOKEN, when set, raises the API rate limit.
"""

import csv
import datetime
import json
import os
import re
import sys
import urllib.request
from collections import Counter

REPO = os.environ.get("GITHUB_REPOSITORY", "rouges78/Rouges-Suite")


def releases():
    page = 1
    while True:
        req = urllib.request.Request(
            f"https://api.github.com/repos/{REPO}/releases?per_page=100&page={page}",
            headers={"Accept": "application/vnd.github+json", "User-Agent": "download-stats"},
        )
        token = os.environ.get("GITHUB_TOKEN")
        if token:
            req.add_header("Authorization", f"Bearer {token}")
        with urllib.request.urlopen(req) as resp:
            batch = json.load(resp)
        yield from batch
        if len(batch) < 100:
            return
        page += 1


def totals():
    """Downloads per app: the tag without its version ("pdfking-v0.1.7" -> "pdfking")."""
    count = Counter()
    for rel in releases():
        app = re.sub(r"-v\d+(\.\d+)*$", "", rel["tag_name"])
        count[app] += sum(a["download_count"] for a in rel["assets"])
    return count


def previous(path):
    """The last snapshot in the file: {app: downloads}, and its date."""
    last, date = {}, None
    if os.path.exists(path):
        with open(path, newline="") as f:
            for row in csv.DictReader(f):
                if row["date"] != date:
                    last, date = {}, row["date"]
                last[row["app"]] = int(row["downloads"])
    return last, date


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else None
    now = totals()
    before, since = previous(path) if path else ({}, None)
    today = datetime.date.today().isoformat()

    head = f"| App | Downloads | Since {since} |" if since else "| App | Downloads |"
    lines = [f"## Downloads, {today}", "", head, "|---|--:|" + ("--:|" if since else "")]
    for app, n in sorted(now.items(), key=lambda kv: -kv[1]):
        row = f"| {app} | {n} |"
        if since:
            row += f" {n - before.get(app, 0):+d} |"
        lines.append(row)
    total = sum(now.values())
    lines.append(f"| **all** | **{total}** |" + (f" **{total - sum(before.values()):+d}** |" if since else ""))
    lines += ["", "Installs plus updates done by the launcher, not distinct people."]
    print("\n".join(lines))

    if path and since != today:
        new = not os.path.exists(path) or os.path.getsize(path) == 0
        with open(path, "a", newline="") as f:
            w = csv.writer(f)
            if new:
                w.writerow(["date", "app", "downloads"])
            for app, n in sorted(now.items()):
                w.writerow([today, app, n])


if __name__ == "__main__":
    main()
