#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import pathlib
import tempfile
import unittest
from unittest import mock


ROOT = pathlib.Path(__file__).resolve().parents[1]
WEB_PATH = ROOT / "bin" / "aerial-web"
FIXTURES = ROOT / "tests" / "fixtures"


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

    def test_save_config_fetches_playlist_before_restart(self):
        with tempfile.TemporaryDirectory() as tmp:
            config = pathlib.Path(tmp) / "aerial.conf"
            playlist = pathlib.Path(tmp) / "playlist.txt"
            config.write_text("AERIAL_SOURCE=classic63\n", encoding="utf-8")
            calls = []

            def fake_run_cmd(args, timeout=15):
                calls.append((args, timeout))
                if "aerial-fetch" in str(args[1]):
                    playlist.write_text("one.mp4\n\ntwo.mp4\n", encoding="utf-8")
                    return {"ok": True, "returncode": 0, "stdout": "", "stderr": ""}
                return {"ok": True, "returncode": 0, "stdout": "", "stderr": ""}

            with mock.patch.object(web, "config_path", return_value=config), mock.patch.object(web, "run_cmd", side_effect=fake_run_cmd):
                payload = web.save_config_and_restart({"AERIAL_PLAYLIST": str(playlist), "AERIAL_SOURCE": "community"})

        self.assertTrue(payload["ok"])
        self.assertEqual(payload["fetch"]["returncode"], 0)
        self.assertEqual(payload["playlist_count"], 2)
        self.assertEqual(calls[0][0], ["python3", str(ROOT / "bin" / "aerial-fetch"), "--config", str(config)])
        self.assertEqual(calls[0][1], 150)
        self.assertEqual(calls[1][0], [web.SYSTEMCTL, "restart", "aerial-signage.service"])

    def test_system_status_omits_mpv_when_ipc_unavailable(self):
        with tempfile.TemporaryDirectory() as tmp:
            playlist = pathlib.Path(tmp) / "playlist.txt"
            playlist.write_text("one.mp4\n", encoding="utf-8")
            with mock.patch.object(web, "run_cmd", return_value={"ok": True, "stdout": "active\n", "stderr": ""}), mock.patch.object(
                web, "query_mpv_stats", return_value={}
            ):
                payload = web.system_status({"AERIAL_PLAYLIST": str(playlist)})
        self.assertNotIn("mpv", payload)
        self.assertEqual(payload["playlist_count"], 1)

    def test_system_status_includes_mpv_when_ipc_returns_values(self):
        with mock.patch.object(web, "run_cmd", return_value={"ok": True, "stdout": "active\n", "stderr": ""}), mock.patch.object(
            web, "query_mpv_stats", return_value={"est_display_fps": 59.9, "drops": 3}
        ):
            payload = web.system_status({})
        self.assertEqual(payload["mpv"], {"est_display_fps": 59.9, "drops": 3})

    def test_import_display_settings_plist_maps_spec_layers(self):
        plist_text = (FIXTURES / "display-settings-sample.plist").read_text(encoding="utf-8")
        payload = web.import_display_settings_plist(plist_text)
        cfg = payload["config"]
        self.assertTrue(payload["ok"])
        self.assertEqual(cfg["AERIAL_CLOCK_ENABLED"], "1")
        self.assertEqual(cfg["AERIAL_CLOCK_CORNER"], "topCenter")
        self.assertEqual(cfg["AERIAL_CLOCK_FORMAT"], "custom")
        self.assertEqual(cfg["AERIAL_CLOCK_SECONDS"], "1")
        self.assertEqual(cfg["AERIAL_CLOCK_HIDE_AMPM"], "1")
        self.assertEqual(cfg["AERIAL_CLOCK_CUSTOM_FORMAT"], "%H:%M:%S")
        self.assertEqual(cfg["AERIAL_DATE_ENABLED"], "1")
        self.assertEqual(cfg["AERIAL_DATE_CORNER"], "bottomCenter")
        self.assertEqual(cfg["AERIAL_DATE_FORMAT"], "custom")
        self.assertEqual(cfg["AERIAL_DATE_CUSTOM_FORMAT"], "%Y/%m/%d")
        self.assertEqual(cfg["AERIAL_MSG_ENABLED"], "1")
        self.assertEqual(cfg["AERIAL_MSG_TEXT"], "Hello")
        self.assertEqual(cfg["AERIAL_LOC_ENABLED"], "1")
        self.assertEqual(cfg["AERIAL_LOC_MODE"], "accessibilityLabel")

    def test_datetime_format_translation_preserves_strftime(self):
        self.assertEqual(web.translate_datetime_format("HH:mm:ss"), "%H:%M:%S")
        self.assertEqual(web.translate_datetime_format("%Y-%m-%d"), "%Y-%m-%d")


if __name__ == "__main__":
    unittest.main()
