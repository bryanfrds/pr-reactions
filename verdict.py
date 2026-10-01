"""Read a Claude Code SubagentStop hook payload on stdin and print the reaction:
"approve", "fail", or "none".

Only the pr-reviewer subagent counts. Its verdict line looks like
`VERDICT: APPROVE` or `VERDICT: REQUEST_CHANGES`. It may be in the payload's
last message, or only in the agent's transcript - sometimes inside a tool call
that hands the report back - so the transcript is searched too.
"""
import json
import re
import sys

REACTIONS = {"APPROVE": "approve", "REQUEST_CHANGES": "fail"}
VERDICT = re.compile(r"VERDICT:\s*([A-Z_]+)")


def last_verdict_text(transcript_path):
    """The last assistant entry in the transcript that states a verdict."""
    found = ""
    try:
        with open(transcript_path) as f:
            for line in f:
                try:
                    entry = json.loads(line)
                except ValueError:
                    continue
                if entry.get("type") != "assistant":
                    continue
                blob = json.dumps(entry.get("message", {}).get("content", ""))
                if "VERDICT:" in blob:
                    found = blob.replace("\\n", "\n")
    except OSError:
        pass
    return found


def reaction(payload):
    kind = payload.get("agent_type") or payload.get("subagent_type") or ""
    if kind and kind != "pr-reviewer":
        return "none"
    text = payload.get("last_assistant_message") or ""
    if "VERDICT:" not in text and payload.get("agent_transcript_path"):
        text = last_verdict_text(payload["agent_transcript_path"])
    verdicts = VERDICT.findall(text)
    return REACTIONS.get(verdicts[-1], "none") if verdicts else "none"


if __name__ == "__main__":
    try:
        print(reaction(json.load(sys.stdin)))
    except ValueError:
        print("none")
