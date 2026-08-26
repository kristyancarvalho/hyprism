import importlib.util
from pathlib import Path
import unittest


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

    def test_hyprland_shadow_is_softened_only_in_light_mode(self):
        light = THEME.theme_from(self.light_raw(), "/tmp/wallpaper.png", "light")
        dark = dict(light, mode="dark")
        self.assertIn('shadow = "rgba(2917132e)"', THEME.render_hyprland(light))
        self.assertIn('shadow = "rgba(0000006e)"', THEME.render_hyprland(dark))

    def test_papirus_inheritance_follows_mode(self):
        self.assertIn("Inherits=Papirus,hicolor", THEME.papirus_index(["16x16"], "light"))
        self.assertIn("Inherits=Papirus-Dark,Papirus,hicolor", THEME.papirus_index(["16x16"], "dark"))

    def test_papirus_folder_details_follow_mode_contrast(self):
        source = '<svg><path fill="#5294e2"/><path fill="#1d344f"/></svg>'
        light = THEME.theme_from(self.light_raw(), "/tmp/wallpaper.png", "light")
        dark = THEME.theme_from(THEME.fallback_palette("dark"), "/tmp/wallpaper.png", "dark")
        self.assertIn(f'fill="{light["onPrimary"]}"', THEME.render_papirus_svg(source, light))
        self.assertIn(f'fill="{THEME.mix(dark["accent"], "#000000", .62)}"', THEME.render_papirus_svg(source, dark))


if __name__ == "__main__":
    unittest.main()
