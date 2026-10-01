"""Tests for verdict.py. Run with: python3 -m unittest discover tests"""
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from verdict import reaction  # noqa: E402


def transcript(*entries):
    f = tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False)
    for e in entries:
        f.write(json.dumps(e) + "\n")
    f.close()
    return f.name


def said(text):
    return {"type": "assistant", "message": {"content": [{"type": "text", "text": text}]}}


class VerdictTests(unittest.TestCase):
    def test_approve_and_request_changes(self):
        self.assertEqual(reaction({"agent_type": "pr-reviewer",
                                   "last_assistant_message": "ok\nVERDICT: APPROVE"}), "approve")
        self.assertEqual(reaction({"agent_type": "pr-reviewer",
                                   "last_assistant_message": "VERDICT: REQUEST_CHANGES"}), "fail")

    def test_comment_and_no_verdict_do_nothing(self):
        self.assertEqual(reaction({"agent_type": "pr-reviewer",
                                   "last_assistant_message": "VERDICT: COMMENT"}), "none")
        self.assertEqual(reaction({"agent_type": "pr-reviewer",
                                   "last_assistant_message": "no verdict here"}), "none")

    def test_other_agents_are_ignored(self):
        self.assertEqual(reaction({"agent_type": "code-reviewer",
                                   "last_assistant_message": "VERDICT: APPROVE"}), "none")

    def test_reads_the_transcript_when_the_payload_has_no_verdict(self):
        path = transcript(said("looking..."), said("VERDICT: APPROVE"))
        self.assertEqual(reaction({"agent_type": "pr-reviewer", "agent_transcript_path": path}), "approve")

    def test_verdict_inside_a_tool_call_counts(self):
        handback = {"type": "assistant", "message": {"content": [
            {"type": "tool_use", "name": "handback", "input": {"report": "...\nVERDICT: REQUEST_CHANGES\n"}}]}}
        path = transcript(handback)
        self.assertEqual(reaction({"agent_type": "pr-reviewer", "agent_transcript_path": path}), "fail")

    def test_the_last_verdict_wins(self):
        path = transcript(said("VERDICT: REQUEST_CHANGES"), said("fixed. VERDICT: APPROVE"))
        self.assertEqual(reaction({"agent_type": "pr-reviewer", "agent_transcript_path": path}), "approve")

    def test_a_missing_transcript_is_not_an_error(self):
        self.assertEqual(reaction({"agent_type": "pr-reviewer",
                                   "agent_transcript_path": "/nonexistent.jsonl"}), "none")


if __name__ == "__main__":
    unittest.main()
