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

    def test_hyprland_shadow_is_softened_only_in_light_mode(self):
        light = THEME.theme_from(self.light_raw(), "/tmp/wallpaper.png", "light")
        dark = dict(light, mode="dark")
        self.assertIn('shadow = "rgba(2917132e)"', THEME.render_hyprland(light))
        self.assertIn('shadow = "rgba(0000006e)"', THEME.render_hyprland(dark))

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
