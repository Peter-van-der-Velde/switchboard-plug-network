// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Adam Bieńkowski (http://launchpad.net/switchboard-network-plug)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <tintou@mailoo.org>
 */

namespace Network.Widgets {
    public class WiFiPage : Gtk.Box {
        public Gtk.Switch control_switch;
        private Gtk.ListBox wifi_list;

        public WiFiPage (NM.Client client) {
            this.orientation = Gtk.Orientation.VERTICAL;
            this.margin = 30;
            this.spacing = this.margin;
            
            wifi_list = new Gtk.ListBox ();
            wifi_list.selection_mode = Gtk.SelectionMode.SINGLE;
            wifi_list.activate_on_single_click = false; 
            
            var scrolled = new Gtk.ScrolledWindow (null, null);
            scrolled.add (wifi_list);
            scrolled.vexpand = true;

            var frame = new Gtk.Frame (null);
            frame.add (scrolled);
            var control_row = new Gtk.ListBoxRow ();
            control_row.selectable = false;

            var wifi_img = new Gtk.Image.from_icon_name ("network-wireless", Gtk.IconSize.DIALOG);
            wifi_img.margin_end = 15;

            var control_label = new Gtk.Label (_("Wi-Fi Network"));
            control_label.get_style_context ().add_class ("h2");

            var wireless_label = new Gtk.Label ("<b>" + _("Wireless:") + "</b>");
            wireless_label.use_markup = true;

            control_switch = new Gtk.Switch ();
            control_switch.active = client.wireless_get_enabled ();

            var control_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            control_box.pack_start (wifi_img, false, false, 0);
            control_box.pack_start (control_label, false, false, 0);
            control_box.pack_end (control_switch, false, false, 0);
            control_box.pack_end (wireless_label, false, false, 0);

            var disconnect_btn = new Gtk.Button.with_label (_("Disconnect"));
            disconnect_btn.get_style_context ().add_class ("destructive-action");

            var forget_btn = new Gtk.Button.with_label (_("Forget"));
           
            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 7);
            button_box.pack_end (disconnect_btn, false, false, 0);
            button_box.pack_end (forget_btn, false, false, 0);
            
            wifi_list.add (control_row);
            this.add (control_box);
            this.add (frame);
            this.add (button_box);
            this.show_all ();   
        }

        public void list_connections_from_device (NM.DeviceWifi? wifidevice) {
            var access_points = wifidevice.get_access_points ();
            access_points.@foreach ((access_point) => {
                var row = new WiFiEntry.from_access_point (access_point);
                if (access_point == wifidevice.get_active_access_point ())
                    row.set_point_connected (true);
                wifi_list.add (row);
                this.show_all ();
            });             
        }             
    }  
}
