# Zotero-based Arxiv Daily Recommendation

This project recommends 5 recent `astro-ph` papers based on your profile.
It is designed so that you can run it with one command.

## What You Need
- Codex Desktop or Codex CLI installed and logged in
- `python3`
- macOS/Linux terminal

## Fastest Start (No Git Required)
1. Open the GitHub repository page.
2. Click `Code` -> `Download ZIP`.
3. Unzip it.
4. Open Terminal in that folder.
5. Run:

```bash
./start
```

If no personal profile exists yet, the script auto-initializes a default profile and still works.

## Git Start (If You Use Git)
```bash
git clone https://github.com/GRQTM/zotero-based-arxiv-daily-recommendation.git
cd zotero-based-arxiv-daily-recommendation
./start
```

## Two Run Modes
- `./start`
  - Recommendation only
  - Uses existing profile, or auto-creates one from template
- `./start -r`
  - Refreshes profile from your Zotero library, then runs recommendation
  - Requires Zotero API key

## Personalized Mode (Optional)
If you want recommendations based on your own Zotero library:

1. Create your key file from the example:

```bash
cp .zotero_api_key.example .zotero_api_key
chmod 600 .zotero_api_key
```

2. Open `.zotero_api_key` and paste your Zotero API key on the first line.
3. Run:

```bash
./start -r
```

Optional:
- Add `.zotero_user_id` file (or set `ZOTERO_USER_ID`) to skip key lookup API call.

Note:
- If you run `./start -r` without any key file, the script auto-creates `.zotero_api_key` template and exits with instructions.

## Typical Daily Usage
1. First time personalized setup: `./start -r`
2. Later runs: `./start`

## Command Reference
- `./start`: recommend from last 2 days of arXiv astro-ph
- `./start -r`: rebuild profile from Zotero + recommend
- `npm start`: same as `./start`
- `bash ./start.sh`: same as `./start`

## Troubleshooting
- `codex binary not found`
  - Install Codex app/CLI, or run with explicit path:
  - `CODEX_BIN=/custom/path/to/codex ./start`
- `permission denied` on start scripts
  - `chmod +x start start.sh`
- `python3: command not found`
  - Install Python 3 and retry

## Security Notes
- API keys are read from environment variables or local key files only.
- Keys are not passed as CLI arguments.
- `.zotero_api_key` and `.zotero_user_id` are git-ignored by default.

## Main Files
- `start.sh`: orchestrates the full pipeline
- `scripts/fetch_zotero_library.py`: fetches Zotero metadata
- `scripts/fetch_arxiv_astro_ph.py`: fetches recent arXiv astro-ph papers
- `prompts/01_build_zotero_profile.prompt.md`: profile generation prompt
- `prompts/02_recommend_astro_ph_last2days.prompt.md`: recommendation prompt
- `templates/zotero_recommendation_profile.sample.md`: fallback profile template
