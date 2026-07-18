#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import os
import pathlib
import contextlib
import io
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

    def test_sources_resolution_back_compat_manifest_override(self):
        sources = [
            {"id": "classic63", "manifest_url": "https://example.invalid/classic.json"},
            {"id": "community", "manifest_url": "https://example.invalid/community.json"},
        ]
        self.assertEqual(
            fetch.resolve_manifest_url("community", fetch.DEFAULTS["AERIAL_MANIFEST_URL"], sources),
            "https://example.invalid/community.json",
        )
        self.assertEqual(
            fetch.resolve_manifest_url("community", "https://override.invalid/entries.json", sources),
            "https://override.invalid/entries.json",
        )

    def test_scene_filtering_and_hidden_videos(self):
        entries = [
            {"id": "a", "accessibilityLabel": "Coast", "scene": "sea"},
            {"id": "b", "accessibilityLabel": "Tokyo", "category": "city"},
            {"id": "c", "accessibilityLabel": "Forest Trail"},
            {"id": "d", "accessibilityLabel": "Mars Orbit"},
        ]
        scene_map = {"Forest": "nature", "Mars": "space"}
        filtered = fetch.filter_entries(entries, "sea,nature,space", "d", scene_map)
        self.assertEqual([entry["id"] for entry in filtered], ["a", "c"])
        self.assertEqual(fetch.resolve_scene(entries[2], scene_map), "nature")
        self.assertEqual(fetch.resolve_scene({"id": "x", "accessibilityLabel": "Unknown"}, {}), "nature")

    def test_labels_tsv_content(self):
        with tempfile.TemporaryDirectory() as tmp:
            labels = pathlib.Path(tmp) / "labels.tsv"
            fetch.write_labels([("a.mov", "City\tLabel", "asset-1", "city", "City Name", '{"0":"POI"}')], labels)
            self.assertEqual(labels.read_text(encoding="utf-8"), 'a.mov\tCity Label\tasset-1\tcity\tCity Name\t{"0":"POI"}\n')

    def test_apple_strings_parser_text_fixture(self):
        raw = (
            '\ufeff/* comment */\n'
            '"A016_C009_0" = "Cape\\nSeals";\n'
            '"QUOTE" = "A \\"quoted\\" value and \\U65E5"; // trailing\n'
        ).encode("utf-16")
        parsed = fetch.parse_apple_strings_bytes(raw)
        self.assertEqual(parsed["A016_C009_0"], "Cape\nSeals")
        self.assertEqual(parsed["QUOTE"], 'A "quoted" value and 日')

    def test_apple_strings_parser_utf16le_without_bom(self):
        raw = '"K" = "V";\n'.encode("utf-16-le")
        self.assertEqual(fetch.parse_apple_strings_bytes(raw), {"K": "V"})

    def test_entry_poi_rows_resolves_localized_strings(self):
        entry = {
            "id": "asset-1",
            "accessibilityLabel": "Label",
            "pointsOfInterest": {"20": "KEY_20", "0": "KEY_0", "30": "Literal location"},
        }
        strings = {
            "ja": {"KEY_0": "日本語0"},
            "en": {"KEY_0": "English 0", "KEY_20": "English 20"},
        }
        rows = fetch.entry_poi_rows(entry, strings)
        self.assertEqual([row["t"] for row in rows], [0, 20, 30])
        self.assertEqual(rows[0], {"t": 0, "key": "KEY_0", "text_ja": "日本語0", "text_en": "English 0"})
        self.assertEqual(rows[1], {"t": 20, "key": "KEY_20", "text_ja": "", "text_en": "English 20"})
        self.assertEqual(rows[2], {"t": 30, "key": "Literal location", "text_ja": "", "text_en": "Literal location"})

    def test_labels_json_content(self):
        with tempfile.TemporaryDirectory() as tmp:
            labels = pathlib.Path(tmp) / "labels.json"
            fetch.write_labels_json(
                [
                    {
                        "file": "a.mov",
                        "label": "City",
                        "accessibilityLabel": "City",
                        "id": "asset-1",
                        "scene": "city",
                        "name": "City Name",
                        "pointsOfInterest": [{"t": 10, "key": "K", "text_ja": "日本語", "text_en": "English"}],
                    }
                ],
                labels,
            )
            payload = json.loads(labels.read_text(encoding="utf-8"))
        self.assertEqual(payload["videos"][0]["label"], "City")
        self.assertEqual(payload["videos"][0]["pointsOfInterest"][0]["text_ja"], "日本語")

    def test_entry_name_and_poi_json(self):
        entry = {"id": "asset-1", "accessibilityLabel": "Label", "name": "Video Name", "pointsOfInterest": {"10": "Point"}}
        self.assertEqual(fetch.entry_name(entry), "Video Name")
        self.assertEqual(fetch.entry_poi_json(entry), '{"10":"Point"}')

    def test_list_videos_output_shape_from_cli(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = pathlib.Path(tmp)
            cache = tmp_path / "cache"
            cache.mkdir()
            (cache / "a.mov").write_text("cached", encoding="utf-8")
            manifest = tmp_path / "entries.json"
            manifest.write_text(
                json.dumps(
                    {
                        "assets": [
                            {
                                "id": "a",
                                "accessibilityLabel": "Sea One",
                                "scene": "sea",
                                "url-1080-H264": "https://example.invalid/a.mov",
                            },
                            {
                                "id": "b",
                                "accessibilityLabel": "City Two",
                                "category": "city",
                                "url-1080-SDR": "https://example.invalid/b.mov",
                            },
                        ]
                    }
                ),
                encoding="utf-8",
            )
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                code = fetch.main(
                    [
                        "--manifest-url",
                        manifest.as_uri(),
                        "--quality",
                        "1080-h264",
                        "--cache-dir",
                        str(cache),
                        "--list-videos",
                    ]
                )
            self.assertEqual(code, 0)
            rows = [line.split("\t") for line in out.getvalue().splitlines()]
            self.assertEqual(rows[0], ["a", "sea", "Sea One", "1", "1"])
            self.assertEqual(rows[1], ["b", "city", "City Two", "0", "0"])


if __name__ == "__main__":
    unittest.main()
