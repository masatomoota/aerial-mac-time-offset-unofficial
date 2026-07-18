#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import os
import pathlib
import tempfile
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]
FETCH_PATH = ROOT / "bin" / "aerial-fetch"


def load_fetch_module():
    loader = importlib.machinery.SourceFileLoader("aerial_fetch", str(FETCH_PATH))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


fetch = load_fetch_module()


class FetchTests(unittest.TestCase):
    def test_normalize_list_and_assets_forms(self):
        entries = [{"url-1080-SDR": "https://example.invalid/a.mov"}]
        self.assertEqual(fetch.normalize_entries(entries), entries)
        self.assertEqual(fetch.normalize_entries({"assets": entries}), entries)

    def test_quality_to_key(self):
        self.assertEqual(fetch.quality_to_key("1080-sdr"), "url-1080-SDR")
        self.assertEqual(fetch.quality_to_key("1080-hdr"), "url-1080-HDR")
        self.assertEqual(fetch.quality_to_key("4k-sdr"), "url-4K-SDR")
        self.assertEqual(fetch.quality_to_key("4k-hdr"), "url-4K-HDR")
        self.assertEqual(fetch.quality_to_key("1080-h264"), "url-1080-H264")

    def test_select_variant_and_fallback(self):
        entry = {
            "url-1080-SDR": "https://example.invalid/sdr.mov",
            "url-4K-SDR": "https://example.invalid/4k.mov",
            "url-1080-H264": "https://example.invalid/h264.mov",
        }
        self.assertEqual(fetch.select_variant(entry, "4k-sdr"), ("url-4K-SDR", "https://example.invalid/4k.mov"))
        self.assertEqual(fetch.select_variant(entry, "4k-hdr"), ("url-1080-SDR", "https://example.invalid/sdr.mov"))
        self.assertIsNone(fetch.select_variant({}, "1080-sdr"))

    def test_select_variant_strict_never_falls_back(self):
        hevc_only = {"url-1080-SDR": "https://example.invalid/sdr.mov"}
        both = {
            "url-1080-SDR": "https://example.invalid/sdr.mov",
            "url-1080-H264": "https://example.invalid/h264.mov",
        }
        # strict: exact variant or nothing
        self.assertIsNone(fetch.select_variant(hevc_only, "1080-h264", strict=True))
        self.assertEqual(
            fetch.select_variant(both, "1080-h264", strict=True),
            ("url-1080-H264", "https://example.invalid/h264.mov"),
        )
        # non-strict still falls back
        self.assertEqual(
            fetch.select_variant(hevc_only, "1080-h264"),
            ("url-1080-SDR", "https://example.invalid/sdr.mov"),
        )

    def test_dry_run_strict_skips_entries_without_variant(self):
        manifest = {
            "assets": [
                {"url-1080-H264": "https://example.invalid/a.mov"},
                {"url-1080-SDR": "https://example.invalid/b.mov"},
                {"url-1080-H264": "https://example.invalid/c.mov"},
            ]
        }
        self.assertEqual(
            fetch.dry_run_urls(manifest, "1080-h264", 0, strict=True),
            ["https://example.invalid/a.mov", "https://example.invalid/c.mov"],
        )

    def test_config_parser_matches_bash_sourcing(self):
        with tempfile.TemporaryDirectory() as tmp:
            conf = pathlib.Path(tmp) / "t.conf"
            conf.write_text(
                "\n".join(
                    [
                        "# full-line comment",
                        "AERIAL_QUALITY=1080-sdr # inline comment",
                        'AERIAL_CLOCK_FONT="Noto Sans # not a comment"',
                        "AERIAL_CACHE_DIR=$HOME/aerial-cache",
                        "AERIAL_PLAYLIST='$HOME/literal.txt'",
                        "BROKEN = with-spaces",
                        "AERIAL_VIDEO_LIMIT=10",
                    ]
                ),
                encoding="utf-8",
            )
            values = fetch.parse_key_value_config(conf)
        # inline comment stripped, exactly like bash sourcing
        self.assertEqual(values["AERIAL_QUALITY"], "1080-sdr")
        # '#' inside quotes is preserved
        self.assertEqual(values["AERIAL_CLOCK_FONT"], "Noto Sans # not a comment")
        # $VAR expands in unquoted/double-quoted values, not in single quotes
        self.assertEqual(values["AERIAL_CACHE_DIR"], os.environ["HOME"] + "/aerial-cache")
        self.assertEqual(values["AERIAL_PLAYLIST"], "$HOME/literal.txt")
        # space-around-= is not a valid assignment (bash would crash on it)
        self.assertNotIn("BROKEN", values)
        self.assertEqual(values["AERIAL_VIDEO_LIMIT"], "10")

    def test_config_parser_quoted_comment_scope_vars_and_injection_lines(self):
        with tempfile.TemporaryDirectory() as tmp:
            conf = pathlib.Path(tmp) / "t.conf"
            conf.write_text(
                "\n".join(
                    [
                        'QUOTED="foo" # trailing comment after quotes',
                        "BASE=/var/lib/aerial-signage",
                        "CHAINED=$BASE/videos",
                        "CURLY=${BASE}/playlist.txt",
                        "SPACED=a b",
                        'DANGLING="unterminated',
                        "UNKNOWNREF=$NO_SUCH_VAR_XYZ_987654/tail",
                    ]
                ),
                encoding="utf-8",
            )
            values = fetch.parse_key_value_config(conf)
        # closing quote + trailing comment: quotes stripped, comment dropped
        self.assertEqual(values["QUOTED"], "foo")
        # $VAR / ${VAR} expand against earlier assignments in the same file
        self.assertEqual(values["CHAINED"], "/var/lib/aerial-signage/videos")
        self.assertEqual(values["CURLY"], "/var/lib/aerial-signage/playlist.txt")
        # lines the launcher would refuse are skipped, not misread
        self.assertNotIn("SPACED", values)
        self.assertNotIn("DANGLING", values)
        # unset $VAR expands to empty, matching bash expansion when sourced
        self.assertEqual(values["UNKNOWNREF"], "/tail")

    def test_load_manifest_falls_back_on_wrong_shape(self):
        with tempfile.TemporaryDirectory() as tmp:
            bad = pathlib.Path(tmp) / "bad.json"
            bad.write_text(json.dumps({"message": "API rate limit exceeded"}), encoding="utf-8")
            entries, source = fetch.load_manifest(bad.as_uri())
        self.assertTrue(source.endswith("manifest/entries.json"), source)
        self.assertGreater(len(entries), 0)

    def test_download_one_skips_url_without_filename(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = fetch.download_one(
                "https://example.invalid?id=1", pathlib.Path(tmp)
            )
        self.assertIsNone(result)

    def test_is_truthy(self):
        for raw in ("1", "true", "True", "YES", "on"):
            self.assertTrue(fetch.is_truthy(raw), raw)
        for raw in ("0", "false", "", "no", "off"):
            self.assertFalse(fetch.is_truthy(raw), raw)

    def test_dry_run_selects_expected_urls_and_limit(self):
        manifest = {
            "assets": [
                {"url-4K-HDR": "https://example.invalid/a.mov"},
                {"url-1080-SDR": "https://example.invalid/b.mov"},
                {"not-a-url": "skip"},
            ]
        }
        self.assertEqual(fetch.dry_run_urls(manifest, "4k-hdr", 0), [
            "https://example.invalid/a.mov",
            "https://example.invalid/b.mov",
        ])
        self.assertEqual(fetch.dry_run_urls(manifest, "4k-hdr", 1), ["https://example.invalid/a.mov"])


if __name__ == "__main__":
    unittest.main()
