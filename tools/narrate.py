#!/usr/bin/env python3
"""Generate narration audio for the published pages from their speech companions.

Reads docs/audio/narration-config.json and docs/audio/pronunciation.json, sends each
segment of every navigated page's .speech.json to the configured speech service, and
records the result in docs/audio/manifest.json. A segment is regenerated only when its
text, the pronunciation rules or the configuration changed. Needs DEEPINFRA_API_KEY.

  python3 tools/narrate.py --list      # passages, characters, estimated cost; no requests
  python3 tools/narrate.py --generate  # generate what is missing or stale
  python3 tools/narrate.py --check     # exit 1 when a clip is missing or stale
"""
import argparse, base64, concurrent.futures, hashlib, json, os, re, sys, threading, urllib.error, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "docs", "audio")
PRICE_PER_CHARACTER = 0.62 / 1_000_000


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def sha(data):
    return hashlib.sha256(data if isinstance(data, bytes) else data.encode()).hexdigest()


def canonical(obj):
    return json.dumps(obj, sort_keys=True, ensure_ascii=False, separators=(",", ":"))


def navigated_pages():
    nav = open(os.path.join(ROOT, "mkdocs.yml"), encoding="utf-8").read()
    pages = sorted(set("docs/" + p for p in re.findall(r"^\s*-\s+[^:\n]+:\s+([A-Za-z0-9_/.-]+\.md)\s*$", nav, re.M)))
    return [p for p in pages if os.path.exists(os.path.join(ROOT, p[:-3] + ".speech.json"))]


def segments(page):
    speech = load(os.path.join(ROOT, page[:-3] + ".speech.json"))
    for section, items in speech.items():
        if section.startswith("_"):
            continue
        for index, item in enumerate(items):
            if not item.get("skip"):
                yield section, index, item["text"], item.get("pause", 200)


def apply_rules(text, rules):
    for rule in sorted(rules, key=lambda r: -len(r["term"])):
        flags = re.IGNORECASE if rule.get("ignore_case") else 0
        pattern = r"(?<![A-Za-z0-9_])" + re.escape(rule["term"]) + r"(?![A-Za-z0-9_])"
        if "phonemes" in rule:
            replacement = lambda m, r=rule: f"[{m.group(0)}](/{r['phonemes']}/)"
        else:
            replacement = lambda m, r=rule: r["spoken"]
        text = re.sub(pattern, replacement, text, flags=flags)
    return text


def clip_name(page, section, index):
    return f"{page[:-3].replace('/', '-')}/{section}-{index:02d}"


def plan(config, rules):
    manifest_path = os.path.join(AUDIO, "manifest.json")
    manifest = load(manifest_path) if os.path.exists(manifest_path) else {"clips": {}}
    config_digest, rules_digest = sha(canonical(config)), sha(canonical(rules))
    items = []
    for page in navigated_pages():
        for section, index, text, pause in segments(page):
            name = clip_name(page, section, index)
            sent = apply_rules(text, rules["rules"])
            key = sha(canonical([text, rules_digest, config_digest]))
            old = manifest["clips"].get(name)
            fresh = (
                old is not None
                and old["key"] == key
                and os.path.exists(os.path.join(AUDIO, "clips", name + ".mp3"))
            )
            items.append(dict(name=name, page=page, section=section, index=index, text=text,
                              sent=sent, pause=pause, key=key, fresh=fresh))
    return manifest, items, config_digest, rules_digest


def request(config, text, api_key):
    body = {
        "text": text,
        "preset_voice": config["voice"]["preset_voice"],
        "output_format": config["output_format"],
        "speed": config["speed"],
        "service_tier": config["service_tier"],
        "return_timestamps": config["return_timestamps"],
    }
    req = urllib.request.Request(
        config["endpoint"], json.dumps(body).encode(),
        {"Authorization": "Bearer " + api_key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=300) as r:
        return json.load(r)


def main():
    ap = argparse.ArgumentParser()
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--list", action="store_true")
    mode.add_argument("--generate", action="store_true")
    mode.add_argument("--check", action="store_true")
    ap.add_argument("--jobs", type=int, default=8, help="concurrent requests while generating")
    ap.add_argument("--only", help="restrict to clips whose name contains this text")
    args = ap.parse_args()

    config = load(os.path.join(AUDIO, "narration-config.json"))
    rules = load(os.path.join(AUDIO, "pronunciation.json"))
    manifest, items, config_digest, rules_digest = plan(config, rules)
    if args.only:
        items = [i for i in items if args.only in i["name"]]
    todo = [i for i in items if not i["fresh"]]
    chars = sum(len(i["sent"]) for i in todo)

    if args.list:
        for i in items:
            print(("fresh " if i["fresh"] else "TODO  ") + f"{len(i['sent']):6d}  {i['name']}")
        print(f"{len(todo)} of {len(items)} clips to generate, {chars} characters, "
              f"estimated ${chars * PRICE_PER_CHARACTER:.4f}")
        return 0
    if args.check:
        for i in todo:
            print("stale or missing:", i["name"])
        return 1 if todo else 0

    api_key = os.environ.get("DEEPINFRA_API_KEY")
    if not api_key:
        sys.exit("DEEPINFRA_API_KEY is not set")
    lock, stop = threading.Lock(), threading.Event()
    done = [0]
    spent = [0.0]

    def one(i):
        if stop.is_set():
            return
        try:
            r = request(config, i["sent"], api_key)
            if r["inference_status"]["status"] != "succeeded":
                raise RuntimeError(f"inference status {r['inference_status']}")
            audio = base64.b64decode(r["audio"].split(",", 1)[-1])
        except (urllib.error.URLError, TimeoutError, RuntimeError, KeyError) as e:
            stop.set()
            print(f"stopped at {i['name']}: {e}; a billable request is not retried automatically", flush=True)
            return
        path = os.path.join(AUDIO, "clips", i["name"] + ".mp3")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(audio)
        words = [{"text": w["text"], "start": round(w["start"], 3), "end": round(w["end"], 3)}
                 for w in r.get("words") or []]
        cost = r["inference_status"]["cost"]
        with lock:
            spent[0] += cost
            done[0] += 1
            manifest["clips"][i["name"]] = {
                "page": i["page"], "section": i["section"], "index": i["index"],
                "key": i["key"], "text_sha256": sha(i["text"]), "sent_text": i["sent"],
                "pause_ms": i["pause"], "audio_sha256": sha(audio), "characters": r["input_character_length"],
                "cost": cost, "duration": words[-1]["end"] if words else None, "words": words,
            }
            manifest["pronunciation_sha256"], manifest["configuration_sha256"] = rules_digest, config_digest
            with open(os.path.join(AUDIO, "manifest.json"), "w", encoding="utf-8") as f:
                json.dump(manifest, f, ensure_ascii=False, indent=1, sort_keys=True)
                f.write("\n")
            print(f"[{done[0]}/{len(todo)}] {i['name']}  {r['input_character_length']} chars  ${cost:.6f}", flush=True)

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        list(pool.map(one, todo))
    print(f"generated {done[0]} of {len(todo)} clips, ${spent[0]:.4f}")
    if stop.is_set():
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
