# pr-reactions

When Claude Code reviews a pull request for me, I wanted to *see* the result, not dig for it in the chat. So now a picture fades in at the bottom of the screen with a sound: one for an approval, another when changes are requested. Mine are a basketball meme for a green review and a Thanos memoji crumbling to dust for a red one.

This repo has the script and two plain cards to start with. Bring your own pictures and sounds.

![The two default cards: a green APPROVED card and a red CHANGES REQUESTED card](docs/cards.png)

## How it works

Claude Code can run a command when a subagent finishes (a `SubagentStop` hook). This one:

1. Checks the subagent was `pr-reviewer`, and ignores every other agent.
2. Finds its verdict line, `VERDICT: APPROVE` or `VERDICT: REQUEST_CHANGES`. It looks in the agent's last message first, then in its transcript, because some setups hand the report back inside a tool call.
3. Shows the matching picture in a small rounded window at the bottom centre of the screen, just above the Dock. The window fades in, stays a couple of seconds and fades out. Clicks go straight through it, and animated GIFs play.
4. Plays the matching sound alongside it, if there is one.

A `COMMENT` verdict, or anything else, shows nothing. The popup runs on its own and the hook returns straight away, so Claude isn't held up. It uses about 75MB for the few seconds it's on screen, then exits.

It's macOS only for now, because the popup is drawn with AppKit through `osascript`.

## Setup

You need Claude Code, Python 3, and a `pr-reviewer` subagent that ends its review with a verdict line. If you don't have one, copy [`examples/pr-reviewer.md`](examples/pr-reviewer.md) into `~/.claude/agents/`.

```bash
git clone https://github.com/bryanfrds/pr-reactions.git ~/pr-reactions
cd ~/pr-reactions
./install.sh
```

The installer adds the hook to `~/.claude/settings.json`, keeping a backup next to it, and creates `~/.config/pr-reactions/`. Chats that are already open pick it up after you run `/hooks` once, or restart them. New chats have it straight away.

Try both reactions without waiting for a real review:

```bash
./pr-reactions.sh --show approve
./pr-reactions.sh --show fail
```

To uninstall, run `./install.sh --remove`.

## Your own pictures and sounds

Put them in `~/.config/pr-reactions/`, named after the reaction:

```
~/.config/pr-reactions/
  approve.gif     # or .png / .jpg
  approve.mp3     # or .m4a / .wav / .aiff
  fail.gif
  fail.mp3
  config          # optional
```

Anything you leave out falls back to the default card, or to no sound. The `config` file is plain shell:

```bash
APPROVE_SECONDS=4    # how long it stays fully visible (fading adds about 1s)
FAIL_SECONDS=1.5
VOLUME=0.35          # 1 is full volume
```

A few `ffmpeg` one-liners I used to get mine right:

```bash
# Cut a sound to its first 3 seconds, quieter, fading in and out
ffmpeg -i loud.mp3 -t 3 -af "volume=0.35,afade=t=in:d=0.3,afade=t=out:st=2.4:d=0.6" approve.mp3

# Make a GIF's white background see-through, and play it once instead of looping
ffmpeg -i reaction.gif -filter_complex "[0]colorkey=0xFFFFFF:0.3:0.05,split[a][b];[a]palettegen=reserve_transparent=1[p];[b][p]paletteuse=alpha_threshold=160" -loop -1 fail.gif
```

Memes and sound clips usually belong to someone else, so keep yours in the config folder and out of any repo you publish. This repo's `.gitignore` already covers `media/`.

## Files

- `pr-reactions.sh`: the hook. It picks the reaction, finds the files and starts the popup and sound.
- `verdict.py`: reads the hook's JSON and works out `approve`, `fail` or `none`.
- `popup.js`: the fading window (JavaScript for Automation).
- `install.sh`: adds or removes the hook.
- `scripts/make-cards.js`: redraws the default cards.
- `tests/`: unit tests for the verdict parser, plus a dry-run check of the whole hook. Run them with `python3 -m unittest discover tests` and `bash tests/test_hook.sh`. CI runs both on every pull request.

## License

MIT
