/*-
 * Copyright (c) 2015-2018 elementary LLC.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

public class Network.WifiMenuItem : Gtk.ListBoxRow {
    public signal void user_action ();
    public signal void show_settings ();

    public bool is_secured { get; private set; }
    public bool active { get; set; }
    public Network.State state { get; set; default = Network.State.DISCONNECTED; }

    private NM.AccessPoint _tmp_ap;
    public NM.AccessPoint ap {
        get {
            return _tmp_ap;
        }
    }

    public GLib.Bytes ssid {
        get {
            return _tmp_ap.get_ssid ();
        }
    }

    private Gee.LinkedList<NM.AccessPoint> _ap;
    private uint8 strength {
        get {
            uint8 strength = 0;
            foreach (var ap in _ap) {
                strength = uint8.max (strength, ap.get_strength ());
            }
            return strength;
        }
    }

    public Gtk.Image img_strength { get; private set; }
    public Gtk.Label ssid_label { get; private set; }
    public Gtk.Label status_label { get; private set; }

    private Gtk.Image lock_img;
    private Gtk.Image error_img;
    private Gtk.Revealer connect_button_revealer;
    private Gtk.Revealer settings_button_revealer;
    private Gtk.Spinner spinner;

    public WifiMenuItem (NM.AccessPoint ap, NM.Device? device = null) {
        img_strength = new Gtk.Image ();
        img_strength.icon_size = Gtk.IconSize.DND;

        ssid_label = new Gtk.Label (null);
        ssid_label.ellipsize = Pango.EllipsizeMode.END;
        ssid_label.xalign = 0;

        status_label = new Gtk.Label (null);
        status_label.use_markup = true;
        status_label.xalign = 0;

        lock_img = new Gtk.Image.from_icon_name ("channel-insecure-symbolic", Gtk.IconSize.MENU);

        /* TODO: investigate this, it has not been tested yet. */
        error_img = new Gtk.Image.from_icon_name ("process-error-symbolic", Gtk.IconSize.MENU);

        spinner = new Gtk.Spinner ();

        var connect_button = new Gtk.Button.with_label (_("Connect"));
        connect_button.valign = Gtk.Align.CENTER;

        var settings_button = new Gtk.Button.from_icon_name ("view-more-horizontal-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        settings_button.halign = Gtk.Align.END;
        settings_button.hexpand = true;
        settings_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        settings_button_revealer = new Gtk.Revealer ();
        settings_button_revealer.reveal_child = false;
        settings_button_revealer.add (settings_button);

        connect_button_revealer = new Gtk.Revealer ();
        connect_button_revealer.transition_type = Gtk.RevealerTransitionType.NONE;
        connect_button_revealer.reveal_child = true;
        connect_button_revealer.add (connect_button);

        var grid = new Gtk.Grid ();
        grid.valign = Gtk.Align.CENTER;
        grid.column_spacing = 6;
        grid.margin = 6;
        grid.attach (img_strength, 0, 0, 1, 2);
        grid.attach (ssid_label, 1, 0);
        grid.attach (status_label, 1, 1, 2);
        grid.attach (lock_img, 2, 0);
        grid.attach (error_img, 3, 0, 1, 2);
        grid.attach (spinner, 4, 0, 1, 2);
        grid.attach (settings_button_revealer, 5, 0, 1, 2);
        grid.attach (connect_button_revealer, 6, 0, 1, 2);

        _ap = new Gee.LinkedList<NM.AccessPoint> ();

        /* Adding the access point triggers update */
        add_ap (ap);

        add (grid);

        notify["state"].connect (update);
        notify["active"].connect (update);

        connect_button.clicked.connect (() => {
            user_action ();
        });

        settings_button.clicked.connect (() => {
            show_settings ();
        });

        update ();
    }

    void update_tmp_ap () {
        uint8 strength = 0;
        foreach (var ap in _ap) {
            _tmp_ap = strength > ap.strength ? _tmp_ap : ap;
            strength = uint8.max (strength, ap.strength);
        }
    }

    private void update () {
        ssid_label.label = NM.Utils.ssid_to_utf8 (ap.get_ssid ().get_data ());
        unowned string state_string;

        img_strength.icon_name = "network-wireless-signal-" + strength_to_string (strength);
        img_strength.show_all ();

        var flags = ap.get_wpa_flags ();
        is_secured = false;
        if (NM.@80211ApSecurityFlags.GROUP_WEP40 in flags) {
            is_secured = true;
            state_string = _("40/64-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.GROUP_WEP104 in flags) {
            is_secured = true;
            state_string = _("104/128-bit WEP encrypted");
        } else if (NM.@80211ApSecurityFlags.KEY_MGMT_PSK in flags) {
            is_secured = true;
            state_string = _("WPA encrypted");
        } else if (flags != NM.@80211ApSecurityFlags.NONE || ap.get_rsn_flags () != NM.@80211ApSecurityFlags.NONE) {
            is_secured = true;
            state_string = _("Encrypted");
        } else {
            state_string = _("Unsecured");
        }

        lock_img.visible = !is_secured;
        lock_img.no_show_all = !lock_img.visible;

        hide_item (error_img);
        spinner.active = false;

        switch (state) {
            case State.FAILED:
                show_item (error_img);
                state_string = _("Could not be connected to");
                break;
            case State.CONNECTING:
                spinner.active = true;
                state_string = _("Connecting");
                break;
            case State.CONNECTED:
                connect_button_revealer.reveal_child = false;
                settings_button_revealer.reveal_child = true;
                break;
        }

        status_label.label = GLib.Markup.printf_escaped ("<span font_size='small'>%s</span>", state_string);
    }

    private void show_item (Gtk.Widget w) {
        w.visible = true;
        w.no_show_all = !w.visible;
    }

    private void hide_item (Gtk.Widget w) {
        w.visible = false;
        w.no_show_all = !w.visible;
    }

    public void add_ap (NM.AccessPoint ap) {
        _ap.add (ap);
        update_tmp_ap ();
        update ();
    }

    private string strength_to_string (uint8 strength) {
        if (strength < 30) {
            return "weak";
        } else if (strength < 55) {
            return "ok";
        } else if (strength < 80) {
            return "good";
        } else {
            return "excellent";
        }
    }

    public bool remove_ap (NM.AccessPoint ap) {
        _ap.remove (ap);
        update_tmp_ap ();
        return !_ap.is_empty;
    }
}
