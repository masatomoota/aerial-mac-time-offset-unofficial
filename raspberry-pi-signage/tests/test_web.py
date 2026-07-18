#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import pathlib
import tempfile
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[1]
WEB_PATH = ROOT / "bin" / "aerial-web"


def load_web_module():
    loader = importlib.machinery.SourceFileLoader("aerial_web", str(WEB_PATH))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


web = load_web_module()


class WebTests(unittest.TestCase):
    def test_rewrite_config_preserves_comments_unknown_and_quotes_spaces(self):
        original = "\n".join(
            [
                "# comment",
                "UNKNOWN_KEY=keep",
                "AERIAL_MSG_TEXT=old",
                "AERIAL_CLOCK_FONT_SIZE=48",
            ]
        )
        rewritten = web.rewrite_config_text(
            original,
            {
                "AERIAL_MSG_TEXT": "Studio Vibes Wi-Fi\\nSSID : demo",
                "AERIAL_CLOCK_FONT_SIZE": "50",
                "AERIAL_SOURCE": "community",
            },
        )
        self.assertIn("# comment", rewritten)
        self.assertIn("UNKNOWN_KEY=keep", rewritten)
        self.assertIn('AERIAL_MSG_TEXT="Studio Vibes Wi-Fi\\nSSID : demo"', rewritten)
        self.assertIn("AERIAL_CLOCK_FONT_SIZE=50", rewritten)
        self.assertIn("AERIAL_SOURCE=community", rewritten)

    def test_rewrite_config_rejects_invalid_values(self):
        with self.assertRaises(ValueError):
            web.rewrite_config_text("", {"AERIAL_MSG_TEXT": 'bad " quote'})
        with self.assertRaises(ValueError):
            web.rewrite_config_text("", {"AERIAL_MPV_EXTRA": "x; rm -rf /"})

    def test_token_matches(self):
        self.assertTrue(web.token_matches("secret", "secret"))
        self.assertFalse(web.token_matches("secret", "other"))
        self.assertFalse(web.token_matches("", ""))

    def test_write_config_file_replaces_in_place(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "aerial.conf"
            path.write_text("# keep\nAERIAL_SOURCE=classic63\n", encoding="utf-8")
            web.write_config_file(path, {"AERIAL_SOURCE": "community", "AERIAL_VIDEO_LIMIT": 3})
            text = path.read_text(encoding="utf-8")
        self.assertIn("# keep", text)
        self.assertIn("AERIAL_SOURCE=community", text)
        self.assertIn("AERIAL_VIDEO_LIMIT=3", text)

    def test_api_state_with_fake_status(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = pathlib.Path(tmp) / "aerial.conf"
            path.write_text("AERIAL_SOURCE=classic63\n", encoding="utf-8")
            with mock.patch.object(web, "config_path", return_value=path), mock.patch.object(
                web, "system_status", return_value={"service_active": True}
            ):
                payload = web.api_state()
        self.assertEqual(payload["config"]["AERIAL_SOURCE"], "classic63")
        self.assertTrue(payload["status"]["service_active"])


if __name__ == "__main__":
    unittest.main()
