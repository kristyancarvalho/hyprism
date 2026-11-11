import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("hyprism_theme", ROOT / "scripts/theme/generate-theme.py")
THEME = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(THEME)


class ThemeTests(unittest.TestCase):
    def light_raw(self):
        return {
            "background": "#fff8f6", "foreground": "#291713", "accent": "#af2800", "primary": "#af2800",
            "on_primary": "#ffffff", "primary_container": "#db3400", "matugenSource": "#af2800",
            "secondary": "#895040", "on_secondary": "#ffffff", "secondary_container": "#ff7350",
            "tertiary": "#76558e", "on_tertiary": "#ffffff", "surface_low": "#fff1ed",
            "surface_container": "#ffe9e4", "surface_high": "#ffe2db", "surface_highest": "#ffdbd3",
            "on_surface_variant": "#5d3f38", "outline": "#926f66", "inactive_border": "#e8bdb3",
            "error": "#ba1a1a", "on_error": "#ffffff", "error_container": "#ffdad6",
        }

    def test_presets_keep_identity_and_readable_contrast_in_both_modes(self):
        palettes = THEME.preset_palettes()
        self.assertEqual(set(palettes), {"nord", "tokyo-night", "catppuccin", "gruvbox", "everforest", "rose-pine", "monochrome"})
        for name in palettes:
            for mode in ("dark", "light"):
                with self.subTest(name=name, mode=mode):
                    theme = THEME.preset_theme(name, mode, "/wallpaper.png")
                    self.assertEqual(theme["background"], palettes[name][mode]["background"])
                    self.assertEqual(theme["mode"], mode)
                    self.assertGreaterEqual(THEME.contrast(theme["foreground"], theme["background"]), 4.5)
                    self.assertGreaterEqual(THEME.contrast(theme["mutedForeground"], theme["background"]), 4.5)
                    self.assertGreaterEqual(THEME.contrast(theme["accent"], theme["background"]), 3.0)
                    self.assertGreaterEqual(THEME.contrast(theme["accentForeground"], theme["accent"]), 3.0)

    def test_monochrome_preset_is_grayscale(self):
        for mode in ("dark", "light"):
            theme = THEME.preset_theme("monochrome", mode, "")
            for key, value in theme.items():
                if isinstance(value, str) and value.startswith("#"):
                    with self.subTest(mode=mode, key=key):
                        self.assertEqual(len({value[1:3], value[3:5], value[5:7]}), 1)
        self.assertEqual(THEME.preset_theme("monochrome", "dark", "")["background"], "#000000")
        self.assertEqual(THEME.preset_theme("monochrome", "light", "")["background"], "#ffffff")

    def test_palette_setting_defaults_to_wallpaper(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "user.json"
            config.write_text('{"appearance": {"mode": "light", "palette": "catppuccin"}}', encoding="utf-8")
            with mock.patch.dict(THEME.os.environ, {"HYPRISM_CONFIG": str(config)}):
                self.assertEqual(THEME.appearance_settings(), ("light", 0, "catppuccin"))
            config.write_text('{"appearance": {"palette": "unknown"}}', encoding="utf-8")
            with mock.patch.dict(THEME.os.environ, {"HYPRISM_CONFIG": str(config)}):
                self.assertEqual(THEME.appearance_settings()[2], "wallpaper")

    def test_light_theme_has_semantic_surface_hierarchy_and_contrast(self):
        theme = THEME.theme_from(self.light_raw(), "/tmp/wallpaper.png", "light")
        self.assertEqual(theme["mode"], "light")
        self.assertNotEqual(theme["background"], theme["surface"])
        self.assertNotEqual(theme["surface"], theme["surfaceContainerHigh"])
        self.assertGreaterEqual(THEME.contrast(theme["foreground"], theme["background"]), 7)
        self.assertGreaterEqual(THEME.contrast(theme["accent"], theme["background"]), 3.2)
        self.assertNotEqual(theme["surfaceActive"], theme["accent"])

    def test_toolkit_and_gtk_outputs_follow_light_mode(self):
        theme = THEME.theme_from(self.light_raw(), "/tmp/wallpaper.png", "light")
        toolkit = THEME.render_hyprtoolkit(theme)
        THEME.validate_hyprtoolkit(toolkit)
        self.assertIn("background = rgba(fff8f6ff)", toolkit)
        self.assertIn("gtk-application-prefer-dark-theme=0", THEME.render_gtk_settings(theme))
        self.assertIn("Colloid-Hyprism-Light-Matugen", THEME.render_gtk_settings(theme))

    def test_white_temperature_changes_shared_light_surfaces_in_steps(self):
        raw = self.light_raw()
        themes = [THEME.theme_from(THEME.warm_light_palette(raw, level), "/tmp/wallpaper.png", "light") for level in range(4)]
        regular, warm = themes[0], themes[2]
        dark_raw = THEME.fallback_palette("dark")
        self.assertNotEqual(warm["background"], regular["background"])
        self.assertGreater(THEME.rgb(warm["background"])[0], THEME.rgb(warm["background"])[2])
        self.assertEqual(len({theme["background"] for theme in themes}), 4)
        self.assertGreater(THEME.rgb(themes[3]["background"])[0] - THEME.rgb(themes[3]["background"])[2], THEME.rgb(themes[1]["background"])[0] - THEME.rgb(themes[1]["background"])[2])
        self.assertIn(f'background = rgba({warm["background"][1:]}ff)', THEME.render_hyprtoolkit(warm))
        self.assertIn(warm["background"], THEME.render_kitty(warm))
        self.assertEqual(THEME.warm_light_palette(dark_raw, 0), dark_raw)

    def test_hyprland_shadows_are_soft_theme_tinted_and_cover_inactive_windows(self):
        for name in ("tokyo-night", "gruvbox", "monochrome"):
            for mode in ("dark", "light"):
                with self.subTest(name=name, mode=mode):
                    theme = THEME.preset_theme(name, mode, "")
                    active, inactive = THEME.shadow_colors(theme)
                    rendered = THEME.render_hyprland(theme)
                    self.assertIn(f'shadow = "{active}"', rendered)
                    self.assertIn(f'shadow_inactive = "{inactive}"', rendered)
                    self.assertLessEqual(int(active[-3:-1], 16), 0x80)
                    self.assertEqual(inactive, active)
                    self.assertGreater(int(inactive[-3:-1], 16), 0)
        tokyo = THEME.shadow_colors(THEME.preset_theme("tokyo-night", "dark", ""))[0]
        self.assertNotEqual(tokyo[5:11], "000000")
        appearance = (ROOT / "config/hypr/modules/appearance.lua").read_text(encoding="utf-8")
        self.assertIn("color_inactive = palette.shadow_inactive,", appearance)

    def test_hyprlock_light_palette_uses_accessible_inverse_colors(self):
        theme = THEME.theme_from(self.light_raw(), "/tmp/wallpaper.png", "light")
        palette = THEME.hyprlock_palette(theme)
        self.assertLess(THEME.luminance(palette["surface"]), .12)
        self.assertGreaterEqual(THEME.contrast(palette["foreground"], palette["surface"]), 7)
        for role in ("muted", "accent", "secondary", "error"):
            self.assertGreaterEqual(THEME.contrast(palette[role], palette["surface"]), 4.5)
        rendered = THEME.render_hyprlock_config(theme)
        self.assertIn(f'$hyprism_surface = rgb({palette["surface"][1:]})', rendered)
        self.assertIn(f'$hyprism_foreground = rgb({palette["foreground"][1:]})', rendered)

    def test_hyprlock_messages_follow_interface_language(self):
        theme = THEME.theme_from(THEME.fallback_palette("dark"), "/tmp/wallpaper.png", "dark")
        english = THEME.render_hyprlock_config(theme, "en")
        portuguese = THEME.render_hyprlock_config(theme, "pt-BR")
        self.assertIn("    check_text = Authenticating…", english)
        self.assertIn("    fail_text = Incorrect password", english)
        self.assertIn("    text = Locked", english)
        self.assertIn("date +'%m/%d/%Y'", english)
        self.assertIn("    check_text = Autenticando…", portuguese)
        self.assertIn("    fail_text = Senha incorreta", portuguese)
        self.assertIn("    text = Bloqueado", portuguese)
        self.assertIn("date +'%d/%m/%Y'", portuguese)

    def test_dynamic_media_label_is_theme_aware_and_kept_in_generated_config(self):
        for mode, raw in (("dark", THEME.fallback_palette("dark")), ("light", self.light_raw())):
            with self.subTest(mode=mode):
                theme = THEME.theme_from(raw, "/tmp/wallpaper.png", mode)
                rendered = THEME.render_hyprlock_config(theme, "pt-BR")
                self.assertIn("text = cmd[update:2500] hyprism-media-lock-indicator", rendered)
                self.assertIn("color = $hyprism_muted", rendered)
                self.assertIn("reload_cmd = hyprism-media-lock-indicator --cover", rendered)
                image_block = rendered.split("\nimage {\n", 1)[1].split("\n}\n", 1)[0]
                self.assertIn("\n    path =\n", image_block)

    def test_papirus_inheritance_follows_mode(self):
        self.assertIn("Inherits=Papirus,hicolor", THEME.papirus_index(["16x16"], "light"))
        self.assertIn("Inherits=Papirus-Dark,Papirus,hicolor", THEME.papirus_index(["16x16"], "dark"))

    def test_papirus_folder_details_follow_mode_contrast(self):
        source = '<svg><path fill="#5294e2"/><path fill="#1d344f"/></svg>'
        light = THEME.theme_from(self.light_raw(), "/tmp/wallpaper.png", "light")
        dark = THEME.theme_from(THEME.fallback_palette("dark"), "/tmp/wallpaper.png", "dark")
        self.assertIn(f'fill="{light["onPrimary"]}"', THEME.render_papirus_svg(source, light))
        self.assertIn(f'fill="{THEME.mix(dark["accent"], "#000000", .62)}"', THEME.render_papirus_svg(source, dark))

    def test_unchanged_colloid_palette_still_checks_source_patch(self):
        with tempfile.TemporaryDirectory() as temporary:
            previous_output = THEME.OUT
            THEME.OUT = Path(temporary)
            try:
                with mock.patch.object(THEME, "update_colloid") as update_colloid:
                    content = "$accent-dark: #123456;\n"
                    THEME.publish_colloid_palette(content, "dark")
                    THEME.publish_colloid_palette(content, "dark")
                    self.assertEqual(update_colloid.call_count, 2)
                    self.assertEqual(update_colloid.call_args.args[1], "dark")
            finally:
                THEME.OUT = previous_output


if __name__ == "__main__":
    unittest.main()
